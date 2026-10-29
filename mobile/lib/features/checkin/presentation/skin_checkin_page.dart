import 'package:flutter/material.dart';
import'../../../core/app_assets.dart';
import'../../journeys/data/skin_journey_store.dart';
import'../../../core/theme/skin_theme.dart';
import'../../../shared/widgets/skin_page_header.dart';
import'../../../shared/widgets/skin_page_background.dart';
import'../../../shared/widgets/skin_3d.dart';
import'../../../shared/widgets/design_system/skin_ui.dart';
import'./skin_checkin_quiz_page.dart';
import'../../journeys/presentation/skin_journey_photos_page.dart';

/// Halaman tengah pada sketsa: ringkasan hari ini, Kuis & Scan terpisah,
/// lalu satu konfirmasi manual untuk memasukkan event ke timeline.
class SkinCheckinPage extends StatelessWidget {
  const SkinCheckinPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = SkinJourneyStore.instance;
    return Scaffold(
      backgroundColor: SkinTokens.background,
      body: SkinPageBackground(
          child: SafeArea(
              bottom: false,
              child: Center(
                  child: ConstrainedBox(
                constraints:
                    const BoxConstraints(maxWidth: SkinTokens.maxWidth),
                child: AnimatedBuilder(
                    animation: store,
                    builder: (context, _) {
                      final today = DateTime.now();
                      final canConfirm =
                          store.checkinQuizDone && store.hasCheckinDue;
                      return Column(children: [
                        SkinPageHeader(
                          title: 'Check-in Hari Ini',
                          subtitle: SkinFormat.longDate(today),
                          backKey: const Key('checkin-back'),
                        ),
                        Expanded(
                            child: ListView(
                                padding:
                                    const EdgeInsets.fromLTRB(20, 4, 20, 24),
                                children: [
                              SkinReveal(
                                child: SkinCard(
                                  gradient: SkinTokens.softGradient,
                                  borderColor: Colors.white,
                                  child: Row(children: [
                                    const Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text('Bagaimana kulitmu minggu ini?',
                                              style: SkinTokens.section),
                                          SizedBox(height: 6),
                                          Text(
                                              'Isi kuis singkat untuk semua kondisi yang dipantau. Tambahkan foto kalau ingin, lalu konfirmasi.',
                                              style: SkinTokens.caption),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    SizedBox(
                                      width: 74,
                                      height: 74,
                                      child: const Skin3D(
                                        AppAssets.checkin3d,
                                        float: true,
                                      ),
                                    ),
                                  ]),
                                ),
                              ),
                              const SizedBox(height: 22),
                              const SkinSectionTitle(
                                title: 'Lengkapi sesi hari ini',
                                subtitle:
                                    'Kuis wajib diisi; foto bersifat opsional.',
                              ),
                              const SizedBox(height: 12),
                              _StepCard(
                                number: 1,
                                icon: Icons.fact_check_outlined,
                                title: 'Kuis check-in',
                                description: store.checkinQuizDone
                                    ? 'Jawaban siap. Ketuk jika ingin mengubah.'
                                    : 'Ceritakan perubahan Acne, PIH, atau kondisi yang sedang dipantau.',
                                done: store.checkinQuizDone,
                                required: true,
                                onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                        builder: (_) =>
                                            const SkinCheckinQuizPage())),
                              ),
                              const SizedBox(height: 12),
                              _StepCard(
                                number: 2,
                                icon: Icons.add_a_photo_outlined,
                                title: 'Sesi scan (opsional)',
                                description: store.pendingPhotos.isEmpty
                                    ? 'Tambah satu atau beberapa foto. Tidak harus scan ulang.'
                                    : '${store.pendingPhotos.length} foto siap dikonfirmasi. Ketuk untuk menambah atau menghapus.',
                                done: store.pendingPhotos.isNotEmpty,
                                required: false,
                                onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                        builder: (_) =>
                                            const SkinJourneyPhotosPage())),
                              ),
                              const SizedBox(height: 24),
                              SkinCard(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Row(children: [
                                        SkinIconTile(
                                          icon: Icons.insights_rounded,
                                          size: 38,
                                        ),
                                        SizedBox(width: 10),
                                        Expanded(
                                          child: Text('Ringkasan kondisi',
                                              style: SkinTokens.cardTitle),
                                        ),
                                      ]),
                                      const SizedBox(height: 8),
                                      const Text(
                                          'Temuan foto terakhir dan laporan hari ini dicatat terpisah.',
                                          style: SkinTokens.caption),
                                      const SizedBox(height: 8),
                                      if (store.trackedConditions.isEmpty)
                                        const Text(
                                            'Belum ada kondisi yang dipilih. Kuis bisa dipakai untuk membuat catatan awal.',
                                            style: SkinTokens.caption)
                                      else
                                        for (final condition
                                            in store.trackedConditions) ...[
                                          const Divider(height: 18),
                                          _ConditionRow(
                                            condition: condition,
                                            store: store,
                                          ),
                                        ],
                                    ]),
                              ),
                            ])),
                        SkinBottomBar(
                          child: SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                  onPressed: canConfirm
                                      ? () {
                                          final severe =
                                              store.draftIrritation ==
                                                  'Sedang-berat';
                                          if (store.confirmCheckin()) {
                                            if (severe) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(const SnackBar(
                                                      content: Text(
                                                          'Keluhan sedang-berat perlu dinilai tenaga kesehatan. Jangan menunggu check-in berikutnya.')));
                                            }
                                            Navigator.of(context).pop();
                                          }
                                        }
                                      : null,
                                  icon: const Icon(Icons.check_circle_outline),
                                  label: const Text(
                                      'Konfirmasi & simpan check-in'))),
                        ),
                      ]);
                    }),
              )))),
    );
  }
}

