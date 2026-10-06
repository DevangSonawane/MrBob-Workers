import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/app_haptics.dart';

/// Primary forest CTA — the pill button from the client
/// signup flow (52px, radius 999, soft shadow, press scale).
class PrimaryButton extends StatefulWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.enabled = true,
    this.height = 52,
    this.radius = 999,
  });

  final String label;
  final VoidCallback onTap;
  final bool enabled;
  final double height;
  final double radius;

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton> {
  double _scale = 1;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.enabled
          ? () {
              AppHaptics.confirm();
              widget.onTap();
            }
          : null,
      onTapDown: widget.enabled
          ? (_) => setState(() => _scale = 0.97)
          : null,
      onTapUp: widget.enabled
          ? (_) => setState(() => _scale = 1)
          : null,
      onTapCancel: () => setState(() => _scale = 1),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: AnimatedOpacity(
          opacity: widget.enabled ? 1 : 0.35,
          duration: const Duration(milliseconds: 180),
          child: Container(
            height: widget.height,
            decoration: BoxDecoration(
              color: AppColors.brandForest,
              borderRadius: BorderRadius.circular(widget.radius),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.16),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              widget.label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Standard card decoration used across partner screens:
/// white, hairline border, soft shadow.
BoxDecoration partnerCardDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(AppColors.radiusCard),
    border: Border.all(color: AppColors.borderSubtle),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.05),
        blurRadius: 14,
        offset: const Offset(0, 4),
      ),
    ],
  );
}
