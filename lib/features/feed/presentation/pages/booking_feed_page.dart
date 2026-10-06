import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/models/gig_booking.dart';
import '../../../../core/models/job_session.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_haptics.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../job/presentation/pages/arrival_otp_page.dart';
import '../../../job/presentation/pages/booking_detail_page.dart';
import '../../../job/presentation/pages/in_progress_page.dart';
import '../widgets/job_request_card.dart';

/// S8 — Home. One job at a time.
///
/// Workers felt overwhelmed by a wall of full cards, so the feed
/// now shows a single focus card ("Best match") with Next to
/// browse, and the rest as quiet one-line rows under "Up next".
/// Earnings live on the Earnings tab — Home is only: next action.
class BookingFeedPage extends StatefulWidget {
  const BookingFeedPage({super.key});

  @override
  State<BookingFeedPage> createState() => _BookingFeedPageState();
}

class _BookingFeedPageState extends State<BookingFeedPage> {
  Timer? _simulationTimer;
  bool _isNavigating = false;

  /// Which pending booking is in focus. Indexes into
  /// [AppState.pendingBookings]; clamped on every build.
  int _focusIndex = 0;

  @override
  void initState() {
    super.initState();
    _simulationTimer = Timer.periodic(const Duration(seconds: 45), (_) {
      if (mounted) AppState.instance.injectNewBooking();
    });
  }

  @override
  void dispose() {
    _simulationTimer?.cancel();
    super.dispose();
  }

  Future<void> _acceptBooking(GigBooking booking) async {
    if (_isNavigating) return;
    if (AppState.instance.hasActiveJob) {
      final leave = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Accept this job instead?',
              style: TextStyle(
                  color: AppColors.brandForest,
                  fontSize: 16,
                  fontWeight: FontWeight.w700)),
          content: const Text(
              'You have an active job. It will be cancelled.',
              style: TextStyle(color: AppColors.mutedText, fontSize: 13.5)),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Stay')),
            FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: AppColors.brandForest),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Accept'),
            ),
          ],
        ),
      );
      if (leave != true || !mounted) return;
      AppState.instance.cancelActiveJob();
    }
    setState(() => _isNavigating = true);
    AppState.instance.acceptBooking(booking);
    _focusIndex = 0;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => BookingDetailPage(booking: booking)),
    );
    if (mounted) setState(() => _isNavigating = false);
  }

  void _declineBooking(List<GigBooking> pending, int index) {
    AppHaptics.tick();
    AppState.instance.declineBooking(pending[index]);
    // Keep focus on a valid card after the removal.
    if (pending.length <= 1) {
      _focusIndex = 0;
    } else if (_focusIndex >= pending.length - 1) {
      _focusIndex = 0;
    }
    setState(() {});
  }

  void _focusJob(String id, List<GigBooking> pending) {
    final i = pending.indexWhere((b) => b.id == id);
    if (i < 0 || i == _focusIndex) return;
    AppHaptics.press();
    setState(() => _focusIndex = i);
  }

  void _openDetail(GigBooking booking) {
    AppHaptics.press();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => BookingDetailPage(booking: booking)),
    );
  }

  void _continueJob(JobSession session) {
    AppHaptics.press();
    switch (session.phase) {
      case JobPhase.enroute:
      case JobPhase.arrived:
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => BookingDetailPage(booking: session.booking)),
        );
      case JobPhase.otpPending:
      case JobPhase.otpVerified:
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => ArrivalOtpPage(booking: session.booking)),
        );
      case JobPhase.inProgress:
        Navigator.push(
            context, MaterialPageRoute(builder: (_) => const InProgressPage()));
      case JobPhase.completed:
        break;
    }
  }

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: ValueListenableBuilder<bool>(
          valueListenable: AppState.instance.isOnline,
          builder: (context, isOnline, child) {
            return ValueListenableBuilder<JobSession?>(
              valueListenable: AppState.instance.activeJob,
              builder: (context, activeJob, _) {
                return ValueListenableBuilder<List<GigBooking>>(
                  valueListenable: AppState.instance.bookings,
                  builder: (context, _, child) {
                    final pending = AppState.instance.pendingBookings;
                    final focus = pending.isEmpty
                        ? null
                        : pending[_focusIndex.clamp(0, pending.length - 1)];
                    final rest = focus == null
                        ? const <GigBooking>[]
                        : pending.where((b) => b.id != focus.id).toList();
                    return ListView(
                      padding:
                          EdgeInsets.fromLTRB(16, 10, 16, 100 + bottomInset),
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_greeting,
                                      style: const TextStyle(
                                          color: AppColors.mutedText,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500)),
                                  const SizedBox(height: 1),
                                  ValueListenableBuilder(
                                    valueListenable:
                                        AppState.instance.profile,
                                    builder: (context, profile, _) {
                                      final name = profile.name.isEmpty
                                          ? 'Partner'
                                          : profile.name.split(' ').first;
                                      return Text(name,
                                          style: const TextStyle(
                                              color: AppColors.brandForest,
                                              fontSize: 18,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: -0.3));
                                    },
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(isOnline ? 'Online' : 'Offline',
                                    style: TextStyle(
                                        color: isOnline
                                            ? AppColors.brandForest
                                            : AppColors.mutedText,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600)),
                                const SizedBox(width: 6),
                                Switch.adaptive(
                                  value: isOnline,
                                  activeThumbColor: const Color(0xFF1E8E3E),
                                  onChanged: (v) {
                                    AppHaptics.confirm();
                                    AppState.instance.isOnline.value = v;
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                        if (activeJob != null &&
                            activeJob.phase != JobPhase.completed) ...[
                          const SizedBox(height: 10),
                          _ActiveJobRow(
                            session: activeJob,
                            onContinue: () => _continueJob(activeJob),
                          ),
                        ],
                        const SizedBox(height: 14),
                        if (!isOnline)
                          const EmptyState(
                            icon: LucideIcons.wifiOff,
                            title: "You're offline",
                            subtitle: 'Go online to receive requests.',
                          )
                        else if (focus == null)
                          const EmptyState(
                            icon: LucideIcons.inbox,
                            title: 'No new requests',
                            subtitle:
                                "We'll notify you when one comes in.",
                          )
                        else ...[
                          Row(
                            children: [
                              const Text('Best match',
                                  style: TextStyle(
                                      color: AppColors.brandForest,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800)),
                              const SizedBox(width: 6),
                              if (pending.length > 1)
                                Text(
                                    '${_focusIndex.clamp(0, pending.length - 1) + 1} of ${pending.length}',
                                    style: const TextStyle(
                                        color: AppColors.mutedText,
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w500)),
                            ],
                          ),
                          const SizedBox(height: 2),
                          const Text('One at a time. No rush.',
                              style: TextStyle(
                                  color: AppColors.mutedText,
                                  fontSize: 12.5)),
                          const SizedBox(height: 10),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            transitionBuilder: (child, animation) =>
                                FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0.06, 0),
                                  end: Offset.zero,
                                ).animate(animation),
                                child: child,
                              ),
                            ),
                            child: JobRequestCard(
                              key: ValueKey(focus.id),
                              booking: focus,
                              isTop: true,
                              onAccept: () => _acceptBooking(focus),
                              onDecline: () => _declineBooking(
                                  pending,
                                  pending.indexWhere(
                                      (b) => b.id == focus.id)),
                              onViewDetails: () => _openDetail(focus),
                            ),
                          ),
                          if (rest.isNotEmpty) ...[
                            const SizedBox(height: 14),
                            Text('Up next · ${rest.length}',
                                style: const TextStyle(
                                    color: AppColors.mutedText,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: AppColors.borderSubtle),
                              ),
                              child: Column(
                                children: [
                                  for (var i = 0;
                                      i < rest.length;
                                      i++) ...[
                                    _WaitingRow(
                                      booking: rest[i],
                                      onTap: () => _focusJob(
                                          rest[i].id, pending),
                                    ),
                                    if (i != rest.length - 1)
                                      const Divider(
                                          height: 1,
                                          indent: 12,
                                          endIndent: 12,
                                          color:
                                              AppColors.borderSubtle),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ],
                      ],
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _WaitingRow extends StatelessWidget {
  const _WaitingRow({required this.booking, required this.onTap});

  final GigBooking booking;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: booking.skill.color,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(booking.skill.icon,
                  size: 15, color: AppColors.brandForest),
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
                          fontSize: 13,
                          fontWeight: FontWeight.w700)),
                  Text(
                      '${booking.distanceKm.toStringAsFixed(1)} km · ${booking.slotLabel}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: AppColors.mutedText, fontSize: 11.5)),
                ],
              ),
            ),
            Text('₹${booking.payout}',
                style: const TextStyle(
                    color: AppColors.brandForest,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800)),
            const SizedBox(width: 4),
            const Icon(LucideIcons.chevronRight,
                size: 15, color: AppColors.mutedText),
          ],
        ),
      ),
    );
  }
}

