import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trackedify/views/pages/get_started_page.dart';

void main() {
  Widget buildGetStartedPage() {
    return const MaterialApp(home: GetStartedPage());
  }

  group('GetStartedPage Widget Tests', () {
    testWidgets('renders GetStartedPage elements properly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildGetStartedPage());

      expect(find.text('Almost there'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Get Started'), findsOneWidget);
      expect(find.text('Import Data From DB'), findsOneWidget);
    });

    testWidgets('allows entering username in TextField', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildGetStartedPage());

      final textField = find.byType(TextField);
      await tester.enterText(textField, 'John Doe');
      await tester.pump();

      expect(find.text('John Doe'), findsOneWidget);
    });
  });
}
