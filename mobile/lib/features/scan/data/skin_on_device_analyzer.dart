import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' show Rect;

import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:flutter_litert/flutter_litert.dart';

import '../models/skin_analysis.dart';

/// On-device inference pipeline for the three exported YOLOv8 LiteRT models.
///
/// Pipeline: ML Kit face detection -> largest-face crop with 12% context ->
/// 640x640 letterbox -> YOLOv8 raw-output decode/NMS -> real findings.
/// Skin type deliberately remains the existing UI demo value for now.
class SkinOnDeviceAnalyzer {
  SkinOnDeviceAnalyzer._();

  static final SkinOnDeviceAnalyzer instance = SkinOnDeviceAnalyzer._();

  static const int _inputSize = 640;
  static const int _anchors = 8400;
  static const int _maskChannels = 32;
  static const int _maskSize = 160;
  // Match the prototype slider's lowest setting (0.05) to ensure sensitive detection on mobile.
  static const double _detectionConfidenceThreshold = 0.05;
  static const double _segmentationConfidenceThreshold = 0.05;
  static const double _nmsIouThreshold = 0.70;
  static const double _facePadding = 0.12;
  static const int _maxDetections = 300;

  static const _modelVersion =
      'skinsight-yolov8-litert-face-roi-v3-detect-conf-005';
  static const _detectionAsset =
      'assets/ml_models/acne_pih_darkcircle_float32.tflite';
  static const _rednessAsset = 'assets/ml_models/redness_float32.tflite';
  static const _wrinkleAsset = 'assets/ml_models/wrinkle_float32.tflite';

  static const _detectionNames = <String>['Acne', 'PIH', 'Dark Circle'];

  FaceDetector? _faceDetector;
  _YoloRuntime? _detectionRuntime;
  _YoloRuntime? _rednessRuntime;
  _YoloRuntime? _wrinkleRuntime;
  Future<void>? _initializing;
  bool _disposed = false;

  SkinAnalysis? _lastAnalysis;
  Uint8List? _lastBytes;

  SkinAnalysis? get lastAnalysis => _lastAnalysis;

  void clearCache() {
    _lastAnalysis = null;
    _lastBytes = null;
  }

  Future<void> _ensureInitialized() {
    if (_disposed) {
      throw StateError('SkinSight analyzer sudah ditutup.');
    }
    if (_faceDetector != null &&
        _detectionRuntime != null &&
        _rednessRuntime != null &&
        _wrinkleRuntime != null) {
      return Future<void>.value();
    }
    return _initializing ??= _initialize();
  }

  Future<void> _initialize() async {
    try {
      _faceDetector = FaceDetector(
        options: FaceDetectorOptions(
          performanceMode: FaceDetectorMode.accurate,
          enableLandmarks: false,
          enableContours: false,
          enableClassification: false,
          minFaceSize: 0.08,
        ),
      );

      _detectionRuntime = await _YoloRuntime.load(
        _detectionAsset,
        expectedOutputs: const [
          [1, 7, _anchors],
        ],
      );
      _rednessRuntime = await _YoloRuntime.load(
        _rednessAsset,
        expectedOutputs: const [
          [1, 37, _anchors],
          [1, _maskChannels, _maskSize, _maskSize],
        ],
      );
      _wrinkleRuntime = await _YoloRuntime.load(
        _wrinkleAsset,
        expectedOutputs: const [
          [1, 37, _anchors],
          [1, _maskChannels, _maskSize, _maskSize],
        ],
      );
    } catch (_) {
      await _closeRuntimes();
      await _faceDetector?.close();
      _faceDetector = null;
      _initializing = null;
      rethrow;
    }
  }

  /// Analyzes one photo and returns the same SkinAnalysis model used by the UI.
  /// Acne/PIH/Dark Circle use confidence 0.05; segmentation uses 0.25.
  /// Throws a readable error when no face is found or model assets are missing.
  Future<SkinAnalysis> analyze(Uint8List bytes) async {
    if (bytes.isEmpty) {
      throw const SkinAnalysisException('File foto kosong. Ambil foto ulang.');
    }
    if (_lastAnalysis != null && _lastBytes != null) {
      final cachedBytes = _lastBytes!;
      if (identical(cachedBytes, bytes) ||
          (cachedBytes.length == bytes.length &&
              cachedBytes.isNotEmpty &&
              cachedBytes[0] == bytes[0] &&
              cachedBytes[cachedBytes.length ~/ 2] == bytes[bytes.length ~/ 2] &&
              cachedBytes[cachedBytes.length - 1] == bytes[bytes.length - 1])) {
        return _lastAnalysis!;
      }
    }
    await _ensureInitialized();

    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw const SkinAnalysisException(
        'Format foto tidak dapat dibaca. Gunakan JPG atau PNG.',
      );
    }
    final oriented = img.bakeOrientation(decoded);

