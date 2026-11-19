import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/skin_theme.dart';
import '../../../shared/widgets/design_system/skin_ui.dart';
import '../../../shared/widgets/skin_analyzing_overlay.dart';
import '../data/skin_live_face_guide.dart';
import '../data/skin_on_device_analyzer.dart';
import './skin_result_page.dart';

class SkinScanPage extends StatefulWidget {
  final bool enableCamera;

  /// Mengembalikan bytes ke halaman sesi foto tanpa membuka Hasil Analisis.
  final bool returnPhoto;

  const SkinScanPage(
      {super.key, this.enableCamera = true, this.returnPhoto = false});

  @override
  State<SkinScanPage> createState() => _SkinScanPageState();
}

class _SkinScanPageState extends State<SkinScanPage>
    with WidgetsBindingObserver {
  static const _night = Color(0xFF121614);

  CameraController? _controller;
  List<CameraDescription> _cameras = const [];
  int _cameraIndex = 0;
  bool _isLoading = true;
  bool _isCapturing = false;
  bool _isAnalyzing = false;
  String _analysisPhase = 'Mempersiapkan foto...';
  bool _automaticMode = true;
  String? _errorMessage;

  // Real-time Face Guide & Stability Tracker
  final SkinLiveFaceGuide _guide = SkinLiveFaceGuide(requiredStableMs: 1200);
  FaceDetector? _liveFaceDetector;
  LiveFaceFeedback _feedback = LiveFaceFeedback.initial;
  bool _isStreaming = false;
  bool _isProcessingFrame = false;
  DateTime _lastFrameTime = DateTime.now();
  bool _showShutterFlash = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.enableCamera) {
      _initializeCamera();
    } else {
      _isLoading = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    if (state == AppLifecycleState.inactive) {
      if (controller.value.isStreamingImages) {
        controller.stopImageStream();
        _isStreaming = false;
      }
      controller.dispose();
      _controller = null;
    } else if (state == AppLifecycleState.resumed && widget.enableCamera) {
      _initializeCamera(preferredIndex: _cameraIndex);
    }
  }

  Future<void> _initializeCamera({int? preferredIndex}) async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _feedback = LiveFaceFeedback.initial;
      });
    }

    try {
      final cameras = await availableCameras().timeout(
        const Duration(seconds: 30),
      );
      if (cameras.isEmpty) {
        throw CameraException(
          'NoCamera',
          'Tidak ada kamera yang ditemukan pada perangkat ini.',
        );
      }

      final frontIndex = cameras.indexWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
      );
      final selectedIndex = preferredIndex != null &&
              preferredIndex >= 0 &&
              preferredIndex < cameras.length
          ? preferredIndex
          : (frontIndex >= 0 ? frontIndex : 0);

      final oldController = _controller;
      if (oldController != null && oldController.value.isStreamingImages) {
        try {
          await oldController.stopImageStream();
        } catch (_) {}
      }

      final controller = CameraController(
        cameras[selectedIndex],
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );
      _controller = controller;
      await oldController?.dispose();
      await controller.initialize().timeout(const Duration(seconds: 30));

      if (!mounted) {
        await controller.dispose();
        return;
      }

      _liveFaceDetector ??= FaceDetector(
        options: FaceDetectorOptions(
          performanceMode: FaceDetectorMode.fast,
          minFaceSize: 0.15,
        ),
      );

      setState(() {
        _cameras = cameras;
        _cameraIndex = selectedIndex;
        _isLoading = false;
      });

      _startImageStream(controller);
    } on CameraException catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = switch (error.code) {
          'CameraAccessDenied' ||
          'CameraAccessDeniedWithoutPrompt' ||
          'CameraAccessRestricted' =>
            'Izin kamera belum diberikan. Izinkan akses kamera lalu coba lagi.',
          _ => error.description ?? 'Kamera tidak dapat dibuka.',
        };
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Kamera tidak dapat dibuka. Coba muat ulang halaman.';
      });
    }
  }

  void _startImageStream(CameraController controller) {
    if (!mounted || !widget.enableCamera || _isStreaming) return;
    _guide.reset();
    try {
      controller.startImageStream((CameraImage image) {
        _onCameraFrame(image);
      });
      _isStreaming = true;
    } catch (_) {
      _isStreaming = false;
    }
  }

  Future<void> _onCameraFrame(CameraImage image) async {
    if (!mounted || _isProcessingFrame || _isCapturing || _isAnalyzing) return;

    final now = DateTime.now();
    // Pembatasan laju evaluasi ~11 frame per detik untuk efisiensi CPU dan kelancaran 60fps UI
    if (now.difference(_lastFrameTime).inMilliseconds < 90) return;
    _lastFrameTime = now;

    final detector = _liveFaceDetector;
    final controller = _controller;
    if (detector == null ||
        controller == null ||
        !controller.value.isInitialized ||
        controller.value.isTakingPicture) {
      return;
    }

    _isProcessingFrame = true;
    try {
      final inputImage = _guide.createInputImageFromCamera(
        image: image,
        camera: _cameras[_cameraIndex],
        deviceOrientation: controller.value.deviceOrientation,
      );

      if (inputImage == null) return;

      final faces = await detector.processImage(inputImage);
      if (!mounted || _isCapturing || _isAnalyzing) return;

      final feedback = _guide.evaluate(
        faces: faces,
        imageSize: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: inputImage.metadata?.rotation ?? InputImageRotation.rotation0deg,
        isAutomaticMode: _automaticMode,
      );

      if (mounted) {
        setState(() {
          _feedback = feedback;
        });
      }

      // Foto otomatis: jika posisi pas & stabil terpenuhi, picu pengambilan gambar
      if (_automaticMode && feedback.isReadyToCapture && !_isCapturing) {
        _takePicture(isAuto: true);
      }
    } catch (_) {
      // Non-fatal frame drop
    } finally {
      _isProcessingFrame = false;
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2 || _isCapturing || _isAnalyzing) return;
    if (_controller?.value.isStreamingImages == true) {
      try {
        await _controller?.stopImageStream();
      } catch (_) {}
      _isStreaming = false;
    }
    final nextIndex = (_cameraIndex + 1) % _cameras.length;
    await _initializeCamera(preferredIndex: nextIndex);
  }

  Future<void> _takePicture({bool isAuto = false}) async {
    final controller = _controller;
    if (controller == null ||
        !controller.value.isInitialized ||
        controller.value.isTakingPicture ||
        _isCapturing) {
      return;
    }

    setState(() {
      _isCapturing = true;
      _showShutterFlash = true;
    });

    try {
      HapticFeedback.mediumImpact();
    } catch (_) {}

    Future<void>.delayed(const Duration(milliseconds: 140), () {
      if (mounted) setState(() => _showShutterFlash = false);
    });

    try {
      // Hentikan image stream sebelum takePicture untuk mencegah konflik plugin kamera
      if (controller.value.isStreamingImages) {
        await controller.stopImageStream();
        _isStreaming = false;
      }

      final picture = await controller.takePicture();
      final bytes = await picture.readAsBytes();
      if (!mounted) return;
      await _openResult(bytes);
    } on CameraException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.description ?? 'Gagal mengambil foto.')),
      );
      if (mounted &&
          _controller != null &&
          _controller!.value.isInitialized &&
          !_isAnalyzing) {
        _startImageStream(_controller!);
      }
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  Future<void> _pickFromGallery() async {
    if (_isCapturing || _isAnalyzing) return;
    final controller = _controller;
    if (controller?.value.isStreamingImages == true) {
      try {
        await controller?.stopImageStream();
      } catch (_) {}
      _isStreaming = false;
    }

    final picture = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
      maxWidth: 1600,
    );

    if (picture == null) {
      if (mounted &&
          controller != null &&
          controller.value.isInitialized &&
          !_isAnalyzing) {
        _startImageStream(controller);
      }
      return;
    }

    if (!mounted) return;
    await _openResult(await picture.readAsBytes());
  }

  Future<void> _openResult(Uint8List bytes) async {
    final controller = _controller;
    if (controller?.value.isStreamingImages == true) {
      try {
        await controller?.stopImageStream();
      } catch (_) {}
      _isStreaming = false;
    }

    setState(() {
      _isAnalyzing = true;
      _analysisPhase = 'Mendeteksi area wajah...';
    });

    try {
      final analysisFuture = SkinOnDeviceAnalyzer.instance.analyze(bytes);

      // Staged transition gives user reassuring real-time feedback
      await Future<void>.delayed(const Duration(milliseconds: 650));
      if (mounted && _isAnalyzing) {
        setState(() => _analysisPhase = 'Menjalankan model On-Device LiteRT...');
      }

      await Future<void>.delayed(const Duration(milliseconds: 650));
      if (mounted && _isAnalyzing) {
        setState(() => _analysisPhase = 'Memindai jerawat, kemerahan & kerutan...');
      }

      final analysis = await analysisFuture;
      if (mounted && _isAnalyzing) {
        setState(() => _analysisPhase = 'Menyusun hasil analisis...');
      }
      await Future<void>.delayed(const Duration(milliseconds: 400));

      if (!mounted) return;

      if (widget.returnPhoto) {
        Navigator.of(context).pop(bytes);
        return;
      }

      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => SkinResultPage(
            selfieBytes: bytes,
            analysis: analysis,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
      if (mounted &&
          _controller != null &&
          _controller!.value.isInitialized &&
          !_isAnalyzing) {
        _startImageStream(_controller!);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          _isCapturing = false;
        });
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_controller?.value.isStreamingImages == true) {
      try {
        _controller?.stopImageStream();
      } catch (_) {}
    }
    _controller?.dispose();
    _liveFaceDetector?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isAnalyzing,
      child: Scaffold(
        backgroundColor: _night,
        body: Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF2A3330), _night],
                ),
              ),
              child: SafeArea(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: SkinTokens.maxWidth),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final compact =
                            constraints.maxWidth < 350 || constraints.maxHeight < 640;
                        return Column(
                          children: [
                            const _ScanHeader(),
                            Expanded(
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: compact ? 14 : 18,
                                ),
                                child: _CameraFrame(
                                  compact: compact,
                                  controller: _controller,
                                  loading: _isLoading,
                                  errorMessage: _errorMessage,
                                  feedback: _feedback,
                                  automatic: _automaticMode,
                                  onRetry: _initializeCamera,
                                ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.fromLTRB(
                                28,
                                compact ? 10 : 14,
                                28,
                                compact ? 10 : 14,
                              ),
                              child: Text(
                                'Ambil foto wajah tanpa filter, dengan pencahayaan merata dan posisi serupa tiap check-in. Foto tidak menentukan diagnosis.',
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: .62),
                                  fontSize: 12,
                                  height: 1.4,
                                ),
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.fromLTRB(
                                18,
                                compact ? 12 : 16,
                                18,
                                compact ? 10 : 14,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: .06),
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(30),
                                ),
                                border: Border(
                                  top: BorderSide(
                                    color: Colors.white.withValues(alpha: .08),
                                  ),
                                ),
                              ),
                              child: Column(
                                children: [
                                  _ModeSwitch(
                                    automatic: _automaticMode,
                                    compact: compact,
                                    onChanged: (value) {
                                      setState(() {
                                        _automaticMode = value;
                                        _guide.reset();
                                        _feedback = LiveFaceFeedback.initial;
                                      });
                                    },
                                  ),
                                  SizedBox(height: compact ? 12 : 18),
                                  _CaptureControls(
                                    compact: compact,
                                    canSwitch: _cameras.length > 1,
                                    isCapturing: _isCapturing || _isAnalyzing,
                                    automatic: _automaticMode,
                                    stabilityProgress: _feedback.stabilityProgress,
                                    onGallery: _pickFromGallery,
                                    onCapture: () => _takePicture(isAuto: false),
                                    onSwitch: _switchCamera,
                                  ),
                                  SizedBox(height: compact ? 8 : 12),
                                  Text(
                                    _automaticMode
                                        ? 'Mode otomatis aktif: hadap kamera & tahan posisi stabil saat wajah berada di bingkai.'
                                        : 'Mode manual aktif: posisikan wajah, lalu tekan tombol shutter saat siap.',
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: .72),
                                      fontSize: compact ? 12 : 13,
                                      height: 1.35,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            if (_showShutterFlash)
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                ),
              ),
            if (_isAnalyzing)
              SkinAnalyzingOverlay(phase: _analysisPhase),
          ],
        ),
      ),
    );
  }
}

