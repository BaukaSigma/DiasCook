import 'package:flutter/material.dart';
import 'api.dart';
import 'registration.dart';
import 'home.dart';
import 'forgot_password.dart';
import 'admin/admin_panel.dart';
import 'localization.dart';

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
        SnackBar(content: Text(Loc.tr('error'))),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final body = await ApiService.login(email, password);

      if (body['ok'] == true) { 
        final loggedInUserId = body['userId']; 
        final isAdmin = body['isAdmin'] == true;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(Loc.tr('saved')), backgroundColor: Colors.green),
        );
        
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(body['error'] ?? Loc.tr('error'))),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${Loc.tr('error')}: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
  
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
    return ValueListenableBuilder<String>(
      valueListenable: Loc.lang,
      builder: (context, lang, child) {
        return Scaffold(
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orange.shade700, Colors.orange.shade300],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      DropdownButton<String>(
                        value: lang,
                        dropdownColor: Colors.orange.shade800,
                        iconEnabledColor: Colors.white,
                        underline: Container(),
                        onChanged: (val) {
                          if (val != null) Loc.lang.value = val;
                        },
                        items: const [
                          DropdownMenuItem(value: 'kz', child: Text('ҚАЗ', style: TextStyle(color: Colors.white, fontSize: 13))),
                          DropdownMenuItem(value: 'ru', child: Text('РУС', style: TextStyle(color: Colors.white, fontSize: 13))),
                          DropdownMenuItem(value: 'en', child: Text('ENG', style: TextStyle(color: Colors.white, fontSize: 13))),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  const Icon(Icons.restaurant_menu, size: 80, color: Colors.white),
                  const SizedBox(height: 10),
                  Text(
                    Loc.tr('app_title'),
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 40),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: const Offset(0, 5))],
                    ),
                    child: Column(
                      children: [
                        Text(Loc.tr('login_title'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 24),
                        TextField(
                          controller: emailController,
                          decoration: InputDecoration(
                            labelText: Loc.tr('email_label'),
                            prefixIcon: const Icon(Icons.email),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: passwordController,
                          obscureText: _obscure,
                          decoration: InputDecoration(
                            labelText: Loc.tr('password_label'),
                            prefixIcon: const Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                              onPressed: () => setState(() => _obscure = !_obscure),
                            ),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordScreen())),
                            child: Text(Loc.tr('forgot_password'), style: const TextStyle(color: Colors.orange)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange.shade700,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: _loading 
                                ? const CircularProgressIndicator(color: Colors.white) 
                                : Text(Loc.tr('login'), style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: _loginAsGuest,
                    child: Text(Loc.tr('login_as_guest'), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(Loc.tr('no_account'), style: const TextStyle(color: Colors.white)),
                      TextButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegistrationScreen())),
                        child: Text(Loc.tr('register'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
