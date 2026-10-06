import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/presentation/pages/login_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Pre-warm the liquid-glass fragment shaders before the first frame so
  // glass surfaces render immediately instead of flashing (SKILL.md §2).
  await LiquidGlassWidgets.initialize();
  runApp(
    LiquidGlassWidgets.wrap(
      // On, but pinned: the tier-stepping re-grades glass quality at runtime
      // (benchmark ~3s after launch, then ongoing demote/recover), which made
      // the tab-bar indicator visibly pop in and out on device.
      //
      // The scope is still required, because it is the only thing that caps
      // quality. With it absent, GlassScaffold / GlassTabBar promote their
      // bars to GlassQuality.premium regardless of the theme tier, and on a
      // pre-A15 GPU that pair blows the 16 ms raster budget (23.4 ms measured)
      // and surfaces the package's premium performance warning.
      //
      // maxQuality + allowStepUp:false means the ceiling is standard, so there
      // is no promotion and therefore no pop — the scope only ever demotes.
      adaptiveQuality: true,
      adaptiveConfig: const GlassAdaptiveScopeConfig(
        maxQuality: GlassQuality.standard,
        initialQuality: GlassQuality.standard,
        allowStepUp: false,
      ),
      respectSystemAccessibility: true,
      // Bridges Material ThemeMode into the glass brightness cascade
      // without the package importing flutter/material (SKILL.md §2).
      brightnessResolver: Theme.maybeBrightnessOf,
      theme: GlassThemeData.simple(
        blur: 12,
        thickness: 25,
        quality: GlassQuality.standard,
      ),
      child: MediaQuery.withClampedTextScaling(
        // Cap system text-scale zoom at 1.3× so large
        // display-size settings never blow up the
        // fixed-rhythm layouts (cards, pills, CTAs),
        // while still honoring accessibility scaling.
        minScaleFactor: 1.0,
        maxScaleFactor: 1.3,
        child: const MrBobPartnerApp(),
      ),
    ),
  );
}

class MrBobPartnerApp extends StatelessWidget {
  const MrBobPartnerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MrBob Partner',
      theme: AppTheme.light,
      home: const LoginPage(),
    );
  }
}
