import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/models/gig_worker_profile.dart';
import '../../../../core/models/kyc_document.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_haptics.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../../skills/presentation/pages/skills_select_page.dart';

/// S7 tab 4 — worker profile.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      body: SafeArea(
        bottom: false,
        child: ValueListenableBuilder<GigWorkerProfile>(
          valueListenable: AppState.instance.profile,
          builder: (context, profile, _) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
              children: [
                Text(
                  'Profile',
                  style: TextStyle(
                    color: AppColors.brandForest,
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 26),
                _IdentityCard(profile: profile),
                const SizedBox(height: 20),
                _SkillsCard(profile: profile),
                const SizedBox(height: 20),
                _DocumentsCard(profile: profile),
                const SizedBox(height: 32),
                const _SignOut(),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({required this.profile});

  final GigWorkerProfile profile;

  @override
  Widget build(BuildContext context) {
    final name = profile.name.isEmpty ? 'New worker' : profile.name;
    final phone = profile.phone.isEmpty ? 'Not set' : '+91 ${profile.phone}';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    String kycLabel;
    Color kycColor;
    IconData kycIcon;
    if (profile.kycStatus == KycStatus.verified) {
      kycLabel = 'KYC verified';
      kycColor = const Color(0xFF16A34A);
      kycIcon = LucideIcons.badgeCheck;
    } else if (profile.kycStatus == KycStatus.rejected) {
      kycLabel = 'KYC rejected';
      kycColor = const Color(0xFFDC2626);
      kycIcon = LucideIcons.circleX;
    } else {
      kycLabel = 'KYC pending';
      kycColor = const Color(0xFFD97706);
      kycIcon = LucideIcons.clock;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.brandForest.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                initial,
                style: const TextStyle(
                  color: AppColors.brandForest,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      color: AppColors.brandForest,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    phone,
                    style: const TextStyle(
                      color: AppColors.mutedText,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: kycColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(kycIcon, size: 14, color: kycColor),
                  const SizedBox(width: 6),
                  Text(
                    kycLabel,
                    style: TextStyle(
                      color: kycColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SkillsCard extends StatelessWidget {
  const _SkillsCard({required this.profile});

  final GigWorkerProfile profile;

  void _openPicker(BuildContext context) {
    AppHaptics.press();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SkillsSelectPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Work you do',
                    style: TextStyle(
                      color: AppColors.brandForest,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => _openPicker(context),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.brandForest.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'Change',
                      style: TextStyle(
                        color: AppColors.brandForest,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (profile.skills.isEmpty)
              GestureDetector(
                onTap: () => _openPicker(context),
                behavior: HitTestBehavior.opaque,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    'Nothing picked yet',
                    style: TextStyle(
                      color: AppColors.mutedText,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              )
            else
              GestureDetector(
                onTap: () => _openPicker(context),
                behavior: HitTestBehavior.opaque,
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final skill in profile.skills)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: skill.color,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          skill.title,
                          style: const TextStyle(
                            color: AppColors.brandForest,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DocumentsCard extends StatelessWidget {
  const _DocumentsCard({required this.profile});

  final GigWorkerProfile profile;

  @override
  Widget build(BuildContext context) {
    final doc = profile.kycDocument;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ID you uploaded',
              style: TextStyle(
                color: AppColors.brandForest,
                fontSize: 15,
                fontWeight: FontWeight.w800,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 14),
            if (doc == null)
              const Text(
                'Nothing uploaded',
                style: TextStyle(
                  color: AppColors.mutedText,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F8F8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      doc.type == KycDocType.aadhar
                          ? LucideIcons.idCard
                          : LucideIcons.creditCard,
                      size: 18,
                      color: AppColors.brandForest,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      doc.label,
                      style: const TextStyle(
                        color: AppColors.brandForest,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        doc.maskedNumber,
                        textAlign: TextAlign.end,
                        style: const TextStyle(
                          color: AppColors.mutedText,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SignOut extends StatelessWidget {
  const _SignOut();

  void _signOut(BuildContext context) {
    AppHaptics.confirm();
    AppState.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton(
        onPressed: () => _signOut(context),
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFFDC2626),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
        child: const Text(
          'Sign out',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
