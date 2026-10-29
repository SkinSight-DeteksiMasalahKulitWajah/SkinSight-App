import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../widgets/asset_images.dart';
import '../core/app_assets.dart';
import '../data/skin_journey_store.dart';
import '../data/skin_notification_center.dart';
import '../models/profile_data.dart';
import '../theme/skin_theme.dart';
import '../widgets/skin_bottom_nav.dart';
import '../widgets/skin_checkin_shortcut.dart';
import '../widgets/skin_page_background.dart';
import '../widgets/skin_3d.dart';
import '../widgets/skin_ui.dart';
import 'skin_checkin_page.dart';
import 'skin_education_page.dart';
import 'skin_journeys_page.dart';
import 'skin_notifications_page.dart';
import 'skin_profile_page.dart';
import 'skin_quiz_page.dart';
import 'skin_scan_page.dart';

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

  /// Tab tersembunyi tetap hidup, tapi animasinya dibekukan: tanpa ini,
  /// animasi di tab yang tak terlihat terus meminta frame baru untuk seluruh
  /// layar.
  Widget _tab(int index, Widget child) =>
      TickerMode(enabled: index == _currentIndex, child: child);

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: SkinTokens.background,
        // Bilah navigasi melayang di atas konten yang tergulir di belakangnya.
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
  Navigator.of(context).push(MaterialPageRoute<void>(
    builder: (_) => SkinJourneyStore.instance.questionnaireDone
        ? const SkinScanPage()
        : const SkinQuizPage(),
  ));
}

void _openJourneys(BuildContext context) {
  Navigator.of(context).push(MaterialPageRoute<void>(
    settings: const RouteSettings(name: '/journeys'),
    builder: (_) => const SkinJourneysPage(),
  ));
}

class _HomeScrollView extends StatelessWidget {
  const _HomeScrollView({super.key, required this.onOpenEducation});

  final VoidCallback onOpenEducation;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final compact = constraints.maxWidth < 350;
      final horizontal = compact ? 16.0 : SkinTokens.pageInset;
      Widget section(Widget child, {double top = 16, int order = 0}) => Padding(
            padding: EdgeInsets.only(top: top),
            child: SkinReveal.staggered(index: order, child: child),
          );

      return CustomScrollView(
        physics: const ClampingScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              horizontal,
              0,
              horizontal,
              SkinBottomNav.overlap + 16,
            ),
            sliver: SliverToBoxAdapter(
              // Saat digulir cukup lapisan ini yang digeser; isinya tidak
              // dilukis ulang setiap frame.
              child: RepaintBoundary(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    section(_Header(compact: compact), top: 12),
                    section(const _HealthReportCard(), top: 20, order: 1),
                    section(const _RoutineRow(), order: 2),
                    section(const _HomeCheckinShortcut(), top: 0, order: 2),
                    section(_ScanCard(compact: compact), order: 3),
                    section(const _SkinJourneyCard(), top: 26, order: 4),
                    section(const _RecentActivitySection(), top: 28, order: 5),
                    section(_DailyTipCard(onOpen: onOpenEducation),
                        top: 24, order: 6),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    });
  }
}

// ───────────────────────── Header ─────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileData>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
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
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: SkinTokens.aqua,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: SkinTokens.shadows,
                    ),
                    child: profile.photoBytes == null
                        ? Image.asset(
                            AppAssets.avatar3d,
                            key: const Key('home-default-avatar'),
                            fit: BoxFit.cover,
                            alignment: const Alignment(0, .6),
                            cacheWidth: 160,
                            filterQuality: FilterQuality.medium,
                            errorBuilder: assetErrorBuilder,
                          )
                        : Image.memory(
                            profile.photoBytes!,
                            key: const Key('home-profile-photo'),
                            fit: BoxFit.cover,
                            cacheWidth: thumbnailCacheWidth(context, 44),
                            gaplessPlayback: true,
                          ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: SkinPill(
                  label: SkinFormat.greeting(DateTime.now()),
                  icon: Icons.wb_twilight_rounded,
                ),
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
        ),
        const SizedBox(height: 22),
        // Dua Text terpisah agar nama tetap satu widget tersendiri.
        DefaultTextStyle.merge(
          style: TextStyle(
            fontSize: compact ? 27 : 32,
            height: 1.15,
            letterSpacing: -.5,
            color: SkinTokens.ink,
          ),
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.end,
            children: [
              const Text('Halo '),
              Text(
                profile.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Pendamping kulitmu mulai di sini!',
          style: TextStyle(fontSize: 14, color: SkinTokens.muted),
        ),
      ],
    );
  }
}

