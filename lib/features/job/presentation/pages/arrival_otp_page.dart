import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/models/gig_booking.dart';
import '../../../../core/models/job_session.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_haptics.dart';
import '../../../../shared/widgets/otp_boxes.dart';
import 'in_progress_page.dart';

/// S10 — arrived → OTP → start. One card that morphs in place:
/// enter 4 digits → it animates into a green-tick "OTP verified" card.
class ArrivalOtpPage extends StatefulWidget {
  const ArrivalOtpPage({super.key, required this.booking});

  final GigBooking booking;

  @override
  State<ArrivalOtpPage> createState() => _ArrivalOtpPageState();
}

class _ArrivalOtpPageState extends State<ArrivalOtpPage> {
  final _otpController = TextEditingController();
  final _otpFocus = FocusNode();

  /// Single-flight guards — the reported "repeatedly moved" glitch
  /// was a double push: [_startWorking] pushed AND the session
  /// listener pushed again on the same frame.
  bool _goingToWork = false;
  bool _popped = false;

  @override
  void initState() {
    super.initState();
    // Auto-verify the moment the 4th digit lands, so the card
    // morphs without needing the button.
    _otpController.addListener(_onOtpChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _otpFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _otpController.removeListener(_onOtpChanged);
    _otpController.dispose();
    _otpFocus.dispose();
    super.dispose();
  }

  void _onOtpChanged() {
    if (_otpController.text.length != 4) return;
    final session = AppState.instance.activeJob.value;
    if (session == null || session.phase == JobPhase.otpVerified) return;
    _verify();
  }

  void _verify() {
    if (_otpController.text.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter all 4 digits')),
      );
      return;
    }
    AppHaptics.confirm();
    AppState.instance.verifyOtp();
    FocusScope.of(context).unfocus();
  }

  /// State-only: navigation happens exactly once in the listener below.
  void _startWorking() {
    if (_goingToWork) return;
    AppHaptics.success();
    AppState.instance.startWorking();
  }

