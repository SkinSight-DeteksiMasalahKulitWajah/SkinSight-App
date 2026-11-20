import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/api/cloud_sync.dart';
import '../../../core/api/supabase_direct.dart';
import '../../../core/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/skin_theme.dart';
import '../../../shared/widgets/asset_images.dart';
import '../../../shared/widgets/design_system/skin_ui.dart';
import '../../../shared/widgets/navigation/skin_bottom_nav.dart';
import '../../../shared/widgets/shimmer_skeleton.dart';
import '../../../shared/widgets/skin_3d.dart';
import '../../../shared/widgets/skin_page_background.dart';
import '../../checkin/presentation/skin_checkin_page.dart';
import '../../checkin/presentation/widgets/skin_checkin_shortcut.dart';
import '../../education/presentation/skin_education_page.dart';
import '../../history/data/skin_history_repository.dart';
import '../../history/presentation/skin_history_page.dart';
import '../../journeys/data/skin_journey_store.dart';
import '../../journeys/presentation/skin_journeys_page.dart';
import '../../notifications/data/skin_notification_center.dart';
import '../../notifications/presentation/skin_notifications_page.dart';
import '../../profile/models/profile_data.dart';
import '../../profile/presentation/skin_profile_page.dart';
import '../../scan/presentation/skin_quiz_page.dart';
import '../../scan/presentation/skin_result_page.dart';
import '../../scan/presentation/skin_scan_page.dart';

class SkinHomePage extends StatefulWidget {
  final int initialIndex;

  const SkinHomePage({super.key, this.initialIndex = 0});

  @override
  State<SkinHomePage> createState() => _SkinHomePageState();
}

