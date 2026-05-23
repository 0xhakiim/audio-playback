// lib/screens/login_screen.dart

import 'package:flutter/material.dart';
import 'signup_screen.dart';
import '../services/auth_service.dart';

const _kBg      = Color(0xFF0D0B08);
const _kSurface = Color(0xFF13100C);
const _kCard    = Color(0xFF1C1710);
const _kBorder  = Color(0xFF2A241C);
const _kGold    = Color(0xFFC49A3C);
const _kCream   = Color(0xFFF0EDE6);
const _kMuted   = Color(0xFF9B8A6A);
const _kDim     = Color(0xFF7A7060);

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final loginEmail = TextEditingController();
  final loginPwd   = TextEditingController();
  final service    = AuthService();

  bool _loading      = false;
  bool _showPassword = false;

  @override
  void dispose() {
    loginEmail.dispose();
    loginPwd.dispose();
    super.dispose();
  }

  Future<void> login() async {
    final email    = loginEmail.text.trim();
    final password = loginPwd.text;

    if (!service.isValidEmail(email)) { showMsg('Invalid email'); return; }
    if (password.isEmpty)             { showMsg('Enter your password'); return; }

    await _performLogin(email, password);
  }

  Future<void> _performLogin(String email, String password) async {
    setState(() => _loading = true);
    final success = await service.login(email, password);
    if (!success) {
      if (mounted) {
        setState(() => _loading = false);
        showMsg('Wrong email or password');
      }
    }
  }

  void showMsg(String msg) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(
        content: Text(msg, style: const TextStyle(color: _kCream)),
        backgroundColor: _kCard,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: _kBorder),
        ),
      ));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 48),

              // ── Logo mark ──────────────────────────────────────────────
              Center(
                child: Column(
                  children: [
                    Image.asset(
                      'assets/images/sawtq_logo.png',
                      width: 88,
                      height: 88,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Sawtq',
                      style: TextStyle(
                        color: _kCream,
                        fontSize: 32,
                        fontWeight: FontWeight.w300,
                        letterSpacing: -1,
                      ),
                    ),
                    const Text(
                      'صوتق',
                      style: TextStyle(color: _kGold, fontSize: 16, letterSpacing: 2),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 48),

              const Text(
                'Welcome back',
                style: TextStyle(
                  color: _kCream,
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Sign in to continue listening',
                style: TextStyle(color: _kMuted, fontSize: 15),
              ),

              const SizedBox(height: 32),

              // ── Email ──────────────────────────────────────────────────
              _FieldLabel(label: 'Email'),
              const SizedBox(height: 8),
              TextField(
                controller: loginEmail,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: _kCream, fontSize: 15),
                decoration: _inputDec(
                  hint: 'you@example.com',
                  icon: Icons.mail_outline,
                ),
              ),

              const SizedBox(height: 20),

              // ── Password ───────────────────────────────────────────────
              _FieldLabel(label: 'Password'),
              const SizedBox(height: 8),
              TextField(
                controller: loginPwd,
                obscureText: !_showPassword,
                style: const TextStyle(color: _kCream, fontSize: 15),
                decoration: _inputDec(
                  hint: '••••••••',
                  icon: Icons.lock_outline,
                  suffix: IconButton(
                    icon: Icon(
                      _showPassword ? Icons.visibility_off : Icons.visibility,
                      color: _kDim,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _showPassword = !_showPassword),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // ── Login button ───────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kGold,
                    foregroundColor: _kBg,
                    disabledBackgroundColor: _kGold.withOpacity(0.4),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26)),
                    elevation: 0,
                  ),
                  child: _loading
                      ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: _kBg))
                      : const Text(
                    'Sign in',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ── Sign up link ───────────────────────────────────────────
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account?",
                        style: TextStyle(color: _kMuted, fontSize: 14)),
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const SignupPage()),
                      ),
                      style: TextButton.styleFrom(foregroundColor: _kGold),
                      child: const Text('Sign up',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDec(
      {required String hint, required IconData icon, Widget? suffix}) =>
      InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: _kDim, fontSize: 14),
        prefixIcon: Icon(icon, color: _kDim, size: 20),
        suffixIcon: suffix,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _kBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _kGold, width: 1.5),
        ),
        filled: true,
        fillColor: _kSurface,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      );
}

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel({required this.label});
  @override
  Widget build(BuildContext context) => Text(
    label,
    style: const TextStyle(
      color: _kMuted,
      fontSize: 12,
      letterSpacing: 0.8,
      fontWeight: FontWeight.w500,
    ),
  );
}