class _ScanHeader extends StatelessWidget {
  const _ScanHeader();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        child: Row(
          children: [
            SkinCircleButton(
              key: const Key('scan-back'),
              tooltip: 'Kembali',
              icon: Icons.arrow_back_ios_new_rounded,
              iconColor: Colors.white,
              background: Colors.white.withValues(alpha: .12),
              shadow: false,
              onPressed: () => Navigator.of(context).maybePop(),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Scan Wajah',
                    style: TextStyle(
                      fontFamily: SkinTokens.serif,
                      color: Colors.white,
                      fontSize: 26,
                      height: 1.05,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Hadap kamera dengan cahaya merata',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: .62),
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const _ScanBadge(),
          ],
        ),
      );
}

class _ScanBadge extends StatelessWidget {
  const _ScanBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: SkinTokens.primaryBright.withValues(alpha: .18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: SkinTokens.primaryBright.withValues(alpha: .4),
        ),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome, size: 13, color: Color(0xFFBFD8D2)),
          SizedBox(width: 5),
          Text(
            'AI',
            style: TextStyle(
              color: Color(0xFFBFD8D2),
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              letterSpacing: .6,
            ),
          ),
        ],
      ),
    );
  }
}

class _CameraFrame extends StatelessWidget {
  final bool compact;
  final CameraController? controller;
  final bool loading;
  final String? errorMessage;
  final LiveFaceFeedback feedback;
  final bool automatic;
  final VoidCallback onRetry;

