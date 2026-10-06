import 'package:flutter/services.dart';

/// One haptic language for the whole app, mapped by interaction weight:
/// [tick] for state changes (tab switches, chips, steppers), [press] for
/// discrete taps (buttons, tiles, cards), [confirm] for a committed action
/// (booking, payment, OTP submit) and [success] for a finished flow.
class AppHaptics {
  AppHaptics._();

  /// State changed: a tab, chip, segment or stepper moved to a new value.
  static void tick() => HapticFeedback.selectionClick();

  /// Something discrete was tapped: a button, list tile or card.
  static void press() => HapticFeedback.lightImpact();

  /// The user committed to something with consequences: placing a booking,
  /// paying, submitting a code.
  static void confirm() => HapticFeedback.mediumImpact();

  /// A flow finished successfully.
  static void success() => HapticFeedback.heavyImpact();
}
