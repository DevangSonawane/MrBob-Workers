import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../models/skill.dart';

/// The 8 services a worker can declare, seeded from the client
/// app's catalog (same titles/subtitles/icons/tints).
const skills = <Skill>[
  Skill(
    id: 'civil',
    title: 'Civil touch-ups',
    subtitle: 'Cracks, plaster chips, hollow patches',
    icon: LucideIcons.construction,
    color: Color(0xFFFFF3D0),
  ),
  Skill(
    id: 'plumbing',
    title: 'Plumbing fixes',
    subtitle: 'Leaks, faucets, traps, low pressure',
    icon: LucideIcons.wrench,
    color: Color(0xFFFFF8E8),
  ),
  Skill(
    id: 'electrical',
    title: 'Electrical snags',
    subtitle: 'Switches, sockets, lights, tripping',
    icon: LucideIcons.zap,
    color: Color(0xFFFFE3A1),
  ),
  Skill(
    id: 'painting',
    title: 'Painting repairs',
    subtitle: 'Patch paint, seepage stains, scuffs',
    icon: LucideIcons.paintRoller,
    color: Color(0xFFF7F3EA),
  ),
  Skill(
    id: 'carpentry',
    title: 'Carpentry fixes',
    subtitle: 'Hinges, drawers, doors, shelves',
    icon: LucideIcons.hammer,
    color: Color(0xFFFFEDBF),
  ),
  Skill(
    id: 'inspection',
    title: 'Deep inspection',
    subtitle: 'Post-handover checklist and estimate',
    icon: LucideIcons.clipboardCheck,
    color: Color(0xFFF4E7C5),
  ),
  Skill(
    id: 'ac',
    title: 'AC servicing',
    subtitle: 'Cooling checks, cleaning, gas diagnosis',
    icon: LucideIcons.snowflake,
    color: Color(0xFFE4F4F6),
  ),
  Skill(
    id: 'appliance',
    title: 'Appliance repair',
    subtitle: 'Washers, ovens, chimneys, small fixes',
    icon: LucideIcons.refrigerator,
    color: Color(0xFFEAF3DE),
  ),
];

Skill skillById(String id) {
  for (final skill in skills) {
    if (skill.id == id) return skill;
  }
  return skills.first;
}

/// Resolves either the app's short service id or the display name returned by
/// the API. The API currently returns a UUID in `service.id`, so callers must
/// also consider `service.name` before choosing a fallback.
Skill? skillByReference(String? value) {
  if (value == null || value.trim().isEmpty) return null;

  final normalized = value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  for (final skill in skills) {
    final id = skill.id.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    final title = skill.title.toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9]'),
      '',
    );
    if (normalized == id || normalized == title) return skill;
  }

  // API catalogue names are not guaranteed to match the partner-app labels.
  if (normalized.contains('appliance')) return skills[7];
  if (normalized.contains('plumb')) return skills[1];
  if (normalized.contains('electric')) return skills[2];
  if (normalized.contains('paint')) return skills[3];
  if (normalized.contains('carpent')) return skills[4];
  if (normalized.contains('inspection')) return skills[5];
  if (normalized == 'ac' || normalized.contains('aircondition')) {
    return skills[6];
  }
  if (normalized.contains('civil') || normalized.contains('mason')) {
    return skills[0];
  }
  return null;
}
