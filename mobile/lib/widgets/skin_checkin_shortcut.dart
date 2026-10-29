import 'package:flutter/material.dart';

import '../data/skin_journey_store.dart';
import '../theme/skin_theme.dart';
import 'skin_ui.dart';

class SkinCheckinShortcut extends StatelessWidget {
  const SkinCheckinShortcut({
    required this.week,
    required this.dueDate,
    required this.status,
    required this.onPressed,
    required this.buttonKey,
    super.key,
  });

  final int week;
  final DateTime dueDate;
  final CheckinPromptStatus status;
  final VoidCallback onPressed;
  final Key buttonKey;

  String get _title => switch (status) {
        CheckinPromptStatus.dueToday => 'Waktunya check-in kulitmu!',
        CheckinPromptStatus.lateThisWeek =>
          'Check-in minggu ini belum kamu isi.',
        CheckinPromptStatus.resumedAfterMissedWeek =>
          'Yuk, lanjutkan pemantauan kulitmu minggu ini.',
      };

  @override
  Widget build(BuildContext context) {
    return SkinCard(
      padding: const EdgeInsets.all(18),
      radius: 30,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SkinIconTile(icon: Icons.edit_calendar_rounded, size: 46),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkinPill(label: 'Minggu ke-$week', dense: true),
                    const SizedBox(height: 6),
                    Text(
                      _title,
                      style: const TextStyle(
                        color: SkinTokens.ink,
                        fontSize: 15.5,
                        height: 1.3,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Sudah masuk minggu ke-$week. Yuk, catat perubahan kondisi kulitmu minggu ini.',
                      style: SkinTokens.caption,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 330;
              final date = Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.schedule_rounded,
                    size: 15,
                    color: SkinTokens.muted,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Jadwal: ${SkinFormat.date(dueDate)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: SkinTokens.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              );
              final button = FilledButton(
                key: buttonKey,
                onPressed: onPressed,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 44),
                  padding: const EdgeInsets.fromLTRB(18, 0, 8, 0),
                  textStyle: Theme.of(context).textTheme.labelLarge!.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Mulai Check-in'),
                    SizedBox(width: 8),
                    CircleAvatar(
                      radius: 13,
                      backgroundColor: Color(0x29FFFFFF),
                      child: Icon(
                        Icons.play_arrow_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              );

              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    date,
                    const SizedBox(height: 10),
                    button,
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: date),
                  const SizedBox(width: 10),
                  button,
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
