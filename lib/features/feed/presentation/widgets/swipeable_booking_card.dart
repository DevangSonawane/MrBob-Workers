import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/models/gig_booking.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/primary_button.dart';

/// Swipeable incoming-booking card (S8). Drag right to
/// accept, left to decline: directional overlays fade in
/// with the drag, and past 120 px (or a 500 px/s flick)
/// the card flies off and fires the matching callback.
/// Below the threshold it springs back (elasticOut).
class SwipeableBookingCard extends StatefulWidget {
  const SwipeableBookingCard({
    super.key,
    required this.booking,
    required this.onAccepted,
    required this.onDeclined,
  });

  final GigBooking booking;
  final VoidCallback onAccepted;
  final VoidCallback onDeclined;

  @override
  State<SwipeableBookingCard> createState() => _SwipeableBookingCardState();
}

class _SwipeableBookingCardState extends State<SwipeableBookingCard>
    with SingleTickerProviderStateMixin {
  static const _threshold = 120.0;
  static const _velocityThreshold = 500.0;

  static const _acceptGreen = Color(0xFF1E8E3E);
  static const _declineRed = Color(0xFFD93025);

  late final AnimationController _flight = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 240),
  )..addListener(() {
      if (mounted) setState(() {});
    });

  Animation<double>? _flightAnimation;
  double _dragDelta = 0;

  double get _offset => _flightAnimation?.value ?? _dragDelta;

  @override
  void dispose() {
    _flight.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (_flight.isAnimating) return;
    setState(() => _dragDelta += details.delta.dx);
  }

  void _onDragEnd(DragEndDetails details) {
    if (_flight.isAnimating) return;
    final velocity = details.velocity.pixelsPerSecond.dx;
    if (_dragDelta > _threshold || velocity > _velocityThreshold) {
      _flyOff(1);
    } else if (_dragDelta < -_threshold || velocity < -_velocityThreshold) {
      _flyOff(-1);
    } else {
      _springBack();
    }
  }

  void _flyOff(int direction) {
    final width = MediaQuery.sizeOf(context).width;
    _flight.duration = const Duration(milliseconds: 200);
    _flightAnimation = Tween<double>(
      begin: _dragDelta,
      end: direction * width * 1.2,
    ).animate(CurvedAnimation(parent: _flight, curve: Curves.easeIn))
      ..addStatusListener((status) {
        if (status != AnimationStatus.completed) return;
        final end = _flightAnimation?.value ?? _dragDelta;
        _flightAnimation = null;
        if (direction > 0) {
          widget.onAccepted();
        } else {
          widget.onDeclined();
        }
        // The action can be blocked (e.g. the user keeps
        // an active job): if we are still mounted, glide
        // back from the fly-off point so the card stays
        // usable.
        if (mounted && _flightAnimation == null) {
          _springBack(end);
        }
      });
    _flight.forward(from: 0);
  }

  void _springBack([double? from]) {
    _flight.duration = const Duration(milliseconds: 460);
    _flightAnimation = Tween<double>(begin: from ?? _dragDelta, end: 0).animate(
      CurvedAnimation(parent: _flight, curve: Curves.elasticOut),
    )..addStatusListener((status) {
        if (status != AnimationStatus.completed) return;
        _flightAnimation = null;
        if (mounted) setState(() => _dragDelta = 0);
      });
    _flight.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final acceptOpacity = (_offset / _threshold).clamp(0.0, 1.0);
    final declineOpacity = (-_offset / _threshold).clamp(0.0, 1.0);
    return Semantics(
      label: '${widget.booking.skill.title} booking, '
          '${widget.booking.distanceKm.toStringAsFixed(1)} km away, '
          'pays ₹${widget.booking.payout}. '
          'Swipe right to accept, left to decline.',
      child: GestureDetector(
        onHorizontalDragUpdate: _onDragUpdate,
        onHorizontalDragEnd: _onDragEnd,
        child: Stack(
          children: [
            Transform.translate(
              offset: Offset(_offset, 0),
              child: _CardContent(booking: widget.booking),
            ),
            if (acceptOpacity > 0.01)
              Positioned.fill(
                child: Opacity(
                  opacity: acceptOpacity,
                  child: _SwipeOverlay(
                    icon: LucideIcons.check,
                    label: 'Release to accept',
                    color: _acceptGreen,
                  ),
                ),
              ),
            if (declineOpacity > 0.01)
              Positioned.fill(
                child: Opacity(
                  opacity: declineOpacity,
                  child: _SwipeOverlay(
                    icon: LucideIcons.x,
                    label: 'Release to decline',
                    color: _declineRed,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Card body — same rhythm as the client booking card:
/// tinted skill icon, title/subtitle, address, distance
/// + ETA, slot chip, prominent payout, customer rating
/// and an italic notes snippet.
class _CardContent extends StatelessWidget {
  const _CardContent({required this.booking});

  final GigBooking booking;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: partnerCardDecoration(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: booking.skill.color,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  booking.skill.icon,
                  color: AppColors.brandForest,
                  size: 26,
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
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      booking.skill.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.mutedText,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '₹${booking.payout}',
                style: const TextStyle(
                  color: AppColors.brandForest,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(LucideIcons.mapPin,
                  size: 14, color: AppColors.mutedText),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  booking.addressLine,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.mutedText,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(LucideIcons.navigation,
                  size: 14, color: AppColors.mutedText),
              const SizedBox(width: 5),
              Text(
                '${booking.distanceKm.toStringAsFixed(1)} km',
                style: const TextStyle(
                  color: AppColors.mutedText,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 12),
              const Icon(LucideIcons.clock,
                  size: 14, color: AppColors.mutedText),
              const SizedBox(width: 5),
              Text(
                '~${booking.etaMinutes} min',
                style: const TextStyle(
                  color: AppColors.mutedText,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              _SlotChip(label: booking.slotLabel),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(LucideIcons.star,
                  size: 14, color: AppColors.brandGold),
              const SizedBox(width: 4),
              Text(
                booking.customerRating.toStringAsFixed(1),
                style: const TextStyle(
                  color: AppColors.brandForest,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  booking.customerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.brandForest,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (booking.notes.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              '"${booking.notes}"',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.mutedText,
                fontSize: 13,
                fontWeight: FontWeight.w400,
                fontStyle: FontStyle.italic,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SlotChip extends StatelessWidget {
  const _SlotChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surfaceTint,
        borderRadius: BorderRadius.circular(AppColors.radiusPill),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: AppColors.brandForest,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Directional full-card overlay revealed while dragging
/// toward that side (green check / red x + hint label).
class _SwipeOverlay extends StatelessWidget {
  const _SwipeOverlay({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppColors.radiusCard),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 40),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