    final tempDirectory = await Directory.systemTemp.createTemp(
      'skinsight_face_',
    );
    final tempFile = File('${tempDirectory.path}/input_image.jpg');

    try {
      // Normalize EXIF orientation before ML Kit reads the file. This keeps
      // ML Kit face coordinates aligned with the decoded image used for crop.
      final uprightJpeg = img.encodeJpg(oriented, quality: 95);
      await tempFile.writeAsBytes(uprightJpeg, flush: true);
      final faces = await _faceDetector!.processImage(
        InputImage.fromFilePath(tempFile.path),
      );
      if (faces.isEmpty) {
        throw const SkinAnalysisException(
          'Wajah tidak terdeteksi. Hadap kamera, pastikan wajah terlihat jelas dan pencahayaan cukup.',
        );
      }

      // As in the original Python pipeline, only the largest face is analyzed.
      var largestFace = faces.first;
      for (final face in faces.skip(1)) {
        final area = face.boundingBox.width * face.boundingBox.height;
        final largestArea = largestFace.boundingBox.width *
            largestFace.boundingBox.height;
        if (area > largestArea) largestFace = face;
      }
      final faceRect = largestFace.boundingBox;
      final paddedCrop = _cropPaddedFace(oriented, faceRect);
      final faceCrop = paddedCrop.image;
      if (faceRect.width < 100 || faceRect.height < 100 ||
          faceCrop.width < 100 || faceCrop.height < 100) {
        throw const SkinAnalysisException(
          'Wajah terlalu kecil atau terlalu jauh. Dekatkan wajah ke kamera dan ambil foto dengan pencahayaan cukup.',
        );
      }

      final normFaceRect = Rect.fromLTRB(
        (faceRect.left / oriented.width).clamp(0.0, 1.0),
        (faceRect.top / oriented.height).clamp(0.0, 1.0),
        (faceRect.right / oriented.width).clamp(0.0, 1.0),
        (faceRect.bottom / oriented.height).clamp(0.0, 1.0),
      );

      final prepared = _letterbox(faceCrop);

      final detectionOutput = await _detectionRuntime!.run(prepared.input);
      final detectionCandidates = _decodeCandidates(
        detectionOutput[0],
        classCount: 3,
        coefficientCount: 0,
        confidenceThreshold: _detectionConfidenceThreshold,
      );
      final detectionKept = _nonMaximumSuppression(detectionCandidates);
      final detectionCounts = <String, int>{
        for (final name in _detectionNames) name: 0,
      };
      final confidences = <String, double>{};
      final visualBoxes = <SkinVisualBox>[];

      for (final candidate in detectionKept) {
        final clipped = _toCropBox(candidate, prepared);
        if (clipped == null) continue;
        final name = _detectionNames[candidate.classId];
        detectionCounts[name] = (detectionCounts[name] ?? 0) + 1;
        confidences[name] = math.max(
          confidences[name] ?? 0.0,
          candidate.score,
        ).toDouble();

        final fullX1 = ((paddedCrop.paddedX1 + clipped.x1) / oriented.width).clamp(0.0, 1.0);
        final fullY1 = ((paddedCrop.paddedY1 + clipped.y1) / oriented.height).clamp(0.0, 1.0);
        final fullX2 = ((paddedCrop.paddedX1 + clipped.x2) / oriented.width).clamp(0.0, 1.0);
        final fullY2 = ((paddedCrop.paddedY1 + clipped.y2) / oriented.height).clamp(0.0, 1.0);
        if (fullX2 > fullX1 && fullY2 > fullY1) {
          visualBoxes.add(
            SkinVisualBox(
              label: name,
              score: candidate.score,
              normalizedRect: Rect.fromLTRB(fullX1, fullY1, fullX2, fullY2),
            ),
          );
        }
      }

      final rednessOutput = await _rednessRuntime!.run(prepared.input);
      final rednessResult = _decodeSegmentation(
        prediction: rednessOutput[0],
        prototypes: rednessOutput[1],
        prepared: prepared,
      );
      if (rednessResult.area > 0) {
        confidences['Redness'] = rednessResult.maxConfidence;
        for (final box in rednessResult.boxes) {
          final fullX1 = ((paddedCrop.paddedX1 + box.x1) / oriented.width).clamp(0.0, 1.0);
          final fullY1 = ((paddedCrop.paddedY1 + box.y1) / oriented.height).clamp(0.0, 1.0);
          final fullX2 = ((paddedCrop.paddedX1 + box.x2) / oriented.width).clamp(0.0, 1.0);
          final fullY2 = ((paddedCrop.paddedY1 + box.y2) / oriented.height).clamp(0.0, 1.0);
          if (fullX2 > fullX1 && fullY2 > fullY1) {
            visualBoxes.add(
              SkinVisualBox(
                label: 'Redness',
                score: rednessResult.maxConfidence,
                normalizedRect: Rect.fromLTRB(fullX1, fullY1, fullX2, fullY2),
              ),
            );
          }
        }
      }

      final wrinkleOutput = await _wrinkleRuntime!.run(prepared.input);
      final wrinkleResult = _decodeSegmentation(
        prediction: wrinkleOutput[0],
        prototypes: wrinkleOutput[1],
        prepared: prepared,
      );
      if (wrinkleResult.area > 0) {
        confidences['Wrinkle'] = wrinkleResult.maxConfidence;
        for (final box in wrinkleResult.boxes) {
          final fullX1 = ((paddedCrop.paddedX1 + box.x1) / oriented.width).clamp(0.0, 1.0);
          final fullY1 = ((paddedCrop.paddedY1 + box.y1) / oriented.height).clamp(0.0, 1.0);
          final fullX2 = ((paddedCrop.paddedX1 + box.x2) / oriented.width).clamp(0.0, 1.0);
          final fullY2 = ((paddedCrop.paddedY1 + box.y2) / oriented.height).clamp(0.0, 1.0);
          if (fullX2 > fullX1 && fullY2 > fullY1) {
            visualBoxes.add(
              SkinVisualBox(
                label: 'Wrinkle',
                score: wrinkleResult.maxConfidence,
                normalizedRect: Rect.fromLTRB(fullX1, fullY1, fullX2, fullY2),
              ),
            );
          }
        }
      }

      final segmentationAreas = <String, double>{
        'Redness': rednessResult.area,
        'Wrinkle': wrinkleResult.area,
      };
      final visualFindings = <String>[
        for (final name in _detectionNames)
          if ((detectionCounts[name] ?? 0) > 0) name,
        if (rednessResult.area > 0) 'Redness',
        if (wrinkleResult.area > 0) 'Wrinkle',
      ];

      final result = SkinAnalysis(
        id: 'ml-${DateTime.now().microsecondsSinceEpoch}',
        analyzedAt: DateTime.now(),
        selfieBytes: bytes,
        score: 0,
        oil: 0,
        pores: 0,
        acne: 0,
        redness: 0,
        title: visualFindings.isEmpty
            ? 'Tidak ada temuan visual yang lolos ambang model'
            : 'Temuan: ${visualFindings.join(', ')}',
        skinType: 'Dry', // Temporary dummy; skin-type model is not enabled.
        skinTypeConfidence: 0.86,
        visualFindings: visualFindings,
        modelConnected: true,
        isDemo: false,
        detectionCounts: detectionCounts,
        segmentationAreas: segmentationAreas,
        classConfidences: confidences,
        modelVersion: _modelVersion,
        faceRect: normFaceRect,
        visualBoxes: visualBoxes,
        imageWidth: oriented.width,
        imageHeight: oriented.height,
      );
      _lastAnalysis = result;
      _lastBytes = bytes;
      return result;
    } on SkinAnalysisException {
      rethrow;
    } catch (error) {
      throw SkinAnalysisException(
        'Analisis on-device gagal: ${_readableError(error)}',
      );
    } finally {
      try {
        if (await tempFile.exists()) await tempFile.delete();
        if (await tempDirectory.exists()) {
          await tempDirectory.delete(recursive: true);
        }
      } catch (_) {
        // Temporary photo cleanup must not hide the inference result/error.
      }
    }
  }

  _PaddedFaceCrop _cropPaddedFace(img.Image source, Rect rect) {
    final width = source.width;
    final height = source.height;
    var x1 = rect.left.floor();
    var y1 = rect.top.floor();
    var x2 = rect.right.ceil();
    var y2 = rect.bottom.ceil();

    // ML Kit returns coordinates for the upright image. Clamp before padding.
    x1 = x1.clamp(0, width - 1).toInt();
    y1 = y1.clamp(0, height - 1).toInt();
    x2 = x2.clamp(x1 + 1, width).toInt();
    y2 = y2.clamp(y1 + 1, height).toInt();

    final faceWidth = x2 - x1;
    final faceHeight = y2 - y1;
    final padX = (faceWidth * _facePadding).round();
    final padY = (faceHeight * _facePadding).round();
    final paddedX1 = (x1 - padX).clamp(0, width - 1).toInt();
    final paddedY1 = (y1 - padY).clamp(0, height - 1).toInt();
    final paddedX2 = (x2 + padX).clamp(paddedX1 + 1, width).toInt();
    final paddedY2 = (y2 + padY).clamp(paddedY1 + 1, height).toInt();

    final cropped = img.copyCrop(
      source,
      x: paddedX1,
      y: paddedY1,
      width: paddedX2 - paddedX1,
      height: paddedY2 - paddedY1,
    );

    return _PaddedFaceCrop(
      image: cropped,
      paddedX1: paddedX1,
      paddedY1: paddedY1,
      paddedX2: paddedX2,
      paddedY2: paddedY2,
    );
  }

  _PreparedInput _letterbox(img.Image source) {
    final scale = math.min(
      _inputSize / source.width,
      _inputSize / source.height,
    ).toDouble();
    final resizedWidth =
        (source.width * scale).round().clamp(1, _inputSize).toInt();
    final resizedHeight =
        (source.height * scale).round().clamp(1, _inputSize).toInt();
    final padX = _inputSize - resizedWidth;
    final padY = _inputSize - resizedHeight;
    // Same asymmetric rounding convention used by Ultralytics LetterBox.
    final left = (padX / 2 - 0.1).round();
    final top = (padY / 2 - 0.1).round();

    final resized = img.copyResize(
      source,
      width: resizedWidth,
      height: resizedHeight,
      interpolation: img.Interpolation.linear,
    );

    final planeSize = _inputSize * _inputSize;
    final input = Float32List(3 * planeSize);
    const paddingValue = 114.0 / 255.0;
    input.fillRange(0, input.length, paddingValue);

    for (var y = 0; y < resizedHeight; y++) {
      final targetY = y + top;
      for (var x = 0; x < resizedWidth; x++) {
        final pixel = resized.getPixel(x, y);
        final targetX = x + left;
        final offset = targetY * _inputSize + targetX;
        input[offset] = pixel.r.toDouble() / 255.0;
        input[planeSize + offset] = pixel.g.toDouble() / 255.0;
        input[2 * planeSize + offset] = pixel.b.toDouble() / 255.0;
      }
    }

    return _PreparedInput(
      input: input,
      sourceWidth: source.width,
      sourceHeight: source.height,
      scale: scale,
      left: left,
      top: top,
    );
  }

  List<_YoloCandidate> _decodeCandidates(
    Object prediction, {
    required int classCount,
    required int coefficientCount,
    required double confidenceThreshold,
  }) {
    final channels = prediction as List;
    if (channels.length != 1) {
      throw StateError('Batch output YOLO tidak sesuai.');
    }
    final channelData = channels[0] as List;
    final expectedChannels = 4 + classCount + coefficientCount;
    if (channelData.length != expectedChannels) {
      throw StateError(
        'Output YOLO memiliki ${channelData.length} channel, diharapkan $expectedChannels.',
      );
    }

    final candidates = <_YoloCandidate>[];
    for (var anchor = 0; anchor < _anchors; anchor++) {
      var bestClass = 0;
      var bestScore = -double.infinity;
      for (var classIndex = 0; classIndex < classCount; classIndex++) {
        final score = (channelData[4 + classIndex] as List)[anchor] as num;
        if (score > bestScore) {
          bestScore = score.toDouble();
          bestClass = classIndex;
        }
      }
      if (!bestScore.isFinite || bestScore < confidenceThreshold) continue;

      final rawCx = ((channelData[0] as List)[anchor] as num).toDouble();
      final rawCy = ((channelData[1] as List)[anchor] as num).toDouble();
      final rawW = ((channelData[2] as List)[anchor] as num).toDouble();
      final rawH = ((channelData[3] as List)[anchor] as num).toDouble();
      if (![rawCx, rawCy, rawW, rawH].every((v) => v.isFinite) ||
          rawW <= 0 ||
          rawH <= 0) {
        continue;
      }

      // YOLOv8 LiteRT outputs box coordinates normalized to [0..1].
      // When normalized, scale up to the 640x640 letterbox coordinate space.
      final isNormalized =
          rawCx <= 2.0 && rawCy <= 2.0 && rawW <= 2.0 && rawH <= 2.0;
      final scaleFactor = isNormalized ? _inputSize.toDouble() : 1.0;

      final centerX = rawCx * scaleFactor;
      final centerY = rawCy * scaleFactor;
      final boxWidth = rawW * scaleFactor;
      final boxHeight = rawH * scaleFactor;

      final coefficients = <double>[];
      for (var index = 0; index < coefficientCount; index++) {
        coefficients.add(
          ((channelData[4 + classCount + index] as List)[anchor] as num)
              .toDouble(),
        );
      }
      candidates.add(
        _YoloCandidate(
          x1: centerX - boxWidth / 2,
          y1: centerY - boxHeight / 2,
          x2: centerX + boxWidth / 2,
          y2: centerY + boxHeight / 2,
          score: bestScore,
          classId: bestClass,
          coefficients: coefficients,
        ),
      );
    }
    return candidates;
  }

  List<_YoloCandidate> _nonMaximumSuppression(
    List<_YoloCandidate> candidates,
  ) {
    candidates.sort((a, b) => b.score.compareTo(a.score));
    final kept = <_YoloCandidate>[];
    for (final candidate in candidates) {
      var suppressed = false;
      for (final previous in kept) {
        if (candidate.classId == previous.classId &&
            _intersectionOverUnion(candidate, previous) > _nmsIouThreshold) {
          suppressed = true;
          break;
        }
      }
      if (!suppressed) {
        kept.add(candidate);
        if (kept.length >= _maxDetections) break;
      }
    }
    return kept;
  }

  double _intersectionOverUnion(_YoloCandidate a, _YoloCandidate b) {
    final left = math.max(a.x1, b.x1);
    final top = math.max(a.y1, b.y1);
    final right = math.min(a.x2, b.x2);
    final bottom = math.min(a.y2, b.y2);
    final intersection = math.max(0.0, right - left) *
        math.max(0.0, bottom - top);
    final areaA = math.max(0.0, a.x2 - a.x1) * math.max(0.0, a.y2 - a.y1);
    final areaB = math.max(0.0, b.x2 - b.x1) * math.max(0.0, b.y2 - b.y1);
    final union = areaA + areaB - intersection;
    return union <= 0 ? 0.0 : (intersection / union).toDouble();
  }

  _CropBox? _toCropBox(_YoloCandidate candidate, _PreparedInput prepared) {
    final x1 = ((candidate.x1 - prepared.left) / prepared.scale)
        .clamp(0.0, prepared.sourceWidth.toDouble()).toDouble();
    final y1 = ((candidate.y1 - prepared.top) / prepared.scale)
        .clamp(0.0, prepared.sourceHeight.toDouble()).toDouble();
    final x2 = ((candidate.x2 - prepared.left) / prepared.scale)
        .clamp(0.0, prepared.sourceWidth.toDouble()).toDouble();
    final y2 = ((candidate.y2 - prepared.top) / prepared.scale)
        .clamp(0.0, prepared.sourceHeight.toDouble()).toDouble();
    if (x2 <= x1 || y2 <= y1) return null;
    return _CropBox(x1, y1, x2, y2);
  }

  _SegmentationResult _decodeSegmentation({
    required Object prediction,
    required Object prototypes,
    required _PreparedInput prepared,
  }) {
    final candidates = _decodeCandidates(
      prediction,
      classCount: 1,
      coefficientCount: _maskChannels,
      confidenceThreshold: _segmentationConfidenceThreshold,
    );
    final kept = _nonMaximumSuppression(candidates);
    if (kept.isEmpty) return const _SegmentationResult(0, 0);

    final protoBatch = prototypes as List;
    if (protoBatch.length != 1) {
      throw StateError('Batch prototype segmentation tidak sesuai.');
    }
    final protoChannels = protoBatch[0] as List;
    if (protoChannels.length != _maskChannels) {
      throw StateError('Jumlah prototype mask tidak sesuai.');
    }

    final unionMask = Uint8List(prepared.sourceWidth * prepared.sourceHeight);
    var maxConfidence = 0.0;
    final validBoxes = <_CropBox>[];

    for (final candidate in kept) {
      final box = _toCropBox(candidate, prepared);
      if (box == null) continue;
      final minX = box.x1.floor().clamp(0, prepared.sourceWidth - 1).toInt();
      final minY = box.y1.floor().clamp(0, prepared.sourceHeight - 1).toInt();
      final maxX = box.x2.ceil().clamp(minX + 1, prepared.sourceWidth).toInt();
      final maxY = box.y2.ceil().clamp(minY + 1, prepared.sourceHeight).toInt();
      final instanceMask = <int>[];

      // Decode the mask coefficients against the 32x160x160 prototype tensor.
      final logits = Float32List(_maskSize * _maskSize);
      for (var py = 0; py < _maskSize; py++) {
        for (var px = 0; px < _maskSize; px++) {
          var value = 0.0;
          for (var channel = 0; channel < _maskChannels; channel++) {
            final plane = protoChannels[channel] as List;
            final row = plane[py] as List;
            value += candidate.coefficients[channel] *
                (row[px] as num).toDouble();
          }
          logits[py * _maskSize + px] = value;
        }
      }

      var instanceArea = 0;
      for (var y = minY; y < maxY; y++) {
        final protoY = ((y + 0.5) * prepared.scale + prepared.top) /
                _inputSize *
                _maskSize -
            0.5;
        for (var x = minX; x < maxX; x++) {
          final protoX = ((x + 0.5) * prepared.scale + prepared.left) /
                  _inputSize *
                  _maskSize -
              0.5;
          if (_sampleBilinear(logits, protoX, protoY) > 0) {
            final offset = y * prepared.sourceWidth + x;
            instanceMask.add(offset);
            instanceArea++;
          }
        }
      }

      // Matches the original Python post-processing minimum mask-pixel guard.
      if (instanceArea < 20) continue;
      validBoxes.add(box);
      maxConfidence = math.max(maxConfidence, candidate.score).toDouble();
      for (final offset in instanceMask) {
        unionMask[offset] = 1;
      }
    }

    var unionArea = 0;
    for (final pixel in unionMask) {
      if (pixel != 0) unionArea++;
    }
    final faceArea = prepared.sourceWidth * prepared.sourceHeight;
    return _SegmentationResult(
      faceArea == 0 ? 0 : unionArea / faceArea,
      maxConfidence,
      validBoxes,
    );
  }

  double _sampleBilinear(Float32List data, double x, double y) {
    final clampedX = x.clamp(0.0, (_maskSize - 1).toDouble()).toDouble();
    final clampedY = y.clamp(0.0, (_maskSize - 1).toDouble()).toDouble();
    final x0 = clampedX.floor();
    final y0 = clampedY.floor();
    final x1 = math.min(x0 + 1, _maskSize - 1).toInt();
    final y1 = math.min(y0 + 1, _maskSize - 1).toInt();
    final dx = clampedX - x0;
    final dy = clampedY - y0;
    final top = data[y0 * _maskSize + x0] * (1 - dx) +
        data[y0 * _maskSize + x1] * dx;
    final bottom = data[y1 * _maskSize + x0] * (1 - dx) +
        data[y1 * _maskSize + x1] * dx;
    return top * (1 - dy) + bottom * dy;
  }

  String _readableError(Object error) {
    final message = error.toString();
    return message.startsWith('Exception: ')
        ? message.substring('Exception: '.length)
        : message;
  }

  Future<void> _closeRuntimes() async {
    final runtimes = <_YoloRuntime?>[
      _detectionRuntime,
      _rednessRuntime,
      _wrinkleRuntime,
    ];
    _detectionRuntime = null;
    _rednessRuntime = null;
    _wrinkleRuntime = null;
    for (final runtime in runtimes) {
      await runtime?.close();
    }
  }

  Future<void> dispose() async {
    _disposed = true;
    await _faceDetector?.close();
    _faceDetector = null;
    await _closeRuntimes();
  }
}

