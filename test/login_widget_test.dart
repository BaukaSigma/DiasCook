import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:first/login.dart';

void main() {
  testWidgets('Кіру бетіндегі валидация тесті', (WidgetTester tester) async {
    // 1. Экранды жүктейміз
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

    // 2. Email мен Пароль өрістерін табамыз
    final emailField = find.byType(TextField).at(0);
    final passwordField = find.byType(TextField).at(1);
    final loginButton = find.byType(ElevatedButton);

    // 3. Қате деректерді енгіземіз
    await tester.enterText(emailField, 'қате-email');
    await tester.enterText(passwordField, ''); // Бос пароль
    
    // 4. Батырманы басамыз
    await tester.tap(loginButton);
    await tester.pump(); // Экранның жаңаруын күтеміз (rebuild)

    // 5. Нәтижені тексереміз: Снэкбар немесе қате туралы мәтін шықты ма?
    // Ескерту: Төмендегі мәтін сіздің login.dart-тағы ErrorMessage-бен сәйкес болуы керек
    expect(find.textContaining('Email немесе құпия сөз бос'), findsNothing); 
    // Егер сізде SnackBar шықса:
    expect(find.byType(SnackBar), findsOneWidget);
  });

  testWidgets('Қонақ ретінде кіру батырмасы бар ма?', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
    
    // "Қонақ ретінде кіру" деген мәтіні бар батырманы іздеу
    expect(find.text('Қонақ ретінде кіру'), findsOneWidget);
  });
}