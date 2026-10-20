import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/models/gig_booking.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_haptics.dart';
import 'offer_countdown.dart';

/// Best-match hero card — big and centered.
///
/// One job, decision-ready: what, when, how far, how much.
/// Actions: Accept (forest) + Decline (red).
///
/// H3 adds two states on top of that:
/// - an active offer shows a live countdown and a Decline button,
/// - a job nobody near took is open to all vendors and shows Accept only.
class JobRequestCard extends StatelessWidget {
  const JobRequestCard({
    super.key,
    required this.booking,
    required this.onAccept,
    required this.onDecline,
    required this.onViewDetails,
    this.isTop = false,
    this.onOfferExpired,
  });

  final GigBooking booking;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final VoidCallback onViewDetails;

  /// Kept for callers; no longer styles differently.
  final bool isTop;

  /// Called when an offer runs out so the job can leave the list.
  final VoidCallback? onOfferExpired;

  @override
  Widget build(BuildContext context) {
    final isAsap = booking.slotLabel.toUpperCase() == 'ASAP';
    final offer = booking.offer;
    return GestureDetector(
      onTap: () {
        AppHaptics.press();
        onViewDetails();
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.borderSubtle),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (offer != null) ...[
              OfferCountdown(offer: offer, onExpired: onOfferExpired),
              const SizedBox(height: 12),
            ] else if (booking.openToAll) ...[
              const _OpenToAllChip(),
              const SizedBox(height: 12),
            ],
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: booking.skill.color,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(
                booking.skill.icon,
                color: AppColors.brandForest,
                size: 30,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              booking.skill.title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.brandForest,
                fontSize: 19,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _metaLine(isAsap),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.mutedText,
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '₹${booking.payout}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.brandForest,
                fontSize: 32,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.8,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(LucideIcons.mapPin,
                    size: 14, color: AppColors.mutedText),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    booking.addressLine,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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
            if (booking.bookingNumber != null) ...[
              const SizedBox(height: 6),
              Text(
                booking.bookingNumber!,
                style: const TextStyle(
                  color: AppColors.mutedText,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _AcceptButton(
                    label: 'Accept · ₹${booking.payout}',
                    onTap: () {
                      AppHaptics.confirm();
                      onAccept();
                    },
                  ),
                ),
                if (offer != null) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: _DeclineButton(
                      onTap: () {
                        AppHaptics.tick();
                        onDecline();
                      },
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// "ASAP · 0.2 km away · ~12 min" — the distance is dropped when the
  /// server has no position for the job or the vendor.
  String _metaLine(bool isAsap) {
    final parts = <String>[
      if (isAsap) 'ASAP' else booking.slotLabel,
      if (booking.distanceKm != null)
        '${booking.distanceKm!.toStringAsFixed(1)} km away',
      if (booking.etaMinutes > 0) '~${booking.etaMinutes} min',
    ];
    return parts.join(' · ');
  }
}

class _OpenToAllChip extends StatelessWidget {
  const _OpenToAllChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.surfaceTint,
        borderRadius: BorderRadius.circular(AppColors.radiusPill),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.globe, size: 14, color: AppColors.brandForest),
          SizedBox(width: 6),
          Text(
            'Open to all vendors',
            style: TextStyle(
              color: AppColors.brandForest,
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _AcceptButton extends StatelessWidget {
  const _AcceptButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: AppColors.brandForest,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _DeclineButton extends StatelessWidget {
  const _DeclineButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: _red.withValues(alpha: 0.09),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: const Text(
          'Decline',
          style: TextStyle(
            color: _red,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

const _red = Color(0xFFDC2626);
