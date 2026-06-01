import 'package:flutter/material.dart';
import 'api.dart';
import 'login.dart';
import 'home.dart';
import 'localization.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController surnameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    nameController.dispose();
    surnameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final name = nameController.text.trim();
    final surname = surnameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final confirm = confirmPasswordController.text.trim();
    final phone = phoneController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(Loc.tr('error'))),
      );
      return;
    }

    if (password != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(Loc.tr('error'))),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final res = await ApiService.register({
        'name': name,
        'surname': surname,
        'email': email,
        'password': password,
        'phone': phone,
      });

      if (res['ok'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(Loc.tr('saved')), backgroundColor: Colors.green),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => HomeScreen(userId: res['userId'])),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res['error'] ?? Loc.tr('error'))),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${Loc.tr('error')}: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
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
                  const Icon(Icons.person_add, size: 70, color: Colors.white),
                  const SizedBox(height: 10),
                  Text(
                    Loc.tr('register_title'),
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    Loc.tr('register_subtitle'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 30),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        _buildField(nameController, Loc.tr('name_label'), Icons.person),
                        const SizedBox(height: 16),
                        _buildField(surnameController, Loc.tr('surname_label'), Icons.person_outline),
                        const SizedBox(height: 16),
                        _buildField(phoneController, Loc.tr('phone_label'), Icons.phone),
                        const SizedBox(height: 16),
                        _buildField(emailController, Loc.tr('email_label'), Icons.email),
                        const SizedBox(height: 16),
                        _buildField(passwordController, Loc.tr('password_label'), Icons.lock, obscure: _obscure),
                        const SizedBox(height: 16),
                        _buildField(confirmPasswordController, Loc.tr('repeat_password_label'), Icons.lock_outline, obscure: _obscure),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _register,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange.shade700,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: _loading 
                                ? const CircularProgressIndicator(color: Colors.white) 
                                : Text(Loc.tr('register'), style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(Loc.tr('already_have_account'), style: const TextStyle(color: Colors.white)),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(Loc.tr('login'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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

  Widget _buildField(TextEditingController controller, String label, IconData icon, {bool obscure = false}) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
