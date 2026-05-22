// login_screen.dart

import 'package:flutter/material.dart';
import 'signup_screen.dart';
import '../services/auth_service.dart';
import '../services/biometric_service.dart';

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

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    final available = await bio.isAvailable;
    final hasCreds  = await bio.hasSavedCredentials;

    print("BIOMETRICS DEBUG: Available = $available | Has Creds = $hasCreds");

    if (mounted) {
      setState(() {
        _bioAvailable = available;
        _hasBioCreds = hasCreds;
      });
    }
  }

  @override
  void dispose() {
    loginEmail.dispose();
    loginPwd.dispose();
    super.dispose();
  }

  // Modified entry-point for logging in
  Future<void> login() async {
    final email = loginEmail.text.trim();
    final password = loginPwd.text;

    if (!service.isValidEmail(email)) {
      showMsg('Invalid email');
      return;
    }
    if (password.isEmpty) {
      showMsg('Enter your password');
      return;
    }

    // If biometrics are supported but not yet set up, prompt them BEFORE logging in
    if (_bioAvailable && !_hasBioCreds) {
      _offerBiometricSetup(email, password);
    } else {
      await _performLogin(email, password, saveBio: false);
    }
  }

  // Handles the actual authentication call to your backend/Firebase
  Future<void> _performLogin(String email, String password, {required bool saveBio}) async {
    setState(() => _loading = true);
    final success = await service.login(email, password);

    if (success) {
      if (saveBio) {
        // We write to secure storage in the background (no UI needed)
        await bio.saveCredentials(email, password);
      }
    } else {
      if (mounted) {
        setState(() => _loading = false);
        showMsg('Wrong email or password');
      }
    }
  }

  // Displays the dialog before the reactive transition unmounts this page
  void _offerBiometricSetup(String email, String password) {
    showDialog(
      context: context,
      barrierDismissible: false, // Force them to choose an option
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.fingerprint, color: Color(0xFF1DB954), size: 28),
          SizedBox(width: 10),
          Flexible(child: Text('Enable fingerprint login?',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))),
        ]),
        content: const Text('Log in faster next time using your fingerprint.',
            style: TextStyle(color: Color(0xFFB3B3B3), fontSize: 14)),
        actions: [
          TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _performLogin(email, password, saveBio: false);
              },
              child: const Text('Not now', style: TextStyle(color: Color(0xFFB3B3B3)))
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1DB954),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))
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
    final authenticated = await bio.authenticate(reason: 'Use your fingerprint to log in');
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
                decoration: _inputDec('Email')
            ),
            const SizedBox(height: 16),
            TextField(
                controller: loginPwd,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDec('Password')
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity, height: 48,
              child: ElevatedButton(
                onPressed: _loading ? null : login,
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1DB954),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))
                ),
                child: _loading
                    ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                    : const Text('Login', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            if (_bioAvailable && _hasBioCreds) ...[
              const SizedBox(height: 16),
              const Row(children: [
                Expanded(child: Divider(color: Colors.white24)),
                Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('or', style: TextStyle(color: Colors.white38, fontSize: 13))
                ),
                Expanded(child: Divider(color: Colors.white24)),
              ]),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity, height: 48,
                child: OutlinedButton.icon(
                  onPressed: _loading ? null : _loginWithBiometrics,
                  style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white24),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))
                  ),
                  icon: const Icon(Icons.fingerprint, size: 24, color: Color(0xFF1DB954)),
                  label: const Text('Login with Fingerprint',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Text("Don't have an account?", style: TextStyle(color: Colors.white70)),
              TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SignupPage())),
                child: const Text('Sign up', style: TextStyle(color: Color(0xFF1DB954))),
              ),
            ]),
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