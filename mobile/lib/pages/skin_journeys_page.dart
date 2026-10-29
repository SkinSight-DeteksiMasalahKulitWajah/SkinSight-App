import 'package:flutter/material.dart';

import '../core/app_assets.dart';
import '../data/skin_journey_store.dart';
import '../theme/skin_theme.dart';
import '../widgets/asset_images.dart';
import '../widgets/skin_bottom_nav.dart';
import '../widgets/skin_page_background.dart';
import '../widgets/skin_page_header.dart';
import '../widgets/skin_3d.dart';
import '../widgets/skin_ui.dart';
import 'skin_progress_page.dart';
import 'skin_quiz_page.dart';

class SkinJourneysPage extends StatelessWidget {
  const SkinJourneysPage({super.key});

  Future<void> _startJourney(BuildContext context) async {
    SkinJourneyStore.instance.beginNewJourney();
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const SkinQuizPage()),
    );
  }

  Future<void> _openJourney(
    BuildContext context,
    SkinJourneyRecord journey,
  ) async {
    if (!SkinJourneyStore.instance.selectJourney(journey.id)) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const SkinProgressPage()),
    );
  }

  Future<void> _showActions(
    BuildContext context,
    SkinJourneyRecord journey,
  ) async {
    final action = await showModalBottomSheet<_JourneyAction>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
                child: Row(
                  children: [
                    const SkinIconTile(icon: Icons.spa_outlined, size: 40),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        journey.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: SkinTokens.cardTitle.copyWith(fontSize: 17),
                      ),
                    ),
                  ],
                ),
              ),
              _actionTile(
                sheetContext,
                _JourneyAction.rename,
                Icons.edit_outlined,
                'Edit nama',
                key: Key('rename-journey-${journey.id}'),
              ),
              _actionTile(
                sheetContext,
                _JourneyAction.pin,
                journey.isPinned
                    ? Icons.push_pin_outlined
                    : Icons.push_pin_rounded,
                journey.isPinned ? 'Lepas pin' : 'Pin perjalanan',
                key: Key('pin-journey-${journey.id}'),
              ),
              if (journey.status != JourneyStatus.active)
                _actionTile(
                  sheetContext,
                  _JourneyAction.activate,
                  Icons.play_circle_outline_rounded,
                  'Aktifkan kembali',
                ),
              if (journey.status == JourneyStatus.active) ...[
                _actionTile(
                  sheetContext,
                  _JourneyAction.complete,
                  Icons.task_alt_rounded,
                  'Tandai selesai',
                ),
                _actionTile(
                  sheetContext,
                  _JourneyAction.cancel,
                  Icons.cancel_outlined,
                  'Batalkan perjalanan',
                  key: Key('cancel-journey-${journey.id}'),
                ),
              ],
              const Divider(height: 20),
              ListTile(
                key: Key('trash-journey-${journey.id}'),
                leading: const SkinIconTile(
                  icon: Icons.delete_outline_rounded,
                  tone: SkinTone.danger,
                  size: 38,
                ),
                title: const Text(
                  'Pindahkan ke sampah',
                  style: TextStyle(
                    color: SkinTokens.coral,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                onTap: () => Navigator.pop(sheetContext, _JourneyAction.trash),
              ),
            ],
          ),
        ),
      ),
    );
    if (!context.mounted || action == null) return;
    final store = SkinJourneyStore.instance;
    switch (action) {
      case _JourneyAction.rename:
        await _renameJourney(context, journey);
      case _JourneyAction.pin:
        store.togglePin(journey.id);
      case _JourneyAction.activate:
        store.setJourneyStatus(journey.id, JourneyStatus.active);
      case _JourneyAction.complete:
        store.setJourneyStatus(journey.id, JourneyStatus.completed);
      case _JourneyAction.cancel:
        store.setJourneyStatus(journey.id, JourneyStatus.cancelled);
      case _JourneyAction.trash:
        store.moveJourneyToTrash(journey.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Perjalanan dipindahkan ke sampah.'),
              action: SnackBarAction(
                label: 'Pulihkan',
                onPressed: () => store.restoreJourney(journey.id),
              ),
            ),
          );
        }
    }
  }

  Widget _actionTile(
    BuildContext context,
    _JourneyAction action,
    IconData icon,
    String label, {
    Key? key,
  }) {
    return ListTile(
      key: key,
      leading: SkinIconTile(icon: icon, size: 38),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      onTap: () => Navigator.pop(context, action),
    );
  }

  Future<void> _renameJourney(
    BuildContext context,
    SkinJourneyRecord journey,
  ) async {
    var draftName = journey.name;
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const SkinIconTile(icon: Icons.edit_outlined, size: 48),
        title: const Text('Edit nama perjalanan'),
        content: TextFormField(
          key: const Key('journey-name-field'),
          initialValue: journey.name,
          autofocus: true,
          maxLength: 50,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(labelText: 'Nama perjalanan'),
          onChanged: (value) => draftName = value,
          onFieldSubmitted: (value) => Navigator.pop(dialogContext, value),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          FilledButton(
            key: const Key('save-journey-name'),
            style: FilledButton.styleFrom(minimumSize: const Size(96, 46)),
            onPressed: () => Navigator.pop(dialogContext, draftName),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    if (name != null) {
      SkinJourneyStore.instance.renameJourney(journey.id, name);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = SkinJourneyStore.instance;
    return Scaffold(
      extendBody: true,
      backgroundColor: SkinTokens.background,
      body: SkinPageBackground(
          child: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: SkinTokens.maxWidth),
            child: AnimatedBuilder(
              animation: store,
              builder: (context, _) {
                final journeys = store.journeys;
                return Column(children: [
                  const SkinPageHeader(
                    title: 'Skin Journey',
                    subtitle: 'Pantau setiap perjalanan kulit secara terpisah.',
                    backKey: Key('journeys-back'),
                  ),
                  Expanded(
                      child: ListView(
                    key: const Key('journeys-list'),
                    padding: const EdgeInsets.fromLTRB(
                        20, 4, 20, SkinBottomNav.overlap + 16),
                    children: [
                      SkinReveal(
                        child: _NewJourneyCard(
                          onTap: () => _startJourney(context),
                        ),
                      ),
                      const SizedBox(height: 26),
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Perjalanan Saya',
                              style: SkinTokens.section,
                            ),
                          ),
                          SkinPill(
                            label: '${journeys.length} perjalanan',
                            tone: SkinTone.neutral,
                          ),
                          const SizedBox(width: 6),
                          IconButton(
                            key: const Key('open-journey-trash'),
                            tooltip: 'Sampah',
                            onPressed: () => Navigator.of(context).push<void>(
                              MaterialPageRoute<void>(
                                builder: (_) => const SkinJourneyTrashPage(),
                              ),
                            ),
                            icon: Badge(
                              isLabelVisible: store.trashedJourneys.isNotEmpty,
                              backgroundColor: SkinTokens.coral,
                              label: Text('${store.trashedJourneys.length}'),
                              child: const Icon(
                                Icons.delete_outline_rounded,
                                color: SkinTokens.muted,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (journeys.isEmpty)
                        const _EmptyJourneys()
                      else
                        for (var index = 0;
                            index < journeys.length;
                            index++) ...[
                          SkinReveal.staggered(
                            index: index,
                            child: _JourneyListItem(
                              journey: journeys[index],
                              onTap: () =>
                                  _openJourney(context, journeys[index]),
                              onMore: () =>
                                  _showActions(context, journeys[index]),
                            ),
                          ),
                          if (index < journeys.length - 1)
                            const SizedBox(height: 12),
                        ],
                    ],
                  )),
                ]);
              },
            ),
          ),
        ),
      )),
      bottomNavigationBar: const SkinBottomNav(currentIndex: 3),
    );
  }
}

