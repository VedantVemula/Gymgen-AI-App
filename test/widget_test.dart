import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Widget test placeholder to validate build', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: Center(child: Text('GymGen AI')))));

    expect(find.text('GymGen AI'), findsOneWidget);
  });
}