class _ActiveJobRow extends StatelessWidget {
  const _ActiveJobRow({required this.session, required this.onContinue});

  final JobSession session;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final booking = session.booking;
    return GestureDetector(
      onTap: onContinue,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.brandForest, width: 1.2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Active job',
                    style: TextStyle(
                        color: AppColors.mutedText,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600)),
                const Spacer(),
                Text('₹${booking.payout}',
                    style: const TextStyle(
                        color: AppColors.brandForest,
                        fontSize: 15,
                        fontWeight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: 4),
            Text(booking.skill.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: AppColors.brandForest,
                    fontSize: 14,
                    fontWeight: FontWeight.w700)),
            Text(booking.addressLine,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: AppColors.mutedText, fontSize: 12.5)),
            const SizedBox(height: 8),
            _ThinProgress(phase: session.phase),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(_ctaLabel(session.phase),
                    style: const TextStyle(
                        color: AppColors.brandForest,
                        fontSize: 13,
                        fontWeight: FontWeight.w700)),
                const SizedBox(width: 4),
                const Icon(LucideIcons.arrowRight,
                    size: 14, color: AppColors.brandForest),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _ctaLabel(JobPhase phase) => switch (phase) {
        JobPhase.enroute => 'Go to customer',
        JobPhase.arrived || JobPhase.otpPending => 'Enter OTP',
        JobPhase.otpVerified => 'Start work',
        JobPhase.inProgress => 'Continue work',
        JobPhase.completed => 'View details',
      };
}

class _ThinProgress extends StatelessWidget {
  const _ThinProgress({required this.phase});

  final JobPhase phase;

  @override
  Widget build(BuildContext context) {
    final step = switch (phase) {
      JobPhase.enroute => 1,
      JobPhase.arrived || JobPhase.otpPending => 2,
      JobPhase.otpVerified => 3,
      JobPhase.inProgress => 3,
      JobPhase.completed => 4,
    };
    return Row(
      children: [
        for (var i = 1; i <= 4; i++) ...[
          Expanded(
            child: Container(
              height: 3,
              decoration: BoxDecoration(
                color: i <= step
                    ? AppColors.brandForest
                    : const Color(0xFFE8E3D5),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          if (i != 4) const SizedBox(width: 4),
        ],
      ],
    );
  }
}
