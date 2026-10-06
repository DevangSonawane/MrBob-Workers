import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/models/job_session.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_haptics.dart';
import 'job_complete_page.dart';

/// S11 — working screen. Timer + job line + finish. No checklist, no scroll.
class InProgressPage extends StatefulWidget {
  const InProgressPage({super.key});

  @override
  State<InProgressPage> createState() => _InProgressPageState();
}

class _InProgressPageState extends State<InProgressPage> {
  Timer? _timer;

  /// Single-flight guards for the two auto-nav exits.
  bool _finishing = false;
  bool _popped = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _finish(JobSession session) {
    if (_finishing) return;
    if (!(ModalRoute.of(context)?.isCurrent ?? false)) return;
    _finishing = true;
    AppHaptics.confirm();
    AppState.instance.completeJob();
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => JobCompletePage(booking: session.booking)),
    ).then((_) {
      if (mounted) _finishing = false;
    });
  }

  void _popOnce() {
    if (_popped || !mounted) return;
    _popped = true;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('Working',
            style: TextStyle(
                color: AppColors.brandForest,
                fontSize: 16,
                fontWeight: FontWeight.w700)),
      ),
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: SafeArea(
          bottom: false,
          child: ValueListenableBuilder<JobSession?>(
            valueListenable: AppState.instance.activeJob,
            builder: (context, session, _) {
              if (session == null) {
                WidgetsBinding.instance.addPostFrameCallback((_) => _popOnce());
                return const SizedBox.shrink();
              }
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Step 3 of 4 · Working',
                            style: TextStyle(
                                color: AppColors.mutedText, fontSize: 12)),
                        const SizedBox(height: 6),
                        Container(
                          height: 3,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFEDE7),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: 0.75,
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.brandForest,
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 18, horizontal: 14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border:
                            Border.all(color: AppColors.borderSubtle),
                      ),
                      child: Column(
                        children: [
                          Text(
                            _formatElapsed(session.elapsed),
                            style: const TextStyle(
                                color: AppColors.brandForest,
                                fontSize: 34,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.8),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${session.booking.skill.title} · ₹${session.booking.payout} on completion',
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: AppColors.mutedText,
                                fontSize: 12.5),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            session.booking.addressLine,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: AppColors.mutedText,
                                fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  Padding(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, 10 + bottomInset),
                    child: GestureDetector(
                      onTap: () => _finish(session),
                      child: Container(
                        height: 46,
                        decoration: BoxDecoration(
                          color: AppColors.brandForest,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: const Text('Mark as complete',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700)),
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

String _formatElapsed(Duration elapsed) {
  final h = elapsed.inHours;
  final m = elapsed.inMinutes.remainder(60);
  final s = elapsed.inSeconds.remainder(60);
  final mm = m.toString().padLeft(2, '0');
  final ss = s.toString().padLeft(2, '0');
  return h > 0 ? '$h:$mm:$ss' : '$mm:$ss';
}
