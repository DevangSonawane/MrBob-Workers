import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_haptics.dart';
import '../../../../shared/widgets/otp_boxes.dart';
import '../../../../features/onboarding/data/onboarding_repository.dart';
import 'onboarding_details_page.dart';
import 'onboarding_phone_page.dart';
import 'onboarding_verification_page.dart';
import 'onboarding_verified_page.dart';

class OnboardingOtpPage extends StatefulWidget {
  const OnboardingOtpPage({super.key, required this.phone});

  final String phone;

  @override
  State<OnboardingOtpPage> createState() => _OnboardingOtpPageState();
}

class _OnboardingOtpPageState extends State<OnboardingOtpPage> {
  final _otpController = TextEditingController();
  final _otpFocusNode = FocusNode();
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _otpController.addListener(_handleOtpChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _otpFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _otpController.removeListener(_handleOtpChanged);
    _otpController.dispose();
    _otpFocusNode.dispose();
    super.dispose();
  }

  void _handleOtpChanged() {
    if (_otpController.text.length == 4) {
      _verifyOtp();
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.length != 4) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final repo = OnboardingRepository.instance;
      final phone = widget.phone;
      final result = await repo.verifyOtp(phone, otp);
      if (!mounted) return;
      AppHaptics.success();

      final step = result.application.flow?.currentStep ?? 2;
      if (step == 5) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const OnboardingVerifiedPage()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => _routeForStep(step, phone),
          ),
        );
      }
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ??
          'Invalid OTP. Please try again.';
      if (!mounted) return;
      setState(() => _error = message);
      _otpController.clear();
      AppHaptics.press();
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Network error. Please try again.');
      AppHaptics.press();
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Widget _routeForStep(int step, String phone) {
    if (step >= 4) {
      return OnboardingVerificationPage(phone: phone);
    }
    return OnboardingDetailsPage(phone: phone);
  }

  void _back() {
    AppHaptics.press();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const OnboardingPhonePage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.white),
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 6),
                    child: Row(
                      children: [
                        _BackButton(onTap: _back),
                        const Spacer(),
                        const SizedBox(width: 44),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.fromLTRB(26, 32, 26, 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Verify your phone number',
                            style: TextStyle(
                              color: AppColors.brandForest,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              height: 1.12,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Enter the 4-digit code sent to ${widget.phone}.',
                            style: const TextStyle(
                              color: Color(0xFFB8B8B8),
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              height: 1.22,
                            ),
                          ),
                          const SizedBox(height: 26),
                          OtpBoxes(
                            focusNode: _otpFocusNode,
                            controller: _otpController,
                            onCompleted: _loading ? () {} : _verifyOtp,
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: 16),
                            Text(
                              _error!,
                              style: const TextStyle(
                                color: Colors.redAccent,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Positioned(
                left: 22,
                right: 22,
                bottom: 0,
                child: AnimatedPadding(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  padding: EdgeInsets.only(
                    bottom: keyboardInset + 14 + bottomInset * 0.3,
                  ),
                  child: _ResendButton(
                    onResend: _verifyOtp,
                    loading: _loading,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: IconButton(
        onPressed: onTap,
        style: IconButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.brandForest,
          shape: const CircleBorder(),
        ),
        icon: const Icon(LucideIcons.chevronLeft, size: 25),
      ),
    );
  }
}

class _ResendButton extends StatelessWidget {
  const _ResendButton({required this.onResend, required this.loading});

  final VoidCallback onResend;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onResend,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.brandForest,
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.16),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: loading
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text(
                'Verify',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
      ),
    );
  }
}
