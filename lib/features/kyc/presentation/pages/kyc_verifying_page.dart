import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mrbob_partner/features/skills/presentation/pages/skills_select_page.dart';

import '../../../../core/models/gig_worker_profile.dart';
import '../../../../core/models/kyc_document.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_haptics.dart';
import '../../../../shared/widgets/primary_button.dart';
import 'kyc_document_page.dart';

/// Forest-green seal for the verified state (spec: #2E7D32-ish).
const _sealGreen = Color(0xFF2E7D32);

/// Reference-client seal red for the rejected state.
const _sealRed = Color(0xFFCE2E30);

/// S5 — simulated KYC verification: pulsing seal → verified/rejected.
class KycVerifyingPage extends StatefulWidget {
  const KycVerifyingPage({super.key});

  @override
  State<KycVerifyingPage> createState() => _KycVerifyingPageState();
}

class _KycVerifyingPageState extends State<KycVerifyingPage> {
  Timer? _verifyTimer;

  @override
  void initState() {
    super.initState();
    final status = AppState.instance.profile.value.kycStatus;
    // Guard: direct entry without a submitted document — bounce back.
    if (status == KycStatus.notStarted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).pop();
      });
      return;
    }
    if (status == KycStatus.submitted || status == KycStatus.verifying) {
      // Simulated vendor check — auto-approves after ~2.5s (§8).
      _verifyTimer = Timer(const Duration(milliseconds: 2500), () {
        final profile = AppState.instance.profile.value;
        AppState.instance.updateProfile(
          profile.copyWith(kycStatus: KycStatus.verified),
        );
        AppHaptics.success();
      });
    }
  }

  @override
  void dispose() {
    _verifyTimer?.cancel();
    _verifyTimer = null;
    super.dispose();
  }

  void _continueToSkills() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const SkillsSelectPage()),
    );
  }

  void _tryAgain() {
    final profile = AppState.instance.profile.value;
    AppState.instance.updateProfile(
      profile.copyWith(kycStatus: KycStatus.notStarted, clearKycDocument: true),
    );
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const KycDocumentPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.white),
        child: SafeArea(
          child: ValueListenableBuilder<GigWorkerProfile>(
            valueListenable: AppState.instance.profile,
            builder: (context, profile, _) {
              if (profile.kycStatus == KycStatus.verified) {
                return _VerifiedBody(
                  profile: profile,
                  bottomInset: bottomInset,
                  onContinue: _continueToSkills,
                );
              }
              if (profile.kycStatus == KycStatus.rejected) {
                return _RejectedBody(
                  bottomInset: bottomInset,
                  onTryAgain: _tryAgain,
                );
              }
              if (profile.kycStatus == KycStatus.notStarted) {
                return const SizedBox.shrink();
              }
              return _VerifyingBody(profile: profile);
            },
          ),
        ),
      ),
    );
  }
}

class _VerifyingBody extends StatelessWidget {
  const _VerifyingBody({required this.profile});

  final GigWorkerProfile profile;

  @override
  Widget build(BuildContext context) {
    final label = profile.kycDocument?.label ?? 'document';
    final icon = profile.kycDocument?.type == KycDocType.pan
        ? LucideIcons.creditCard
        : LucideIcons.idCard;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(26),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _VerifyingSeal(icon: icon),
            const SizedBox(height: 30),
            Text(
              'Verifying your $label with the database…',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.brandForest,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 20),
            const SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.brandForest,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pulsing document seal while the (simulated) vendor check runs.
class _VerifyingSeal extends StatefulWidget {
  const _VerifyingSeal({required this.icon});

  final IconData icon;

  @override
  State<_VerifyingSeal> createState() => _VerifyingSealState();
}

class _VerifyingSealState extends State<_VerifyingSeal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.9, end: 1.06).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      child: Container(
        width: 104,
        height: 104,
        decoration: BoxDecoration(
          color: AppColors.brandForest.withValues(alpha: 0.07),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Icon(widget.icon, size: 44, color: AppColors.brandForest),
      ),
      builder: (context, child) {
        return Transform.scale(scale: _pulse.value, child: child);
      },
    );
  }
}

