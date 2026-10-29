import 'package:flutter/material.dart';

import '../core/app_assets.dart';
import '../core/theme/skin_theme.dart';
import '../shared/widgets/skin_3d.dart';
import '../shared/widgets/skin_page_background.dart';
import '../shared/widgets/design_system/skin_ui.dart';

class SkinSightSplashScreen extends StatelessWidget {
  const SkinSightSplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SkinPageBackground(
        child: SizedBox.expand(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Skin3D(AppAssets.aloe3d, width: 170, height: 108),
              SizedBox(height: 14),
              SkinWordmark(fontSize: 32),
              SizedBox(height: 6),
              Text(
                'Kenali, catat, dan pahami kulitmu',
                style: TextStyle(color: SkinTokens.muted, fontSize: 14),
              ),
              SizedBox(height: 34),
              SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(strokeWidth: 2.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
