import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const brandGold = Color(0xFFFCB723);
  static const brandForest = Color(0xFF0D230D);
  static const background = Colors.white;
  static const surfaceTint = Color(0xFFFFF7E4);
  // Premium refinement: softer warm-beige, less saturated than old #ECE5D6.
  // Used for card hairlines — always with subtle opacity and paired with
  // soft shadow so the edge feels feathered, not stamped.
  static const border = Color(0xFFE8E3D5);
  // Ultra-subtle hairline for white cards (7-8% forest on white) — the
  // true premium border. Prefer this for Card/BoxDecoration on white.
  static const borderSubtle = Color(0x140D230D);
  static const mutedText = Color(0xFF6B726B);
  // Premium shadow — soft, diffused, barely lifts the card.
  static const cardShadow = Color(0x0F0D230D);

  // Canonical radii for non-input card surfaces.
  static const double radiusCard = 15;
  static const double radiusCardInner = 15;
  static const double radiusPill = 999;
}
