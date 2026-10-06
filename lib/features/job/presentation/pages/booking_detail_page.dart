import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/models/gig_booking.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_haptics.dart';
import '../../../../shared/widgets/osm_tile_background.dart';
import 'arrival_otp_page.dart';
import 'in_progress_page.dart';

/// S9 — booking detail. Compact: small map, plain rows, one action bar.
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
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _MapHeader(booking: booking),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: _TitleRow(booking: booking),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: _StepLine(current: 1),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                      child: _Card(
                        child: _AddressLines(booking: booking),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: _Card(child: _CustomerRow(booking: booking)),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: _Card(child: _NotesLines(booking: booking)),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: _Card(child: _EarningsLines(booking: booking)),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 10 + bottomInset),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                      top: BorderSide(color: AppColors.borderSubtle)),
                ),
                child: Row(
                  children: [
                    _OutlineAction(
                      icon: LucideIcons.navigation,
                      label: 'Navigate',
                      onTap: () => _openDirections(context),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _onPrimary(context),
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.brandForest,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text(_ctaLabel(),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _ctaLabel() {
    return switch (booking.status) {
      GigBookingStatus.accepted => 'I have arrived',
      GigBookingStatus.arrived => 'Enter OTP',
      GigBookingStatus.inProgress => 'Continue work',
      GigBookingStatus.completed => 'View completion',
      _ => 'I have arrived',
    };
  }

  void _onPrimary(BuildContext context) {
    AppHaptics.confirm();
    final active = AppState.instance.activeJob.value;
    final isActiveBooking =
        active != null && active.booking.id == booking.id;
    if (booking.status == GigBookingStatus.accepted ||
        (!isActiveBooking && booking.status == GigBookingStatus.incoming)) {
      if (!isActiveBooking) AppState.instance.acceptBooking(booking);
      AppState.instance.markArrived();
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => ArrivalOtpPage(booking: booking)));
    } else if (booking.status == GigBookingStatus.arrived) {
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => ArrivalOtpPage(booking: booking)));
    } else if (booking.status == GigBookingStatus.inProgress) {
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => const InProgressPage()));
    } else {
      AppState.instance.markArrived();
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => ArrivalOtpPage(booking: booking)));
    }
  }

  Future<void> _openDirections(BuildContext context) async {
    AppHaptics.press();
    final destination = '${booking.latitude},${booking.longitude}';
    final googleMaps = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$destination');
    final geoIntent = Uri.parse('geo:$destination?q=$destination');
    try {
      var launched = false;
      if (await canLaunchUrl(googleMaps)) {
        launched = await launchUrl(googleMaps,
            mode: LaunchMode.externalApplication);
      }
      if (!launched && await canLaunchUrl(geoIntent)) {
        launched =
            await launchUrl(geoIntent, mode: LaunchMode.externalApplication);
      }
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No maps app available')));
      }
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open directions')));
    }
  }
}

class _MapHeader extends StatefulWidget {
  const _MapHeader({required this.booking});
  final GigBooking booking;

  @override
  State<_MapHeader> createState() => _MapHeaderState();
}

class _MapHeaderState extends State<_MapHeader> {
  Offset _offset = Offset.zero;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: Stack(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanUpdate: (d) => setState(() {
              _offset += d.delta;
              _offset = Offset(_offset.dx.clamp(-180, 180),
                  _offset.dy.clamp(-220, 220));
            }),
            child: OsmTileBackground(
              offset: _offset,
              latitude: widget.booking.latitude,
              longitude: widget.booking.longitude,
            ),
          ),
          const Center(
              child: MapPinMarker(color: AppColors.brandForest, size: 36)),
          Positioned(
            top: 10,
            left: 12,
            child: GestureDetector(
              onTap: () {
                AppHaptics.press();
                Navigator.pop(context);
              },
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: const Icon(LucideIcons.arrowLeft,
                    size: 18, color: AppColors.brandForest),
              ),
            ),
          ),
          Positioned(
            left: 12,
            bottom: 10,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Text(
                '${widget.booking.distanceKm} km · ~${widget.booking.etaMinutes} min',
                style: const TextStyle(
                    color: AppColors.brandForest,
                    fontSize: 12,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TitleRow extends StatelessWidget {
  const _TitleRow({required this.booking});
  final GigBooking booking;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
              color: booking.skill.color, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Icon(booking.skill.icon,
              color: AppColors.brandForest, size: 20),
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
                      fontSize: 15,
                      fontWeight: FontWeight.w700)),
              Text('${booking.slotLabel} · ${booking.durationLabel}',
                  style: const TextStyle(
                      color: AppColors.mutedText, fontSize: 12)),
            ],
          ),
        ),
        Text('₹${booking.payout}',
            style: const TextStyle(
                color: AppColors.brandForest,
                fontSize: 18,
                fontWeight: FontWeight.w800)),
      ],
    );
  }
}