class _VerifiedBody extends StatelessWidget {
  const _VerifiedBody({
    required this.profile,
    required this.bottomInset,
    required this.onContinue,
  });

  final GigWorkerProfile profile;
  final double bottomInset;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final doc = profile.kycDocument;
    return Column(
      children: [
        const Spacer(),
        const SizedBox(
          width: 104,
          height: 104,
          child: CustomPaint(
            painter: _SealPainter(color: _sealGreen, mark: _SealMark.check),
          ),
        ),
        const SizedBox(height: 22),
        const Text(
          "You're verified",
          style: TextStyle(
            color: AppColors.brandForest,
            fontSize: 22,
            fontWeight: FontWeight.w900,
            height: 1.12,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Your identity has been verified.',
          style: TextStyle(
            color: AppColors.mutedText,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 26),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 26),
          child: _SummaryCard(document: doc),
        ),
        const Spacer(),
        Padding(
          padding: EdgeInsets.fromLTRB(22, 0, 22, 14 + bottomInset),
          child: PrimaryButton(label: 'Continue', onTap: onContinue),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.document});

  final KycDocument? document;

  @override
  Widget build(BuildContext context) {
    final isPan = document?.type == KycDocType.pan;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: partnerCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isPan ? LucideIcons.creditCard : LucideIcons.idCard,
                size: 22,
                color: AppColors.brandForest,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      document?.label ?? 'Document',
                      style: const TextStyle(
                        color: AppColors.brandForest,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      document?.maskedNumber ?? '',
                      style: const TextStyle(
                        color: AppColors.mutedText,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: AppColors.border),
          ),
          _SummaryRow(label: 'Holder name', value: document?.holderName ?? '—'),
          const SizedBox(height: 10),
          _SummaryRow(label: 'Date of birth', value: document?.dob ?? '—'),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.mutedText,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: AppColors.brandForest,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _RejectedBody extends StatelessWidget {
  const _RejectedBody({required this.bottomInset, required this.onTryAgain});

  final double bottomInset;
  final VoidCallback onTryAgain;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Spacer(),
        const SizedBox(
          width: 104,
          height: 104,
          child: CustomPaint(
            painter: _SealPainter(color: _sealRed, mark: _SealMark.close),
          ),
        ),
        const SizedBox(height: 22),
        const Text(
          'Verification failed',
          style: TextStyle(
            color: AppColors.brandForest,
            fontSize: 22,
            fontWeight: FontWeight.w900,
            height: 1.12,
          ),
        ),
        const SizedBox(height: 8),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            "We couldn't verify this document. Please try again.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.mutedText,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
        ),
        const Spacer(),
        Padding(
          padding: EdgeInsets.fromLTRB(22, 0, 22, 14 + bottomInset),
          child: PrimaryButton(label: 'Try again', onTap: onTryAgain),
        ),
      ],
    );
  }
}

/// Scalloped verification seal — the client `_SealPainter` idea,
/// parameterized with a green check (verified) or red X (rejected).
class _SealPainter extends CustomPainter {
  const _SealPainter({required this.color, required this.mark});

  final Color color;
  final _SealMark mark;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final base = size.width / 2;
    const bumps = 22;
    final path = Path();
    for (var i = 0; i <= bumps * 12; i++) {
      final angle = i / (bumps * 12) * 2 * math.pi;
      final radius = base * 0.90 + base * 0.10 * math.sin(angle * bumps);
      final point = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color);

    final arm = base * 0.24;
    final markPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = base * 0.12
      ..strokeCap = StrokeCap.round;
    if (mark == _SealMark.close) {
      canvas.drawLine(
        center + Offset(-arm, -arm),
        center + Offset(arm, arm),
        markPaint,
      );
      canvas.drawLine(
        center + Offset(-arm, arm),
        center + Offset(arm, -arm),
        markPaint,
      );
    } else {
      canvas.drawLine(
        center + Offset(-arm * 1.15, -arm * 0.05),
        center + Offset(-arm * 0.15, arm * 0.85),
        markPaint,
      );
      canvas.drawLine(
        center + Offset(-arm * 0.15, arm * 0.85),
        center + Offset(arm * 1.15, -arm * 0.75),
        markPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SealPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.mark != mark;
}

enum _SealMark { check, close }
