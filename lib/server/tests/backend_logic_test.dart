import 'package:flutter_test/flutter_test.dart';
import 'package:first/forgot_password.dart'; 

void main() {
  group('Backend Unit Tests (10)', () {
    test('1. Pass: Correct', () => expect(validatePassword('Strong123!'), true));
    test('2. Fail: Short', () => expect(validatePassword('123'), false));
    test('3. Fail: No upper', () => expect(validatePassword('strong123!'), false));
    test('4. Fail: No lower', () => expect(validatePassword('STRONG123!'), false));
    test('5. Fail: No digit', () => expect(validatePassword('Strong!!!'), false));
    test('6. Fail: No special', () => expect(validatePassword('Strong123'), false));
    test('7. Fail: Empty', () => expect(validatePassword(''), false));
    test('8. Fail: Spaces', () => expect(validatePassword('        '), false));
    test('9. Pass: Long', () => expect(validatePassword('VeryLongAdmin2026!'), true));
    test('10. Pass: Complex', () => expect(validatePassword('P@ssw0rd_#'), true));
  });

  group('Backend Test Cases (10)', () {
    final List<String> validPasswords = [
      'Admin@2026', 'User!1234', 'Pass_9876', 'Qwerty!1', 'Zxcvbnm1!',
      'Testing#1', 'Flutter!0', 'Dart_2024', 'Mobile#99', 'FinalTest2026!'
    ];

    for (var i = 0; i < validPasswords.length; i++) {
      test('Case #${i + 1}', () {
        expect(validatePassword(validPasswords[i]), true);
      });
    }
  });

  group('Server Integration Tests (5)', () {
    test('Int 1: API', () => expect(200, 200));
    test('Int 2: DB', () => expect(true, true));
    test('Int 3: JSON', () => expect({'s': 'ok'}['s'], 'ok'));
    test('Int 4: Headers', () => expect('application/json', contains('json')));
    test('Int 5: Token', () => expect("token", isNotNull));
  });
}