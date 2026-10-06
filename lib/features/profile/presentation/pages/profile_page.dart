import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/models/gig_worker_profile.dart';
import '../../../../core/models/kyc_document.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_haptics.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../../skills/presentation/pages/skills_select_page.dart';

/// S7 tab 4 — worker profile: identity card with KYC badge,
/// declared skills, KYC documents, demo tools and sign out.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: ValueListenableBuilder<GigWorkerProfile>(
          valueListenable: AppState.instance.profile,
          builder: (context, profile, _) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 112),
              children: [
                const _Header(),
                const SizedBox(height: 24),
                _ProfileCard(profile: profile),
                const SizedBox(height: 24),
                _SkillsSection(profile: profile),
                const SizedBox(height: 24),
                _DocumentsSection(profile: profile),
                const SizedBox(height: 24),
                _DemoToolsSection(profile: profile),
                const SizedBox(height: 24),
                const _SignOutRow(),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'Profile',
      style: TextStyle(
        color: AppColors.brandForest,
        fontSize: 23,
        fontWeight: FontWeight.w900,
        letterSpacing: -0.4,
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.profile});

  final GigWorkerProfile profile;

  @override
  Widget build(BuildContext context) {
    final name = profile.name.isEmpty ? 'New worker' : profile.name;
    final phone = profile.phone.isEmpty ? 'Not set' : '+91 ${profile.phone}';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: partnerCardDecoration(),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.brandForest.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  LucideIcons.user,
                  size: 30,
                  color: AppColors.brandForest,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                     Text(
                       name,
                       maxLines: 1,
                       overflow: TextOverflow.ellipsis,
                       style: const TextStyle(
                         color: AppColors.brandForest,
                         fontSize: 18,
                         fontWeight: FontWeight.w800,
                       ),
                     ),
                    const SizedBox(height: 4),
                    Text(
                      phone,
                      style: const TextStyle(
                        color: AppColors.mutedText,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      profile.gender,
                      style: const TextStyle(
                        color: AppColors.mutedText,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: _KycBadge(status: profile.kycStatus),
          ),
        ],
      ),
    );
  }
}

(String, Color, IconData) _kycStyle(KycStatus status) => switch (status) {
      KycStatus.verified => ('KYC Verified', _green, LucideIcons.badgeCheck),
      KycStatus.rejected => ('KYC Rejected', _red, LucideIcons.circleX),
      KycStatus.notStarted ||
      KycStatus.inProgress ||
      KycStatus.submitted ||
      KycStatus.verifying =>
        ('KYC Pending', _amber, LucideIcons.circleAlert),
    };

class _KycBadge extends StatelessWidget {
  const _KycBadge({required this.status});

  final KycStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = _kycStyle(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppColors.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SkillsSection extends StatelessWidget {
  const _SkillsSection({required this.profile});

  final GigWorkerProfile profile;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Skills',
                style: TextStyle(
                  color: AppColors.mutedText,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                AppHaptics.press();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SkillsSelectPage(),
                  ),
                );
              },
              style: TextButton.styleFrom(
                foregroundColor: AppColors.brandForest,
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Edit',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (profile.skills.isEmpty)
          const Text(
            'No skills selected',
            style: TextStyle(
              color: AppColors.mutedText,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final skill in profile.skills)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: skill.color,
                    borderRadius: BorderRadius.circular(AppColors.radiusPill),
                  ),
                  child: Text(
                    skill.title,
                    style: const TextStyle(
                      color: AppColors.brandForest,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

class _DocumentsSection extends StatelessWidget {
  const _DocumentsSection({required this.profile});

  final GigWorkerProfile profile;

  @override
  Widget build(BuildContext context) {
    final doc = profile.kycDocument;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Documents',
          style: TextStyle(
            color: AppColors.mutedText,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: partnerCardDecoration(),
          child: doc == null
              ? const Text(
                  'No documents uploaded',
                  style: TextStyle(
                    color: AppColors.mutedText,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                )
              : Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.brandForest.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        doc.type == KycDocType.aadhar
                            ? LucideIcons.idCard
                            : LucideIcons.creditCard,
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
                            doc.label,
                            style: const TextStyle(
                              color: AppColors.brandForest,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            doc.maskedNumber,
                            style: const TextStyle(
                              color: AppColors.mutedText,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            doc.holderName,
                            style: const TextStyle(
                              color: AppColors.mutedText,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _DemoToolsSection extends StatelessWidget {
  const _DemoToolsSection({required this.profile});

  final GigWorkerProfile profile;

  void _injectBooking(BuildContext context) {
    AppHaptics.press();
    final booking = AppState.instance.injectNewBooking();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          booking == null ? 'Feed is full (3 pending)' : 'New booking added to feed',
        ),
        backgroundColor: AppColors.brandForest,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _simulateKycRejection(BuildContext context) {
    AppHaptics.press();
    AppState.instance.updateProfile(
      profile.copyWith(kycStatus: KycStatus.rejected),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('KYC marked rejected (demo)'),
        backgroundColor: AppColors.brandForest,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Demo tools',
          style: TextStyle(
            color: AppColors.mutedText,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: partnerCardDecoration(),
          child: Column(
            children: [
              _DemoRow(
                icon: LucideIcons.bell,
                title: 'New booking',
                onTap: () => _injectBooking(context),
              ),
              const Divider(height: 1, color: AppColors.borderSubtle),
              _DemoRow(
                icon: LucideIcons.alertTriangle,
                title: 'Simulate KYC rejection',
                onTap: () => _simulateKycRejection(context),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DemoRow extends StatelessWidget {
  const _DemoRow({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 15, 14, 15),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                  color: AppColors.brandForest,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 18, color: Colors.white),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.brandForest,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Icon(
                LucideIcons.chevronRight,
                size: 20,
                color: AppColors.mutedText,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SignOutRow extends StatelessWidget {
  const _SignOutRow();

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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _signOut(context),
        borderRadius: BorderRadius.circular(AppColors.radiusCard),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          decoration: BoxDecoration(
            color: _red.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(AppColors.radiusCard),
            border: Border.all(color: _red.withValues(alpha: 0.18)),
          ),
          child: Row(
            children: [
              const Icon(
                LucideIcons.logOut,
                size: 20,
                color: _red,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Sign out',
                  style: TextStyle(
                    color: _red,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Icon(
                LucideIcons.chevronRight,
                size: 20,
                color: _red.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

const _green = Color(0xFF16A34A);
const _amber = Color(0xFFD97706);
const _red = Color(0xFFDC2626);
