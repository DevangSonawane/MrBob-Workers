import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/models/job_session.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_haptics.dart';
import '../../../../shared/widgets/primary_button.dart';
import 'job_complete_page.dart';

/// S11 — the live job: wall-clock elapsed timer
/// (survives pauses), a demo checklist and the
/// "Mark as complete" CTA.
class InProgressPage extends StatefulWidget {
  const InProgressPage({super.key});

  @override
  State<InProgressPage> createState() => _InProgressPageState();
}

class _InProgressPageState extends State<InProgressPage> {
  static const _checklistItems = [
    'Gather tools',
    'Confirm scope with customer',
    'Clean up area',
  ];

  Timer? _timer;
  final List<bool> _checked = [false, false, false];

  @override
  void initState() {
    super.initState();
    // Tick every second; the displayed time is derived
    // from session.elapsed (a wall-clock diff), so it
    // survives app pauses.
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggleItem(int index) {
    AppHaptics.tick();
    setState(() => _checked[index] = !_checked[index]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: Colors.white,
        ),
        child: SafeArea(
          bottom: false,
          child: ValueListenableBuilder<JobSession?>(
            valueListenable: AppState.instance.activeJob,
            builder: (context, session, _) {
              if (session == null) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) Navigator.pop(context);
                });
                return const SizedBox.shrink();
              }
              return Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                      children: [
                        _JobHeader(session: session),
                        const SizedBox(height: 14),
                        _TimerCard(session: session),
                        const SizedBox(height: 14),
                        _ChecklistCard(
                          items: _checklistItems,
                          checked: _checked,
                          onToggle: _toggleItem,
                        ),
                      ],
                    ),
                  ),
                  // Sticky CTA — PrimaryButton fires the
                  // confirm haptic itself.
                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                      child: PrimaryButton(
                        label: 'Mark as complete',
                        onTap: () {
                          AppState.instance.completeJob();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => JobCompletePage(
                                booking: session.booking,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _JobHeader extends StatelessWidget {
  const _JobHeader({required this.session});

  final JobSession session;

  @override
  Widget build(BuildContext context) {
    final booking = session.booking;
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: booking.skill.color,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Icon(
            booking.skill.icon,
            size: 24,
            color: AppColors.brandForest,
          ),
        ),
        const SizedBox(width: 14),
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
                   fontSize: 18,
                   fontWeight: FontWeight.w800,
                   letterSpacing: -0.3,
                 ),
               ),
              const SizedBox(height: 3),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(
                      LucideIcons.mapPin,
                      size: 14,
                      color: AppColors.mutedText,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      booking.addressLine,
                      maxLines: 2,
                      style: const TextStyle(
                        color: AppColors.mutedText,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const _PhaseChip(),
      ],
    );
  }
}

class _PhaseChip extends StatelessWidget {
  const _PhaseChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _blue.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppColors.radiusPill),
      ),
      child: const Text(
        'In progress',
        style: TextStyle(
          color: _blue,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _TimerCard extends StatelessWidget {
  const _TimerCard({required this.session});

  final JobSession session;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
      decoration: partnerCardDecoration(),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                LucideIcons.clock,
                size: 15,
                color: AppColors.mutedText,
              ),
              SizedBox(width: 6),
              Text(
                'Elapsed time',
                style: TextStyle(
                  color: AppColors.mutedText,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _formatElapsed(session.elapsed),
            style: const TextStyle(
              color: AppColors.brandForest,
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChecklistCard extends StatelessWidget {
  const _ChecklistCard({
    required this.items,
    required this.checked,
    required this.onToggle,
  });

  final List<String> items;
  final List<bool> checked;
  final ValueChanged<int> onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: partnerCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Job checklist',
              style: TextStyle(
                color: AppColors.brandForest,
                fontSize: 15,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
          ),
          for (var i = 0; i < items.length; i++) ...[
            _ChecklistRow(
              label: items[i],
              checked: checked[i],
              onTap: () => onToggle(i),
            ),
          ],
        ],
      ),
    );
  }
}

class _ChecklistRow extends StatelessWidget {
  const _ChecklistRow({
    required this.label,
    required this.checked,
    required this.onTap,
  });

  final String label;
  final bool checked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: checked ? AppColors.brandForest : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: checked ? AppColors.brandForest : AppColors.border,
                  width: 1.4,
                ),
              ),
              alignment: Alignment.center,
              child: checked
                  ? const Icon(
                      LucideIcons.check,
                      size: 14,
                      color: Colors.white,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: checked
                      ? AppColors.mutedText
                      : AppColors.brandForest,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  decoration: checked ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// mm:ss, or h:mm:ss once the job passes an hour.
String _formatElapsed(Duration elapsed) {
  final hours = elapsed.inHours;
  final minutes = elapsed.inMinutes.remainder(60);
  final seconds = elapsed.inSeconds.remainder(60);
  final mm = minutes.toString().padLeft(2, '0');
  final ss = seconds.toString().padLeft(2, '0');
  return hours > 0 ? '$hours:$mm:$ss' : '$mm:$ss';
}

const _blue = Color(0xFF2563EB);