/// Tiga tab memakai IndexedStack agar tidak dihancurkan setiap berpindah menu.
class _SkinHomePageState extends State<SkinHomePage> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, 2);
  }

  void _selectTab(int i) {
    if (i == _currentIndex) return;
    setState(() => _currentIndex = i);
  }

  Widget _tab(int index, Widget child) =>
      TickerMode(enabled: index == _currentIndex, child: child);

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: SkinTokens.background,
        extendBody: true,
        body: SkinPageBackground(
          child: SafeArea(
            bottom: false,
            child: Center(
              child: ConstrainedBox(
                constraints:
                    const BoxConstraints(maxWidth: SkinTokens.maxWidth),
                child: SizedBox.expand(
                  child: IndexedStack(
                    index: _currentIndex,
                    children: [
                      _tab(
                        0,
                        _HomeScrollView(
                          key: const PageStorageKey('home-tab'),
                          onOpenEducation: () => _selectTab(1),
                        ),
                      ),
                      _tab(
                        1,
                        const SkinEducationPage(
                          embedded: true,
                          key: PageStorageKey('education-tab'),
                        ),
                      ),
                      _tab(
                        2,
                        const SkinProfilePage(
                          embedded: true,
                          key: PageStorageKey('profile-tab'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        bottomNavigationBar: SkinBottomNav(
          currentIndex: _currentIndex == 2 ? 4 : _currentIndex,
          onSelected: _selectTab,
          onJourney: () => _openJourneys(context),
        ),
      );
}

void _startScan(BuildContext context) {
  final store = SkinJourneyStore.instance;
  final readyForScan = store.questionnaireDone && store.consent == true;
  Navigator.of(context).push(MaterialPageRoute<void>(
    builder: (_) => readyForScan ? const SkinScanPage() : const SkinQuizPage(),
  ));
}

void _openJourneys(BuildContext context) {
  Navigator.of(context).push(MaterialPageRoute<void>(
    settings: const RouteSettings(name: '/journeys'),
    builder: (_) => const SkinJourneysPage(),
  ));
}

void _openHistory(BuildContext context) {
  Navigator.of(context).push(MaterialPageRoute<void>(
    settings: const RouteSettings(name: '/history'),
    builder: (_) => const SkinHistoryPage(),
  ));
}

String _localizeCondition(String raw) {
  switch (raw.trim().toLowerCase()) {
    case 'acne':
      return 'Jerawat';
    case 'pih':
    case 'hyperpigmentation':
    case 'dark spots':
      return 'Noda Gelap (PIH)';
    case 'dark circle':
    case 'dark circles':
      return 'Lingkar Mata';
    case 'redness':
    case 'erythema':
      return 'Kemerahan';
    case 'wrinkle':
    case 'wrinkles':
    case 'fine lines':
      return 'Garis Halus';
    case 'pores':
    case 'enlarged pores':
      return 'Pori Besar';
    default:
      return raw;
  }
}

class _HomeScrollView extends StatelessWidget {
  const _HomeScrollView({super.key, required this.onOpenEducation});

  final VoidCallback onOpenEducation;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final compact = constraints.maxWidth < 350;
      final horizontal = compact ? 16.0 : 20.0;

      return RefreshIndicator(
        onRefresh: () async {
          if (!SupabaseDirect.isSignedIn) return;
          await CloudSync.instance.refresh(retryBackend: true);
        },
        color: SkinTokens.primary,
        backgroundColor: Colors.white,
        child: CustomScrollView(
          physics: const ClampingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                horizontal,
                12,
                horizontal,
                SkinBottomNav.overlap + 20,
              ),
              sliver: SliverToBoxAdapter(
                child: RepaintBoundary(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _Header(compact: compact),
                      const SizedBox(height: 18),
                      _ScanHeroCard(compact: compact),
                      const _HomeCheckinShortcut(),
                      const SizedBox(height: 16),
                      _SkinJourneyOverviewCard(compact: compact),
                      const SizedBox(height: 26),
                      const _RecentActivitySection(),
                      const SizedBox(height: 24),
                      _DailyTipCard(onOpen: onOpenEducation),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

// ───────────────────────── Compact Header ─────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileData>();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Semantics(
          button: true,
          label: 'Buka profil ${profile.name}',
          child: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              key: const Key('open-profile'),
              customBorder: const CircleBorder(),
              onTap: () => Navigator.of(context).pushNamed('/profile'),
              child: Container(
                width: 44,
                height: 44,
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: SkinTokens.shadows,
                ),
                child: ClipOval(
                  child: ColoredBox(
                    color: SkinTokens.mint,
                    child: profile.photoBytes == null
                        ? Image.asset(
                            AppAssets.avatar3d,
                            key: const Key('home-default-avatar'),
                            fit: BoxFit.cover,
                            width: 40,
                            height: 40,
                            alignment: const Alignment(0, .6),
                            cacheWidth: 160,
                            filterQuality: FilterQuality.medium,
                            errorBuilder: assetErrorBuilder,
                          )
                        : Image.memory(
                            profile.photoBytes!,
                            key: const Key('home-profile-photo'),
                            fit: BoxFit.cover,
                            width: 40,
                            height: 40,
                            cacheWidth: thumbnailCacheWidth(context, 44),
                            gaplessPlayback: true,
                          ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                SkinFormat.greeting(DateTime.now()),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.25,
                  fontWeight: FontWeight.w600,
                  color: SkinTokens.muted,
                ),
              ),
              const SizedBox(height: 1),
              // Dua Text terpisah agar nama tetap satu widget tersendiri.
              Row(
                children: [
                  Text(
                    'Halo, ',
                    style: TextStyle(
                      fontSize: compact ? 18 : 20,
                      height: 1.2,
                      letterSpacing: -.3,
                      fontWeight: FontWeight.w500,
                      color: SkinTokens.ink,
                    ),
                  ),
                  Flexible(
                    child: Text(
                      profile.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: compact ? 18 : 20,
                        height: 1.2,
                        letterSpacing: -.3,
                        fontWeight: FontWeight.w800,
                        color: SkinTokens.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        AnimatedBuilder(
          animation: Listenable.merge([
            SkinJourneyStore.instance,
            SkinNotificationCenter.instance,
          ]),
          builder: (context, _) {
            final notifications =
                SkinNotificationFeed.build(SkinJourneyStore.instance);
            final hasUnread = notifications.any(
              (item) => !SkinNotificationCenter.instance.isRead(item.id),
            );
            return Semantics(
              button: true,
              label: hasUnread
                  ? 'Buka notifikasi, ada yang belum dibaca'
                  : 'Buka notifikasi',
              child: SkinCircleButton(
                key: const Key('open-notifications'),
                icon: hasUnread
                    ? Icons.notifications_active_outlined
                    : Icons.notifications_none_rounded,
                badge: hasUnread,
                badgeKey: const Key('home-notification-unread-dot'),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const SkinNotificationsPage(),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(width: 8),
        SkinGridMenuButton(
          key: const Key('open-settings'),
          tooltip: 'Pengaturan tampilan',
          onPressed: () => Navigator.of(context).pushNamed('/settings'),
        ),
      ],
    );
  }
}

// ───────────────────────── Primary Scan Action Hero ─────────────────────────

class _ScanHeroCard extends StatelessWidget {
  const _ScanHeroCard({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final thumbWidth = compact ? 84.0 : 96.0;
    final thumbHeight = compact ? 102.0 : 116.0;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: SkinTokens.deepGradient,
        borderRadius: BorderRadius.circular(26),
        boxShadow: SkinTokens.glow(AppColors.forestDeep, opacity: .22),
      ),
      child: Padding(
        padding: EdgeInsets.all(compact ? 16 : 18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cek kondisi kulitmu hari ini',
                    style: TextStyle(
                      fontSize: compact ? 17.5 : 19.5,
                      height: 1.2,
                      letterSpacing: -.3,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Deteksi jerawat, noda gelap & kemerahan dalam hitungan detik.',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.4,
                      color: Color(0xFFD4E8E0),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Material(
                    color: Colors.white,
                    shape: const StadiumBorder(),
                    child: InkWell(
                      key: const Key('open-skin-journey'),
                      customBorder: const StadiumBorder(),
                      onTap: () => _startScan(context),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: compact ? 14 : 16,
                          vertical: 10,
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.center_focus_weak_rounded,
                              size: 16,
                              color: AppColors.forestDeep,
                            ),
                            SizedBox(width: 7),
                            Flexible(
                              child: Text(
                                'Mulai Scan',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.forestDeep,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              key: const Key('home-skin-girl'),
              width: thumbWidth,
              height: thumbHeight,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withValues(alpha: .28),
                  width: 1.5,
                ),
              ),
              child: const Stack(
                fit: StackFit.expand,
                children: [
                  SkinPortrait(
                    asset: AppAssets.scanPortrait,
                    alignment: Alignment(.2, -.2),
                    semanticLabel: 'Ilustrasi pemindaian wajah',
                    profile: true,
                  ),
                  SkinScanMesh(region: Rect.fromLTWH(.28, .35, .46, .52)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Banner jatuh tempo check-in: hanya muncul saat waktunya check-in mingguan.
class _HomeCheckinShortcut extends StatelessWidget {
  const _HomeCheckinShortcut();

  @override
  Widget build(BuildContext context) {
    final store = SkinJourneyStore.instance;
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final dueDate = store.activeDueDate;
        final status = store.checkinPromptStatus;
        if (dueDate == null || status == null) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: const EdgeInsets.only(top: 14),
          child: SkinCheckinShortcut(
            key: const Key('home-checkin-shortcut'),
            buttonKey: const Key('home-start-checkin'),
            week: store.currentWeek,
            dueDate: dueDate,
            status: status,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const SkinCheckinPage(),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ───────────────────── Unified Skin Journey + 7-Day Cadence ─────────────────────

/// Menggabungkan ringkasan Laporan Kulit, jadwal Check-in, dan Skin Journey
/// dalam satu panel bersih dengan strip kalender 7 hari berbasis data nyata.
class _SkinJourneyOverviewCard extends StatelessWidget {
  const _SkinJourneyOverviewCard({required this.compact});

  final bool compact;

  static String _ago(DateTime date, DateTime today) {
    final days = SkinJourneyStore.day(today)
        .difference(SkinJourneyStore.day(date))
        .inDays;
    if (days <= 0) return 'Hari ini';
    if (days == 1) return 'Kemarin';
    if (days < 7) return '$days hari lalu';
    return SkinFormat.dayMonth(date);
  }

  @override
  Widget build(BuildContext context) {
    final store = SkinJourneyStore.instance;
    final history = SkinHistoryRepository.instance;

    return AnimatedBuilder(
      animation: Listenable.merge([store, history]),
      builder: (context, _) {
        final hasBaseline = store.hasBaseline;
        final due = store.hasCheckinDue;
        final next = store.nextCheckin;

        // Kumpulkan tanggal aktivitas nyata lintas scan & check-in untuk
        // strip ritme mingguan dan waktu scan terakhir.
        final activeDays = <DateTime>{};
        DateTime? lastActivity;

        void recordDate(DateTime d) {
          activeDays.add(SkinJourneyStore.day(d));
          if (lastActivity == null || d.isAfter(lastActivity!)) {
            lastActivity = d;
          }
        }

        for (final photo in store.photos) {
          recordDate(photo.date);
        }
        for (final rec in history.records) {
          recordDate(rec.analyzedAt);
        }
        for (final checkin in store.allCheckins) {
          recordDate(checkin.date);
        }

        final totalScans = store.photos.length > history.records.length
            ? store.photos.length
            : history.records.length;
        final subtitle = hasBaseline
            ? '$totalScans foto · ${store.checkins.length} check-in tersimpan'
            : 'Scan pertama membuka grafik tren mingguan';

        return SkinCard(
          inkKey: const Key('home-open-skin-journey'),
          onTap: () => _openJourneys(context),
          color: Colors.white,
          borderColor: SkinTokens.border,
          padding: EdgeInsets.all(compact ? 14 : 16),
          radius: 24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    key: const Key('home-journey-cat'),
                    width: 46,
                    height: 46,
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: AppColors.mintTint,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Skin3D(AppAssets.journey3d, size: 36),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Flexible(
                              child: Text(
                                'Skin Journey',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 16,
                                  height: 1.25,
                                  fontWeight: FontWeight.w800,
                                  color: SkinTokens.ink,
                                ),
                              ),
                            ),
                            if (hasBaseline) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.mintTint,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  'Mgg ${store.currentWeek}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: SkinTokens.primary,
                                    fontFeatures: [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            height: 1.35,
                            color: SkinTokens.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: AppColors.surfaceTint,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: SkinTokens.ink,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _WeeklyCadenceStrip(
                today: SkinJourneyStore.day(store.today),
                activeDays: activeDays,
                compact: compact,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.mistBottom,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: SkinTokens.border.withValues(alpha: .75),
                  ),
                ),
                child: IntrinsicHeight(
                  child: Row(
                    children: [
                      Expanded(
                        child: _JourneyMetricCell(
                          label: 'Scan terakhir',
                          value: lastActivity == null
                              ? 'Belum ada'
                              : _ago(lastActivity!, store.today),
                        ),
                      ),
                      const VerticalDivider(
                        width: 20,
                        thickness: 1,
                        color: SkinTokens.border,
                      ),
                      Expanded(
                        child: _JourneyMetricCell(
                          label: 'Check-in berikutnya',
                          value: !hasBaseline
                              ? 'Setelah scan awal'
                              : due
                                  ? 'Tersedia hari ini'
                                  : next != null
                                      ? SkinFormat.dayMonth(next)
                                      : 'Terjadwal',
                          highlight: due,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _WeeklyCadenceStrip extends StatelessWidget {
  const _WeeklyCadenceStrip({
    required this.today,
    required this.activeDays,
    required this.compact,
  });

  final DateTime today;
  final Set<DateTime> activeDays;
  final bool compact;

  static const _labels = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

  @override
  Widget build(BuildContext context) {
    final monday = today.subtract(Duration(days: today.weekday - 1));
    final dotSize = compact ? 28.0 : 32.0;

    return Row(
      children: List.generate(7, (index) {
        final dayDate = monday.add(Duration(days: index));
        final isToday = SkinJourneyStore.sameDay(dayDate, today);
        final hasRecord = activeDays.contains(dayDate);

        return Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _labels[index],
                maxLines: 1,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
                  color: isToday ? SkinTokens.primary : SkinTokens.muted,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: dotSize,
                height: dotSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: hasRecord
                      ? SkinTokens.primary
                      : isToday
                          ? AppColors.mintTint
                          : AppColors.surfaceTint,
                  border: isToday && !hasRecord
                      ? Border.all(color: SkinTokens.primary, width: 1.6)
                      : null,
                ),
                alignment: Alignment.center,
                child: hasRecord
                    ? const Icon(
                        Icons.check_rounded,
                        size: 15,
                        color: Colors.white,
                      )
                    : Text(
                        '${dayDate.day}',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight:
                              isToday ? FontWeight.w800 : FontWeight.w600,
                          color:
                              isToday ? SkinTokens.primary : SkinTokens.muted,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _JourneyMetricCell extends StatelessWidget {
  const _JourneyMetricCell({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: SkinTokens.muted,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: highlight ? SkinTokens.primary : SkinTokens.ink,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

// ───────────────────────── Aktivitas Terbaru ─────────────────────────

class _RecentActivitySection extends StatelessWidget {
  const _RecentActivitySection();

  @override
  Widget build(BuildContext context) {
    final store = SkinJourneyStore.instance;
    final history = SkinHistoryRepository.instance;
    final cloud = CloudSync.instance;
    return AnimatedBuilder(
      animation: Listenable.merge([store, history, cloud]),
      builder: (context, _) {
        final activities = _latestActivities(store, history);
        final isLoading = activities.isEmpty &&
            (cloud.isSyncing || history.isSyncing || store.isSyncing);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkinSectionTitle(
              title: 'Aktivitas Terbaru',
              subtitle: 'Hasil scan dan check-in terakhirmu',
              trailing: TextButton(
                key: const Key('home-see-all-history'),
                onPressed: () => _openHistory(context),
                style: TextButton.styleFrom(
                  foregroundColor: SkinTokens.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(44, 40),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Lihat semua',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: SkinTokens.primary,
                      ),
                    ),
                    SizedBox(width: 2),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: SkinTokens.primary,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (isLoading)
              const _LoadingActivity()
            else if (activities.isEmpty)
              const _EmptyActivity()
            else
              SizedBox(
                height: 148,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final cardWidth =
                        (constraints.maxWidth * .78).clamp(216.0, 286.0);
                    return ListView.separated(
                      key: const Key('recent-activity-list'),
                      scrollDirection: Axis.horizontal,
                      clipBehavior: Clip.none,
                      physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics(),
                      ),
                      itemCount: activities.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) => KeyedSubtree(
                        key:
                            ValueKey('recent-activity-${activities[index].id}'),
                        child: SizedBox(
                          width: cardWidth,
                          child: _ActivityCard(activity: activities[index]),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  List<_RecentActivity> _latestActivities(
    SkinJourneyStore store,
    SkinHistoryRepository history,
  ) {
    final activities = <_RecentActivity>[];
    final photosInCheckins =
        store.allCheckins.expand((checkin) => checkin.photoIds).toSet();

    for (final checkin in store.allCheckins) {
      final conditions =
          checkin.perClass.keys.map(_localizeCondition).toList();
      final conditionLabel = conditions.isEmpty
          ? 'Laporan rutin kulitmu berhasil disimpan.'
          : '${conditions.take(2).join(' & ')}${conditions.length > 2 ? ' +${conditions.length - 2}' : ''} diperbarui.';
      activities.add(_RecentActivity(
        id: 'checkin-${checkin.id ?? checkin.date.microsecondsSinceEpoch}',
        date: checkin.date,
        title: 'Check-in selesai',
        description: conditionLabel,
        icon: Icons.task_alt_rounded,
        tone: SkinTone.success,
      ));
    }

    final scanTimes = <DateTime>[];
    for (final record in history.records) {
      scanTimes.add(record.analyzedAt);
      final findings =
          record.visualFindings.map(_localizeCondition).toList();
      final description = findings.isNotEmpty
          ? '${findings.take(2).join(' & ')}${findings.length > 2 ? ' +${findings.length - 2}' : ''} tercatat dari hasil analisismu.'
          : record.skinType.isNotEmpty
              ? 'Tipe kulit ${record.skinType} tercatat di riwayatmu.'
              : 'Hasil analisis kulit tersimpan di riwayatmu.';
      activities.add(_RecentActivity(
        id: record.id,
        date: record.analyzedAt,
        title: 'Hasil scan tersimpan',
        description: description,
        icon: Icons.center_focus_strong_rounded,
        tone: SkinTone.peach,
        onTap: (ctx) => Navigator.of(ctx).push(MaterialPageRoute<void>(
          builder: (_) => SkinResultPage(analysis: record, archived: true),
        )),
      ));
    }

    JourneyPhoto? oldestPhoto;
    for (final photo in store.photos) {
      if (oldestPhoto == null || photo.date.isBefore(oldestPhoto.date)) {
        oldestPhoto = photo;
      }
    }

    for (final photo in store.photos) {
      if (photosInCheckins.contains(photo.id)) continue;
      final alreadyInScans = scanTimes.any(
        (t) => t.difference(photo.date).inSeconds.abs() <= 5,
      );
      if (alreadyInScans) continue;
      final isFirstScan = oldestPhoto?.id == photo.id &&
          store.baselineDate != null &&
          SkinJourneyStore.sameDay(photo.date, store.baselineDate!);
      final findings = photo.visualFindings.map(_localizeCondition).toList();
      final description = findings.isNotEmpty
          ? '${findings.take(2).join(' & ')}${findings.length > 2 ? ' +${findings.length - 2}' : ''} tercatat dari hasil analisismu.'
          : photo.skinType != null
              ? 'Tipe kulit ${photo.skinType} tercatat di perjalananmu.'
              : 'Hasil analisis kulit tersimpan di perjalananmu.';
      activities.add(_RecentActivity(
        id: photo.id,
        date: photo.date,
        title: isFirstScan ? 'Scan awal tersimpan' : 'Hasil scan tersimpan',
        description: description,
        icon: Icons.center_focus_strong_rounded,
        tone: SkinTone.peach,
      ));
    }

    activities.sort((a, b) => b.date.compareTo(a.date));
    return activities.take(3).toList(growable: false);
  }
}

class _LoadingActivity extends StatelessWidget {
  const _LoadingActivity();

  @override
  Widget build(BuildContext context) {
    return const SkinCard(
      key: Key('recent-activity-loading'),
      color: Colors.white,
      borderColor: SkinTokens.border,
      padding: EdgeInsets.all(14),
      radius: 22,
      child: ShimmerLoading(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SkeletonBox(
                  width: 36,
                  height: 36,
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                SkeletonBox(
                  width: 92,
                  height: 22,
                  borderRadius: BorderRadius.all(Radius.circular(999)),
                ),
              ],
            ),
            SizedBox(height: 12),
            SkeletonBox(width: 170, height: 15),
            SizedBox(height: 8),
            SkeletonBox(width: double.infinity, height: 12),
          ],
        ),
      ),
    );
  }
}

class _EmptyActivity extends StatelessWidget {
  const _EmptyActivity();

  @override
  Widget build(BuildContext context) {
    return SkinCard(
      key: const Key('recent-activity-empty'),
      color: Colors.white,
      borderColor: SkinTokens.border,
      padding: const EdgeInsets.all(14),
      radius: 22,
      onTap: () => _startScan(context),
      child: const Row(
        children: [
          SkinIconTile(
            icon: Icons.history_rounded,
            tone: SkinTone.success,
            size: 42,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Belum ada riwayat scan',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: SkinTokens.ink,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Hasil scan wajah dan check-in terbarumu akan tercatat otomatis di sini.',
                  style: TextStyle(
                    color: SkinTokens.muted,
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.activity});

  final _RecentActivity activity;

  @override
  Widget build(BuildContext context) {
    return SkinCard(
      key: const Key('recent-activity-card'),
      color: Colors.white,
      borderColor: SkinTokens.border,
      onTap: activity.onTap == null ? null : () => activity.onTap!(context),
      padding: const EdgeInsets.all(14),
      radius: 22,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SkinIconTile(icon: activity.icon, tone: activity.tone, size: 36),
              const SizedBox(width: 10),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceTint,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      _activityDate(
                        activity.date,
                        SkinJourneyStore.instance.today,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: SkinTokens.muted,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            activity.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: SkinTokens.ink,
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            activity.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: SkinTokens.muted,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  String _activityDate(DateTime date, DateTime today) {
    final eventDay = DateTime(date.year, date.month, date.day);
    final currentDay = DateTime(today.year, today.month, today.day);
    final difference = currentDay.difference(eventDay).inDays;
    final time = SkinFormat.time(date);
    if (difference == 0) return 'Hari ini · $time';
    if (difference == 1) return 'Kemarin · $time';
    return SkinFormat.shortDate(date);
  }
}

class _RecentActivity {
  const _RecentActivity({
    required this.id,
    required this.date,
    required this.title,
    required this.description,
    required this.icon,
    required this.tone,
    this.onTap,
  });

  final String id;
  final DateTime date;
  final String title;
  final String description;
  final IconData icon;
  final SkinTone tone;
  final void Function(BuildContext context)? onTap;
}

// ───────────────────────── Panduan Harian ─────────────────────────

class _DailyTipCard extends StatelessWidget {
  const _DailyTipCard({required this.onOpen});

  final VoidCallback onOpen;

  static const _tips = <(String, String, IconData)>[
    (
      'Pakai sunscreen setiap pagi',
      'Perlindungan UV membantu mencegah noda gelap tampak makin pekat.',
      Icons.wb_sunny_outlined,
    ),
    (
      'Foto di cahaya yang sama',
      'Pencahayaan konsisten membuat perbandingan antar check-in lebih akurat.',
      Icons.light_mode_outlined,
    ),
    (
      'Satu produk baru dalam satu waktu',
      'Perubahan bertahap memudahkanmu mengenali pemicu iritasi kulit.',
      Icons.science_outlined,
    ),
    (
      'Hindari memencet jerawat',
      'Memencet lesi dapat menambah risiko peradangan dan bekas noda gelap.',
      Icons.back_hand_outlined,
    ),
    (
      'Bersihkan wajah dengan lembut',
      'Pembersih ringan tanpa rasa tertarik membantu menjaga skin barrier.',
      Icons.water_drop_outlined,
    ),
    (
      'Catat keluhan yang kamu rasakan',
      'Rasa perih atau gatal sama pentingnya dengan temuan visual di foto.',
      Icons.edit_note_rounded,
    ),
    (
      'Konsisten lebih penting',
      'Rutinitas sederhana lebih mudah dipertahankan dalam jangka panjang.',
      Icons.repeat_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final tip = _tips[DateTime.now().weekday % _tips.length];
    return SkinCard(
      inkKey: const Key('home-daily-tip'),
      onTap: onOpen,
      color: Colors.white,
      borderColor: SkinTokens.border,
      padding: const EdgeInsets.all(16),
      radius: 22,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.surfaceTint,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Skin3D(AppAssets.serum3d, size: 44),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tip.$1,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.3,
                    fontWeight: FontWeight.w700,
                    color: SkinTokens.ink,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  tip.$2,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    height: 1.4,
                    color: SkinTokens.muted,
                  ),
                ),
                const SizedBox(height: 8),
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        'Baca edukasi lainnya',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: SkinTokens.primary,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    SizedBox(width: 2),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
                      color: SkinTokens.primary,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
