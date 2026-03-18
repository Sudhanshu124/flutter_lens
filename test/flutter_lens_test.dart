import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_lens/flutter_lens.dart';

void main() {
  testWidgets('FlutterLens wraps child widget', (WidgetTester tester) async {
    // Build FlutterLens with a simple child
    await tester.pumpWidget(
      const FlutterLens(
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: Text('Test'),
            ),
          ),
        ),
      ),
    );

    // Verify the child is rendered
    expect(find.text('Test'), findsOneWidget);
  });

  testWidgets('FlutterLens can be disabled', (WidgetTester tester) async {
    await tester.pumpWidget(
      const FlutterLens(
        enabled: false,
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: Text('Disabled'),
            ),
          ),
        ),
      ),
    );

    // Verify the child is still rendered when disabled
    expect(find.text('Disabled'), findsOneWidget);
  });

  test('InspectionTrigger enum has expected values', () {
    expect(InspectionTrigger.values.length, 2);
    expect(InspectionTrigger.values, contains(InspectionTrigger.tap));
    expect(InspectionTrigger.values, contains(InspectionTrigger.longPress));
  });
}
