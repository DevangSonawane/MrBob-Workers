import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_haptics.dart';
import '../../../earnings/presentation/pages/earnings_page.dart';
import '../../../feed/presentation/pages/booking_feed_page.dart';
import '../../../jobs/presentation/pages/jobs_page.dart';
import '../../../profile/presentation/pages/profile_page.dart';

/// The 4-tab partner shell (spec S7): Home (feed) | Jobs |
/// Earnings | Profile. Structure and glass metrics copied
/// from the client app's MainShell.
class PartnerShell extends StatefulWidget {
  const PartnerShell({super.key});

  /// Named-route tag so flows (e.g. job completion) can pop
  /// back to the existing shell instead of the auth pages
  /// beneath it.
  static const routeName = '/home';

  @override
  State<PartnerShell> createState() => _PartnerShellState();
}

class _PartnerShellState extends State<PartnerShell> {
  int tab = 0;

  /// Icon-only tabs ([GlassTab.label] left null so the icon
  /// centers — text labels overflowed their cells at large
  /// system font sizes). [GlassTab.semanticLabel] keeps
  /// screen-reader names.
  static const _tabs = [
    GlassTab(
      icon: Icon(LucideIcons.home),
      activeIcon: Icon(LucideIcons.house),
      semanticLabel: 'Home',
    ),
    GlassTab(
      icon: Icon(LucideIcons.briefcase),
      activeIcon: Icon(LucideIcons.briefcase),
      semanticLabel: 'Jobs',
    ),
    GlassTab(
      icon: Icon(LucideIcons.wallet),
      activeIcon: Icon(LucideIcons.wallet),
      semanticLabel: 'Earnings',
    ),
    GlassTab(
      icon: Icon(LucideIcons.user),
      activeIcon: Icon(LucideIcons.userRound),
      semanticLabel: 'Profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    const screens = [
      BookingFeedPage(),
      JobsPage(),
      EarningsPage(),
      ProfilePage(),
    ];

    // GlassScaffold (SKILL.md §3, scaffold_nav_demo.dart) owns z-ordering so
    // the floating tab pill always paints above tab bodies, and extends the
    // body behind the bar — tab pages already reserve bottom padding for it.
    return GlassScaffold(
      backgroundColor: Colors.white,
      extendBody: true,
      body: screens[tab],
      bottomBar: GlassTabBar.bottom(
        selectedIndex: tab,
        onTabSelected: _selectTab,
        tabs: _tabs,
        // Slim metrics: slightly smaller pill, tighter icon rhythm.
        // Safe with icon-only tabs (no label text left to overflow).
        barHeight: 58,
        iconSize: 22,
        spacing: 4,
        horizontalPadding: 16,
        verticalPadding: 16,
        // Apple-style: light tint, real blur + saturation + edge light.
        // Definition comes from refraction and the specular edge — not
        // opacity — so the pill stays liquid over any page.
        settings: LiquidGlassSettings(
          glassColor: Colors.white.withValues(alpha: 0.32),
          blur: 20,
          thickness: 28,
          saturation: 1.7,
          lightIntensity: 0.7,
          ambientStrength: 0.1,
        ),
        selectedIconColor: AppColors.brandForest,
        unselectedIconColor: AppColors.mutedText,
        showIndicator: true,
        // Forest-tinted pill: the default indicator washes out over our
        // white pages, which is why the selection circle kept disappearing.
        indicatorColor: AppColors.brandForest.withValues(alpha: 0.18),
        interactionGlowColor: Colors.transparent,
      ),
    );
  }

  void _selectTab(int value) {
    // Re-tapping the current tab is a no-op, so it stays silent.
    if (value == tab) return;
    // Light impact rather than a selection tick: a page swap is the loudest
    // interaction in the app, and selectionClick is too subtle to feel over
    // the tab bar's own spring animation.
    AppHaptics.press();
    setState(() => tab = value);
  }
}
