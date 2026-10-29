import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthSession extends ChangeNotifier {
  AuthSession._();

  static final instance = AuthSession._();

  static const _signedInKey = 'skinsight_signed_in';
  static const _onboardingKey = 'skinsight_onboarding_completed';

  bool _isSignedIn = false;
  bool _hasCompletedOnboarding = false;

  bool get isSignedIn => _isSignedIn;
  bool get hasCompletedOnboarding => _hasCompletedOnboarding;

  Future<void> load() async {
    try {
      final preferences = SharedPreferencesAsync();
      _isSignedIn = await preferences.getBool(_signedInKey) ?? false;
      _hasCompletedOnboarding =
          await preferences.getBool(_onboardingKey) ?? false;
    } on Object {
      _isSignedIn = false;
      _hasCompletedOnboarding = false;
    }
  }

  void signIn() {
    _isSignedIn = true;
    notifyListeners();
    unawaited(_writeBool(_signedInKey, true));
  }

  void completeOnboarding() {
    _hasCompletedOnboarding = true;
    notifyListeners();
    unawaited(_writeBool(_onboardingKey, true));
  }

  void signOut() {
    _isSignedIn = false;
    notifyListeners();
    unawaited(_writeBool(_signedInKey, false));
  }

  Future<void> _writeBool(String key, bool value) async {
    try {
      await SharedPreferencesAsync().setBool(key, value);
    } on StateError {
      // Widget tests do not register a preferences platform implementation.
    }
  }
}
