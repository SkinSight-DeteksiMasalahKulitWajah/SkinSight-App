import 'dart:async';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import'../data/skin_demo_data.dart';
import'../../journeys/data/skin_journey_store.dart';

import'../../../core/theme/skin_theme.dart';
import'../../../shared/widgets/design_system/skin_ui.dart';
import 'package:image_picker/image_picker.dart';

import'./skin_result_page.dart';

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
  bool _automaticMode = true;
  String? _errorMessage;

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
      final controller = CameraController(
        cameras[selectedIndex],
        ResolutionPreset.high,
        enableAudio: false,
      );
      _controller = controller;
      await oldController?.dispose();
      await controller.initialize().timeout(const Duration(seconds: 30));

      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _cameras = cameras;
        _cameraIndex = selectedIndex;
        _isLoading = false;
      });
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

  Future<void> _switchCamera() async {
    if (_cameras.length < 2 || _isCapturing) return;
    final nextIndex = (_cameraIndex + 1) % _cameras.length;
    await _initializeCamera(preferredIndex: nextIndex);
  }

  Future<void> _takePicture() async {
    final controller = _controller;
    if (controller == null ||
        !controller.value.isInitialized ||
        controller.value.isTakingPicture ||
        _isCapturing) {
      return;
    }

    setState(() => _isCapturing = true);
    try {
      final picture = await controller.takePicture();
      final bytes = await picture.readAsBytes();
      if (!mounted) return;
      await _openResult(bytes);
    } on CameraException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.description ?? 'Gagal mengambil foto.')),
      );
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  Future<void> _pickFromGallery() async {
    if (_isCapturing) return;
    final picture = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
      maxWidth: 1600,
    );
    if (picture == null || !mounted) return;
    await _openResult(await picture.readAsBytes());
  }

  Future<void> _openResult(Uint8List bytes) async {
    if (widget.returnPhoto) {
      Navigator.of(context).pop(bytes);
      return;
    }
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => SkinResultPage(
            selfieBytes: bytes,
            analysis: SkinDemoData.forPhoto(bytes,
                sessionIndex: SkinJourneyStore.instance.photos.length)),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _night,
      body: DecoratedBox(
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
                              onChanged: (value) => setState(
                                () => _automaticMode = value,
                              ),
                            ),
                            SizedBox(height: compact ? 12 : 18),
                            _CaptureControls(
                              compact: compact,
                              canSwitch: _cameras.length > 1,
                              isCapturing: _isCapturing,
                              onGallery: _pickFromGallery,
                              onCapture: _takePicture,
                              onSwitch: _switchCamera,
                            ),
                            SizedBox(height: compact ? 8 : 12),
                            Text(
                              _automaticMode
                                  ? 'Pastikan wajah terang, lalu tekan tombol saat posisi sudah pas.'
                                  : 'Mode manual aktif. Tekan tombol untuk mengambil selfie.',
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
  final VoidCallback onRetry;

  const _CameraFrame({
    required this.compact,
    required this.controller,
    required this.loading,
    required this.errorMessage,
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
              const CustomPaint(painter: _FaceGuidePainter()),
            if (!loading && errorMessage == null)
              Align(
                alignment: const Alignment(0, .9),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: compact ? 8 : 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: .45),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: .14),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.face_retouching_natural,
                          size: 16, color: Color(0xFFBFD8D2)),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Posisikan wajah di dalam frame',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
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
  final VoidCallback onGallery;
  final VoidCallback onCapture;
  final VoidCallback onSwitch;

  const _CaptureControls({
    required this.compact,
    required this.canSwitch,
    required this.isCapturing,
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
                  gradient: const SweepGradient(
                    colors: [
                      Color(0xFFBFD8D2),
                      SkinTokens.primaryBright,
                      Colors.white,
                      Color(0xFFBFD8D2),
                    ],
                  ),
                  boxShadow:
                      SkinTokens.glow(SkinTokens.primaryBright, opacity: .45),
                ),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: _SkinScanPageState._night,
                    shape: BoxShape.circle,
                  ),
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: isCapturing
                        ? const Padding(
                            padding: EdgeInsets.all(18),
                            child: CircularProgressIndicator(
                              color: SkinTokens.primary,
                              strokeWidth: 3,
                            ),
                          )
                        : const Icon(
                            Icons.camera_alt_rounded,
                            color: SkinTokens.primaryDark,
                            size: 26,
                          ),
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
  const _FaceGuidePainter();

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

    canvas.drawOval(
      oval,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white.withValues(alpha: .85),
    );

    final dashPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFBFD8D2);
    final path = Path()..addOval(oval.deflate(12));
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(distance, distance + 9),
          dashPaint,
        );
        distance += 18;
      }
    }

    final cornerPaint = Paint()
      ..color = const Color(0xFFBFD8D2)
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

    bracket(Offset(left, top + corner), Offset(left, top),
        Offset(left + corner, top));
    bracket(Offset(right - corner, top), Offset(right, top),
        Offset(right, top + corner));
    bracket(Offset(left, bottom - corner), Offset(left, bottom),
        Offset(left + corner, bottom));
    bracket(Offset(right - corner, bottom), Offset(right, bottom),
        Offset(right, bottom - corner));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
