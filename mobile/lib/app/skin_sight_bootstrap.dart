import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/settings/font_settings.dart';
import '../core/theme/skin_theme.dart';
import '../features/auth/models/auth_session.dart';
import 'skin_sight_app.dart';
import 'skin_sight_splash_screen.dart';

void runSkinSight() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const _SkinSightBootstrap());
}

class _SkinSightBootstrap extends StatefulWidget {
  const _SkinSightBootstrap();

  @override
  State<_SkinSightBootstrap> createState() => _SkinSightBootstrapState();
}

class _SkinSightBootstrapState extends State<_SkinSightBootstrap> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      await Future.wait([
        SkinFontSettings.instance.load(),
        AuthSession.instance.load(),
        _initializeSupabase(),
      ]).timeout(const Duration(seconds: 2));
    } catch (error, stackTrace) {
      debugPrint('Startup preferences could not be loaded: $error');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      if (mounted) setState(() => _ready = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_ready) {
      return const SkinSightApp(respectPersistedSession: true);
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: SkinTokens.theme(),
      home: const SkinSightSplashScreen(),
    );
  }
}

Future<void> _initializeSupabase() async {
  const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) return;

  await Supabase.initialize(
    url: supabaseUrl,
    publishableKey: supabaseAnonKey,
  );
}
