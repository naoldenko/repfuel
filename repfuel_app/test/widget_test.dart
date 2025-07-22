// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:repfuel_app/main.dart';

void main() {
  testWidgets('Sales Trainer App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SalesTrainerApp());

    // Verify that our app title is displayed.
    expect(find.text('Smart Sales Trainer'), findsOneWidget);
    expect(find.text('Select Product Type'), findsOneWidget);
  });
}
