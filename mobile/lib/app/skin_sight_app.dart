import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/settings/font_settings.dart';
import '../core/theme/skin_theme.dart';
import '../features/about/presentation/skin_about_page.dart';
import '../features/auth/data/auth_service.dart';
import '../features/auth/models/auth_session.dart';
import '../features/auth/presentation/skin_auth_choice_page.dart';
import '../features/auth/presentation/skin_login_page.dart';
import '../features/history/presentation/skin_history_page.dart';
import '../features/home/presentation/skin_home_page.dart';
import '../features/journeys/presentation/skin_journeys_page.dart';
import '../features/legal/presentation/skin_legal_pages.dart';
import '../features/notifications/presentation/skin_notifications_page.dart';
import '../features/profile/models/profile_data.dart';
import '../features/profile/presentation/skin_account_page.dart';
import '../features/profile/presentation/skin_profile_page.dart';
import '../features/scan/presentation/skin_result_page.dart';
import '../features/settings/presentation/skin_settings_page.dart';
import '../features/start/presentation/skin_start_page.dart';
import '../features/support/presentation/skin_help_page.dart';
import '../features/onboarding/presentation/skin_onboarding_page.dart';

class SkinSightApp extends StatelessWidget {
  const SkinSightApp({super.key, this.respectPersistedSession = false});

  final bool respectPersistedSession;

  bool _isSupabaseAvailable() {
    try {
      Supabase.instance.client;
      return true;
    } on Object {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSupabaseAvailable = _isSupabaseAvailable();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProfileData()),
        Provider<AuthService>(
          create: (_) => isSupabaseAvailable
              ? SupabaseAuthService()
              : FakeAuthService(),
        ),
      ],
      child: AnimatedBuilder(
        animation: SkinFontSettings.instance,
        builder: (context, _) => MaterialApp(
          debugShowCheckedModeBanner: false,
          initialRoute: respectPersistedSession && AuthSession.instance.isSignedIn
              ? '/home'
              : '/',
          theme: SkinTokens.theme(
            fontFamily: SkinFontSettings.instance.fontFamily,
          ),
          routes: {
            '/': (_) => const SkinStartPage(),
            '/home': (_) => const SkinHomePage(),
            '/education': (_) => const SkinHomePage(initialIndex: 1),
            '/journeys': (_) => const SkinJourneysPage(),
            // Keep the old path working for existing deep links.
            '/catalog': (_) => const SkinHomePage(initialIndex: 1),
            '/about': (_) => const SkinAboutPage(),
            '/login': (_) => const SkinLoginPage(),
            '/register': (_) => const SkinLoginPage(initialRegisterMode: true),
            '/auth': (_) => const SkinAuthChoicePage(),
            '/onboarding': (_) => const SkinOnboardingPage(),
            '/help': (_) => const SkinHelpPage(),
            '/history': (_) => const SkinHistoryPage(),
            '/notifications': (_) => const SkinNotificationsPage(),
            '/profile': (_) => const SkinProfilePage(),
            '/account': (_) => const SkinAccountPage(),
            '/settings': (_) => const SkinSettingsPage(),
            '/privacy': (_) => const SkinPrivacyPage(),
            '/terms': (_) => const SkinTermsPage(),
            '/result': (_) => const SkinResultPage(),
          },
        ),
      ),
    );
  }
}
