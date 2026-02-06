import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'home.dart'; 
import 'login.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController surnameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController repeatController = TextEditingController();

  bool _obscure1 = true;
  bool _obscure2 = true;
  bool _loading = false;
  // TODO: Бұл жердегі URL-ді мобильді құрылғыдан тексеріп жатсаңыз, IP-адреске өзгерту қажет.
  final String _baseUrl = 'http://localhost:3001/api'; 

  @override
  void dispose() {
    nameController.dispose();
    surnameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    passwordController.dispose();
    repeatController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) =>
      email.contains('@') && email.contains('.');

  bool _isValidPassword(String pass) => pass.length >= 8;

  Future<void> _register() async {
    final name = nameController.text.trim();
    final surname = surnameController.text.trim();
    final phone = phoneController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final repeatPassword = repeatController.text.trim();

    if (name.isEmpty || surname.isEmpty || phone.isEmpty || !_isValidEmail(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Өтінеміз, барлық жеке деректерді тексеріңіз.')),
      );
      return;
    }

    if (!_isValidPassword(password)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Құпия сөз кемінде 8 таңбадан тұруы керек.')),
      );
      return;
    }

    if (password != repeatPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Құпия сөздер сәйкес келмейді.')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'surname': surname,
          'phone': phone,
          'email': email,
          'password': password,
        }),
      );

      final body = jsonDecode(res.body);

      if (res.statusCode == 201) {
        final userId = body['userId'] ?? 'guest';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Тіркелу сәтті аяқталды!')),
        );
        
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => HomeScreen(userId: userId, startIndex: 0),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(body['error'] ?? 'Белгісіз қате. Қайтадан байқаңыз.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Серверге қосылу қатесі: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final buttonChild = _loading
        ? const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
            ),
          )
        : const Text('Тіркелу');
    
    // Ескерту: Жоғарғы плашканың биіктігі 220, форманың отступы 260.
    final double topContainerHeight = 220; 
    final double formTopPadding = 260; 

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ------------------------------------
          // 1. Жоғарғы қызғылт сары градиенттік бөлік (Биіктігі 220)
          // ------------------------------------
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: topContainerHeight, 
              // Тек қана статус-бардан кейінгі отступ
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top, 
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orange.shade700, Colors.orange.shade400],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
              child: Column(
                // **БАСТЫ ӨЗГЕРІС:** Барлық элементтерді тігінен ортаға теңестіру
                mainAxisAlignment: MainAxisAlignment.center, 
                children: const [
                  Icon(
                    Icons.person_add,
                    size: 50,
                    color: Colors.white,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Жаңа аккаунт',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Тіркеліп, рецепттерді таңдаулыға сақтаңыз',
                    style: TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
          
          // ------------------------------------
          // 2. Тіркелу формасы (Отступ 260)
          // ------------------------------------
          Positioned.fill(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(top: formTopPadding), // Отступ 260
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Қосымша отступты алып тастадым, себебі 260 жеткілікті
                    // const SizedBox(height: 20), 

                    // Аты
                    TextField(
                      controller: nameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: _buildInputDecoration('Аты', Icons.person_outline),
                    ),
                    const SizedBox(height: 16),

                    // Тегі
                    TextField(
                      controller: surnameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: _buildInputDecoration('Тегі', Icons.person_outline),
                    ),
                    const SizedBox(height: 16),
                    
                    // Телефон
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: _buildInputDecoration('Телефон нөмірі', Icons.phone_outlined),
                    ),
                    const SizedBox(height: 16),

                    // Электрондық пошта
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: _buildInputDecoration('Электрондық пошта', Icons.email_outlined),
                    ),
                    const SizedBox(height: 16),

                    // Құпия сөз
                    TextField(
                      controller: passwordController,
                      obscureText: _obscure1,
                      decoration: _buildPasswordDecoration('Құпия сөз', Icons.lock_outline, _obscure1, () => setState(() => _obscure1 = !_obscure1)),
                    ),
                    const SizedBox(height: 16),

                    // Құпия сөзді қайталау
                    TextField(
                      controller: repeatController,
                      obscureText: _obscure2,
                      decoration: _buildPasswordDecoration('Құпия сөзді қайталау', Icons.lock_outline, _obscure2, () => setState(() => _obscure2 = !_obscure2)),
                    ),

                    const SizedBox(height: 24),
                    
                    // Тіркелу батырмасы
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        onPressed: _loading ? null : _register,
                        child: buttonChild,
                      ),
                    ),

                    const SizedBox(height: 16),
                    
                    // Кіру батырмасы
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Аккаунтыңыз бұрыннан бар ма?'),
                          const SizedBox(width: 6),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context); // Артқа, LoginScreen-ге
                            },
                            child: Text(
                              'Кіру',
                              style: TextStyle(color: Colors.orange.shade700, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24), 
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // input field-терге арналған көмекші функция
  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.orange),
      filled: true,
      fillColor: Colors.grey.shade100,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.orange.shade400, width: 2),
      ),
    );
  }
  
  // құпия сөз өрістеріне арналған көмекші функция
  InputDecoration _buildPasswordDecoration(String label, IconData icon, bool obscure, VoidCallback toggleVisibility) {
    return _buildInputDecoration(label, icon).copyWith(
      suffixIcon: IconButton(
        icon: Icon(
          obscure ? Icons.visibility : Icons.visibility_off,
          color: Colors.grey,
        ),
        onPressed: toggleVisibility,
      ),
    );
  }
}
