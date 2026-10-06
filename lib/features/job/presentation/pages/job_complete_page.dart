import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/models/gig_booking.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_haptics.dart';
import '../../../../shared/widgets/primary_button.dart';

/// S12 — job completion: green scalloped seal,
/// summary, earnings card, optional customer
/// rating and the "Done" CTA.
class JobCompletePage extends StatefulWidget {
  const JobCompletePage({super.key, required this.booking});

  final GigBooking booking;

  @override
  State<JobCompletePage> createState() => _JobCompletePageState();
}

class _JobCompletePageState extends State<JobCompletePage> {
  int _rating = 0;

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    return Scaffold(
      backgroundColor: Colors.white,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: Colors.white,
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                  children: [
                    Center(
                      child: SizedBox(
                        width: 104,
                        height: 104,
                        child: CustomPaint(painter: _SealPainter()),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Center(
                      child: Text(
                        'Job completed!',
                        style: TextStyle(
                          color: AppColors.brandForest,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 26),
                    _SummaryCard(booking: booking),
                    const SizedBox(height: 12),
                    _EarningsCard(booking: booking),
                    const SizedBox(height: 12),
                    _RatingCard(
                      rating: _rating,
                      onRated: (value) {
                        AppHaptics.tick();
                        setState(() => _rating = value);
                      },
                      onSkip: _done,
                    ),
                  ],
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
                  child: PrimaryButton(label: 'Done', onTap: _done),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _done() {
    AppHaptics.success();
    Navigator.popUntil(context, (route) => route.isFirst);
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.booking});

  final GigBooking booking;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: partnerCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: booking.skill.color,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(
                  booking.skill.icon,
                  size: 22,
                  color: AppColors.brandForest,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.skill.title,
                      style: const TextStyle(
                        color: AppColors.brandForest,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'for ${booking.customerName}',
                      style: const TextStyle(
                        color: AppColors.mutedText,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          Row(
            children: [
              const Icon(
                LucideIcons.clock,
                size: 18,
                color: AppColors.brandForest,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Duration worked: ${_durationWorked()}',
                  style: const TextStyle(
                    color: AppColors.brandForest,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(
                  LucideIcons.mapPin,
                  size: 18,
                  color: AppColors.brandForest,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  booking.addressLine,
                  maxLines: 2,
                  style: const TextStyle(
                    color: AppColors.brandForest,
                    fontSize: 13.5,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// The active session's elapsed as "{m} min" or
  /// "{h} hr {m} min"; falls back to the booking's
  /// estimate when no live session matches.
  String _durationWorked() {
    final session = AppState.instance.activeJob.value;
    if (session == null || session.booking.id != booking.id) {
      return booking.durationLabel;
    }
    final elapsed = session.elapsed;
    final hours = elapsed.inHours;
    final minutes = elapsed.inMinutes.remainder(60);
    if (hours > 0) return '$hours hr $minutes min';
    return '${elapsed.inMinutes} min';
  }
}

class _EarningsCard extends StatelessWidget {
  const _EarningsCard({required this.booking});

  final GigBooking booking;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: partnerCardDecoration(),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.brandGold.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(
              LucideIcons.wallet,
              size: 22,
              color: AppColors.brandGold,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '₹${booking.payout}',
                        style: const TextStyle(
                          color: _goldText,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const TextSpan(
                        text: ' added to your earnings',
                        style: TextStyle(
                          color: AppColors.brandForest,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'Moved from pending to available balance',
                  style: TextStyle(
                    color: AppColors.mutedText,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RatingCard extends StatelessWidget {
  const _RatingCard({
    required this.rating,
    required this.onRated,
    required this.onSkip,
  });

  final int rating;
  final ValueChanged<int> onRated;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: partnerCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Rate the customer',
            style: TextStyle(
              color: AppColors.brandForest,
              fontSize: 15,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 3),
          const Text(
            'Optional — helps us improve matches.',
            style: TextStyle(
              color: AppColors.mutedText,
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 1; i <= 5; i++) ...[
                GestureDetector(
                  onTap: () => onRated(i),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: Icon(
                      LucideIcons.star,
                      size: 32,
                      color: i <= rating
                          ? AppColors.brandGold
                          : const Color(0xFFD8D3C8),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onSkip,
              child: const Text(
                'Skip',
                style: TextStyle(
                  color: AppColors.mutedText,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Green scalloped seal with a rounded white check,
/// adapted from the client's red X seal.
class _SealPainter extends CustomPainter {
  const _SealPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final base = size.width / 2;
    const bumps = 22;
    final path = Path();
    for (var i = 0; i <= bumps * 12; i++) {
      final angle = i / (bumps * 12) * 2 * math.pi;
      final radius = base * 0.90 + base * 0.10 * math.sin(angle * bumps);
      final point = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(path, Paint()..color = _sealGreen);

    final arm = base * 0.26;
    final checkPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = base * 0.12
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      center + Offset(-arm, -arm * 0.15),
      center + Offset(-arm * 0.12, arm * 0.72),
      checkPaint,
    );
    canvas.drawLine(
      center + Offset(-arm * 0.12, arm * 0.72),
      center + Offset(arm * 1.05, -arm * 0.72),
      checkPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

const _sealGreen = Color(0xFF2E9E4F);
const _goldText = Color(0xFFB8860B);