class SkinAnalysisException implements Exception {
  const SkinAnalysisException(this.message);
  final String message;

  @override
  String toString() => message;
}

class _PreparedInput {
  const _PreparedInput({
    required this.input,
    required this.sourceWidth,
    required this.sourceHeight,
    required this.scale,
    required this.left,
    required this.top,
  });

  final Float32List input;
  final int sourceWidth;
  final int sourceHeight;
  final double scale;
  final int left;
  final int top;
}

class _CropBox {
  const _CropBox(this.x1, this.y1, this.x2, this.y2);
  final double x1;
  final double y1;
  final double x2;
  final double y2;
}

class _YoloCandidate {
  const _YoloCandidate({
    required this.x1,
    required this.y1,
    required this.x2,
    required this.y2,
    required this.score,
    required this.classId,
    required this.coefficients,
  });

  final double x1;
  final double y1;
  final double x2;
  final double y2;
  final double score;
  final int classId;
  final List<double> coefficients;
}

class _SegmentationResult {
  const _SegmentationResult(this.area, this.maxConfidence, [this.boxes = const []]);
  final double area;
  final double maxConfidence;
  final List<_CropBox> boxes;
}

class _PaddedFaceCrop {
  const _PaddedFaceCrop({
    required this.image,
    required this.paddedX1,
    required this.paddedY1,
    required this.paddedX2,
    required this.paddedY2,
  });

