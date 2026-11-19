import 'dart:io';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

/// Status panduan wajah real-time saat pemindaian kamera.
enum FaceAlignmentStatus {
  noFace,
  multipleFaces,
  tooFar,
  tooClose,
  offCenter,
  tilted,
  unstable,
  holdingSteady,
  readyToCapture,
}

/// Data hasil evaluasi frame kamera untuk umpan balik pengguna.
class LiveFaceFeedback {
  final FaceAlignmentStatus status;
  final String message;
  final double stabilityProgress; // 0.0 sampai 1.0
  final bool isRelatable;
  final bool isReadyToCapture;
  final Rect? normalizedFaceBox;

  const LiveFaceFeedback({
    required this.status,
    required this.message,
    this.stabilityProgress = 0.0,
    this.isRelatable = false,
    this.isReadyToCapture = false,
    this.normalizedFaceBox,
  });

  static const initial = LiveFaceFeedback(
    status: FaceAlignmentStatus.noFace,
    message: 'Posisikan wajah di dalam bingkai',
  );
}

/// Pengelola konversi frame kamera, penilaian kesesuaian posisi wajah (Face ROI),
/// serta deteksi kestabilan untuk foto otomatis & manual.
class SkinLiveFaceGuide {
  SkinLiveFaceGuide({int requiredStableMs = 1200})
      : _requiredStableMs = requiredStableMs;

  final int _requiredStableMs;

  double? _prevCenterX;
  double? _prevCenterY;
  double? _prevWidth;
  int _stableAccumulatedMs = 0;
  DateTime? _lastEvaluationTime;

  void reset() {
    _prevCenterX = null;
    _prevCenterY = null;
    _prevWidth = null;
    _stableAccumulatedMs = 0;
    _lastEvaluationTime = null;
  }

  /// Mengonversi CameraImage ke InputImage untuk Google ML Kit.
  InputImage? createInputImageFromCamera({
    required CameraImage image,
    required CameraDescription camera,
    required DeviceOrientation deviceOrientation,
  }) {
    final rotation = _resolveRotation(camera, deviceOrientation);

    if (Platform.isAndroid) {
      final rawFormat = image.format.raw;
      final format = InputImageFormatValue.fromRawValue(rawFormat);

      // Jika format kamera NV21 (raw 17)
      if (format == InputImageFormat.nv21 || image.planes.length == 1) {
        final WriteBuffer buffer = WriteBuffer();
        for (final plane in image.planes) {
          buffer.putUint8List(plane.bytes);
        }
        final bytes = buffer.done().buffer.asUint8List();

        return InputImage.fromBytes(
          bytes: bytes,
          metadata: InputImageMetadata(
            size: Size(image.width.toDouble(), image.height.toDouble()),
            rotation: rotation,
            format: InputImageFormat.nv21,
            bytesPerRow: image.planes[0].bytesPerRow,
          ),
        );
      }

      // Jika kamera menghasilkan 3 plane YUV420_888, gabungkan ke NV21
      if (image.planes.length >= 3) {
        final nv21Bytes = _yuv420ToNv21(image);
        return InputImage.fromBytes(
          bytes: nv21Bytes,
          metadata: InputImageMetadata(
            size: Size(image.width.toDouble(), image.height.toDouble()),
            rotation: rotation,
            format: InputImageFormat.nv21,
            bytesPerRow: image.width,
          ),
        );
      }

      // Fallback byte buffer umum
      final WriteBuffer buffer = WriteBuffer();
      for (final plane in image.planes) {
        buffer.putUint8List(plane.bytes);
      }
      return InputImage.fromBytes(
        bytes: buffer.done().buffer.asUint8List(),
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: InputImageFormat.nv21,
          bytesPerRow: image.planes[0].bytesPerRow,
        ),
      );
    }

