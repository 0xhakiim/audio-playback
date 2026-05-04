import 'package:flutter/material.dart';
import 'signup_screen.dart';
import '../services/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final loginEmail = TextEditingController();
  final loginPwd   = TextEditingController();
  final service    = AuthService();
  bool _loading    = false;

  @override
  void dispose() {
    loginEmail.dispose();
    loginPwd.dispose();
    super.dispose();
  }

  Future<void> login() async {
    if (!service.isValidEmail(loginEmail.text.trim())) {
      showMsg('Invalid email'); return;
    }
    if (loginPwd.text.isEmpty) {
      showMsg('Enter your password'); return;
    }

    setState(() => _loading = true);
    final success = await service.login(loginEmail.text.trim(), loginPwd.text);
    if (mounted) setState(() => _loading = false);

    if (!success && mounted) {
      showMsg('Wrong email or password');
    }
    // On success: AuthGate in main.dart detects the Firebase auth state
    // change and automatically swaps to MainScaffold — no Navigator.push needed.
  }

  void showMsg(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        title: const Text('Login', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 32),
            TextField(
              controller: loginEmail,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDec('Email'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: loginPwd,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDec('Password'),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _loading ? null : login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1DB954),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                ),
                child: _loading
                    ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                    : const Text('Login', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Don't have an account?", style: TextStyle(color: Colors.white70)),
                TextButton(
                  onPressed: () => Navigator.push(
                      context, MaterialPageRoute(builder: (_) => const SignupPage())),
                  child: const Text('Sign up', style: TextStyle(color: Color(0xFF1DB954))),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDec(String label) => InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: Colors.white54),
    enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
    focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF1DB954))),
    filled: true,
    fillColor: const Color(0xFF1E1E1E),
  );
}