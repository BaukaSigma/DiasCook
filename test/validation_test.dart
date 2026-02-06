import 'package:flutter_test/flutter_test.dart';

// Тексеру функциялары (бұл жерде біз логиканы тексеру үшін көшіріп алдық)
bool isValidEmail(String email) => email.contains('@') && email.contains('.');

bool isValidPassword(String password) {
  final passwordRegex = RegExp(
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#$%^&*()_+={}\[\]|\\:;"<,>.?/~`])[A-Za-z\d!@#$%^&*()_+={}\[\]|\\:;"<,>.?/~`]{8,}$');
  return passwordRegex.hasMatch(password);
}

void main() {
  group('Валидация тесттері', () {
    
    test('Email дұрыс форматты қабылдауы керек', () {
      expect(isValidEmail('test@mail.com'), true);
      expect(isValidEmail('invalid-email'), false);
    });

    test('Құпия сөз қауіпсіздік талаптарына сай болуы керек', () {
      // Дұрыс құпия сөз
      expect(isValidPassword('Strong123!'), true);
      
      // Тым қысқа
      expect(isValidPassword('Short1!'), false);
      
      // Сан жоқ
      expect(isValidPassword('NoNumber!'), false);
      
      // Арнайы символ жоқ
      expect(isValidPassword('NoSymbol123'), false);
    });
  });
}