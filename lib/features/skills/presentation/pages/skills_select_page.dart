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

const _pageBg = Color(0xFFFAF9F6);
const _selectedTint = Color(0xFFEDF4ED);

/// S6 — "What work can you do?"
///
/// Clean, single-screen picker: one heading, a 2-column grid of
/// selectable cards, and one pinned CTA. No step counter, no nag
/// banner — the CTA itself carries the state.
///
/// Edit-aware: when opened from Profile (skills already saved)
/// it pre-selects and just pops on save instead of pushing Shell.
class SkillsSelectPage extends StatefulWidget {
  const SkillsSelectPage({super.key});

  @override
  State<SkillsSelectPage> createState() => _SkillsSelectPageState();
}

class _SkillsSelectPageState extends State<SkillsSelectPage> {
  late final Set<String> _selectedIds;
  late final bool _isEditMode;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final saved = AppState.instance.profile.value.skills;
      _isEditMode = saved.isNotEmpty;
      _selectedIds = {for (final s in saved) s.id};
      _initialized = true;
    }
  }

  void _toggle(Skill skill) {
    AppHaptics.tick();
    setState(() {
      if (!_selectedIds.remove(skill.id)) _selectedIds.add(skill.id);
    });
  }

  void _toggleAll() {
    AppHaptics.tick();
    setState(() {
      if (_selectedIds.length == skills.length) {
        _selectedIds.clear();
      } else {
        _selectedIds.addAll(skills.map((s) => s.id));
      }
    });
  }

  void _onContinue() {
    if (_selectedIds.isEmpty) return;
    AppHaptics.success();
    final selected =
        skills.where((s) => _selectedIds.contains(s.id)).toList();
    AppState.instance.updateProfile(
      AppState.instance.profile.value.copyWith(skills: selected),
    );
    if (_isEditMode && Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          settings: const RouteSettings(name: PartnerShell.routeName),
          builder: (_) => const PartnerShell(),
        ),
      );
    }
  }

  String _ctaLabel(int count) {
    if (_isEditMode) {
      return count == 0 ? 'Save changes' : 'Save changes · $count selected';
    }
    return count == 0 ? 'Continue' : 'Continue · $count selected';
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final count = _selectedIds.length;
    final allSelected = count == skills.length;

    return Scaffold(
      backgroundColor: _pageBg,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: _pageBg,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // ---- Top bar: back + a single quiet action ----
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 6, 8, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        AppHaptics.press();
                        Navigator.maybePop(context);
                      },
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.borderSubtle),
                        ),
                        child: const Icon(LucideIcons.arrowLeft,
                            size: 20, color: AppColors.brandForest),
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _toggleAll,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                        child: Text(
                          allSelected ? 'Clear all' : 'Select all',
                          style: const TextStyle(
                            color: AppColors.brandForest,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            decoration: TextDecoration.underline,
                            decorationColor: AppColors.border,
                            decorationThickness: 2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ---- Heading ----
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 4, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'What work can you do?',
                      style: TextStyle(
                        color: AppColors.brandForest,
                        fontSize: 27,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                        letterSpacing: -0.6,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Pick everything you can handle.',
                      style: TextStyle(
                        color: AppColors.mutedText,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              // ---- Grid ----
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  physics: const BouncingScrollPhysics(),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    mainAxisExtent: 140,
                  ),
                  itemCount: skills.length,
                  itemBuilder: (context, index) {
                    final skill = skills[index];
                    return _SkillCard(
                      skill: skill,
                      selected: _selectedIds.contains(skill.id),
                      onTap: () => _toggle(skill),
                    );
                  },
                ),
              ),

              // ---- Fade so the grid dissolves into the CTA bar ----
              IgnorePointer(
                child: Container(
                  height: 20,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x00FAF9F6), _pageBg],
                    ),
                  ),
                ),
              ),

              // ---- Pinned CTA ----
              Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(color: AppColors.borderSubtle),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x0A0D230D),
                      blurRadius: 16,
                      offset: Offset(0, -4),
                    ),
                  ],
                ),
                padding: EdgeInsets.fromLTRB(20, 14, 20, 14 + bottomInset),
                child: PrimaryButton(
                  label: _ctaLabel(count),
                  height: 56,
                  enabled: count > 0,
                  onTap: _onContinue,
                ),
              ),
            ],
          ),
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
      label: '${skill.title}. ${skill.subtitle}',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
          decoration: BoxDecoration(
            color: selected ? _selectedTint : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? AppColors.brandForest : AppColors.borderSubtle,
              width: selected ? 1.6 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: selected ? 0.07 : 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: skill.color,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Icon(skill.icon,
                        color: AppColors.brandForest, size: 19),
                  ),
                  const Spacer(),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: selected ? AppColors.brandForest : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected
                            ? AppColors.brandForest
                            : const Color(0xFFD8D3C8),
                        width: 1.6,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: selected
                        ? const Icon(LucideIcons.check,
                            size: 13, color: Colors.white)
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                skill.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.brandForest,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 3),
              Expanded(
                child: Text(
                  skill.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.mutedText,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    height: 1.25,
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
