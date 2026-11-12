import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';

import '../../core/theme/skin_theme.dart';

/// Full-screen analyzing overlay displayed during on-device ML inference.
/// Shows animated pulsing face scanner, staged status messages, progress bar,
/// and privacy reassurance ("On-Device AI · 100% Privat di HP").
class SkinAnalyzingOverlay extends StatefulWidget {
  const SkinAnalyzingOverlay({
    super.key,
    this.title = 'Kami sedang memeriksa kulitmu...',
    required this.phase,
  });

  final String title;
  final String phase;

  @override
  State<SkinAnalyzingOverlay> createState() => _SkinAnalyzingOverlayState();
}

class _SkinAnalyzingOverlayState extends State<SkinAnalyzingOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulseAnimation = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.85),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        final scale = 1.0 + (_pulseAnimation.value * 0.08);
                        final glow = 0.3 + (_pulseAnimation.value * 0.4);
                        return Transform.scale(
                          scale: scale,
                          child: Container(
                            width: 104,
                            height: 104,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  SkinTokens.aqua.withValues(alpha: glow),
                                  SkinTokens.aqua.withValues(alpha: 0.08),
                                  Colors.transparent,
                                ],
                                stops: const [0.4, 0.75, 1.0],
                              ),
                              border: Border.all(
                                color: SkinTokens.aqua.withValues(alpha: 0.6),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: SkinTokens.aqua
                                      .withValues(alpha: glow * 0.5),
                                  blurRadius: 28,
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.face_retouching_natural_rounded,
                                size: 48,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 32),
                    Text(
                      widget.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: SkinTokens.serif,
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: -0.3,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 12),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 260),
                      child: Text(
                        widget.phase,
                        key: ValueKey(widget.phase),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: SkinTokens.sans,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w400,
                          color: Colors.white.withValues(alpha: 0.78),
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: SizedBox(
                        width: 180,
                        height: 4,
                        child: LinearProgressIndicator(
                          backgroundColor:
                              Colors.white.withValues(alpha: 0.15),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            SkinTokens.aqua,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.lock_outline_rounded,
                            size: 13,
                            color: SkinTokens.aqua.withValues(alpha: 0.9),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'On-Device AI · 100% Privat di HP',
                            style: TextStyle(
                              fontFamily: SkinTokens.sans,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withValues(alpha: 0.7),
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
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
