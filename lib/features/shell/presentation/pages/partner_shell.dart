import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../../../core/state/app_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_haptics.dart';
import '../../../earnings/presentation/pages/earnings_page.dart';
import '../../../feed/presentation/pages/booking_feed_page.dart';
import '../../../jobs/presentation/pages/jobs_page.dart';
import '../../../profile/presentation/pages/profile_page.dart';

/// The 4-tab partner shell (spec S7): Home (feed) | Jobs |
/// Earnings | Profile.
///
/// Visually mirrors the client app's MainShell: a detached liquid-glass
/// tab pill floating over the page, icon-only with screen-reader labels.
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
  Offset? _navPointerDown;
  bool _isNavDragging = false;

  @override
  void initState() {
    super.initState();
    // H3: sync the online switch with the server whenever the shell opens —
    // it also covers a fresh sign-in after a sign-out.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppState.instance.loadPresence();
    });
  }

  /// Icon-only tabs ([GlassTab.label] left null so the icon centers —
  /// text labels overflowed their cells at large system font sizes).
  /// [GlassTab.semanticLabel] keeps screen-reader names.
  static const _tabs = [
    GlassTab(
      icon: Icon(Icons.home_outlined),
      activeIcon: Icon(Icons.home_rounded),
      semanticLabel: 'Home',
    ),
    GlassTab(
      icon: Icon(Icons.work_outline_rounded),
      activeIcon: Icon(Icons.work_rounded),
      semanticLabel: 'Jobs',
    ),
    GlassTab(
      icon: Icon(Icons.account_balance_wallet_outlined),
      activeIcon: Icon(Icons.account_balance_wallet_rounded),
      semanticLabel: 'Earnings',
    ),
    GlassTab(
      icon: Icon(Icons.person_outline_rounded),
      activeIcon: Icon(Icons.person_rounded),
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

    // Same recipe as the client app's MainShell: GlassScaffold owns
    // z-ordering so the floating pill paints above tab bodies and the body
    // extends behind it — tab pages already reserve bottom padding.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarContrastEnforced: false,
        systemStatusBarContrastEnforced: false,
      ),
      child: GlassScaffold(
        backgroundColor: Colors.white,
        extendBody: true,
        bottomEdgeFade: false,
        body: screens[tab],
        bottomBar: GlassAdaptiveScope(
          minQuality: GlassQuality.premium,
          maxQuality: GlassQuality.premium,
          initialQuality: GlassQuality.premium,
          allowStepUp: false,
          child: Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: (event) => _navPointerDown = event.position,
            onPointerMove: _updateNavDrag,
            onPointerUp: _endNavDrag,
            onPointerCancel: _endNavDrag,
            child: GlassTabBar.bottom(
              selectedIndex: tab,
              onTabSelected: _selectTab,
              tabs: _tabs,
              barHeight: 62,
              barBorderRadius: 32,
              iconSize: 22,
              spacing: 6,
              horizontalPadding: 18,
              verticalPadding: 18,
              quality: GlassQuality.premium,
              backgroundQuality: GlassQuality.premium,
              settings: LiquidGlassSettings(
                glassColor: Colors.white.withValues(alpha: 0.14),
                blur: 6,
                thickness: 32,
                refractiveIndex: 1.35,
                saturation: 1.8,
                lightIntensity: 0.9,
                ambientRim: 0.25,
                whitenStrength: 0.12,
                shadowElevation: 2.2,
                chromaticAberration: _isNavDragging ? 0.85 : 0.5,
              ),
              indicatorSettings: AnimatedGlassIndicator.baseIndicatorSettings
                  .copyWith(chromaticAberration: _isNavDragging ? 0.9 : 0.45),
              selectedIconColor: AppColors.brandForest,
              unselectedIconColor: AppColors.mutedText,
              showIndicator: true,
              indicatorColor: AppColors.brandForest.withValues(alpha: 0.10),
            ),
          ),
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

  void _updateNavDrag(PointerMoveEvent event) {
    final start = _navPointerDown;
    if (start == null || _isNavDragging) return;
    if ((event.position - start).distance < 6) return;
    setState(() => _isNavDragging = true);
  }

  void _endNavDrag(PointerEvent _) {
    _navPointerDown = null;
    if (!_isNavDragging) return;
    setState(() => _isNavDragging = false);
  }
}
