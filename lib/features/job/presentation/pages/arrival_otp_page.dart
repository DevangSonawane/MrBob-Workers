import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/models/gig_booking.dart';
import '../../../../core/models/job_session.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_haptics.dart';
import '../../../../shared/widgets/otp_boxes.dart';
import '../../../../shared/widgets/primary_button.dart';
import 'in_progress_page.dart';

/// S10 — arrived: auto-pops the customer-OTP dialog
/// (demo: any 4 digits pass), then offers the
/// "Start working" CTA once the OTP is verified.
class ArrivalOtpPage extends StatefulWidget {
  const ArrivalOtpPage({super.key, required this.booking});

  final GigBooking booking;

  @override
  State<ArrivalOtpPage> createState() => _ArrivalOtpPageState();
}

class _ArrivalOtpPageState extends State<ArrivalOtpPage> {
  final _otpController = TextEditingController();
  final _otpFocusNode = FocusNode();

  /// Guards the one-shot auto-show of the OTP dialog.
  bool _dialogShown = false;

  /// Guards the one-shot OTP submit — the controller
  /// listener and the keyboard "done" action can
  /// both fire for the same 4-digit entry.
  bool _otpSubmitted = false;

  @override
  void initState() {
    super.initState();
    _otpController.addListener(_handleOtpChanged);
  }

  @override
  void dispose() {
    _otpController.dispose();
    _otpFocusNode.dispose();
    super.dispose();
  }

  /// OtpBoxes locks input at 4 digits — treat that
  /// length as the submit signal.
  void _handleOtpChanged() {
    if (_otpController.text.length == 4) _submitOtp();
  }

  void _submitOtp() {
    if (_otpSubmitted) return;
    _otpSubmitted = true;
    AppHaptics.confirm();
    AppState.instance.verifyOtp();
    Navigator.pop(context);
  }

  void _startWorking() {
    AppHaptics.success();
    AppState.instance.startWorking();
    _openInProgress();
  }

  void _openInProgress() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const InProgressPage()),
    );
  }

  void _showOtpDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: const Text(
              'Verify customer OTP',
              style: TextStyle(
                color: AppColors.brandForest,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ask the customer for the 4-digit code shown on their booking.',
                  style: TextStyle(
                    color: AppColors.mutedText,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                OtpBoxes(
                  focusNode: _otpFocusNode,
                  controller: _otpController,
                  onCompleted: _submitOtp,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceTint,
                    borderRadius: BorderRadius.circular(
                      AppColors.radiusPill,
                    ),
                  ),
                  child: const Text(
                    'Demo OTP: 1234',
                    style: TextStyle(
                      color: _amber,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    // The dialog builds synchronously — focus the OTP field now.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _otpFocusNode.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: Colors.white,
        ),
        child: SafeArea(
          child: ValueListenableBuilder<JobSession?>(
            valueListenable: AppState.instance.activeJob,
            builder: (context, session, _) {
              if (session == null ||
                  session.booking.id != widget.booking.id) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) Navigator.pop(context);
                });
                return const SizedBox.shrink();
              }
              switch (session.phase) {
                case JobPhase.inProgress:
                  // Already working — jump straight to the timer.
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted &&
                        (ModalRoute.of(context)?.isCurrent ?? false)) {
                      _openInProgress();
                    }
                  });
                  return const SizedBox.shrink();
                case JobPhase.completed:
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted &&
                        (ModalRoute.of(context)?.isCurrent ?? false)) {
                      Navigator.pop(context);
                    }
                  });
                  return const SizedBox.shrink();
                case JobPhase.otpVerified:
                  return _VerifiedPanel(
                    booking: widget.booking,
                    onStart: _startWorking,
                  );
                case JobPhase.enroute:
                case JobPhase.arrived:
                case JobPhase.otpPending:
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted && !_dialogShown) {
                      _dialogShown = true;
                      _showOtpDialog();
                    }
                  });
                  return _BookingSummary(booking: widget.booking);
              }
            },
          ),
        ),
      ),
    );
  }
}

/// Booking header shown behind the OTP dialog and
/// under the verified state.
class _BookingSummary extends StatelessWidget {
  const _BookingSummary({required this.booking});

  final GigBooking booking;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: booking.skill.color,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(
                  booking.skill.icon,
                  size: 24,
                  color: AppColors.brandForest,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.skill.title,
                      style: const TextStyle(
                        color: AppColors.brandForest,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                     Text(
                       booking.customerName,
                       maxLines: 1,
                       overflow: TextOverflow.ellipsis,
                       style: const TextStyle(
                         color: AppColors.mutedText,
                         fontSize: 13.5,
                         fontWeight: FontWeight.w500,
                       ),
                     ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(
                  LucideIcons.mapPin,
                  size: 16,
                  color: AppColors.mutedText,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  booking.addressLine,
                  maxLines: 2,
                  style: const TextStyle(
                    color: AppColors.mutedText,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                LucideIcons.clock,
                size: 15,
                color: AppColors.mutedText,
              ),
              const SizedBox(width: 8),
              Text(
                '${booking.slotLabel} • ${booking.durationLabel} visit',
                style: const TextStyle(
                  color: AppColors.mutedText,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VerifiedPanel extends StatelessWidget {
  const _VerifiedPanel({required this.booking, required this.onStart});

  final GigBooking booking;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BookingSummary(booking: booking),
          const Spacer(),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: _green.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(
                  AppColors.radiusPill,
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    LucideIcons.checkCircle,
                    size: 18,
                    color: _green,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'OTP verified',
                    style: TextStyle(
                      color: _green,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
          PrimaryButton(label: 'Start working', onTap: onStart),
        ],
      ),
    );
  }
}

const _amber = Color(0xFFD97706);
const _green = Color(0xFF16A34A);
