import 'package:dio/dio.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_haptics.dart';
import '../../../../features/onboarding/data/onboarding_repository.dart';
import 'onboarding_otp_page.dart';

class OnboardingPhonePage extends StatefulWidget {
  const OnboardingPhonePage({super.key});

  @override
  State<OnboardingPhonePage> createState() => _OnboardingPhonePageState();
}

class _OnboardingPhonePageState extends State<OnboardingPhonePage> {
  final _phoneController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _requestOtp() async {
    final raw = _phoneController.text.trim();
    if (raw.isEmpty || raw.length != 10) {
      setState(() => _error = 'Enter a valid 10-digit mobile number');
      AppHaptics.press();
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final repo = OnboardingRepository.instance;
      final phone = '+91$raw';
      await repo.requestOtp(phone);
      if (!mounted) return;
      AppHaptics.success();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OnboardingOtpPage(phone: phone),
        ),
      );
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ??
          'Could not send OTP. Please try again.';
      if (!mounted) return;
      setState(() => _error = message);
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

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: Colors.white,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        child: SafeArea(
          top: false,
          bottom: false,
          child: Stack(
            children: <Widget>[
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                bottom: 222 + bottomInset,
                child: Image.asset(
                  'assets/login/MrBob Rural Orders Onboarding.png',
                  fit: BoxFit.cover,
                  alignment: Alignment.bottomCenter,
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                bottom: 222 + bottomInset,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: <Color>[
                        Colors.black.withAlpha(32),
                        Colors.black.withAlpha(0),
                        Colors.transparent,
                      ],
                      stops: const <double>[0, 0.36, 0.7],
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: _LoginSheet(
                  bottomInset: bottomInset,
                  phoneController: _phoneController,
                  onContinue: _requestOtp,
                  loading: _loading,
                  error: _error,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoginSheet extends StatelessWidget {
  const _LoginSheet({
    required this.bottomInset,
    required this.phoneController,
    required this.onContinue,
    required this.loading,
    required this.error,
  });

  final double bottomInset;
  final TextEditingController phoneController;
  final VoidCallback onContinue;
  final bool loading;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Color(0x1F000000),
            blurRadius: 14,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(18, 16, 18, 12 + bottomInset),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 370),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Text(
                'Log in or sign up',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF242938),
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 13),
              LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 340;
                  return Row(
                    children: <Widget>[
                      _CountryCodeButton(
                        width: compact ? 76 : 96,
                        compact: compact,
                      ),
                      SizedBox(width: compact ? 7 : 10),
                      Expanded(
                        child: _PhoneNumberField(
                          compact: compact,
                          controller: phoneController,
                          onSubmitted: onContinue,
                        ),
                      ),
                    ],
                  );
                },
              ),
              if (error != null) ...[
                const SizedBox(height: 8),
                Text(
                  error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              SizedBox(
                height: 43,
                child: FilledButton(
                  onPressed: loading ? null : onContinue,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.brandForest,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Continue',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 17),
              Text(
                'By continuing, you agree to our',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: const Color(0xFF242938).withAlpha(220),
                  fontSize: 9.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              const _PolicyLinks(),
            ],
          ),
        ),
      ),
    );
  }
}

class _CountryCodeButton extends StatelessWidget {
  const _CountryCodeButton({required this.width, required this.compact});

  final double width;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: const Color(0xFFE7E9EF), width: 1.1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          _IndiaFlag(compact: compact),
          SizedBox(width: compact ? 6 : 9),
          Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Colors.grey.shade600,
            size: compact ? 20 : 22,
          ),
        ],
      ),
    );
  }
}

class _IndiaFlag extends StatelessWidget {
  const _IndiaFlag({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: SvgPicture.asset(
        'assets/icons/india_flag.svg',
        width: compact ? 24 : 27,
        height: compact ? 16 : 18,
      ),
    );
  }
}

class _PhoneNumberField extends StatelessWidget {
  const _PhoneNumberField({
    required this.compact,
    required this.controller,
    required this.onSubmitted,
  });

  final bool compact;
  final TextEditingController controller;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: const Color(0xFFE7E9EF), width: 1.1),
      ),
      child: Row(
        children: <Widget>[
          SizedBox(width: compact ? 9 : 12),
          Text(
            '+91',
            style: TextStyle(
              color: Colors.black,
              fontSize: compact ? 13 : 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(width: compact ? 6 : 9),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              onSubmitted: (_) => onSubmitted(),
              style: TextStyle(
                color: const Color(0xFF242938),
                fontSize: compact ? 13 : 15,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                hintText: 'Enter Mobile Number',
                hintStyle: TextStyle(
                  color: const Color(0xFF9EA2AE),
                  fontSize: compact ? 12.5 : 15,
                  fontWeight: FontWeight.w600,
                ),
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isCollapsed: true,
              ),
            ),
          ),
          SizedBox(width: compact ? 6 : 9),
        ],
      ),
    );
  }
}

class _PolicyLinks extends StatelessWidget {
  const _PolicyLinks();

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      color: Color(0xFF242938),
      fontSize: 9,
      fontWeight: FontWeight.w500,
      decoration: TextDecoration.underline,
      decorationColor: Color(0xFF242938),
      decorationThickness: 0.8,
    );

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 10,
      runSpacing: 5,
      children: const <Widget>[
        Text('Terms of Service', style: style),
        Text('Privacy Policy', style: style),
        Text('Content Policies', style: style),
      ],
    );
  }
}
