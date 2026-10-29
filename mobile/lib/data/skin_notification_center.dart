import 'package:flutter/foundation.dart';

import 'skin_journey_store.dart';

enum SkinNotificationDestination { scan, journey }

class SkinNotificationItem {
  const SkinNotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.date,
    required this.destination,
    required this.kind,
  });

  final String id;
  final String title;
  final String message;
  final DateTime date;
  final SkinNotificationDestination destination;
  final String kind;
}

/// Status dibaca disimpan selama sesi aplikasi. Isi notifikasi selalu dibangun
/// ulang dari aktivitas Skin Journey agar tidak menjadi data contoh statis.
class SkinNotificationCenter extends ChangeNotifier {
  SkinNotificationCenter._();

  static final SkinNotificationCenter instance = SkinNotificationCenter._();

  final Set<String> _readIds = <String>{};

  bool isRead(String id) => _readIds.contains(id);

  void markRead(String id) {
    if (_readIds.add(id)) notifyListeners();
  }

  void markAllRead(Iterable<SkinNotificationItem> notifications) {
    final before = _readIds.length;
    _readIds.addAll(notifications.map((item) => item.id));
    if (_readIds.length != before) notifyListeners();
  }

  @visibleForTesting
  void reset() {
    if (_readIds.isEmpty) return;
    _readIds.clear();
    notifyListeners();
  }
}

abstract final class SkinNotificationFeed {
  static List<SkinNotificationItem> build(SkinJourneyStore store) {
    final notifications = <SkinNotificationItem>[];

    if (!store.hasBaseline) {
      notifications.add(SkinNotificationItem(
        id: 'start-skin-journey',
        title: 'Mulai scan awalmu',
        message:
            'Simpan hasil pertama untuk membuka timeline dan pengingat check-in.',
        date: store.today,
        destination: SkinNotificationDestination.scan,
        kind: 'reminder',
      ));
    }

    final dueDate = store.activeDueDate;
    if (store.hasCheckinDue && dueDate != null) {
      notifications.add(SkinNotificationItem(
        id: 'checkin-due-${dueDate.toIso8601String()}',
        title: 'Waktunya check-in kulit',
        message:
            'Catat perubahan terbaru agar perjalanan kulitmu tetap terpantau.',
        date: store.today,
        destination: SkinNotificationDestination.journey,
        kind: 'reminder',
      ));
    }

    for (final checkin in store.checkins) {
      final conditions = checkin.perClass.keys.toList();
      notifications.add(SkinNotificationItem(
        id: 'checkin-saved-${checkin.date.microsecondsSinceEpoch}',
        title: 'Check-in berhasil disimpan',
        message: conditions.isEmpty
            ? 'Catatan rutin kulitmu sudah masuk ke Skin Journey.'
            : '${conditions.take(2).join(' dan ')}${conditions.length > 2 ? ' +${conditions.length - 2}' : ''} telah diperbarui.',
        date: checkin.date,
        destination: SkinNotificationDestination.journey,
        kind: 'checkin',
      ));
    }

    for (final photo in store.photos) {
      final findings = photo.visualFindings;
      notifications.add(SkinNotificationItem(
        id: 'scan-result-${photo.id}',
        title: 'Hasil scan sudah tersimpan',
        message: findings.isEmpty
            ? 'Buka Skin Journey untuk melihat kembali hasil analisismu.'
            : '${findings.take(2).join(' dan ')}${findings.length > 2 ? ' +${findings.length - 2}' : ''} tercatat pada hasil terbaru.',
        date: photo.date,
        destination: SkinNotificationDestination.journey,
        kind: 'result',
      ));
    }

    notifications.sort((a, b) => b.date.compareTo(a.date));
    return notifications.take(20).toList(growable: false);
  }
}
