import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/models/gig_booking.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_haptics.dart';
import '../../../shell/presentation/pages/partner_shell.dart';

/// S12 — done. Compact, fits without scrolling: tick, title,
/// one summary line, earnings line, small rating, Done.
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
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final duration = _durationWorked();
    return Scaffold(
      backgroundColor: Colors.white,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.white),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              const SizedBox(height: 28),
              // Small popping tick.
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.4, end: 1),
                duration: const Duration(milliseconds: 450),
                curve: Curves.elasticOut,
                builder: (context, scale, child) => Transform.scale(
                  scale: scale,
                  child: Opacity(
                    opacity: scale.clamp(0.0, 1.0),
                    child: child,
                  ),
                ),
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1E8E3E),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(LucideIcons.check,
                      size: 30, color: Colors.white),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Job completed',
                style: TextStyle(
                  color: AppColors.brandForest,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${booking.skill.title} · $duration · ₹${booking.payout} earned',
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.mutedText,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: booking.skill.color,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Icon(booking.skill.icon,
                            size: 18, color: AppColors.brandForest),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'for ${booking.customerName}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.brandForest,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              booking.addressLine,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.mutedText,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Inline rating — one row, skippable via Done.
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Rate customer',
                      style: TextStyle(
                          color: AppColors.mutedText,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(width: 10),
                  for (var i = 1; i <= 5; i++)
                    GestureDetector(
                      onTap: () {
                        AppHaptics.tick();
                        setState(() => _rating = i);
                      },
                      child: Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 3),
                        child: Icon(
                          LucideIcons.star,
                          size: 24,
                          color: i <= _rating
                              ? AppColors.brandGold
                              : const Color(0xFFD8D3C8),
                        ),
                      ),
                    ),
                ],
              ),
              const Spacer(),
              Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 10 + bottomInset),
                child: GestureDetector(
                  onTap: _done,
                  child: Container(
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.brandForest,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: const Text('Done',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700)),
                  ),
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
    AppState.instance.clearFinishedJob();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        settings: const RouteSettings(name: PartnerShell.routeName),
        builder: (_) => const PartnerShell(),
      ),
      (_) => false,
    );
  }

  String _durationWorked() {
    final session = AppState.instance.activeJob.value;
    if (session == null || session.booking.id != widget.booking.id) {
      return widget.booking.durationLabel;
    }
    final elapsed = session.elapsed;
    final hours = elapsed.inHours;
    final minutes = elapsed.inMinutes.remainder(60);
    if (hours > 0) return '$hours hr $minutes min';
    final m = elapsed.inMinutes;
    return m <= 1 ? '1 min' : '$m min';
  }
}
