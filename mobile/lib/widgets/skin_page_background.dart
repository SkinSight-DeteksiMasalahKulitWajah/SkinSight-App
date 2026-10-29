import 'package:flutter/material.dart';

import '../theme/skin_theme.dart';

/// Latar visual bersama: sage pucat dengan gradien radial lembut (cahaya
/// putih di kiri atas, aqua-sage di kanan, aloe samar di bawah). Dekorasi
/// tidak menerima input sehingga tidak mengganggu gesture halaman.
class SkinPageBackground extends StatelessWidget {
  const SkinPageBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: SkinTokens.sageGradient),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned(
            top: -180,
            left: -140,
            child: IgnorePointer(
              child: _Glow(size: 460, color: Color(0xCCFFFFFF)),
            ),
          ),
          const Positioned(
            top: 120,
            right: -170,
            child: IgnorePointer(
              child: _Glow(size: 380, color: Color(0x80BFD8D2)),
            ),
          ),
          const Positioned(
            left: -120,
            bottom: -140,
            child: IgnorePointer(
              child: _Glow(size: 400, color: Color(0x40A9CDB0)),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
        ),
      ),
    );
  }
}
