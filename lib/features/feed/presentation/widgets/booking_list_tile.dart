import 'package:flutter/material.dart';

import '../../../../core/models/gig_booking.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_haptics.dart';
import '../../../../shared/widgets/primary_button.dart';

/// Non-swipeable row for the queued bookings under the swipe
/// card (S8 "Upcoming for you"): skill icon, title + slot,
/// distance/ETA and the payout, right-aligned in forest.
class BookingListTile extends StatelessWidget {
  const BookingListTile({
    super.key,
    required this.booking,
    required this.onTap,
  });

  final GigBooking booking;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        AppHaptics.press();
        onTap();
      },
      child: Container(
        decoration: partnerCardDecoration(),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: booking.skill.color,
                shape: BoxShape.circle,
              ),
              child: Icon(
                booking.skill.icon,
                color: AppColors.brandForest,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    booking.skill.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.brandForest,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    booking.slotLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.mutedText,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${booking.distanceKm.toStringAsFixed(1)} km • ~${booking.etaMinutes} min',
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
            const SizedBox(width: 10),
            Text(
              '₹${booking.payout}',
              style: const TextStyle(
                color: AppColors.brandForest,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
