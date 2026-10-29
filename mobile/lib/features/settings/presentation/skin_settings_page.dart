import 'package:flutter/material.dart';

import'../../../core/settings/font_settings.dart';
import'../../../core/theme/skin_theme.dart';
import'../../../shared/widgets/skin_page_background.dart';
import'../../../shared/widgets/skin_page_header.dart';
import'../../../shared/widgets/design_system/skin_ui.dart';

class SkinSettingsPage extends StatelessWidget {
  const SkinSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = SkinFontSettings.instance;
    return Scaffold(
      backgroundColor: SkinTokens.background,
      body: SkinPageBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: SkinTokens.maxWidth),
              child: Column(
                children: [
                  const SkinPageHeader(
                    title: 'Settings',
                    subtitle: 'Atur tampilan aplikasi',
                    backKey: Key('settings-back'),
                  ),
                  Expanded(
                    child: AnimatedBuilder(
                      animation: settings,
                      builder: (context, _) => ListView(
                        padding: const EdgeInsets.fromLTRB(20, 6, 20, 28),
                        children: [
                          const SkinSectionTitle(
                            eyebrow: 'TAMPILAN',
                            title: 'Tampilan tulisan',
                            subtitle:
                                'Pilih gaya font yang digunakan di seluruh aplikasi.',
                          ),
                          const SizedBox(height: 16),
                          _FontOption(
                            key: const Key('font-roboto'),
                            title: 'Plus Jakarta Sans',
                            description: 'Modern, bersih, dan mudah dibaca',
                            preview: 'Rawat kulitmu, nikmati prosesnya.',
                            fontFamily: SkinTokens.sans,
                            selected: settings.choice == SkinFontChoice.roboto,
                            onTap: () => settings.select(SkinFontChoice.roboto),
                          ),
                          const SizedBox(height: 12),
                          _FontOption(
                            key: const Key('font-handwritten'),
                            title: 'Handwritten',
                            description: 'Santai seperti catatan pribadi',
                            preview: 'Rawat kulitmu, nikmati prosesnya.',
                            fontFamily: 'Kalam',
                            selected:
                                settings.choice == SkinFontChoice.handwritten,
                            onTap: () =>
                                settings.select(SkinFontChoice.handwritten),
                          ),
                          const SizedBox(height: 18),
                          const SkinNotice(
                            dense: true,
                            tone: SkinTone.neutral,
                            icon: Icons.auto_awesome_outlined,
                            message:
                                'Judul besar selalu memakai huruf serif Cormorant Garamond sebagai ciri khas SkinSight.',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FontOption extends StatelessWidget {
  const _FontOption({
    super.key,
    required this.title,
    required this.description,
    required this.preview,
    required this.fontFamily,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String description;
  final String preview;
  final String fontFamily;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(SkinTokens.radiusLg);
    return AnimatedContainer(
      duration: SkinTokens.medium,
      decoration: BoxDecoration(
        color: selected ? Colors.white : SkinTokens.glass,
        borderRadius: radius,
        border: Border.all(
          color: selected ? SkinTokens.primary : Colors.white,
          width: selected ? 1.4 : 1,
        ),
        boxShadow: selected ? SkinTokens.shadows : null,
      ),
      child: Material(
        type: MaterialType.transparency,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 16, 14),
            child: Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected ? Colors.white : SkinTokens.surfaceAlt,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    'Aa',
                    style: TextStyle(
                      fontFamily: fontFamily,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: SkinTokens.primaryDark,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontFamily: fontFamily,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: SkinTokens.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        description,
                        style: const TextStyle(
                          fontSize: 12,
                          color: SkinTokens.muted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        preview,
                        style: TextStyle(
                          fontFamily: fontFamily,
                          fontSize: 14,
                          color: SkinTokens.ink,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                AnimatedSwitcher(
                  duration: SkinTokens.fast,
                  child: Icon(
                    selected
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    key: ValueKey(selected),
                    color: selected ? SkinTokens.primary : SkinTokens.subtle,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
