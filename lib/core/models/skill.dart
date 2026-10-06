import 'package:flutter/material.dart';

/// A service a gig worker can perform. Seeded from the client app's
/// service catalog so both apps share vocabulary (titles, subtitles,
/// icons, tint colors).
class Skill {
  const Skill({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
}
