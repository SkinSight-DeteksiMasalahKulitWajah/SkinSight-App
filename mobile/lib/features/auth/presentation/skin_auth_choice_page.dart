import 'package:flutter/material.dart';

import 'skin_login_page.dart';

/// Halaman peralihan auth yang langsung mengarahkan ke [SkinLoginPage].
class SkinAuthChoicePage extends StatelessWidget {
  const SkinAuthChoicePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SkinLoginPage();
  }
}