  final img.Image image;
  final int paddedX1;
  final int paddedY1;
  final int paddedX2;
  final int paddedY2;
}

class _YoloRuntime {
  _YoloRuntime(this._interpreter, this._isolate, this._outputShapes);

  final Interpreter _interpreter;
  final IsolateInterpreter _isolate;
  final List<List<int>> _outputShapes;

  static Future<_YoloRuntime> load(
    String asset, {
    required List<List<int>> expectedOutputs,
  }) async {
    final options = InterpreterOptions()..threads = 4;
    final interpreter = await Interpreter.fromAsset(asset, options: options);
    try {
      final inputShape = interpreter.getInputTensor(0).shape;
      if (inputShape.toString() != const [1, 3, 640, 640].toString()) {
        throw StateError('Input tensor $asset tidak sesuai: $inputShape');
      }
      final actualOutputs = interpreter
          .getOutputTensors()
          .map((tensor) => tensor.shape)
          .toList(growable: false);
      if (actualOutputs.length != expectedOutputs.length) {
        throw StateError('Jumlah output tensor $asset tidak sesuai.');
      }
      for (var i = 0; i < expectedOutputs.length; i++) {
        if (actualOutputs[i].toString() != expectedOutputs[i].toString()) {
          throw StateError(
            'Output tensor $asset[$i] ${actualOutputs[i]} tidak sesuai dengan ${expectedOutputs[i]}.',
          );
        }
      }
      if (!interpreter.isAllocated) interpreter.allocateTensors();
      final isolate = await IsolateInterpreter.create(
        address: interpreter.address,
      );
      return _YoloRuntime(interpreter, isolate, actualOutputs);
    } catch (_) {
      interpreter.close();
      rethrow;
    }
  }

  Future<List<Object>> run(Float32List input) async {
    final outputBuffers = _outputShapes.map(_allocate).toList(growable: false);
    if (outputBuffers.length == 1) {
      await _isolate.run(input, outputBuffers.first);
    } else {
      await _isolate.runForMultipleInputs(
        [input],
        {for (var i = 0; i < outputBuffers.length; i++) i: outputBuffers[i]},
      );
    }
    return outputBuffers;
  }

  Object _allocate(List<int> shape, [int depth = 0]) {
    if (depth == shape.length - 1) {
      return Float32List(shape[depth]);
    }
    return List<Object>.generate(
      shape[depth],
      (_) => _allocate(shape, depth + 1),
      growable: false,
    );
  }

  Future<void> close() async {
    await _isolate.close();
    _interpreter.close();
  }
}
