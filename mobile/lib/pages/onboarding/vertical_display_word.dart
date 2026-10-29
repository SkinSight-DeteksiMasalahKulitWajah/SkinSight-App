import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/skin_theme.dart';

/// Kata display serif yang diputar 90° berlawanan jarum jam (dibaca dari
/// bawah ke atas), misalnya "Natural". Putih semi-transparan dengan bayangan
/// sangat halus agar tetap terbaca di atas kaca buram.
///
/// Ukuran mengikuti kotak induk lewat [FittedBox], jadi aman di semua layar.
class VerticalDisplayWord extends StatelessWidget {
  const VerticalDisplayWord(this.text, {super.key, this.opacity = .94});

  final String text;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    const fontSize = 160.0;
    final style = TextStyle(
      fontFamily: SkinTokens.serif,
      fontSize: fontSize,
      // Tinggi baris rapat: "Natural" tidak punya descender, jadi kotak teks
      // dipangkas agar huruf mengisi lebar kolom kaca sebesar mungkin.
      height: .86,
      fontWeight: FontWeight.w300,
      letterSpacing: fontSize * .025,
      color: AppColors.white.withValues(alpha: opacity),
      shadows: [
        Shadow(
          color: AppColors.textPrimary.withValues(alpha: .10),
          blurRadius: 18,
          offset: const Offset(0, 2),
        ),
      ],
    );
    // Kata dekoratif; tidak dibacakan pembaca layar.
    return ExcludeSemantics(
      child: FittedBox(
        fit: BoxFit.contain,
        alignment: Alignment.bottomCenter,
        child: RotatedBox(
          quarterTurns: 3,
          child: Text(
            text,
            maxLines: 1,
            softWrap: false,
            textScaler: TextScaler.noScaling,
            style: style,
          ),
        ),
      ),
    );
  }
}