class _StepLine extends StatelessWidget {
  const _StepLine({required this.current});
  final int current;

  @override
  Widget build(BuildContext context) {
    const labels = ['Accepted', 'Arrived', 'Work', 'Done'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Step $current of 4 · ${labels[current - 1]}',
            style: const TextStyle(
                color: AppColors.mutedText,
                fontSize: 12,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        Row(
          children: [
            for (var i = 1; i <= 4; i++) ...[
              Expanded(
                child: Container(
                  height: 3,
                  decoration: BoxDecoration(
                    color: i <= current
                        ? AppColors.brandForest
                        : const Color(0xFFE8E3D5),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              if (i != 4) const SizedBox(width: 4),
            ],
          ],
        ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: child,
    );
  }
}

class _AddressLines extends StatelessWidget {
  const _AddressLines({required this.booking});
  final GigBooking booking;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(booking.addressLine,
            style: const TextStyle(
                color: AppColors.brandForest,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                height: 1.4)),
        const SizedBox(height: 2),
        Text('Landmark: ${booking.landmark}',
            style: const TextStyle(
                color: AppColors.mutedText, fontSize: 12)),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () {
            Clipboard.setData(ClipboardData(text: booking.addressLine));
            AppHaptics.tick();
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Address copied')));
          },
          child: const Text('Copy address',
              style: TextStyle(
                  color: AppColors.brandForest,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}

class _CustomerRow extends StatelessWidget {
  const _CustomerRow({required this.booking});
  final GigBooking booking;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor:
              AppColors.brandForest.withValues(alpha: 0.07),
          child: Text(
              booking.customerName.isNotEmpty
                  ? booking.customerName[0].toUpperCase()
                  : 'C',
              style: const TextStyle(
                  color: AppColors.brandForest,
                  fontSize: 15,
                  fontWeight: FontWeight.w700)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(booking.customerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: AppColors.brandForest,
                      fontSize: 14,
                      fontWeight: FontWeight.w700)),
              Text(
                  '${booking.customerRating.toStringAsFixed(1)} rated',
                  style: const TextStyle(
                      color: AppColors.mutedText, fontSize: 12)),
            ],
          ),
        ),
        GestureDetector(
          onTap: () {
            AppHaptics.press();
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Calling is disabled in demo')));
          },
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.phone,
                    size: 14, color: AppColors.brandForest),
                SizedBox(width: 5),
                Text('Call',
                    style: TextStyle(
                        color: AppColors.brandForest,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _NotesLines extends StatelessWidget {
  const _NotesLines({required this.booking});
  final GigBooking booking;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(booking.skill.subtitle,
            style: const TextStyle(
                color: AppColors.brandForest,
                fontSize: 13.5,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 3),
        Text(booking.notes,
            style: const TextStyle(
                color: AppColors.mutedText,
                fontSize: 13,
                height: 1.4)),
      ],
    );
  }
}

class _EarningsLines extends StatelessWidget {
  const _EarningsLines({required this.booking});
  final GigBooking booking;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _row('Service charge', '₹${booking.payout}'),
        const SizedBox(height: 4),
        _row('Platform fee', '₹${booking.platformFee}'),
        const Divider(height: 18),
        _row('You get', '₹${booking.payout}', total: true),
      ],
    );
  }

  Widget _row(String l, String v, {bool total = false}) {
    return Row(
      children: [
        Expanded(
            child: Text(l,
                style: TextStyle(
                    color: total
                        ? AppColors.brandForest
                        : AppColors.mutedText,
                    fontSize: total ? 13.5 : 13,
                    fontWeight:
                        total ? FontWeight.w700 : FontWeight.w500))),
        Text(v,
            style: TextStyle(
                color: AppColors.brandForest,
                fontSize: total ? 16 : 13.5,
                fontWeight: FontWeight.w800)),
      ],
    );
  }
}

class _OutlineAction extends StatelessWidget {
  const _OutlineAction(
      {required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: AppColors.brandForest),
            const SizedBox(width: 5),
            Text(label,
                style: const TextStyle(
                    color: AppColors.brandForest,
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
