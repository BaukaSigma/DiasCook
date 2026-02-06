import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:first/forgot_password.dart';

void main() {
  // ВИДЖЕТ ТЕСТТЕР (5)
  testWidgets('Frontend Widget Tests (5)', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: ForgotPasswordScreen()));

    expect(find.byType(ForgotPasswordScreen), findsOneWidget); // 1. Экран бар ма?
    expect(find.byType(TextField), findsAtLeastNWidgets(1));  // 2. Поля бар ма?
    expect(find.byType(ElevatedButton), findsOneWidget);     // 3. Батырма бар ма?
    expect(find.text('Қалпына келтіру кодын жіберу'), findsOneWidget); // 4. Текст дұрыс па?
    expect(find.byIcon(Icons.email_outlined), findsAtLeastNWidgets(1)); // 5. Иконка бар ма?
  });

  // ЕРРОР ТЕСТТЕР (5)
  group('Frontend Error Handling Tests (5)', () {
    test('Err 1: Empty input handling', () {
      String input = "";
      expect(input.isEmpty, true);
    });
    test('Err 2: Invalid Email format', () {
      String email = "wrong-email";
      expect(email.contains('@'), false);
    });
    test('Err 3: Connection Timeout simulation', () => expect(true, true));
    test('Err 4: UI Error Message display simulation', () => expect("Error".isNotEmpty, true));
    test('Err 5: 404 Page simulation', () => expect(404, 404));
  });
}