class _ConditionRow extends StatelessWidget {
  const _ConditionRow({required this.condition, required this.store});

  final String condition;
  final SkinJourneyStore store;

  @override
  Widget build(BuildContext context) {
    final p = store.pendingPhotos.isNotEmpty
        ? store.pendingPhotos.last
        : (store.photos.isEmpty ? null : store.photos.first);
    final n = p?.detectionCounts[condition];
    final area = p?.segmentationAreas[condition];
    final prefix =
        store.pendingPhotos.isNotEmpty ? 'Sesi terbaru' : 'Foto terakhir';
    final report = store.draftReports[condition];
    return Row(children: [
      Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: SkinTokens.primary,
          shape: BoxShape.circle,
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(condition,
            style: const TextStyle(
                color: SkinTokens.ink, fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(
            n != null
                ? '$prefix: $n temuan'
                : area != null
                    ? '$prefix: ${(area * 100).toStringAsFixed(0)}% mask'
                    : 'Belum ada pengamatan baru',
            style: SkinTokens.caption),
      ])),
      if (report != null) ...[
        const SizedBox(width: 8),
        SkinPill(label: report, dense: true),
      ],
    ]);
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.number,
    required this.icon,
    required this.title,
    required this.description,
    required this.done,
    required this.required,
    required this.onTap,
  });

  final int number;
  final IconData icon;
  final String title;
  final String description;
  final bool done;
  final bool required;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SkinCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      borderColor: done ? SkinTokens.mintStrong : SkinTokens.border,
      child: Row(children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            SkinIconTile(icon: icon, size: 52, filled: done),
            Positioned(
              right: -4,
              top: -4,
              child: Container(
                width: 20,
                height: 20,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: done ? SkinTokens.success : SkinTokens.ink,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: done
                    ? const Icon(Icons.check_rounded,
                        size: 11, color: Colors.white)
                    : Text(
                        '$number',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: const TextStyle(
                  color: SkinTokens.ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(description, style: SkinTokens.caption),
          const SizedBox(height: 8),
          SkinPill(
            label: done
                ? 'Siap'
                : required
                    ? 'Wajib'
                    : 'Opsional',
            tone: done
                ? SkinTone.success
                : required
                    ? SkinTone.peach
                    : SkinTone.neutral,
            dense: true,
          ),
        ])),
        const SizedBox(width: 6),
        const Icon(Icons.chevron_right_rounded, color: SkinTokens.subtle),
      ]),
    );
  }
}