  void _goToWorkOnce() {
    if (_goingToWork || !mounted) return;
    if (!(ModalRoute.of(context)?.isCurrent ?? false)) return;
    _goingToWork = true;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const InProgressPage()),
    );
  }

  void _popOnce() {
    if (_popped || !mounted) return;
    _popped = true;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft,
              color: AppColors.brandForest, size: 20),
          onPressed: () {
            AppHaptics.press();
            Navigator.pop(context);
          },
        ),
        title: const Text('Start job',
            style: TextStyle(
                color: AppColors.brandForest,
                fontSize: 16,
                fontWeight: FontWeight.w700)),
      ),
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: SafeArea(
          bottom: false,
          child: ValueListenableBuilder<JobSession?>(
            valueListenable: AppState.instance.activeJob,
            builder: (context, session, _) {
              if (session == null ||
                  session.booking.id != widget.booking.id) {
                WidgetsBinding.instance.addPostFrameCallback((_) => _popOnce());
                return const SizedBox.shrink();
              }
              if (session.phase == JobPhase.inProgress ||
                  session.phase == JobPhase.completed) {
                WidgetsBinding.instance
                    .addPostFrameCallback((_) => _goToWorkOnce());
                return const SizedBox.shrink();
              }
              final verified = session.phase == JobPhase.otpVerified;
              return Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          child: Text(
                            verified
                                ? 'Step 3 of 4 · Start work'
                                : 'Step 2 of 4 · Enter OTP',
                            key: ValueKey<bool>(verified),
                            style: const TextStyle(
                                color: AppColors.mutedText, fontSize: 12),
                          ),
                        ),
                        const SizedBox(height: 6),
                        _ThinBar(fraction: verified ? 0.66 : 0.5),
                        const SizedBox(height: 12),
                        _JobLine(booking: widget.booking),
                        const SizedBox(height: 10),
                        // ---- One morphing card ----
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                          padding:
                              const EdgeInsets.fromLTRB(16, 18, 16, 16),
                          decoration: BoxDecoration(
                            color: verified
                                ? const Color(0xFFF0FDF4)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: verified
                                  ? const Color(0xFF1E8E3E)
                                      .withValues(alpha: 0.45)
                                  : AppColors.borderSubtle,
                              width: verified ? 1.4 : 1,
                            ),
                          ),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 320),
                            switchInCurve: Curves.easeOutBack,
                            switchOutCurve: Curves.easeIn,
                            transitionBuilder: (child, animation) =>
                                FadeTransition(
                              opacity: animation,
                              child: ScaleTransition(
                                  scale: animation, child: child),
                            ),
                            child: verified
                                ? _VerifiedContent(
                                    key: const ValueKey('verified'))
                                : _OtpContent(
                                    key: const ValueKey('otp'),
                                    controller: _otpController,
                                    focusNode: _otpFocus,
                                    onVerify: _verify,
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, 10 + bottomInset),
                    child: GestureDetector(
                      onTap: verified ? _startWorking : _verify,
                      child: Container(
                        height: 46,
                        decoration: BoxDecoration(
                          color: verified
                              ? const Color(0xFF1E8E3E)
                              : AppColors.brandForest,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          child: Text(
                            verified ? 'Start working' : 'Verify OTP',
                            key: ValueKey<bool>(verified),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ThinBar extends StatelessWidget {
  const _ThinBar({required this.fraction});
  final double fraction;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: fraction),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
      builder: (context, value, _) => Container(
        height: 3,
        decoration: BoxDecoration(
          color: const Color(0xFFEFEDE7),
          borderRadius: BorderRadius.circular(999),
        ),
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: value.clamp(0.0, 1.0),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.brandForest,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
      ),
    );
  }
}

class _JobLine extends StatelessWidget {
  const _JobLine({required this.booking});
  final GigBooking booking;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
                color: booking.skill.color, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Icon(booking.skill.icon,
                color: AppColors.brandForest, size: 19),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(booking.skill.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: AppColors.brandForest,
                        fontSize: 14,
                        fontWeight: FontWeight.w700)),
                Text('${booking.customerName} · ${booking.slotLabel}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: AppColors.mutedText, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OtpContent extends StatelessWidget {
  const _OtpContent(
      {super.key,
      required this.controller,
      required this.focusNode,
      required this.onVerify});

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onVerify;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text('Ask customer for OTP',
            style: TextStyle(
                color: AppColors.brandForest,
                fontSize: 16,
                fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        const Text('4-digit code on their booking screen.',
            style:
                TextStyle(color: AppColors.mutedText, fontSize: 13)),
        const SizedBox(height: 16),
        OtpBoxes(
            focusNode: focusNode,
            controller: controller,
            onCompleted: onVerify),
        const SizedBox(height: 12),
        const Text('Demo: 1234 · any 4 digits work',
            style: TextStyle(
                color: AppColors.mutedText,
                fontSize: 12,
                fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _VerifiedContent extends StatelessWidget {
  const _VerifiedContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Popping green tick.
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.4, end: 1),
          duration: const Duration(milliseconds: 450),
          curve: Curves.elasticOut,
          builder: (context, scale, child) => Transform.scale(
            scale: scale,
            child: Opacity(
              opacity: scale.clamp(0.0, 1.0),
              child: child,
            ),
          ),
          child: Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: Color(0xFF1E8E3E),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(LucideIcons.check,
                size: 26, color: Colors.white),
          ),
        ),
        const SizedBox(height: 10),
        const Text('OTP verified',
            style: TextStyle(
                color: AppColors.brandForest,
                fontSize: 16,
                fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        const Text('Customer confirmed. Press Start to begin.',
            textAlign: TextAlign.center,
            style:
                TextStyle(color: AppColors.mutedText, fontSize: 13)),
      ],
    );
  }
}