    if (Platform.isIOS) {
      final WriteBuffer buffer = WriteBuffer();
      for (final plane in image.planes) {
        buffer.putUint8List(plane.bytes);
      }
      final bytes = buffer.done().buffer.asUint8List();
      final format = InputImageFormatValue.fromRawValue(image.format.raw) ??
          InputImageFormat.bgra8888;

      return InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: format,
          bytesPerRow: image.planes[0].bytesPerRow,
        ),
      );
    }

    return null;
  }

  /// Menilai posisi wajah terhadap bingkai panduan & menghitung kestabilan gerakan.
  LiveFaceFeedback evaluate({
    required List<Face> faces,
    required Size imageSize,
    required InputImageRotation rotation,
    bool isAutomaticMode = true,
  }) {
    final now = DateTime.now();
    final elapsedMs = _lastEvaluationTime == null
        ? 100
        : now.difference(_lastEvaluationTime!).inMilliseconds.clamp(10, 400);
    _lastEvaluationTime = now;

    if (faces.isEmpty) {
      reset();
      return const LiveFaceFeedback(
        status: FaceAlignmentStatus.noFace,
        message: 'Posisikan wajah di dalam bingkai',
      );
    }

    if (faces.length > 1) {
      reset();
      return const LiveFaceFeedback(
        status: FaceAlignmentStatus.multipleFaces,
        message: 'Hanya satu wajah yang diperbolehkan dalam frame',
      );
    }

    final face = faces.first;

    // Normalisasi orientasi: rotasi 90 / 270 menukar dimensi lebar dan tinggi.
    final bool isRotated = rotation == InputImageRotation.rotation90deg ||
        rotation == InputImageRotation.rotation270deg;
    final double uprightWidth = isRotated ? imageSize.height : imageSize.width;
    final double uprightHeight = isRotated ? imageSize.width : imageSize.height;

    if (uprightWidth <= 0 || uprightHeight <= 0) {
      return LiveFaceFeedback.initial;
    }

    final box = face.boundingBox;
    final double normCenterX = box.center.dx / uprightWidth;
    final double normCenterY = box.center.dy / uprightHeight;
    final double normWidth = box.width / uprightWidth;
    final double normHeight = box.height / uprightHeight;

    final normBox = Rect.fromLTWH(
      box.left / uprightWidth,
      box.top / uprightHeight,
      normWidth,
      normHeight,
    );

    // 1. Validasi Ukuran/Jarak (terlalu jauh vs terlalu dekat)
    if (normWidth < 0.28 || normHeight < 0.28) {
      reset();
      return LiveFaceFeedback(
        status: FaceAlignmentStatus.tooFar,
        message: 'Dekatkan wajah sedikit ke kamera',
        normalizedFaceBox: normBox,
      );
    }

    if (normWidth > 0.82 || normHeight > 0.82) {
      reset();
      return LiveFaceFeedback(
        status: FaceAlignmentStatus.tooClose,
        message: 'Jauhkan sedikit wajah dari kamera',
        normalizedFaceBox: normBox,
      );
    }

    // 2. Validasi Centering (bingkai oval berpusat di cx=0.5, cy=0.45)
    final double dx = (normCenterX - 0.5).abs();
    final double dy = (normCenterY - 0.45).abs();

    if (dx > 0.16 || dy > 0.18) {
      reset();
      return LiveFaceFeedback(
        status: FaceAlignmentStatus.offCenter,
        message: 'Posisikan wajah tepat di tengah bingkai',
        normalizedFaceBox: normBox,
      );
    }

    // 3. Validasi Kemiringan / Sudut Kepala (Pose tegak & hadap kamera)
    final double? yaw = face.headEulerAngleY;
    final double? roll = face.headEulerAngleZ;

    if (yaw != null && yaw.abs() > 18.0) {
      reset();
      return LiveFaceFeedback(
        status: FaceAlignmentStatus.tilted,
        message: 'Hadap lurus ke depan kamera',
        normalizedFaceBox: normBox,
      );
    }

    if (roll != null && roll.abs() > 18.0) {
      reset();
      return LiveFaceFeedback(
        status: FaceAlignmentStatus.tilted,
        message: 'Tegakkan posisi kepala Anda',
        normalizedFaceBox: normBox,
      );
    }

    // 4. Face ROI relatable & posisi pas! Cek kestabilan gerakan.
    double movement = 0.0;
    double sizeDelta = 0.0;

    if (_prevCenterX != null && _prevCenterY != null && _prevWidth != null) {
      final double mx = normCenterX - _prevCenterX!;
      final double my = normCenterY - _prevCenterY!;
      movement = math.sqrt(mx * mx + my * my);
      sizeDelta = (normWidth - _prevWidth!).abs();
    }

    _prevCenterX = normCenterX;
    _prevCenterY = normCenterY;
    _prevWidth = normWidth;

    // Toleransi kestabilan: gerakan kurang dari 3.8% layar
    final bool isSteady = movement < 0.038 && sizeDelta < 0.045;

    if (!isSteady) {
      _stableAccumulatedMs = (_stableAccumulatedMs - elapsedMs * 2).clamp(0, _requiredStableMs);
      return LiveFaceFeedback(
        status: FaceAlignmentStatus.unstable,
        message: isAutomaticMode
            ? 'Wajah pas! Tahan posisi dan jangan bergerak...'
            : 'Posisi pas! Tekan tombol kamera untuk memotret',
        stabilityProgress: _stableAccumulatedMs / _requiredStableMs,
        isRelatable: true,
        normalizedFaceBox: normBox,
      );
    }

    // Gerakan stabil: akumulasikan waktu stabil
    _stableAccumulatedMs = (_stableAccumulatedMs + elapsedMs).clamp(0, _requiredStableMs);
    final double progress = (_stableAccumulatedMs / _requiredStableMs).clamp(0.0, 1.0);

    if (progress >= 1.0) {
      return LiveFaceFeedback(
        status: FaceAlignmentStatus.readyToCapture,
        message: isAutomaticMode
            ? 'Wajah stabil! Mengambil foto...'
            : 'Posisi sempurna! Siap dipotret.',
        stabilityProgress: 1.0,
        isRelatable: true,
        isReadyToCapture: isAutomaticMode,
        normalizedFaceBox: normBox,
      );
    }

    return LiveFaceFeedback(
      status: FaceAlignmentStatus.holdingSteady,
      message: isAutomaticMode
          ? 'Tahan posisi... ${(progress * 100).toInt()}%'
          : 'Posisi pas! Tekan tombol untuk memotret',
      stabilityProgress: progress,
      isRelatable: true,
      normalizedFaceBox: normBox,
    );
  }

  static InputImageRotation _resolveRotation(
    CameraDescription camera,
    DeviceOrientation deviceOrientation,
  ) {
    const orientations = {
      DeviceOrientation.portraitUp: 0,
      DeviceOrientation.landscapeLeft: 90,
      DeviceOrientation.portraitDown: 180,
      DeviceOrientation.landscapeRight: 270,
    };

    final sensorOrientation = camera.sensorOrientation;
    if (Platform.isAndroid) {
      var compensation = orientations[deviceOrientation] ?? 0;
      if (camera.lensDirection == CameraLensDirection.front) {
        compensation = (sensorOrientation + compensation) % 360;
      } else {
        compensation = (sensorOrientation - compensation + 360) % 360;
      }
      return InputImageRotationValue.fromRawValue(compensation) ??
          InputImageRotation.rotation0deg;
    }

    if (Platform.isIOS) {
      return InputImageRotationValue.fromRawValue(sensorOrientation) ??
          InputImageRotation.rotation0deg;
    }

    return InputImageRotation.rotation0deg;
  }

  static Uint8List _yuv420ToNv21(CameraImage image) {
    final int width = image.width;
    final int height = image.height;
    final int ySize = width * height;
    final int uvSize = width * height ~/ 2;
    final Uint8List nv21 = Uint8List(ySize + uvSize);

    // Salin plane Y
    final Plane yPlane = image.planes[0];
    final int yRowStride = yPlane.bytesPerRow;
    int destOffset = 0;
    for (int row = 0; row < height; row++) {
      final int srcOffset = row * yRowStride;
      nv21.setRange(destOffset, destOffset + width, yPlane.bytes, srcOffset);
      destOffset += width;
    }

    // Salin plane U dan V secara interleave V lalu U untuk format NV21
    final Plane uPlane = image.planes[1];
    final Plane vPlane = image.planes[2];
    final int uRowStride = uPlane.bytesPerRow;
    final int vRowStride = vPlane.bytesPerRow;
    final int uPixelStride = uPlane.bytesPerPixel ?? 1;
    final int vPixelStride = vPlane.bytesPerPixel ?? 1;

    final int halfHeight = height ~/ 2;
    final int halfWidth = width ~/ 2;

    for (int row = 0; row < halfHeight; row++) {
      final int uRowOffset = row * uRowStride;
      final int vRowOffset = row * vRowStride;
      for (int col = 0; col < halfWidth; col++) {
        final int uIndex = uRowOffset + col * uPixelStride;
        final int vIndex = vRowOffset + col * vPixelStride;
        nv21[destOffset++] = vPlane.bytes[vIndex];
        nv21[destOffset++] = uPlane.bytes[uIndex];
      }
    }
    return nv21;
  }
}
