import 'dart:convert';
import 'package:flutter/material.dart';

import 'api.dart';
import 'registration.dart';
import 'home.dart';
import 'forgot_password.dart';
import 'admin/admin_panel.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool _obscure = true;
  bool _loading = false;
  // TODO: Бұл жердегі URL-ді мобильді құрылғыдан тексеріп жатсаңыз, IP-адреске өзгерту қажет.
  final String _baseUrl = 'http://localhost:3001/api'; 

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) =>
      email.contains('@') && email.contains('.');

  Future<void> _login() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (!_isValidEmail(email) || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Өтінеміз, енгізген деректеріңізді тексеріңіз.')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final body = await ApiService.login(email, password);

      if (body['ok'] == true) { 
      // ✅ 1. Получаем ID пользователя из ответа
      final loggedInUserId = body['userId']; 
      final isAdmin = body['isAdmin'] == true;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Сәтті кірдіңіз!'), backgroundColor: Colors.green),
      );
      
      // ✅ 2. ADMIN болса — админ панельге, әйтпесе HomeScreen
      if (isAdmin) {
        final adminData = (body['user'] as Map<String, dynamic>?) ?? {
          'userId': loggedInUserId,
          'email': email,
          'isAdmin': true,
        };
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => AdminPanelScreen(admin: adminData)),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => HomeScreen(userId: loggedInUserId)), 
        );
      }
      } else {
        // Қате
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
  
  // Қонақ ретінде кіру
  void _loginAsGuest() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const HomeScreen(userId: 'guest', startIndex: 0),
      ),
    );
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
        : const Text('Кіру');

    // Құндылықтар registration.dart-пен сәйкестендірілді:
    final double topContainerHeight = 220; 
    final double formTopPadding = 260; 

    // Экранның жоғарғы бөлігін толықтай жабу үшін Stack пайдалану
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ------------------------------------
          // 1. Жоғарғы қызғылт сары градиенттік бөлік (Биіктігі 220, ортаға теңестірілген)
          // ------------------------------------
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: topContainerHeight, 
              padding: EdgeInsets.only(
                // Тек қана статус-бардан кейінгі отступ
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
                    Icons.fastfood,
                    size: 70,
                    color: Colors.white,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'CookPad',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Жеке аккаунтыңызға кіріңіз',
                    style: TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
          
          // ------------------------------------
          // 2. Кіру формасы (Отступ 260)
          // ------------------------------------
          Positioned.fill(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(top: formTopPadding), // Отступ 260
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Электрондық пошта
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Электрондық пошта',
                        prefixIcon: const Icon(Icons.email_outlined, color: Colors.orange),
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
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Құпия сөз
                    TextField(
                      controller: passwordController,
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        labelText: 'Құпия сөз',
                        prefixIcon: const Icon(Icons.lock_outline, color: Colors.orange),
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
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscure ? Icons.visibility : Icons.visibility_off,
                            color: Colors.grey,
                          ),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 8),

                    // Құпия сөзді ұмыттыңыз ба?
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const ForgotPasswordScreen()),
                          );
                        },
                        child: Text(
                          'Құпия сөзді ұмыттыңыз ба?',
                          style: TextStyle(
                              color: Colors.orange.shade600,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                    
                    // Кіру батырмасы
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
                        onPressed: _loading ? null : _login,
                        child: buttonChild,
                      ),
                    ),

                    const SizedBox(height: 16),
                    
                    // Тіркелу және Қонақ ретінде кіру
                    Center(
                      child: Column(
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('Аккаунтыңыз жоқ па?'),
                              const SizedBox(width: 6),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const RegistrationScreen()),
                                  );
                                },
                                child: Text(
                                  'Тіркелу',
                                  style: TextStyle(color: Colors.orange.shade700, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          TextButton(
                                onPressed: _loginAsGuest,
                                child: Text(
                                  'Қонақ ретінде кіру',
                                  style: TextStyle(color: Colors.grey.shade600, fontStyle: FontStyle.italic),
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
}
