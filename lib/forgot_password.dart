import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'login.dart';

// Қалпына келтіру процесінің қадамдары
enum ResetStep { enterEmail, verifyCode, resetPassword }

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController codeController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  ResetStep _currentStep = ResetStep.enterEmail;
  bool _loading = false;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  final String _baseUrl = 'http://localhost:3001/api';

  @override
  void dispose() {
    emailController.dispose();
    codeController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) => email.contains('@') && email.contains('.');
  
  // Құпия сөзді тексеру (Бэкендтегі талаптарға сәйкес)
  bool _isValidPassword(String pass) {
    if (pass.length < 8) return false;
    if (!pass.contains(RegExp(r'[A-Z]'))) return false;
    if (!pass.contains(RegExp(r'[a-z]'))) return false;
    if (!pass.contains(RegExp(r'\d'))) return false;
    if (!pass.contains(RegExp(r'[!@#$%^&*()_+={}\[\]|\\:;"<,>.?/~`]'))) return false;
    return true;
  }

  // 1. Кодты жіберу
  Future<void> _sendCode() async {
    final email = emailController.text.trim();
    if (!_isValidEmail(email)) {
      _showSnackBar('Дұрыс email адресін енгізіңіз.');
      return;
    }

    setState(() => _loading = true);

    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/forgot-password/send-code'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      final body = jsonDecode(res.body);

      if (res.statusCode == 200) {
        _showSnackBar('Қалпына келтіру коды email-ге жіберілді.');
        setState(() => _currentStep = ResetStep.verifyCode);
      } else if (res.statusCode == 404) {
        _showSnackBar(body['error'] ?? 'Бұл email тіркелмеген.');
      } else {
        _showSnackBar(body['error'] ?? 'Сұрау кезінде қате пайда болды.');
      }
    } catch (e) {
      _showSnackBar('Серверге қосылу қатесі.');
    } finally {
      setState(() => _loading = false);
    }
  }

  // 2. Кодты тексеру
  Future<void> _verifyCode() async {
    final email = emailController.text.trim();
    final code = codeController.text.trim();

    if (code.isEmpty || code.length != 6) {
      _showSnackBar('8 таңбалы кодты енгізіңіз.');
      return;
    }

    setState(() => _loading = true);

    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/forgot-password/verify-code'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'code': code}),
      );

      final body = jsonDecode(res.body);

      if (res.statusCode == 200) {
        _showSnackBar('Код сәтті расталды.');
        setState(() => _currentStep = ResetStep.resetPassword);
      } else {
        _showSnackBar(body['error'] ?? 'Кодты тексеру қатесі.');
      }
    } catch (e) {
      _showSnackBar('Серверге қосылу қатесі.');
    } finally {
      setState(() => _loading = false);
    }
  }

  // 3. Құпия сөзді жаңарту
  Future<void> _resetPassword() async {
    final email = emailController.text.trim();
    final newPassword = newPasswordController.text;
    final confirmPassword = confirmPasswordController.text;

    if (newPassword != confirmPassword) {
      _showSnackBar('Құпия сөздер сәйкес келмейді.');
      return;
    }

    // 🚨 Құпия сөзді тексеру
    if (!_isValidPassword(newPassword)) {
      _showSnackBar('Құпия сөз кемінде 8 таңбадан тұруы керек және бір үлкен әріп, бір кіші әріп, бір сан және бір арнайы символ болуы керек.');
      return;
    }

    setState(() => _loading = true);

    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/forgot-password/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'newPassword': newPassword}),
      );

      final body = jsonDecode(res.body);

      if (res.statusCode == 200) {
        _showSnackBar('Құпия сөз сәтті жаңартылды!');
        
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (Route<dynamic> route) => false,
        );
      } else {
        _showSnackBar(body['error'] ?? 'Құпия сөзді жаңарту қатесі.');
      }
    } catch (e) {
      _showSnackBar('Серверге қосылу қатесі.');
    } finally {
      setState(() => _loading = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final double topContainerHeight = 220;
    final double formTopPadding = 260;

    String titleText;
    String subtitleText;
    IconData icon;

    switch (_currentStep) {
      case ResetStep.enterEmail:
        titleText = 'Құпия сөзді қалпына келтіру';
        subtitleText = 'Email-іңізді енгізіңіз';
        icon = Icons.email_outlined;
        break;
      case ResetStep.verifyCode:
        titleText = 'Растау кодын енгізіңіз';
        subtitleText = 'Email-ге жіберілген код';
        icon = Icons.key_outlined;
        break;
      case ResetStep.resetPassword:
        titleText = 'Жаңа құпия сөз';
        subtitleText = 'Құпия сөзді жаңарту';
        icon = Icons.lock_reset;
        break;
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: topContainerHeight,
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
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon, 
                    size: 70,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    titleText,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitleText,
                    style: const TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
          
          Positioned.fill(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(top: formTopPadding),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),
                    
                    _buildStepContent(),
                    
                    const SizedBox(height: 24),
                    
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
                        onPressed: _loading ? null : _getButtonAction(),
                        child: _getButtonChild(),
                      ),
                    ),

                    const SizedBox(height: 16),
                    
                    Center(
                      child: TextButton(
                        onPressed: () {
                          if (_currentStep == ResetStep.enterEmail) {
                            Navigator.pop(context); 
                          } else {
                            setState(() {
                              _currentStep = ResetStep.values[_currentStep.index - 1];
                            });
                          }
                        },
                        child: Text(
                          'Артқа оралу',
                          style: TextStyle(color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                        ),
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

  Widget _buildStepContent() {
    switch (_currentStep) {
      case ResetStep.enterEmail:
        return _buildEmailStep();
      case ResetStep.verifyCode:
        return _buildCodeStep();
      case ResetStep.resetPassword:
        return _buildResetPasswordStep();
    }
  }

  Widget _buildEmailStep() {
    return Column(
      children: [
        const Text(
          'Аккаунтыңызға байланыстырылған email-ді енгізіңіз. Біз сізге растау кодын жібереміз.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: _buildInputDecoration('Email адресі', Icons.email_outlined),
        ),
      ],
    );
  }

  Widget _buildCodeStep() {
    return Column(
      children: [
        Text(
          'Біз ${emailController.text} поштасына 6 таңбалы код жібердік. Кодты тексеру үшін төменге енгізіңіз.',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: codeController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24, letterSpacing: 10),
          decoration: _buildInputDecoration('Код', Icons.key_outlined).copyWith(
            counterText: '', 
            prefixIcon: null,
          ),
        ),
      ],
    );
  }

  Widget _buildResetPasswordStep() {
    return Column(
      children: [
        const Text(
          'Жаңа құпия сөзді орнатыңыз. Құпия сөз кемінде 8 таңбадан тұруы керек және бір үлкен, бір кіші әріп, бір сан және бір арнайы символ болуы керек.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: newPasswordController,
          obscureText: _obscureNew,
          decoration: _buildPasswordDecoration('Жаңа құпия сөз', Icons.lock_outline, _obscureNew, () => setState(() => _obscureNew = !_obscureNew)),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: confirmPasswordController,
          obscureText: _obscureConfirm,
          decoration: _buildPasswordDecoration('Құпия сөзді қайталау', Icons.lock_outline, _obscureConfirm, () => setState(() => _obscureConfirm = !_obscureConfirm)),
        ),
      ],
    );
  }

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

  Widget _getButtonChild() {
    if (_loading) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          color: Colors.white,
          strokeWidth: 2,
        ),
      );
    }
    switch (_currentStep) {
      case ResetStep.enterEmail:
        return const Text('Қалпына келтіру кодын жіберу');
      case ResetStep.verifyCode:
        return const Text('Кодты тексеру');
      case ResetStep.resetPassword:
        return const Text('Құпия сөзді жаңарту');
    }
  }

  VoidCallback _getButtonAction() {
    switch (_currentStep) {
      case ResetStep.enterEmail:
        return _sendCode;
      case ResetStep.verifyCode:
        return _verifyCode;
      case ResetStep.resetPassword:
        return _resetPassword;
    }
  }
}