  const _CameraFrame({
    required this.compact,
    required this.controller,
    required this.loading,
    required this.errorMessage,
    required this.feedback,
    required this.automatic,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withValues(alpha: .1)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildPreview(),
            if (!loading && errorMessage == null)
              CustomPaint(
                painter: _FaceGuidePainter(
                  feedback: feedback,
                  automatic: automatic,
                ),
              ),
            if (!loading && errorMessage == null)
              Align(
                alignment: const Alignment(0, .9),
                child: _buildGuidancePill(compact),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuidancePill(bool compact) {
    IconData icon;
    Color iconColor;

    switch (feedback.status) {
      case FaceAlignmentStatus.readyToCapture:
      case FaceAlignmentStatus.holdingSteady:
        icon = Icons.check_circle_rounded;
        iconColor = const Color(0xFF22C55E);
        break;
      case FaceAlignmentStatus.unstable:
        icon = Icons.face_retouching_natural;
        iconColor = const Color(0xFFBFD8D2);
        break;
      case FaceAlignmentStatus.tooFar:
      case FaceAlignmentStatus.tooClose:
      case FaceAlignmentStatus.offCenter:
      case FaceAlignmentStatus.tilted:
      case FaceAlignmentStatus.multipleFaces:
        icon = Icons.info_outline_rounded;
        iconColor = const Color(0xFFF59E0B);
        break;
      case FaceAlignmentStatus.noFace:
        icon = Icons.face_retouching_natural;
        iconColor = const Color(0xFFBFD8D2);
        break;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: compact ? 8 : 10,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: .55),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: iconColor.withValues(alpha: .45),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: iconColor),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              feedback.message,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (automatic &&
              feedback.stabilityProgress > 0 &&
              feedback.stabilityProgress < 1.0) ...[
            const SizedBox(width: 8),
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                value: feedback.stabilityProgress,
                strokeWidth: 2.2,
                color: const Color(0xFF22C55E),
                backgroundColor: Colors.white.withValues(alpha: .2),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPreview() {
    final camera = controller;
    if (loading) {
      return const ColoredBox(
        color: Color(0xFF1C2421),
        child: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }
    if (errorMessage != null) {
      return ColoredBox(
        color: const Color(0xFF1C2421),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.no_photography_outlined,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .86),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  key: const Key('retry-camera'),
                  onPressed: onRetry,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: SkinTokens.primaryDark,
                    minimumSize: const Size(0, 46),
                  ),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Coba lagi'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    if (camera == null || !camera.value.isInitialized) {
      return const DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: [Color(0xFF34403C), Color(0xFF141917)],
            radius: .9,
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final previewSize = camera.value.previewSize;
        if (previewSize == null) return CameraPreview(camera);
        return ClipRect(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: previewSize.height,
              height: previewSize.width,
              child: CameraPreview(camera),
            ),
          ),
        );
      },
    );
  }
}

class _ModeSwitch extends StatelessWidget {
  final bool automatic;
  final bool compact;
  final ValueChanged<bool> onChanged;

