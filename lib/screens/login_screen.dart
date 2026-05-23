// lib/screens/login_screen.dart
// ── Sawtq brand theme ──────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'signup_screen.dart';
import '../services/auth_service.dart';
import '../services/biometric_service.dart';

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
  final bio        = BiometricService.instance;

  bool _loading      = false;
  bool _bioAvailable = false;
  bool _hasBioCreds  = false;
  bool _showPassword = false;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    final available = await bio.isAvailable;
    final hasCreds  = await bio.hasSavedCredentials;
    if (mounted) {
      setState(() {
        _bioAvailable = available;
        _hasBioCreds  = hasCreds;
      });
    }
  }

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

    if (_bioAvailable && !_hasBioCreds) {
      _offerBiometricSetup(email, password);
    } else {
      await _performLogin(email, password, saveBio: false);
    }
  }

  Future<void> _performLogin(String email, String password,
      {required bool saveBio}) async {
    setState(() => _loading = true);
    final success = await service.login(email, password);
    if (success) {
      if (saveBio) await bio.saveCredentials(email, password);
    } else {
      if (mounted) {
        setState(() => _loading = false);
        showMsg('Wrong email or password');
      }
    }
  }

  void _offerBiometricSetup(String email, String password) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: _kSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: _kBorder),
        ),
        title: const Row(children: [
          Icon(Icons.fingerprint, color: _kGold, size: 28),
          SizedBox(width: 10),
          Flexible(
            child: Text(
              'Enable fingerprint login?',
              style: TextStyle(color: _kCream, fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ]),
        content: const Text(
          'Log in faster next time using your fingerprint.',
          style: TextStyle(color: _kMuted, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _performLogin(email, password, saveBio: false);
            },
            child: const Text('Not now', style: TextStyle(color: _kDim)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _kGold,
              foregroundColor: _kBg,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _performLogin(email, password, saveBio: true);
            },
            child: const Text('Enable', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _loginWithBiometrics() async {
    setState(() => _loading = true);
    final authenticated =
    await bio.authenticate(reason: 'Use your fingerprint to log in');
    if (!authenticated) {
      if (mounted) {
        setState(() => _loading = false);
        showMsg('Fingerprint not recognised');
      }
      return;
    }
    final creds = await bio.getCredentials();
    if (creds == null) {
      if (mounted) {
        setState(() => _loading = false);
        showMsg('No saved credentials — log in with password first');
      }
      return;
    }
    final success = await service.login(creds.email, creds.password);
    if (mounted) {
      setState(() => _loading = false);
      if (!success) showMsg('Biometric login failed — please use your password');
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

              // ── Biometrics ─────────────────────────────────────────────
              if (_bioAvailable && _hasBioCreds) ...[
                const SizedBox(height: 20),
                Row(children: [
                  Expanded(child: Divider(color: _kBorder)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Text('or',
                        style: TextStyle(color: _kDim, fontSize: 13)),
                  ),
                  Expanded(child: Divider(color: _kBorder)),
                ]),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: _loading ? null : _loginWithBiometrics,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _kCream,
                      side: const BorderSide(color: _kBorder),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26)),
                    ),
                    icon: const Icon(Icons.fingerprint, size: 24, color: _kGold),
                    label: const Text(
                      'Sign in with Fingerprint',
                      style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
                    ),
                  ),
                ),
              ],

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