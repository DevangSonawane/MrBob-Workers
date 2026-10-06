import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/models/gig_booking.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_haptics.dart';
import '../../../../shared/widgets/osm_tile_background.dart';
import '../../../../shared/widgets/primary_button.dart';
import 'arrival_otp_page.dart';

/// S9 — booking detail: full OSM map header with the
/// destination pin, then the client-style white sheet
/// (address, how to reach, customer, job summary,
/// earnings) and the sticky "Mark as arrived" CTA.
class BookingDetailPage extends StatelessWidget {
  const BookingDetailPage({super.key, required this.booking});

  final GigBooking booking;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      backgroundColor: Colors.white,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // ---- Map header zone (~45% of screen) ----
              SizedBox(
                height: MediaQuery.sizeOf(context).height * 0.45,
                child: _DestinationMap(booking: booking),
              ),
              // ---- White sheet ----
              Expanded(
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(26),
                    ),
                  ),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                    children: [
                      const Center(
                        child: SizedBox(
                          width: 44,
                          height: 4,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Color(0xFFE0E0E0),
                              borderRadius: BorderRadius.all(
                                Radius.circular(999),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _AddressCard(booking: booking),
                      const SizedBox(height: 12),
                      _DetailCard(
                        child: _ActionRow(
                          icon: LucideIcons.navigation,
                          title: 'How to reach',
                          subtitle: 'Open directions',
                          onTap: () => _openDirections(context),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _CustomerCard(booking: booking),
                      const SizedBox(height: 12),
                      _JobSummaryCard(booking: booking),
                      const SizedBox(height: 12),
                      _DetailCard(
                        child: _ActionRow(
                          icon: LucideIcons.indianRupee,
                          title: 'Earnings',
                          subtitle: 'View payout breakdown',
                          onTap: () => _showPriceSummary(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // ---- Sticky CTA ----
              SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 10, 20, bottomInset),
                  child: PrimaryButton(
                    label: 'Mark as arrived',
                    onTap: () {
                      AppState.instance.markArrived();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ArrivalOtpPage(booking: booking),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Google Maps directions first, `geo:` intent as the
  /// fallback when no browser can handle the URL.
  Future<void> _openDirections(BuildContext context) async {
    final destination = '${booking.latitude},${booking.longitude}';
    final googleMaps = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$destination',
    );
    final geoIntent = Uri.parse('geo:$destination?q=$destination');
    try {
      var launched = false;
      if (await canLaunchUrl(googleMaps)) {
        launched = await launchUrl(
          googleMaps,
          mode: LaunchMode.externalApplication,
        );
      }
      if (!launched && await canLaunchUrl(geoIntent)) {
        launched = await launchUrl(
          geoIntent,
          mode: LaunchMode.externalApplication,
        );
      }
      if (!launched) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No maps app available')),
        );
      }
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open directions')),
      );
    }
  }

  /// Payout breakdown bottom sheet (client pattern):
  /// service charge + platform fee = total paid.
  void _showPriceSummary(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        final inset = MediaQuery.paddingOf(context).bottom;
        return Container(
          padding: EdgeInsets.fromLTRB(20, 14, 20, 18 + inset),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: SizedBox(
                  width: 42,
                  height: 4,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Color(0xFFE0E0E0),
                      borderRadius: BorderRadius.all(Radius.circular(999)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Price summary',
                style: TextStyle(
                  color: AppColors.brandForest,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 14),
              _priceRow('Service charge', '₹${booking.payout}'),
              const SizedBox(height: 10),
              _priceRow('Platform fee', '₹${booking.platformFee}'),
              const Divider(height: 28),
              _priceRow('Total', '₹${booking.totalPaid}', isTotal: true),
            ],
          ),
        );
      },
    );
  }

  Widget _priceRow(String label, String value, {bool isTotal = false}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: isTotal ? AppColors.brandForest : AppColors.mutedText,
              fontSize: isTotal ? 15 : 13.5,
              fontWeight: isTotal ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: AppColors.brandForest,
            fontSize: isTotal ? 16 : 14,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }
}

/// Draggable OSM map centered on the booking destination,
/// with the pin at screen center and overlay controls.
class _DestinationMap extends StatefulWidget {
  const _DestinationMap({required this.booking});

  final GigBooking booking;

  @override
  State<_DestinationMap> createState() => _DestinationMapState();
}

class _DestinationMapState extends State<_DestinationMap> {
  Offset _mapOffset = Offset.zero;

  void _dragMap(DragUpdateDetails details) {
    setState(() {
      _mapOffset += details.delta;
      _mapOffset = Offset(
        _mapOffset.dx.clamp(-180.0, 180.0),
        _mapOffset.dy.clamp(-220.0, 220.0),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    return Stack(
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanUpdate: _dragMap,
          child: OsmTileBackground(
            offset: _mapOffset,
            latitude: booking.latitude,
            longitude: booking.longitude,
          ),
        ),
        // Destination pin at screen center.
        const Center(
          child: MapPinMarker(color: AppColors.brandForest, size: 44),
        ),
        Positioned(
          top: 4,
          left: 12,
          child: _BackButton(
            onTap: () {
              AppHaptics.press();
              Navigator.of(context).pop();
            },
          ),
        ),
        // Distance / ETA chip.
        Positioned(
          left: 14,
          bottom: 14,
          child: _DistanceChip(booking: booking),
        ),
        // Current location (demo: simulated).
        Positioned(
          right: 14,
          bottom: 14,
          child: _CurrentLocationButton(
            onTap: () {
              AppHaptics.press();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Location is simulated in demo')),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      height: 48,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.13),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: IconButton(
          onPressed: onTap,
          icon: const Icon(
            LucideIcons.arrowLeft,
            color: Color(0xFF9C9C9C),
            size: 22,
          ),
        ),
      ),
    );
  }
}

class _DistanceChip extends StatelessWidget {
  const _DistanceChip({required this.booking});

  final GigBooking booking;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppColors.radiusPill),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.13),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            LucideIcons.navigation,
            size: 14,
            color: AppColors.brandForest,
          ),
          const SizedBox(width: 6),
          Text(
            '${booking.distanceKm} km • ~${booking.etaMinutes} min',
            style: const TextStyle(
              color: AppColors.brandForest,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _CurrentLocationButton extends StatelessWidget {
  const _CurrentLocationButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 11, vertical: 9),
          child: Text(
            'Current Location',
            style: TextStyle(
              color: Color(0xFF303030),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({required this.booking});

  final GigBooking booking;

  void _copyAddress(BuildContext context) {
    Clipboard.setData(ClipboardData(text: booking.addressLine));
    AppHaptics.tick();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Address copied')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _DetailCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(
              LucideIcons.mapPin,
              color: AppColors.brandForest,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.addressLine,
                  style: const TextStyle(
                    color: AppColors.brandForest,
                    fontSize: 14,
                    height: 1.42,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Landmark: ${booking.landmark}',
                  style: const TextStyle(
                    color: AppColors.mutedText,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: () => _copyAddress(context),
            borderRadius: BorderRadius.circular(10),
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Icon(
                LucideIcons.copy,
                size: 18,
                color: AppColors.mutedText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  const _CustomerCard({required this.booking});

  final GigBooking booking;

  @override
  Widget build(BuildContext context) {
    return _DetailCard(
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: AppColors.surfaceTint,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  LucideIcons.userRound,
                  color: AppColors.brandForest,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
               Expanded(
                 child: Text(
                   booking.customerName,
                   maxLines: 1,
                   overflow: TextOverflow.ellipsis,
                   style: const TextStyle(
                     color: AppColors.brandForest,
                     fontSize: 15,
                     fontWeight: FontWeight.w800,
                     letterSpacing: -0.2,
                   ),
                 ),
               ),
              const Icon(
                LucideIcons.star,
                color: AppColors.brandGold,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                booking.customerRating.toStringAsFixed(1),
                style: const TextStyle(
                  color: AppColors.brandForest,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          _ActionRow(
            icon: LucideIcons.phone,
            title: 'Call',
            subtitle: 'Call the customer',
            onTap: () => _demoDisabled(context, 'Calling is disabled in demo'),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          _ActionRow(
            icon: LucideIcons.messageCircle,
            title: 'Message',
            subtitle: 'Message the customer',
            onTap: () =>
                _demoDisabled(context, 'Messaging is disabled in demo'),
          ),
        ],
      ),
    );
  }

  void _demoDisabled(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _JobSummaryCard extends StatelessWidget {
  const _JobSummaryCard({required this.booking});

  final GigBooking booking;

  @override
  Widget build(BuildContext context) {
    return _DetailCard(
      child: Column(
        children: [
          Row(
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
                      style: const TextStyle(
                        color: AppColors.brandForest,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      booking.skill.subtitle,
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
                LucideIcons.calendarDays,
                color: AppColors.brandForest,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${booking.slotLabel} • ${booking.durationLabel} visit',
                  style: const TextStyle(
                    color: AppColors.brandForest,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
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
                  LucideIcons.clipboardList,
                  color: AppColors.brandForest,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  booking.notes,
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
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap == null
          ? null
          : () {
              AppHaptics.press();
              onTap!();
            },
      borderRadius: BorderRadius.circular(12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.brandForest, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.brandForest,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.mutedText,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            LucideIcons.chevronRight,
            color: AppColors.mutedText,
            size: 20,
          ),
        ],
      ),
    );
  }
}
