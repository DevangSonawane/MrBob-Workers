import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('root-level text-scale clamp boots without MediaQuery errors',
      (tester) async {
    await tester.pumpWidget(
      MediaQuery.withClampedTextScaling(
        minScaleFactor: 1.0,
        maxScaleFactor: 1.3,
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: Text('Test', style: TextStyle(color: Colors.black)),
            ),
          ),
        ),
      ),
    );
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('Test'), findsOneWidget);
  });
}