// ───────────────────────── Laporan kulit ─────────────────────────

/// Ringkasan nyata dari Skin Journey: minggu berjalan, progres menuju
/// check-in berikutnya, dan waktu scan terakhir. Tidak ada skor kesehatan
/// karangan — SkinSight tidak mendiagnosis.
class _HealthReportCard extends StatelessWidget {
  const _HealthReportCard();

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
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final hasBaseline = store.hasBaseline;
        DateTime? lastScan;
        for (final photo in store.photos) {
          if (lastScan == null || photo.date.isAfter(lastScan)) {
            lastScan = photo.date;
          }
        }
        final daysIn = hasBaseline
            ? SkinJourneyStore.day(store.today)
                    .difference(SkinJourneyStore.day(store.baselineDate))
                    .inDays %
                7
            : 0;
        final progress = hasBaseline ? (daysIn + 1) / 7 : 0.0;

        return SkinCard(
          inkKey: const Key('home-health-report'),
          onTap: () => _openJourneys(context),
          padding: const EdgeInsets.fromLTRB(20, 18, 14, 14),
          radius: 30,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Laporan Kulit', style: SkinTokens.cardTitle),
                        SizedBox(height: 2),
                        Text(
                          'Ringkasan perjalanan kulitmu',
                          style: TextStyle(
                            fontSize: 12,
                            color: SkinTokens.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: SkinRing(
                      value: progress,
                      size: 52,
                      stroke: 5,
                      child: const SkinIconTile(
                        icon: Icons.spa_outlined,
                        size: 32,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: SkinStatCapsule(
                      dark: true,
                      label: 'Skin Journey',
                      value: hasBaseline
                          ? 'Minggu ke-${store.currentWeek}'
                          : 'Belum mulai',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SkinStatCapsule(
                      label: 'Scan terakhir',
                      value: lastScan == null
                          ? 'Belum ada'
                          : _ago(lastScan, store.today),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// ───────────────────────── Rutinitas ─────────────────────────

class _RoutineRow extends StatelessWidget {
  const _RoutineRow();

  @override
  Widget build(BuildContext context) {
    final store = SkinJourneyStore.instance;
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        // Saat check-in jatuh tempo, kartu check-in lengkap yang tampil.
        if (store.activeDueDate != null) return const SizedBox.shrink();
        final hasBaseline = store.hasBaseline;
        final next = store.nextCheckin;
        final date = hasBaseline && next != null ? next : store.today;
        final isToday = SkinJourneyStore.sameDay(date, store.today);
        return SkinCard(
          inkKey: const Key('home-daily-routine'),
          onTap: () =>
              hasBaseline ? _openJourneys(context) : _startScan(context),
          radius: 999,
          padding: const EdgeInsets.fromLTRB(10, 10, 18, 10),
          child: Row(
            children: [
              const SkinIconTile(icon: Icons.schedule_rounded, size: 44),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      SkinFormat.dayMonth(date),
                      style: const TextStyle(
                        fontSize: 12,
                        color: SkinTokens.muted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasBaseline ? 'Check-in mingguan' : 'Scan awal kulit',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: SkinTokens.ink,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                isToday ? 'Hari ini' : 'Terjadwal',
                style: const TextStyle(fontSize: 12.5, color: SkinTokens.muted),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.play_arrow_rounded,
                  size: 18, color: SkinTokens.ink),
            ],
          ),
        );
      },
    );
  }
}

/// Satu akses pemantauan di Home. Tidak ada kartu check-in / aktivitas ganda.
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
          padding: const EdgeInsets.only(top: 16),
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

// ───────────────────────── Scan ─────────────────────────

class _ScanCard extends StatelessWidget {
  const _ScanCard({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final thumb = compact ? 92.0 : 108.0;
    return SkinCard(
      padding: const EdgeInsets.all(10),
      radius: 30,
      child: Row(
        children: [
          Container(
            key: const Key('home-skin-girl'),
            width: thumb,
            height: thumb * 1.18,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white, width: 1.5),
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
                SkinScanMesh(region: Rect.fromLTWH(.3, .38, .44, .5)),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkinPill(
                  label: 'Analisis AI',
                  icon: Icons.auto_awesome_rounded,
                  dense: true,
                ),
                const SizedBox(height: 8),
                Text(
                  'Cek kondisi kulitmu hari ini',
                  style: TextStyle(
                    fontFamily: SkinTokens.serif,
                    fontSize: compact ? 21 : 24,
                    height: 1.08,
                    fontWeight: FontWeight.w500,
                    color: SkinTokens.ink,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Kuis singkat + foto wajah untuk ringkasan temuan visual.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: SkinTokens.muted,
                  ),
                ),
                const SizedBox(height: 10),
                Material(
                  color: SkinTokens.primary,
                  shape: const StadiumBorder(),
                  child: InkWell(
                    key: const Key('open-skin-journey'),
                    customBorder: const StadiumBorder(),
                    onTap: () => _startScan(context),
                    child: const Padding(
                      padding: EdgeInsets.fromLTRB(16, 8, 8, 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              'Mulai Scan',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: Color(0x33FFFFFF),
                            child: Icon(
                              Icons.center_focus_weak_rounded,
                              size: 14,
                              color: Colors.white,
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
        ],
      ),
    );
  }
}

// ───────────────────────── Skin Journey ─────────────────────────

class _SkinJourneyCard extends StatelessWidget {
  const _SkinJourneyCard();

  @override
  Widget build(BuildContext context) {
    final store = SkinJourneyStore.instance;
    return AnimatedBuilder(
        animation: store,
        builder: (context, _) {
          final due = store.hasCheckinDue;
          final hasBaseline = store.hasBaseline;
          final next = store.nextCheckin;
          final nextLabel = next == null ? '' : SkinFormat.shortDate(next);
          final statusText = !hasBaseline
              ? 'Scan awal untuk membuka grafik dan timeline'
              : due
                  ? 'Check-in minggu ini sudah tersedia'
                  : 'Check-in berikutnya: $nextLabel';
          return SkinCard(
            inkKey: const Key('home-open-skin-journey'),
            padding: const EdgeInsets.all(16),
            radius: 30,
            onTap: () => _openJourneys(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      key: const Key('home-journey-cat'),
                      width: 60,
                      height: 60,
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: SkinTokens.aqua.withValues(alpha: .55),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: const Skin3D(AppAssets.journey3d, size: 46),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              const Text(
                                'Skin Journey',
                                style: TextStyle(
                                  fontFamily: SkinTokens.serif,
                                  fontSize: 24,
                                  height: 1.1,
                                  fontWeight: FontWeight.w500,
                                  color: SkinTokens.ink,
                                ),
                              ),
                              if (hasBaseline)
                                SkinPill(
                                  label: 'Minggu ke-${store.currentWeek}',
                                  dense: true,
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            hasBaseline
                                ? 'Lihat perjalanan dan riwayat kulitmu'
                                : 'Mulai catat perjalanan kulitmu',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: SkinTokens.caption,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: SkinTokens.ink,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(8, 8, 14, 8),
                  decoration: BoxDecoration(
                    color: due ? SkinTokens.primary : Colors.white,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: due
                            ? Colors.white.withValues(alpha: .16)
                            : SkinTokens.aqua,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        due
                            ? Icons.notifications_active_outlined
                            : hasBaseline
                                ? Icons.event_available_outlined
                                : Icons.lock_open_rounded,
                        size: 16,
                        color: due ? Colors.white : SkinTokens.ink,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        statusText,
                        style: TextStyle(
                          color: due ? Colors.white : SkinTokens.ink,
                          fontSize: 12.5,
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (due)
                      const Text(
                        'Mulai',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                  ]),
                ),
                if (hasBaseline) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _MiniStat(
                        icon: Icons.photo_library_outlined,
                        label: '${store.photos.length} foto tersimpan',
                      ),
                      const SizedBox(width: 8),
                      _MiniStat(
                        icon: Icons.task_alt_rounded,
                        label: '${store.checkins.length} check-in',
                      ),
                    ],
                  ),
                ],
              ],
            ),
          );
        });
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: SkinTokens.aquaDeep),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: SkinTokens.muted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── Aktivitas ─────────────────────────

class _RecentActivitySection extends StatelessWidget {
  const _RecentActivitySection();

  @override
  Widget build(BuildContext context) {
    final store = SkinJourneyStore.instance;
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final activities = _latestActivities(store);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SkinSectionTitle(
              title: 'Aktivitas Terbaru',
              subtitle: 'Hasil scan dan check-in terakhirmu',
            ),
            const SizedBox(height: 12),
            if (activities.isEmpty)
              const _EmptyActivity()
            else
              SizedBox(
                height: 156,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final cardWidth =
                        (constraints.maxWidth * .76).clamp(220.0, 290.0);
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

  List<_RecentActivity> _latestActivities(SkinJourneyStore store) {
    final activities = <_RecentActivity>[];
    final photosInCheckins =
        store.checkins.expand((checkin) => checkin.photoIds).toSet();

    for (final checkin in store.checkins) {
      final conditions = checkin.perClass.keys.toList();
      final conditionLabel = conditions.isEmpty
          ? 'Laporan rutin kulitmu berhasil disimpan.'
          : '${conditions.take(2).join(' & ')}${conditions.length > 2 ? ' +${conditions.length - 2}' : ''} diperbarui.';
      activities.add(_RecentActivity(
        id: 'checkin-${checkin.date.microsecondsSinceEpoch}',
        date: checkin.date,
        title: 'Check-in selesai',
        description: conditionLabel,
        icon: Icons.task_alt_rounded,
        tone: SkinTone.primary,
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
      final isFirstScan = oldestPhoto?.id == photo.id &&
          store.baselineDate != null &&
          SkinJourneyStore.sameDay(photo.date, store.baselineDate!);
      final findings = photo.visualFindings;
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

class _EmptyActivity extends StatelessWidget {
  const _EmptyActivity();

  @override
  Widget build(BuildContext context) {
    return const SkinCard(
      key: Key('recent-activity-empty'),
      padding: EdgeInsets.all(14),
      child: Row(
        children: [
          SkinIconTile(icon: Icons.history_rounded, tone: SkinTone.neutral),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Hasil scan dan check-in terbarumu akan muncul di sini.',
              style: TextStyle(
                color: SkinTokens.muted,
                fontSize: 13,
                height: 1.45,
              ),
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
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SkinIconTile(icon: activity.icon, tone: activity.tone, size: 38),
              const SizedBox(width: 10),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: SkinPill(
                    dense: true,
                    tone: SkinTone.neutral,
                    label: _activityDate(
                      activity.date,
                      SkinJourneyStore.instance.today,
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
  });

  final String id;
  final DateTime date;
  final String title;
  final String description;
  final IconData icon;
  final SkinTone tone;
}

// ───────────────────────── Tips harian ─────────────────────────

class _DailyTipCard extends StatelessWidget {
  const _DailyTipCard({required this.onOpen});

  final VoidCallback onOpen;

  static const _tips = <(String, String, IconData)>[
    (
      'Pakai sunscreen setiap pagi',
      'Perlindungan UV membantu mencegah noda tampak makin gelap.',
      Icons.wb_sunny_outlined,
    ),
    (
      'Foto di cahaya yang sama',
      'Cahaya serupa membuat perbandingan antar check-in lebih bermakna.',
      Icons.light_mode_outlined,
    ),
    (
      'Satu produk baru dalam satu waktu',
      'Perubahan bertahap memudahkanmu mengenali pemicu iritasi.',
      Icons.science_outlined,
    ),
    (
      'Hindari memencet jerawat',
      'Memencet lesi dapat menambah risiko iritasi dan bekas.',
      Icons.back_hand_outlined,
    ),
    (
      'Bersihkan wajah dengan lembut',
      'Pembersih yang nyaman membantu menjaga skin barrier.',
      Icons.water_drop_outlined,
    ),
    (
      'Catat keluhan yang kamu rasakan',
      'Perih atau gatal sama pentingnya dengan yang terlihat di foto.',
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
      padding: const EdgeInsets.all(18),
      radius: 30,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Aksen 3D: botol serum di atas podium (ikon tip tetap ada di
          // pojok sebagai penanda jenis tips).
          SizedBox(
            width: 62,
            height: 62,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const Positioned.fill(child: Skin3D(AppAssets.serum3d)),
                Positioned(
                  right: -4,
                  bottom: -2,
                  child: SkinIconTile(icon: tip.$3, size: 26, iconSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('TIPS HARI INI', style: SkinTokens.eyebrow),
                const SizedBox(height: 5),
                Text(tip.$1, style: SkinTokens.cardTitle),
                const SizedBox(height: 4),
                Text(tip.$2, style: SkinTokens.caption),
                const SizedBox(height: 10),
                const Row(
                  children: [
                    Flexible(
                      child: Text(
                        'Baca edukasi lainnya',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: SkinTokens.ink,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.play_arrow_rounded,
                        size: 16, color: SkinTokens.ink),
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
