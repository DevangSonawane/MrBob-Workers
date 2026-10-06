import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'core/data/api_client.dart';
import 'core/data/storage_service.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'features/onboarding/data/onboarding_repository.dart';
import 'features/onboarding/presentation/pages/onboarding_details_page.dart';
import 'features/onboarding/presentation/pages/onboarding_phone_page.dart';
import 'features/onboarding/presentation/pages/onboarding_verification_page.dart';
import 'features/shell/presentation/pages/partner_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final storage = StorageService(FlutterSecureStorage());
  final apiClient = ApiClient(storage);
  OnboardingRepository.initialize(apiClient, storage);

  runApp(
    MediaQuery.withClampedTextScaling(
      minScaleFactor: 1.0,
      maxScaleFactor: 1.3,
      child: const MrBobPartnerApp(),
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
      home: const SplashPage(),
    );
  }
}

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    try {
      final repo = OnboardingRepository.instance;
      final hasTokens = await repo.hasTokens;
      if (!mounted) return;
      if (hasTokens) {
        try {
          final app = await repo.getApplication();
          if (!mounted) return;
          _routeByStep(app.flow?.currentStep ?? 2);
        } on DioException catch (_) {
          await repo.clearTokens();
          if (!mounted) return;
          _gotoPhone();
        } catch (_) {
          if (!mounted) return;
          _gotoPhone();
        }
      } else {
        _gotoPhone();
      }
    } on StateError catch (_) {
      // Repository not initialized (e.g. in tests) — stay on splash.
    }
  }

  void _gotoPhone() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const OnboardingPhonePage()),
    );
  }

  void _routeByStep(int step) {
    late final Widget screen;
    if (step == 5) {
      screen = const PartnerShell();
    } else if (step == 4) {
      screen = OnboardingVerificationPage(
        phone: '',
      );
    } else if (step == 3) {
      screen = OnboardingDetailsPage(phone: '');
    } else {
      screen = const OnboardingPhonePage();
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: CircularProgressIndicator(color: AppColors.brandForest),
      ),
    );
  }
}
