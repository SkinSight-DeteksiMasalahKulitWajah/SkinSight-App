import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum SkinFontChoice { roboto, handwritten }

class SkinFontSettings extends ChangeNotifier {
  SkinFontSettings._();

  static final instance = SkinFontSettings._();

  static const _preferenceKey = 'skinsight_font_choice_v2';

  SkinFontChoice _choice = SkinFontChoice.roboto;

  SkinFontChoice get choice => _choice;

  String get fontFamily => switch (_choice) {
        // Nama enum dipertahankan agar preferensi lama tetap terbaca.
        SkinFontChoice.roboto => 'PlusJakartaSans',
        SkinFontChoice.handwritten => 'Kalam',
      };

  Future<void> load() async {
    try {
      final stored = await SharedPreferencesAsync().getString(_preferenceKey);
      _choice = stored == SkinFontChoice.handwritten.name
          ? SkinFontChoice.handwritten
          : SkinFontChoice.roboto;
    } on Object {
      _choice = SkinFontChoice.roboto;
    }
  }

  void select(SkinFontChoice value) {
    if (_choice == value) return;
    _choice = value;
    notifyListeners();
    unawaited(_save(value));
  }

  Future<void> _save(SkinFontChoice value) async {
    try {
      await SharedPreferencesAsync().setString(_preferenceKey, value.name);
    } on StateError {
      // Widget tests do not register a preferences platform implementation.
    }
  }
}
