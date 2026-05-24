import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'login.dart';
import 'localization.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController emailController = TextEditingController();
  bool _loading = false;
  bool _sent = false;

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) => email.contains('@') && email.contains('.');

  Future<void> _sendResetEmail() async {
    final email = emailController.text.trim();
    if (!_isValidEmail(email)) {
      _showSnackBar('Дұрыс электрондық пошта адресін енгізіңіз.');
      return;
    }

    setState(() => _loading = true);

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) {
        setState(() => _sent = true);
        _showSnackBar('Құпия сөзді қалпына келтіру сілтемесі ${email} поштасына жіберілді!');
      }
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = Loc.tr('reset_user_not_found');
          break;
        case 'invalid-email':
          message = Loc.tr('reset_invalid_email');
          break;
        case 'too-many-requests':
          message = Loc.tr('reset_too_many');
          break;
        default:
          message = '${e.message ?? Loc.tr('error')} (${e.code})';
      }
      if (mounted) _showSnackBar(message);
    } catch (e) {
      if (mounted) _showSnackBar('${Loc.tr('error')}: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: Loc.lang,
      builder: (context, lang, _) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 220,
              padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
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
              child: Stack(
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(width: double.infinity),
                      Icon(_sent ? Icons.mark_email_read_outlined : Icons.email_outlined, size: 70, color: Colors.white),
                      const SizedBox(height: 8),
                      Text(
                        _sent ? Loc.tr('reset_sent_title') : Loc.tr('forgot_password_title'),
                        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _sent ? Loc.tr('reset_check_inbox') : Loc.tr('reset_enter_email'),
                        style: const TextStyle(fontSize: 16, color: Colors.white70),
                      ),
                    ],
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: DropdownButton<String>(
                      value: lang,
                      dropdownColor: Colors.orange.shade800,
                      iconEnabledColor: Colors.white,
                      underline: Container(),
                      onChanged: (val) { if (val != null) Loc.lang.value = val; },
                      items: const [
                        DropdownMenuItem(value: 'kz', child: Text('ҚАЗ', style: TextStyle(color: Colors.white, fontSize: 13))),
                        DropdownMenuItem(value: 'ru', child: Text('РУС', style: TextStyle(color: Colors.white, fontSize: 13))),
                        DropdownMenuItem(value: 'en', child: Text('ENG', style: TextStyle(color: Colors.white, fontSize: 13))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned.fill(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(top: 260),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),
                    if (!_sent) ...[
                      Text(
                        Loc.tr('reset_email_hint'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: Loc.tr('email_label'),
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
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          onPressed: _loading ? null : _sendResetEmail,
                          child: _loading
                              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : Text(Loc.tr('reset_send_btn')),
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: 12),
                      const Icon(Icons.check_circle_outline, size: 80, color: Colors.green),
                      const SizedBox(height: 16),
                      Text(
                        Loc.tr('reset_sent_body').replaceFirst('{email}', emailController.text),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 15, color: Colors.grey),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          onPressed: () => Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                            (route) => false,
                          ),
                          child: Text(Loc.tr('back_to_login')),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(Loc.tr('back'), style: TextStyle(color: Colors.grey.shade600, fontStyle: FontStyle.italic)),
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
      },
    );
  }
}

// 🚨 ВЫНЕСЕННАЯ ФУНКЦИЯ ДЛЯ ТЕСТОВ
bool validatePassword(String pass) {
  if (pass.length < 8) return false;
  if (!pass.contains(RegExp(r'[A-Z]'))) return false;
  if (!pass.contains(RegExp(r'[a-z]'))) return false;
  if (!pass.contains(RegExp(r'\d'))) return false;
  if (!pass.contains(RegExp(r'[!@#$%^&*()_+={}\[\]|\\:;"<,>.?/~`]'))) return false;
  return true;
}
