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
