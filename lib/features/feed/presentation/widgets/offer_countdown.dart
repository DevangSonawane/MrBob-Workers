import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/models/job_offer.dart';
import '../../../../core/theme/app_colors.dart';

/// Live countdown of an H3 offer — "Offered to you - 52s left".
///
/// Ticks once a second until [JobOffer.expiresAt]. [onExpired] fires once
/// when the offer runs out so the job can leave the list (it may come back
/// later as open to all).
class OfferCountdown extends StatefulWidget {
  const OfferCountdown({
    super.key,
    required this.offer,
    this.onExpired,
    this.compact = false,
  });

  final JobOffer offer;
  final VoidCallback? onExpired;

  /// Renders a bare "52s" label instead of the pill — used in the quiet
  /// rows under "Up next".
  final bool compact;

  @override
  State<OfferCountdown> createState() => _OfferCountdownState();
}

class _OfferCountdownState extends State<OfferCountdown> {
  Timer? _timer;
  late Duration _remaining;
  bool _reportedExpiry = false;

  @override
  void initState() {
    super.initState();
    _remaining = widget.offer.remaining(DateTime.now());
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    final remaining = widget.offer.remaining(DateTime.now());
    if (!mounted) return;
    setState(() => _remaining = remaining);
    if (remaining == Duration.zero && !_reportedExpiry) {
      _reportedExpiry = true;
      widget.onExpired?.call();
    }
  }

  @override
  void didUpdateWidget(covariant OfferCountdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A refreshed poll can hand the same job a new offer.
    if (oldWidget.offer.expiresAt != widget.offer.expiresAt) {
      _remaining = widget.offer.remaining(DateTime.now());
      _reportedExpiry = false;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final seconds = _remaining.inSeconds;
    final urgent = seconds <= 10;
    final color = urgent ? const Color(0xFFEA580C) : AppColors.brandForest;
    if (widget.compact) {
      return Text(
        '${seconds}s left',
        style: TextStyle(
          color: color,
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: urgent
            ? const Color(0xFFEA580C).withValues(alpha: 0.12)
            : AppColors.surfaceTint,
        borderRadius: BorderRadius.circular(AppColors.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.timer, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            'Offered to you - ${seconds}s left',
            style: TextStyle(
              color: color,
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