class _NewJourneyCard extends StatelessWidget {
  const _NewJourneyCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: SkinTokens.brandGradient,
        borderRadius: BorderRadius.circular(SkinTokens.radiusXl),
        boxShadow: SkinTokens.glow(SkinTokens.primary, opacity: .26),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -40,
            top: -50,
            child: Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .09),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: -6,
            top: 4,
            width: 104,
            height: 104,
            child: const Skin3D(AppAssets.journey3d, float: true),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(right: 96),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mulai Perjalanan Baru',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          height: 1.2,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -.3,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Buat perjalanan baru dengan kuis dan scan awal.',
                        style: TextStyle(
                          color: Color(0xDDFFFFFF),
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    key: const Key('start-new-journey'),
                    onPressed: onTap,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: SkinTokens.primaryDark,
                      minimumSize: const Size.fromHeight(50),
                    ),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Mulai perjalanan baru'),
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

class _JourneyListItem extends StatelessWidget {
  const _JourneyListItem({
    required this.journey,
    required this.onTap,
    required this.onMore,
  });

  final SkinJourneyRecord journey;
  final VoidCallback onTap;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    final findings = journey.findings;
    final start = journey.baselineDate ?? journey.createdAt;
    return SkinCard(
      inkKey: Key('journey-card-${journey.id}'),
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
      borderColor: journey.isPinned ? SkinTokens.mintStrong : SkinTokens.border,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _JourneyThumbnail(journey: journey),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (journey.isPinned) ...[
                      const Icon(
                        Icons.push_pin_rounded,
                        color: SkinTokens.primary,
                        size: 14,
                      ),
                      const SizedBox(width: 5),
                    ],
                    Expanded(
                      child: Text(
                        journey.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: SkinTokens.cardTitle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 7,
                  runSpacing: 5,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _StatusChip(status: journey.status),
                    Text('Dimulai ${SkinFormat.shortDate(start)}',
                        style: SkinTokens.caption.copyWith(fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 8),
                if (findings.isEmpty)
                  const Text(
                    'Belum ada hasil scan',
                    style: TextStyle(
                      color: SkinTokens.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                else
                  Text(
                    findings.join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: SkinTokens.ink,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.photo_library_outlined,
                        size: 13, color: SkinTokens.muted),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        '${journey.photos.length} foto · '
                        '${journey.checkins.length} check-in',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: SkinTokens.caption.copyWith(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            key: Key('journey-menu-${journey.id}'),
            tooltip: 'Kelola perjalanan',
            visualDensity: VisualDensity.compact,
            onPressed: onMore,
            icon: const Icon(Icons.more_vert_rounded, color: SkinTokens.muted),
          ),
        ],
      ),
    );
  }
}

class _JourneyThumbnail extends StatelessWidget {
  const _JourneyThumbnail({required this.journey});

  final SkinJourneyRecord journey;

  @override
  Widget build(BuildContext context) {
    final photo = journey.photos.isEmpty ? null : journey.photos.first;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: photo != null && photo.bytes.isNotEmpty
          ? Image.memory(
              photo.bytes,
              width: 72,
              height: 84,
              fit: BoxFit.cover,
              cacheWidth: thumbnailCacheWidth(context, 72),
            )
          : Container(
              width: 72,
              height: 84,
              decoration:
                  const BoxDecoration(gradient: SkinTokens.softGradient),
              child: const Icon(Icons.spa_outlined,
                  color: SkinTokens.primary, size: 30),
            ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final JourneyStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, tone, icon) = switch (status) {
      JourneyStatus.active => ('Aktif', SkinTone.success, Icons.circle),
      JourneyStatus.completed => (
          'Selesai',
          SkinTone.info,
          Icons.check_rounded
        ),
      JourneyStatus.cancelled => (
          'Batal',
          SkinTone.danger,
          Icons.close_rounded
        ),
    };
    return Container(
      padding: const EdgeInsets.fromLTRB(7, 3, 9, 3),
      decoration: BoxDecoration(
        color: tone.background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: status == JourneyStatus.active ? 7 : 11,
            color: tone.foreground,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: tone.foreground,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyJourneys extends StatelessWidget {
  const _EmptyJourneys();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      key: Key('empty-journeys'),
      padding: EdgeInsets.symmetric(vertical: 28),
      child: SkinEmptyState(
        image: AppAssets.journey3d,
        tone: SkinTone.peach,
        title: 'Belum ada perjalanan.',
        message:
            'Mulai perjalanan baru untuk memantau kulitmu dari waktu ke waktu.',
      ),
    );
  }
}

class SkinJourneyTrashPage extends StatelessWidget {
  const SkinJourneyTrashPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = SkinJourneyStore.instance;
    return Scaffold(
      backgroundColor: SkinTokens.background,
      body: SkinPageBackground(
          child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: SkinTokens.maxWidth),
            child: AnimatedBuilder(
              animation: store,
              builder: (context, _) {
                final items = store.trashedJourneys;
                return Column(
                  children: [
                    const SkinPageHeader(
                      title: 'Sampah',
                      subtitle: 'Perjalanan yang dipindahkan',
                      backKey: Key('journey-trash-back'),
                    ),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                        children: [
                          const SkinNotice(
                            dense: true,
                            tone: SkinTone.neutral,
                            icon: Icons.restore_rounded,
                            message:
                                'Perjalanan di sini tidak dihapus permanen.',
                          ),
                          const SizedBox(height: 16),
                          if (items.isEmpty)
                            const _EmptyTrash()
                          else
                            for (final journey in items)
                              Padding(
                                key: Key('trashed-journey-${journey.id}'),
                                padding: const EdgeInsets.only(bottom: 11),
                                child: SkinCard(
                                  padding:
                                      const EdgeInsets.fromLTRB(14, 12, 8, 12),
                                  child: Row(
                                    children: [
                                      const SkinIconTile(
                                        icon: Icons.delete_outline_rounded,
                                        tone: SkinTone.neutral,
                                        size: 40,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          journey.name,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: SkinTokens.cardTitle,
                                        ),
                                      ),
                                      TextButton.icon(
                                        key: Key(
                                            'restore-journey-${journey.id}'),
                                        onPressed: () =>
                                            store.restoreJourney(journey.id),
                                        icon: const Icon(Icons.restore_rounded,
                                            size: 18),
                                        label: const Text('Pulihkan'),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
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

class _EmptyTrash extends StatelessWidget {
  const _EmptyTrash();

  @override
  Widget build(BuildContext context) {
    return const SkinCard(
      key: Key('empty-journey-trash'),
      padding: EdgeInsets.all(28),
      child: SkinEmptyState(
        compact: true,
        icon: Icons.delete_sweep_outlined,
        tone: SkinTone.neutral,
        title: 'Sampah masih kosong.',
      ),
    );
  }
}

enum _JourneyAction { rename, pin, activate, complete, cancel, trash }
