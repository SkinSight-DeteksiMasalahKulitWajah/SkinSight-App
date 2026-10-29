import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import'../../core/theme/app_colors.dart';
import'../../core/theme/app_motion.dart';
import'../../core/theme/app_spacing.dart';
import'../../core/app_assets.dart';

/// CTA "geser untuk mulai".
///
/// Track kaca selebar penuh dengan thumb putih (lidah buaya 3D + label) yang
/// bisa digeser ke kanan. Tiga chevron tipis (›››) di kanan berkedip
/// bergantian secara berkala. Mengetuk di mana saja pada track, atau menekan Enter/Spasi saat
/// fokus, juga menjalankan [onStart] (fallback aksesibilitas).
class SlideToStartButton extends StatefulWidget {
  const SlideToStartButton({
    super.key,
    required this.label,
    required this.onStart,
    this.semanticHint = 'Geser ke kanan atau ketuk untuk memulai',
    this.height = 64,
  });

  final String label;
  final VoidCallback onStart;
  final String semanticHint;
  final double height;

  @override
  State<SlideToStartButton> createState() => _SlideToStartButtonState();
}

class _SlideToStartButtonState extends State<SlideToStartButton>
    with TickerProviderStateMixin {
  /// Posisi thumb: 0 = kiri, 1 = ujung kanan.
  late final AnimationController _slide = AnimationController(vsync: this);

  /// Satu siklus kedip chevron (1,5 s), diulang setelah jeda [_chevronRest].
  late final AnimationController _chevrons = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );
  Timer? _chevronTimer;

  /// Jeda antar-kedip. Selama jeda layar pembuka tidak menggambar frame
  /// baru, sehingga foto, kolom blur, dan panel kaca di belakangnya tidak
  /// dirender ulang terus-menerus.
  static const _chevronRest = Duration(seconds: 3);

  final _thumbKey = GlobalKey();
  bool _pressed = false;
  bool _focused = false;
  bool _completing = false;

  /// Ambang geser yang dianggap "selesai".
  static const _completeAt = .7;
  static const _flingVelocity = 900.0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AppMotion.loops(context)) {
      if (!_chevrons.isAnimating && _chevronTimer == null) _playChevrons();
    } else {
      _chevronTimer?.cancel();
      _chevronTimer = null;
      _chevrons
        ..stop()
        ..value = 0;
    }
  }

  void _playChevrons() {
    // Selesai di t = 1, yang sama dengan pola diam (t = 0).
    _chevrons.forward(from: 0).then((_) {
      if (mounted) _chevronTimer = Timer(_chevronRest, _playNextChevrons);
    });
  }

  void _playNextChevrons() {
    _chevronTimer = null;
    _playChevrons();
  }

  @override
  void dispose() {
    _chevronTimer?.cancel();
    _slide.dispose();
    _chevrons.dispose();
    super.dispose();
  }

  /// Jarak tempuh thumb dalam piksel logis.
  double get _travel {
    final track = context.findRenderObject() as RenderBox?;
    final thumb = _thumbKey.currentContext?.findRenderObject() as RenderBox?;
    if (track == null || thumb == null || !track.hasSize || !thumb.hasSize) {
      return 1;
    }
    return math.max(1, track.size.width - thumb.size.width - 2 * AppSpacing.xs);
  }

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (_completing) return;
    _slide.value += (details.primaryDelta ?? 0) / _travel;
  }

  void _onDragEnd(DragEndDetails details) {
    _setPressed(false);
    if (_completing) return;
    final velocity = details.primaryVelocity ?? 0;
    if (_slide.value >= _completeAt || velocity > _flingVelocity) {
      _complete();
    } else {
      _slide.animateBack(0, duration: AppMotion.medium, curve: AppMotion.curve);
    }
  }

  void _complete() {
    if (_completing) return;
    _completing = true;
    HapticFeedback.lightImpact();
    _slide
        .animateTo(1, duration: AppMotion.fast, curve: AppMotion.curve)
        .then((_) {
      if (!mounted) return;
      widget.onStart();
      _completing = false;
      // Kembalikan thumb pelan-pelan sementara halaman berikutnya masuk.
      _slide.animateBack(0, duration: AppMotion.slow, curve: AppMotion.curve);
    });
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(widget.height / 2);
    // FocusableActionDetector di luar agar flag "focusable" & aksi fokus dari
    // Focus ikut tergabung ke node semantik tombol (excludeSemantics hanya
    // membuang label/teks anak, bukan informasi fokus).
    return FocusableActionDetector(
      mouseCursor: SystemMouseCursors.click,
      onShowFocusHighlight: (value) => setState(() => _focused = value),
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            _complete();
            return null;
          },
        ),
      },
      child: Semantics(
        button: true,
        label: widget.label,
        hint: widget.semanticHint,
        onTap: _complete,
        excludeSemantics: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => _setPressed(true),
          onTapUp: (_) => _setPressed(false),
          onTapCancel: () => _setPressed(false),
          onTap: _complete,
          onHorizontalDragStart: (_) => _setPressed(true),
          onHorizontalDragUpdate: _onDragUpdate,
          onHorizontalDragEnd: _onDragEnd,
          onHorizontalDragCancel: () => _setPressed(false),
          child: AnimatedScale(
            scale: _pressed ? .97 : 1,
            duration: AppMotion.fast,
            curve: AppMotion.curve,
            child: SizedBox(
              height: widget.height,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  // Rel kaca: putih tipis di atas latar mist, dengan sedikit
                  // rona sage agar tetap terbaca sebagai jalur geser.
                  gradient: LinearGradient(
                    colors: [
                      AppColors.white.withValues(alpha: .55),
                      AppColors.aquaSage.withValues(alpha: .22),
                    ],
                  ),
                  borderRadius: radius,
                  border: Border.all(
                    color: _focused
                        ? AppColors.textPrimary
                        : AppColors.white.withValues(alpha: .95),
                    width: _focused ? 2 : 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.textPrimary.withValues(alpha: .06),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  child: AnimatedBuilder(
                    animation: _slide,
                    builder: (context, thumb) => Stack(
                      children: [
                        Align(
                          alignment: Alignment.centerRight,
                          child: Padding(
                            padding:
                                const EdgeInsets.only(right: AppSpacing.lg),
                            child: RepaintBoundary(
                              child: _Chevrons(
                                animation: _chevrons,
                                visibility:
                                    (1 - _slide.value * 1.6).clamp(0.0, 1.0),
                              ),
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment(-1 + 2 * _slide.value, 0),
                          child: thumb,
                        ),
                      ],
                    ),
                    child: _Thumb(
                      key: _thumbKey,
                      label: widget.label,
                      height: widget.height - 2 * AppSpacing.xs,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({super.key, required this.label, required this.height});

  final String label;
  final double height;

  @override
  Widget build(BuildContext context) {
    final iconSize = height - 2 * AppSpacing.xs;
    return Container(
      height: height,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xs,
        AppSpacing.xs,
        AppSpacing.xl,
        AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(height / 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: .1),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: iconSize,
            height: iconSize,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.mistBottom,
                  AppColors.aquaSage.withValues(alpha: .75),
                ],
              ),
            ),
            // Daun aloe 3D diperbesar & digeser agar ujung daun memenuhi
            // lingkaran, seperti potongan foto pada referensi.
            child: OverflowBox(
              maxWidth: iconSize * 2.1,
              maxHeight: iconSize * 2.1,
              alignment: const Alignment(.15, -.2),
              child: Image.asset(
                AppAssets.aloe3d,
                width: iconSize * 2.1,
                fit: BoxFit.contain,
                cacheWidth: 200,
                excludeFromSemantics: true,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelLarge!.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: -.1,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Chevrons extends AnimatedWidget {
  const _Chevrons(
      {required Animation<double> animation, required this.visibility})
      : super(listenable: animation);

  /// 0–1; memudar saat thumb digeser.
  final double visibility;

  @override
  Widget build(BuildContext context) {
    final t = (listenable as Animation<double>).value;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 3; i++)
          // Chevron dirapatkan (lebar 11 px) agar terbaca sebagai "›››".
          SizedBox(
            width: 11,
            child: OverflowBox(
              maxWidth: 22,
              child: Opacity(
                opacity: visibility * _pulse(t, i),
                child: Icon(
                  Icons.chevron_right_rounded,
                  size: 22,
                  color: AppColors.textSecondary.withValues(alpha: .9),
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// Opasitas tiap chevron: gelombang yang bergeser dari kiri ke kanan.
  /// Saat diam (t = 0) hasilnya bertingkat terang → gelap sebagai isyarat arah.
  static double _pulse(double t, int index) {
    final phase = (t - index * .18) % 1.0;
    final wave = math.sin(phase * math.pi);
    return .25 + .75 * wave * wave;
  }
}