  const _ModeSwitch({
    required this.automatic,
    required this.compact,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: compact ? 44 : 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          _ModeButton(
            label: 'Foto Otomatis',
            icon: Icons.auto_mode_rounded,
            selected: automatic,
            onTap: () => onChanged(true),
          ),
          _ModeButton(
            label: 'Foto Manual',
            icon: Icons.touch_app_outlined,
            selected: !automatic,
            onTap: () => onChanged(false),
          ),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ModeButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final foreground =
        selected ? SkinTokens.primaryDark : Colors.white.withValues(alpha: .7);
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(999),
            child: AnimatedContainer(
              duration: SkinTokens.medium,
              curve: Curves.easeOutCubic,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: selected ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 17, color: foreground),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: TextStyle(
                        color: foreground,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CaptureControls extends StatelessWidget {
  final bool compact;
  final bool canSwitch;
  final bool isCapturing;
  final bool automatic;
  final double stabilityProgress;
  final VoidCallback onGallery;
  final VoidCallback onCapture;
  final VoidCallback onSwitch;

  const _CaptureControls({
    required this.compact,
    required this.canSwitch,
    required this.isCapturing,
    required this.automatic,
    required this.stabilityProgress,
    required this.onGallery,
    required this.onCapture,
    required this.onSwitch,
  });

  @override
  Widget build(BuildContext context) {
    final shutter = compact ? 72.0 : 82.0;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _RoundAction(
          key: const Key('scan-gallery'),
          icon: Icons.photo_library_outlined,
          label: 'Galeri',
          onTap: onGallery,
        ),
        Semantics(
          button: true,
          label: 'Ambil foto wajah',
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              key: const Key('capture-selfie'),
              onTap: isCapturing ? null : onCapture,
              customBorder: const CircleBorder(),
              child: Container(
                width: shutter,
                height: shutter,
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: SweepGradient(
                    colors: automatic && stabilityProgress > 0
                        ? const [
                            Color(0xFF22C55E),
                            Color(0xFF86EFAC),
                            Colors.white,
                            Color(0xFF22C55E),
                          ]
                        : const [
                            Color(0xFFBFD8D2),
                            SkinTokens.primaryBright,
                            Colors.white,
                            Color(0xFFBFD8D2),
                          ],
                  ),
                  boxShadow: SkinTokens.glow(
                    automatic && stabilityProgress > 0
                        ? const Color(0xFF22C55E)
                        : SkinTokens.primaryBright,
                    opacity: .45,
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: _SkinScanPageState._night,
                    shape: BoxShape.circle,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      DecoratedBox(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: SizedBox.expand(
                          child: isCapturing
                              ? const Padding(
                                  padding: EdgeInsets.all(18),
                                  child: CircularProgressIndicator(
                                    color: SkinTokens.primary,
                                    strokeWidth: 3,
                                  ),
                                )
                              : Icon(
                                  automatic
                                      ? Icons.auto_awesome_rounded
                                      : Icons.camera_alt_rounded,
                                  color: SkinTokens.primaryDark,
                                  size: 26,
                                ),
                        ),
                      ),
                      if (automatic && stabilityProgress > 0 && !isCapturing)
                        Positioned.fill(
                          child: CircularProgressIndicator(
                            value: stabilityProgress,
                            strokeWidth: 3.5,
                            color: const Color(0xFF22C55E),
                            backgroundColor: Colors.transparent,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        _RoundAction(
          key: const Key('switch-camera'),
          icon: Icons.cameraswitch_outlined,
          label: 'Balik',
          onTap: canSwitch ? onSwitch : null,
        ),
      ],
    );
  }
}

class _RoundAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _RoundAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Tooltip(
      message: label,
      child: Material(
        color: Colors.white.withValues(alpha: enabled ? .12 : .05),
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 56,
            height: 56,
            child: Icon(
              icon,
              color: Colors.white.withValues(alpha: enabled ? .95 : .3),
              size: 25,
            ),
          ),
        ),
      ),
    );
  }
}

class _FaceGuidePainter extends CustomPainter {
  final LiveFaceFeedback feedback;
  final bool automatic;

  const _FaceGuidePainter({
    required this.feedback,
    required this.automatic,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final oval = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * .45),
      width: size.width * .62,
      height: size.height * .66,
    );

    // Redupkan area di luar oval agar fokus ke wajah.
    final scrim = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addOval(oval);
    canvas.drawPath(
      scrim,
      Paint()..color = Colors.black.withValues(alpha: .38),
    );

    Color accentColor;
    double strokeWidth = 2.0;

    switch (feedback.status) {
      case FaceAlignmentStatus.readyToCapture:
        accentColor = const Color(0xFF22C55E);
        strokeWidth = 3.5;
        break;
      case FaceAlignmentStatus.holdingSteady:
        accentColor = const Color(0xFF4ADE80);
        strokeWidth = 2.5;
        break;
      case FaceAlignmentStatus.unstable:
        accentColor = const Color(0xFFBFD8D2);
        break;
      case FaceAlignmentStatus.tooFar:
      case FaceAlignmentStatus.tooClose:
      case FaceAlignmentStatus.offCenter:
      case FaceAlignmentStatus.tilted:
      case FaceAlignmentStatus.multipleFaces:
        accentColor = const Color(0xFFF59E0B);
        break;
      case FaceAlignmentStatus.noFace:
        accentColor = Colors.white.withValues(alpha: .85);
        break;
    }

    canvas.drawOval(
      oval,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..color = accentColor,
    );

    final dashPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..color = accentColor.withValues(alpha: .6);
    final innerPath = Path()..addOval(oval.deflate(12));
    for (final metric in innerPath.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(distance, distance + 9),
          dashPaint,
        );
        distance += 18;
      }
    }

    // Busur progres kestabilan foto otomatis
    if (automatic && feedback.stabilityProgress > 0) {
      final progressPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.5
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFF22C55E);

      final ovalPath = Path()..addOval(oval);
      final metric = ovalPath.computeMetrics().first;
      final sweepLength = metric.length * feedback.stabilityProgress;
      final startOffset = metric.length * 0.75;
      final p2 = startOffset + sweepLength;

      if (p2 <= metric.length) {
        canvas.drawPath(metric.extractPath(startOffset, p2), progressPaint);
      } else {
        canvas.drawPath(metric.extractPath(startOffset, metric.length), progressPaint);
        canvas.drawPath(metric.extractPath(0, p2 - metric.length), progressPaint);
      }
    }

    final cornerPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round;
    const corner = 28.0;
    final left = size.width * .12;
    final right = size.width * .88;
    final top = size.height * .08;
    final bottom = size.height * .82;

    void bracket(Offset a, Offset b, Offset c) {
      canvas.drawPath(
        Path()
          ..moveTo(a.dx, a.dy)
          ..lineTo(b.dx, b.dy)
          ..lineTo(c.dx, c.dy),
        cornerPaint,
      );
    }

    bracket(Offset(left, top + corner), Offset(left, top), Offset(left + corner, top));
    bracket(Offset(right - corner, top), Offset(right, top), Offset(right, top + corner));
    bracket(Offset(left, bottom - corner), Offset(left, bottom), Offset(left + corner, bottom));
    bracket(Offset(right - corner, bottom), Offset(right, bottom), Offset(right, bottom - corner));
  }

  @override
  bool shouldRepaint(covariant _FaceGuidePainter oldDelegate) {
    return oldDelegate.feedback.status != feedback.status ||
        oldDelegate.feedback.stabilityProgress != feedback.stabilityProgress ||
        oldDelegate.automatic != automatic;
  }
}
