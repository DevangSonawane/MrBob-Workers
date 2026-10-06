import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/models/gig_booking.dart';
import '../../../../core/models/job_session.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_haptics.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../job/presentation/pages/arrival_otp_page.dart';
import '../../../job/presentation/pages/booking_detail_page.dart';
import '../../../job/presentation/pages/in_progress_page.dart';

/// S7 tab 2 — the live job session (phase chip + deep-link CTA
/// into the right screen for the current phase) above the
/// accepted/completed job history.
class JobsPage extends StatelessWidget {
  const JobsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: ValueListenableBuilder<JobSession?>(
          valueListenable: AppState.instance.activeJob,
          builder: (context, activeJob, _) {
            return ValueListenableBuilder<List<GigBooking>>(
              valueListenable: AppState.instance.bookings,
              builder: (context, bookings, _) {
                final history = AppState.instance.historyBookings;
                if (activeJob == null && history.isEmpty) {
                  return const EmptyState(
                    icon: LucideIcons.briefcase,
                    title: 'No jobs yet',
                    subtitle:
                        'Accept a booking from the Home tab to get started.',
                  );
                }
                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 112),
                  children: [
                    const _Header(),
                    const SizedBox(height: 24),
                    if (activeJob != null) ...[
                      _ActiveJobCard(session: activeJob),
                      const SizedBox(height: 28),
                    ],
                    _HistorySection(bookings: history),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'Jobs',
      style: TextStyle(
        color: AppColors.brandForest,
        fontSize: 23,
        fontWeight: FontWeight.w900,
        letterSpacing: -0.4,
      ),
    );
  }
}

class _ActiveJobCard extends StatelessWidget {
  const _ActiveJobCard({required this.session});

  final JobSession session;

  @override
  Widget build(BuildContext context) {
    final booking = session.booking;
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
                       maxLines: 1,
                       overflow: TextOverflow.ellipsis,
                       style: const TextStyle(
                         color: AppColors.brandForest,
                         fontSize: 16,
                         fontWeight: FontWeight.w800,
                       ),
                     ),
                    const SizedBox(height: 2),
                    Text(
                      booking.customerName,
                      style: const TextStyle(
                        color: AppColors.mutedText,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              _PhaseChip(phase: session.phase),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(
                  LucideIcons.mapPin,
                  size: 15,
                  color: AppColors.mutedText,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  booking.addressLine,
                  maxLines: 2,
                  style: const TextStyle(
                    color: AppColors.mutedText,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          if (session.startedAt != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(
                  LucideIcons.clock,
                  size: 15,
                  color: AppColors.mutedText,
                ),
                const SizedBox(width: 6),
                Text(
                  'Elapsed ${_formatElapsed(session.elapsed)}',
                  style: const TextStyle(
                    color: AppColors.brandForest,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          PrimaryButton(
            label: _ctaLabel(session.phase),
            onTap: () => _openPhase(context, session),
          ),
        ],
      ),
    );
  }

  /// Deep-link into the screen that owns the current phase.
  void _openPhase(BuildContext context, JobSession session) {
    switch (session.phase) {
      case JobPhase.enroute:
      case JobPhase.arrived:
      case JobPhase.completed:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BookingDetailPage(booking: session.booking),
          ),
        );
      case JobPhase.otpPending:
      case JobPhase.otpVerified:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ArrivalOtpPage(booking: session.booking),
          ),
        );
      case JobPhase.inProgress:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const InProgressPage()),
        );
    }
  }
}

String _ctaLabel(JobPhase phase) => switch (phase) {
      JobPhase.enroute || JobPhase.arrived => 'View booking',
      JobPhase.otpPending => 'Verify OTP',
      JobPhase.otpVerified => 'Start working',
      JobPhase.inProgress => 'Continue working',
      JobPhase.completed => 'View details',
    };

(String, Color) _phaseStyle(JobPhase phase) => switch (phase) {
      JobPhase.enroute => ('En route', _amber),
      JobPhase.arrived => ('Arrived', _blue),
      JobPhase.otpPending => ('OTP pending', _orange),
      JobPhase.otpVerified => ('OTP verified', _green),
      JobPhase.inProgress => ('In progress', _blue),
      JobPhase.completed => ('Completed', _green),
    };

class _PhaseChip extends StatelessWidget {
  const _PhaseChip({required this.phase});

  final JobPhase phase;

  @override
  Widget build(BuildContext context) {
    final (label, color) = _phaseStyle(phase);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppColors.radiusPill),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _HistorySection extends StatelessWidget {
  const _HistorySection({required this.bookings});

  final List<GigBooking> bookings;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent jobs',
          style: TextStyle(
            color: AppColors.mutedText,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 14),
        Container(
          decoration: partnerCardDecoration(),
          child: Column(
            children: [
              for (var i = 0; i < bookings.length; i++) ...[
                _HistoryRow(booking: bookings[i]),
                if (i != bookings.length - 1)
                  const Divider(height: 1, color: AppColors.borderSubtle),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.booking});

  final GigBooking booking;

  /// Completed and still-active jobs open the booking detail.
  bool get _canOpen =>
      booking.status == GigBookingStatus.completed || booking.status.isActive;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: booking.skill.color,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              booking.skill.icon,
              size: 20,
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
                   maxLines: 1,
                   overflow: TextOverflow.ellipsis,
                   style: const TextStyle(
                     color: AppColors.brandForest,
                     fontSize: 15,
                     fontWeight: FontWeight.w700,
                   ),
                 ),
                const SizedBox(height: 2),
                Text(
                  booking.customerName,
                  style: const TextStyle(
                    color: AppColors.mutedText,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (booking.status == GigBookingStatus.completed)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Text(
                '₹${_formatAmount(booking.payout)}',
                style: const TextStyle(
                  color: AppColors.brandForest,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          _StatusChip(status: booking.status),
        ],
      ),
    );
    if (!_canOpen) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          AppHaptics.press();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BookingDetailPage(booking: booking),
            ),
          );
        },
        child: content,
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final GigBookingStatus status;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppColors.radiusPill),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

Color _statusColor(GigBookingStatus status) => switch (status) {
      GigBookingStatus.completed => _green,
      GigBookingStatus.inProgress => _blue,
      GigBookingStatus.accepted || GigBookingStatus.arrived => _amber,
      GigBookingStatus.declined => AppColors.mutedText,
      GigBookingStatus.cancelled => _red,
      GigBookingStatus.incoming => AppColors.mutedText,
    };

const _green = Color(0xFF16A34A);
const _blue = Color(0xFF2563EB);
const _amber = Color(0xFFD97706);
const _orange = Color(0xFFEA580C);
const _red = Color(0xFFDC2626);

String _formatAmount(int value) {
  final text = value.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < text.length; i++) {
    if (i > 0 && (text.length - i) % 3 == 0) buffer.write(',');
    buffer.write(text[i]);
  }
  return buffer.toString();
}

String _formatElapsed(Duration elapsed) {
  final hours = elapsed.inHours;
  final minutes = elapsed.inMinutes.remainder(60);
  final seconds = elapsed.inSeconds.remainder(60);
  final mm = minutes.toString().padLeft(2, '0');
  final ss = seconds.toString().padLeft(2, '0');
  return hours > 0 ? '$hours:$mm:$ss' : '$mm:$ss';
}
