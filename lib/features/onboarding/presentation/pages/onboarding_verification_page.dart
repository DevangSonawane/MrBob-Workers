import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/models/onboarding/onboarding_application.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_haptics.dart';
import '../../data/onboarding_repository.dart';
import 'onboarding_details_page.dart';
import 'onboarding_verified_page.dart';

class OnboardingVerificationPage extends StatefulWidget {
  const OnboardingVerificationPage({super.key, required this.phone});

  final String phone;

  @override
  State<OnboardingVerificationPage> createState() =>
      _OnboardingVerificationPageState();
}

class _OnboardingVerificationPageState
    extends State<OnboardingVerificationPage> {
  final _repo = OnboardingRepository.instance;
  Timer? _pollTimer;
  bool _loading = true;
  String? _status;
  String? _reviewNote;

  @override
  void initState() {
    super.initState();
    _pollStatus();
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted && _status == null) {
        _pollStatus();
      }
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _pollStatus() async {
    try {
      final app = await _repo.getStatus();
      if (!mounted) return;
      setState(() {
        _status = app.status;
        _reviewNote = app.reviewNote;
        _loading = false;
      });
      _routeByStatus(app);
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _status = 'ERROR';
      });
      _showError(e.response?.data?['message'] as String? ?? 'Poll failed');
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _status = 'ERROR';
      });
    }
  }

  void _routeByStatus(OnboardingApplication app) {
    final status = app.status?.toUpperCase();
    if (status == 'APPROVED') {
      _pollTimer?.cancel();
      AppHaptics.success();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const OnboardingVerifiedPage()),
      );
    } else if (status == 'CHANGES_REQUESTED' || status == 'REJECTED') {
      _pollTimer?.cancel();
      AppHaptics.press();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => OnboardingDetailsPage(phone: widget.phone),
        ),
      );
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: _loading && _status == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(
                        color: AppColors.brandForest,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Checking status...',
                        style: TextStyle(
                          color: AppColors.brandForest,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'We\'ll notify you when verification is complete.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.mutedText,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        LucideIcons.clock,
                        size: 72,
                        color: AppColors.brandGold,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        _status == 'ERROR'
                            ? 'Connection issue'
                            : 'Verification in progress',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.brandForest,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _status == null
                            ? 'Please wait while our team reviews your documents.'
                            : 'Checking for updates...',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.mutedText,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (_reviewNote != null && _reviewNote!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF8E1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.brandGold),
                          ),
                          child: Text(
                            _reviewNote!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.brandForest,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _pollStatus,
                        icon: const Icon(LucideIcons.refreshCw, size: 18),
                        label: const Text('Refresh'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.brandForest,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
