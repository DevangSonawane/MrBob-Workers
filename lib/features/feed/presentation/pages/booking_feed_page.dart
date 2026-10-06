import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/models/gig_booking.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_haptics.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../job/presentation/pages/booking_detail_page.dart';
import '../widgets/booking_list_tile.dart';
import '../widgets/swipeable_booking_card.dart';

/// S8 — Home: the incoming booking feed. The newest
/// pending booking is a swipeable card (right =
/// accept, left = decline) with explicit fallback
/// buttons below; the rest of the queue lists
/// underneath.
class BookingFeedPage extends StatefulWidget {
  const BookingFeedPage({super.key});

  @override
  State<BookingFeedPage> createState() => _BookingFeedPageState();
}

class _BookingFeedPageState extends State<BookingFeedPage> {
  /// Demo simulation (§8): a fresh booking lands every
  /// ~45s while the feed is visible. AppState caps at
  /// 3 pending internally.
  Timer? _simulationTimer;

  /// Guards against double-accept while the booking
  /// detail page is pushing (§10: disable buttons
  /// during transition).
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _simulationTimer = Timer.periodic(const Duration(seconds: 45), (_) {
      if (mounted) {
        AppState.instance.injectNewBooking();
      }
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
      // §7: only one active job — offer to leave it.
      final leave = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('You have an active job'),
          content: const Text('Leave it and accept this one?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Stay'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Leave & accept'),
            ),
          ],
        ),
      );
      if (leave != true || !mounted) return;
      AppState.instance.cancelActiveJob();
    }
    setState(() => _isNavigating = true);
    AppState.instance.acceptBooking(booking);
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => BookingDetailPage(booking: booking)),
    );
    if (mounted) {
      setState(() => _isNavigating = false);
    }
  }

  void _declineBooking(GigBooking booking) {
    AppHaptics.tick();
    AppState.instance.declineBooking(booking);
  }

  void _openDetail(GigBooking booking) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => BookingDetailPage(booking: booking)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        top: true,
        bottom: false,
        left: false,
        right: false,
        child: ValueListenableBuilder<List<GigBooking>>(
          valueListenable: AppState.instance.bookings,
          builder: (context, bookings, _) {
            final pending = AppState.instance.pendingBookings;
            if (pending.isEmpty) {
              return const EmptyState(
                icon: LucideIcons.inbox,
                title: 'No new bookings right now.',
                subtitle: "We'll notify you when one comes in.",
              );
            }
            final top = pending.first;
            final upcoming = pending.skip(1).toList();
            return ListView(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 88 + bottomInset),
              children: [
                const Text(
                  'Home',
                  style: TextStyle(
                    color: AppColors.brandForest,
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'New bookings near you',
                  style: TextStyle(
                    color: AppColors.mutedText,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 18),
                SwipeableBookingCard(
                  key: ValueKey(top.id),
                  booking: top,
                  onAccepted: () {
                    AppHaptics.confirm();
                    _acceptBooking(top);
                  },
                  onDeclined: () => _declineBooking(top),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: PrimaryButton(
                        label: 'Accept',
                        onTap: () => _acceptBooking(top),
                        enabled: !_isNavigating,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _OutlineButton(
                        label: 'Decline',
                        onTap: () => _declineBooking(top),
                        enabled: !_isNavigating,
                      ),
                    ),
                  ],
                ),
                if (upcoming.isNotEmpty) ...[
                  const SizedBox(height: 26),
                  const Text(
                    'Upcoming for you',
                    style: TextStyle(
                      color: AppColors.brandForest,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  for (final booking in upcoming)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: BookingListTile(
                        key: ValueKey(booking.id),
                        booking: booking,
                        onTap: () => _openDetail(booking),
                      ),
                    ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Outline twin of PrimaryButton — same 52px pill
/// metrics and press scale, hairline border instead
/// of fill. The decline haptic lives in the flow,
/// not the button.
class _OutlineButton extends StatefulWidget {
  const _OutlineButton({
    required this.label,
    required this.onTap,
    this.enabled = true,
  });

  final String label;
  final VoidCallback onTap;
  final bool enabled;

  @override
  State<_OutlineButton> createState() => _OutlineButtonState();
}

class _OutlineButtonState extends State<_OutlineButton> {
  double _scale = 1;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.enabled ? widget.onTap : null,
      onTapDown: widget.enabled ? (_) => setState(() => _scale = 0.97) : null,
      onTapUp: widget.enabled ? (_) => setState(() => _scale = 1) : null,
      onTapCancel: () => setState(() => _scale = 1),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: AnimatedOpacity(
          opacity: widget.enabled ? 1 : 0.35,
          duration: const Duration(milliseconds: 180),
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            alignment: Alignment.center,
            child: Text(
              widget.label,
              style: const TextStyle(
                color: AppColors.brandForest,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
