import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:mrbob_partner/core/data/skills_data.dart';
import 'package:mrbob_partner/core/models/skill.dart';
import 'package:mrbob_partner/core/state/app_state.dart';
import 'package:mrbob_partner/core/theme/app_colors.dart';
import 'package:mrbob_partner/core/utils/app_haptics.dart';
import 'package:mrbob_partner/features/shell/presentation/pages/partner_shell.dart';
import 'package:mrbob_partner/shared/widgets/primary_button.dart';

/// S6 — skills multi-select. Worker picks the services they can
/// perform; only these get booked. Selection is committed to the
/// profile before entering the main shell.
class SkillsSelectPage extends StatefulWidget {
  const SkillsSelectPage({super.key});

  @override
  State<SkillsSelectPage> createState() => _SkillsSelectPageState();
}

class _SkillsSelectPageState extends State<SkillsSelectPage> {
  final Set<String> _selectedIds = <String>{};

  int get _selectedCount => _selectedIds.length;

  void _toggle(Skill skill) {
    AppHaptics.tick();
    setState(() {
      if (!_selectedIds.remove(skill.id)) {
        _selectedIds.add(skill.id);
      }
    });
  }

  void _selectAll() {
    AppHaptics.tick();
    setState(() {
      _selectedIds
        ..clear()
        ..addAll(skills.map((skill) => skill.id));
    });
  }

  void _back() {
    AppHaptics.press();
    Navigator.pop(context);
  }

  void _onContinue() {
    if (_selectedIds.isEmpty) return;
    AppHaptics.success();
    final selectedSkills = skills
        .where((skill) => _selectedIds.contains(skill.id))
        .toList();
    AppState.instance.updateProfile(
      AppState.instance.profile.value.copyWith(skills: selectedSkills),
    );
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const PartnerShell()),
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
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 6),
                child: Row(
                  children: [
                    _BackButton(onTap: _back),
                    const Spacer(),
                    _SelectAllButton(onTap: _selectAll),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'What can you do?',
                        style: TextStyle(
                          color: AppColors.brandForest,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          height: 1.12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Select all the services you can perform. You'll only get bookings for these.",
                        style: TextStyle(
                          color: Color(0xFFB8B8B8),
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          height: 1.22,
                        ),
                      ),
                      const SizedBox(height: 22),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.95,
                        children: [
                          for (final skill in skills)
                            _SkillCard(
                              skill: skill,
                              selected: _selectedIds.contains(skill.id),
                              onTap: () => _toggle(skill),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(20, 10, 20, 10 + bottomInset),
                child: Row(
                  children: [
                    Text(
                      '$_selectedCount selected',
                      style: const TextStyle(
                        color: AppColors.brandForest,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: PrimaryButton(
                        label: 'Continue',
                        enabled: _selectedCount > 0,
                        onTap: _onContinue,
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
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: IconButton(
        onPressed: onTap,
        style: IconButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.brandForest,
          shape: const CircleBorder(),
        ),
        icon: const Icon(LucideIcons.chevronLeft, size: 25),
      ),
    );
  }
}

class _SelectAllButton extends StatelessWidget {
  const _SelectAllButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: AppColors.brandForest,
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
      child: const Text(
        'Select all',
        style: TextStyle(
          color: AppColors.brandForest,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SkillCard extends StatelessWidget {
  const _SkillCard({
    required this.skill,
    required this.selected,
    required this.onTap,
  });

  final Skill skill;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.all(14),
          decoration: selected
              ? BoxDecoration(
                  color: skill.color.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(AppColors.radiusCard),
                  border: Border.all(
                    color: AppColors.brandForest,
                    width: 1.4,
                  ),
                )
              : partnerCardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: skill.color,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      skill.icon,
                      color: AppColors.brandForest,
                      size: 24,
                    ),
                  ),
                  const Spacer(),
                  if (selected)
                    Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: AppColors.brandForest,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        LucideIcons.check,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                skill.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                  height: 1.2,
                  color: AppColors.brandForest,
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: Text(
                  skill.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.mutedText,
                    fontSize: 12.5,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
