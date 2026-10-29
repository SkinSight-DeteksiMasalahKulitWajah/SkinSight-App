import 'package:flutter/material.dart';

import '../core/app_assets.dart';
import '../data/skin_journey_store.dart';
import '../data/skin_notification_center.dart';
import '../theme/skin_theme.dart';
import '../widgets/skin_page_background.dart';
import '../widgets/skin_page_header.dart';
import '../widgets/skin_ui.dart';
import 'skin_progress_page.dart';
import 'skin_scan_page.dart';

class SkinNotificationsPage extends StatelessWidget {
  const SkinNotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = SkinJourneyStore.instance;
    final center = SkinNotificationCenter.instance;
    return Scaffold(
      backgroundColor: SkinTokens.background,
      body: SkinPageBackground(
          child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: SkinTokens.maxWidth),
            child: AnimatedBuilder(
              animation: Listenable.merge([store, center]),
              builder: (context, _) {
                final notifications = SkinNotificationFeed.build(store);
                final unread = notifications
                    .where((item) => !center.isRead(item.id))
                    .length;
                final today = notifications
                    .where((item) =>
                        SkinJourneyStore.sameDay(item.date, store.today))
                    .toList();
                final previous = notifications
                    .where((item) =>
                        !SkinJourneyStore.sameDay(item.date, store.today))
                    .toList();

                return Column(
                  children: [
                    SkinPageHeader(
                      title: 'Notifikasi',
                      subtitle: unread == 0
                          ? 'Semua sudah dibaca'
                          : '$unread belum dibaca',
                      backKey: const Key('notifications-back'),
                      trailing: unread == 0
                          ? const SkinIconTile(
                              icon: Icons.done_all_rounded,
                              size: 40,
                            )
                          : TextButton(
                              key: const Key('mark-all-notifications-read'),
                              onPressed: () =>
                                  center.markAllRead(notifications),
                              style: TextButton.styleFrom(
                                backgroundColor: SkinTokens.mint,
                                foregroundColor: SkinTokens.primaryDark,
                                minimumSize: const Size(0, 40),
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 14),
                                shape: const StadiumBorder(),
                                textStyle: Theme.of(context)
                                    .textTheme
                                    .labelLarge!
                                    .copyWith(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                              child: const Text('Tandai dibaca'),
                            ),
                    ),
                    Expanded(
                      child: notifications.isEmpty
                          ? const _EmptyNotifications()
                          : ListView(
                              key: const Key('notifications-list'),
                              physics: const ClampingScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                              children: [
                                if (today.isNotEmpty)
                                  _NotificationGroup(
                                    title: 'Hari ini',
                                    items: today,
                                    center: center,
                                  ),
                                if (today.isNotEmpty && previous.isNotEmpty)
                                  const SizedBox(height: 22),
                                if (previous.isNotEmpty)
                                  _NotificationGroup(
                                    title: 'Sebelumnya',
                                    items: previous,
                                    center: center,
                                  ),
                                const SizedBox(height: 24),
                                const _NotificationFootnote(),
                              ],
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      )),
    );
  }
}

class _NotificationGroup extends StatelessWidget {
  const _NotificationGroup({
    required this.title,
    required this.items,
    required this.center,
  });

  final String title;
  final List<SkinNotificationItem> items;
  final SkinNotificationCenter center;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            title.toUpperCase(),
            style: SkinTokens.eyebrow.copyWith(color: SkinTokens.muted),
          ),
        ),
        for (var index = 0; index < items.length; index++) ...[
          SkinReveal.staggered(
            index: index,
            child: _NotificationTile(
              item: items[index],
              isRead: center.isRead(items[index].id),
              onTap: () => _open(context, items[index]),
            ),
          ),
          if (index != items.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }

  void _open(BuildContext context, SkinNotificationItem item) {
    center.markRead(item.id);
    final page = switch (item.destination) {
      SkinNotificationDestination.scan => const SkinScanPage(),
      SkinNotificationDestination.journey => const SkinProgressPage(),
    };
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.item,
    required this.isRead,
    required this.onTap,
  });

  final SkinNotificationItem item;
  final bool isRead;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (icon, tone) = switch (item.kind) {
      'result' => (Icons.auto_graph_rounded, SkinTone.peach),
      'checkin' => (Icons.task_alt_rounded, SkinTone.primary),
      _ => (Icons.notifications_active_outlined, SkinTone.info),
    };

    return SkinCard(
      inkKey: ValueKey('notification-${item.id}'),
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      color: isRead ? Colors.white : const Color(0xFFEFF5F2),
      borderColor: isRead ? SkinTokens.border : SkinTokens.mintStrong,
      shadow: isRead,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkinIconTile(icon: icon, tone: tone, size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: SkinTokens.ink,
                          fontSize: 14.5,
                          height: 1.3,
                          fontWeight:
                              isRead ? FontWeight.w700 : FontWeight.w800,
                        ),
                      ),
                    ),
                    if (!isRead) ...[
                      const SizedBox(width: 8),
                      Container(
                        width: 9,
                        height: 9,
                        margin: const EdgeInsets.only(top: 4),
                        decoration: const BoxDecoration(
                          color: SkinTokens.peach,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  item.message,
                  style: const TextStyle(
                    color: SkinTokens.muted,
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.schedule_rounded,
                        size: 13, color: SkinTokens.subtle),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        _dateLabel(item.date, SkinJourneyStore.instance.today),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: SkinTokens.muted,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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

  String _dateLabel(DateTime date, DateTime now) {
    if (SkinJourneyStore.sameDay(date, now)) {
      return 'Hari ini · ${SkinFormat.time(date)}';
    }
    return SkinFormat.shortDate(date);
  }
}

class _NotificationFootnote extends StatelessWidget {
  const _NotificationFootnote();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.shield_outlined, size: 16, color: SkinTokens.primary),
        SizedBox(width: 7),
        Flexible(
          child: Text(
            'Notifikasi mengikuti aktivitas Skin Journey milikmu.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: SkinTokens.muted,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyNotifications extends StatelessWidget {
  const _EmptyNotifications();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(34),
        child: SkinEmptyState(
          image: AppAssets.checkin3d,
          title: 'Belum ada notifikasi',
          message: 'Pengingat check-in dan hasil scan akan muncul di sini.',
        ),
      ),
    );
  }
}
