// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oxius_native/main.dart';
import 'package:oxius_native/services/user_state_service.dart';

void main() {
  testWidgets('App boot smoke test', (WidgetTester tester) async {
    // Create a mock user state service for testing
    final userState = UserStateService();
    
    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp(userState: userState));

    // MyApp shows a loading UI while user state initializes.
    expect(find.byType(CircularProgressIndicator), findsWidgets);
  });
}
