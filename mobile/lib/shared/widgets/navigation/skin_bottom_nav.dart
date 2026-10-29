import 'package:flutter/material.dart';

import'../../../features/journeys/data/skin_journey_store.dart';
import'../../../features/scan/presentation/skin_quiz_page.dart';
import'../../../features/scan/presentation/skin_scan_page.dart';
import'../../../core/theme/skin_theme.dart';
import'../design_system/skin_ui.dart';

/// Bilah navigasi bawah melayang: kapsul kaca dengan tombol pindai bulat
/// gelap yang menonjol di tengah.
class SkinBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int>? onSelected;
  final VoidCallback? onJourney;

  const SkinBottomNav({
    super.key,
    required this.currentIndex,
    this.onSelected,
    this.onJourney,
  });

  /// Tinggi area yang ditutupi bilah, untuk padding konten di belakangnya.
  static const overlap = 104.0;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 350;
    // Kept outside the tab IndexedStack: content changes never replace
    // this navigation bar. A repaint boundary also isolates its paint work.
    return RepaintBoundary(
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 12),
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 24),
              child: SkinGlass(
                radius: 999,
                color: SkinTokens.glassStrong,
                borderColor: Colors.white,
                shadows: SkinTokens.shadowsLifted,
                padding: const EdgeInsets.all(6),
                child: Row(
                  children: [
                    _NavItem(
                      key: const Key('bottom-home'),
                      icon: Icons.home_outlined,
                      activeIcon: Icons.home_rounded,
                      label: 'Home',
                      selected: currentIndex == 0,
                      onTap: () => _open(context, 0),
                    ),
                    _NavItem(
                      key: const Key('open-education'),
                      icon: Icons.auto_stories_outlined,
                      activeIcon: Icons.auto_stories_rounded,
                      label: 'Edukasi',
                      selected: currentIndex == 1,
                      onTap: () => _open(context, 1),
                    ),
                    _ScanButton(compact: compact),
                    _NavItem(
                      key: const Key('bottom-journey'),
                      icon: Icons.timeline_outlined,
                      activeIcon: Icons.timeline_rounded,
                      label: 'Perjalanan',
                      selected: currentIndex == 3,
                      onTap: () => _open(context, 3),
                    ),
                    _NavItem(
                      key: const Key('bottom-profile'),
                      icon: Icons.person_outline_rounded,
                      activeIcon: Icons.person_rounded,
                      label: 'Profil',
                      selected: currentIndex == 4,
                      onTap: () => _open(context, 4),
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

  void _open(BuildContext context, int index) {
    // Perjalanan membuka katalog journey, baik dari home maupun halaman lain.
    if (index == 3) {
      if (onJourney != null) {
        onJourney!();
      } else if (currentIndex != 3) {
        Navigator.of(context).pushNamed('/journeys');
      }
      return;
    }

    if (index == currentIndex) return;
    final tabIndex = index == 4 ? 2 : index;
    if (onSelected != null) {
      onSelected!(tabIndex);
      return;
    }

    final navigator = Navigator.of(context);
    if (index == 0) {
      var foundHome = false;
      navigator.popUntil((route) {
        foundHome = route.settings.name == '/home';
        return foundHome || route.isFirst;
      });
      if (!foundHome) navigator.pushReplacementNamed('/home');
      return;
    }

    final route = index == 1 ? '/education' : '/profile';
    if (currentIndex == 0) {
      navigator.pushNamed(route);
    } else {
      navigator.pushReplacementNamed(route);
    }
  }
}

class _ScanButton extends StatelessWidget {
  const _ScanButton({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 52.0 : 58.0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Semantics(
        button: true,
        label: 'Pindai wajah',
        excludeSemantics: true,
        child: Tooltip(
          message: 'Pindai wajah',
          child: Material(
            color: SkinTokens.primary,
            shape: const CircleBorder(),
            elevation: 0,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              key: const Key('bottom-scan'),
              onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) => SkinJourneyStore.instance.questionnaireDone
                    ? const SkinScanPage()
                    : const SkinQuizPage(),
              )),
              child: SizedBox(
                width: size,
                height: size,
                child: const Icon(
                  Icons.center_focus_weak_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    super.key,
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(
        selected: selected,
        button: true,
        label: label,
        excludeSemantics: true,
        child: Tooltip(
          message: label,
          child: InkWell(
            onTap: onTap,
            customBorder: const StadiumBorder(),
            child: SizedBox(
              height: 52,
              child: Center(
                child: AnimatedContainer(
                  duration: SkinTokens.medium,
                  curve: Curves.easeOutCubic,
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: selected ? Colors.white : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected
                          ? Colors.white
                          : SkinTokens.ink.withValues(alpha: .08),
                    ),
                    boxShadow: selected ? SkinTokens.shadows : null,
                  ),
                  child: AnimatedSwitcher(
                    duration: SkinTokens.fast,
                    child: Icon(
                      selected ? activeIcon : icon,
                      key: ValueKey(selected),
                      color: selected ? SkinTokens.ink : SkinTokens.muted,
                      size: 22,
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
