import 'package:flutter/material.dart';

import '../theme/skin_theme.dart';
import 'skin_ui.dart';

/// Header halaman: tombol kembali kaca bulat, judul serif, subjudul
/// opsional, aksi kanan.
class SkinPageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Key? backKey;
  final Widget? trailing;
  final VoidCallback? onBack;

  const SkinPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.backKey,
    this.trailing,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
        child: Row(children: [
          SkinCircleButton(
            key: backKey,
            tooltip: 'Kembali',
            icon: Icons.arrow_back_ios_new_rounded,
            onPressed: onBack ?? () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: SkinTokens.serif,
                    fontSize: 26,
                    height: 1.1,
                    fontWeight: FontWeight.w500,
                    color: SkinTokens.ink,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: SkinTokens.caption.copyWith(fontSize: 12.5),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing!,
          ],
        ]),
      );
}
