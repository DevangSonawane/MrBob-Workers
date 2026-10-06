import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/presentation/pages/login_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MediaQuery.withClampedTextScaling(
      // Cap system text-scale zoom at 1.3× so large display-size settings
      // never blow up the fixed-rhythm layouts, while still honoring
      // accessibility scaling.
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
      home: const LoginPage(),
    );
  }
}
