import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:mrbob_partner/core/theme/app_colors.dart';
import 'package:mrbob_partner/shared/widgets/empty_state.dart';
import 'package:mrbob_partner/shared/widgets/primary_button.dart';

void main() {
  testWidgets('EmptyState renders title and subtitle', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: EmptyState(
            icon: LucideIcons.inbox,
            title: 'No new bookings right now.',
            subtitle: "We'll notify you when one comes in.",
          ),
        ),
      ),
    );

    expect(find.text('No new bookings right now.'), findsOneWidget);
    expect(
      find.text("We'll notify you when one comes in."),
      findsOneWidget,
    );
    expect(find.byIcon(LucideIcons.inbox), findsOneWidget);
  });

  testWidgets('PrimaryButton fires onTap and shows label', (tester) async {
    var tapped = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PrimaryButton(
            label: 'Mark as arrived',
            onTap: () => tapped++,
          ),
        ),
      ),
    );

    expect(find.text('Mark as arrived'), findsOneWidget);
    await tester.tap(find.text('Mark as arrived'));
    await tester.pump();
    expect(tapped, 1);
  });

  testWidgets('PrimaryButton is disabled when enabled is false', (tester) async {
    var tapped = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PrimaryButton(
            label: 'Continue',
            enabled: false,
            onTap: () => tapped++,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Continue'));
    await tester.pump();
    expect(tapped, 0);
  });

  test('partnerCardDecoration uses the design tokens', () {
    final decoration = partnerCardDecoration();
    expect(decoration.color, Colors.white);
    expect(
      (decoration.border as Border).top.color,
      AppColors.borderSubtle,
    );
  });
}
