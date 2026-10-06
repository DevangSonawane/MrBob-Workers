import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mrbob_partner/main.dart';

void main() {
  testWidgets('root-level text-scale clamp boots without MediaQuery errors',
      (tester) async {
    // Replicates the exact runApp tree from main.dart:
    // MediaQuery.withClampedTextScaling sits ABOVE MaterialApp,
    // with no ambient MediaQuery ancestor.
    await tester.pumpWidget(
      MediaQuery.withClampedTextScaling(
        minScaleFactor: 1.0,
        maxScaleFactor: 1.3,
        child: MrBobPartnerApp(),
      ),
    );
    expect(find.byType(MaterialApp), findsOneWidget);
    await tester.pumpAndSettle();
  });
}
