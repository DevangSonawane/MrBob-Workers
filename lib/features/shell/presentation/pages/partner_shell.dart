import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_haptics.dart';
import '../../../earnings/presentation/pages/earnings_page.dart';
import '../../../feed/presentation/pages/booking_feed_page.dart';
import '../../../jobs/presentation/pages/jobs_page.dart';
import '../../../profile/presentation/pages/profile_page.dart';

/// The 4-tab partner shell (spec S7): Home (feed) | Jobs |
/// Earnings | Profile.
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

  @override
  Widget build(BuildContext context) {
    const screens = [
      BookingFeedPage(),
      JobsPage(),
      EarningsPage(),
      ProfilePage(),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: screens[tab],
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: AppColors.brandForest.withValues(alpha: 0.12),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return TextStyle(
              color: selected ? AppColors.brandForest : AppColors.mutedText,
              fontSize: 11,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            );
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return IconThemeData(
              color: selected ? AppColors.brandForest : AppColors.mutedText,
              size: 22,
            );
          }),
        ),
        child: NavigationBar(
          selectedIndex: tab,
          onDestinationSelected: _selectTab,
          height: 72,
          elevation: 0,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(
              icon: Icon(LucideIcons.home),
              selectedIcon: Icon(LucideIcons.house),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(LucideIcons.briefcase),
              selectedIcon: Icon(LucideIcons.briefcase),
              label: 'Jobs',
            ),
            NavigationDestination(
              icon: Icon(LucideIcons.wallet),
              selectedIcon: Icon(LucideIcons.wallet),
              label: 'Earnings',
            ),
            NavigationDestination(
              icon: Icon(LucideIcons.user),
              selectedIcon: Icon(LucideIcons.userRound),
              label: 'Profile',
            ),
          ],
        ),
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
