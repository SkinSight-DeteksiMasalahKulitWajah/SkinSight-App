import 'package:flutter/material.dart';

import '../../../core/theme/skin_theme.dart';
import '../../../features/journeys/data/skin_journey_store.dart';
import '../../../features/scan/presentation/skin_quiz_page.dart';
import '../../../features/scan/presentation/skin_scan_page.dart';

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
  static const overlap = 110.0;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 360;
    // Kept outside the tab IndexedStack: content changes never replace
    // this navigation bar. A repaint boundary also isolates its paint work.
    return RepaintBoundary(
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 12),
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 18),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: SkinTokens.border),
                  boxShadow: SkinTokens.shadowsLifted,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 6,
                  ),
                  child: Row(
                    children: [
                      _NavItem(
                        key: const Key('bottom-home'),
                        icon: Icons.home_outlined,
                        activeIcon: Icons.home_rounded,
                        label: 'Home',
                        compact: compact,
                        selected: currentIndex == 0,
                        onTap: () => _open(context, 0),
                      ),
                      _NavItem(
                        key: const Key('open-education'),
                        icon: Icons.auto_stories_outlined,
                        activeIcon: Icons.auto_stories_rounded,
                        label: 'Edukasi',
                        compact: compact,
                        selected: currentIndex == 1,
                        onTap: () => _open(context, 1),
                      ),
                      _ScanButton(compact: compact),
                      _NavItem(
                        key: const Key('bottom-journey'),
                        icon: Icons.timeline_outlined,
                        activeIcon: Icons.timeline_rounded,
                        label: compact ? 'Journey' : 'Perjalanan',
                        compact: compact,
                        selected: currentIndex == 3,
                        onTap: () => _open(context, 3),
                      ),
                      _NavItem(
                        key: const Key('bottom-profile'),
                        icon: Icons.person_outline_rounded,
                        activeIcon: Icons.person_rounded,
                        label: 'Profil',
                        compact: compact,
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
    final size = compact ? 50.0 : 54.0;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: compact ? 2 : 6),
      child: Semantics(
        button: true,
        label: 'Pindai wajah',
        excludeSemantics: true,
        child: Tooltip(
          message: 'Pindai wajah',
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: SkinTokens.glow(SkinTokens.primary, opacity: .26),
            ),
            child: Material(
              color: SkinTokens.primary,
              shape: const CircleBorder(),
              elevation: 0,
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                key: const Key('bottom-scan'),
                onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                  builder: (_) => SkinJourneyStore.instance.questionnaireDone &&
                          SkinJourneyStore.instance.consent == true
                      ? const SkinScanPage()
                      : const SkinQuizPage(),
                )),
                child: SizedBox(
                  width: size,
                  height: size,
                  child: const Icon(
                    Icons.center_focus_weak_rounded,
                    color: Colors.white,
                    size: 24,
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

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool compact;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    super.key,
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.compact,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fg = selected ? SkinTokens.primary : SkinTokens.muted;
    return Expanded(
      child: Semantics(
        selected: selected,
        button: true,
        label: label,
        excludeSemantics: true,
        child: Tooltip(
          message: label,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: SkinTokens.fast,
                curve: Curves.easeOutCubic,
                constraints: const BoxConstraints(minHeight: 52),
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 2 : 4,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: selected ? SkinTokens.mint : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      selected ? activeIcon : icon,
                      color: fg,
                      size: compact ? 20 : 21,
                    ),
                    const SizedBox(height: 3),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        label,
                        maxLines: 1,
                        softWrap: false,
                        style: TextStyle(
                          fontSize: compact ? 10 : 10.5,
                          height: 1.1,
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w600,
                          color: fg,
                        ),
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
