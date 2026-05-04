import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});
  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final service         = AuthService();
  final firstName       = TextEditingController();
  final lastName        = TextEditingController();
  final email           = TextEditingController();
  final confirmEmail    = TextEditingController();
  final password        = TextEditingController();
  final confirmPassword = TextEditingController();
  DateTime? dob;
  bool _loading = false;

  @override
  void dispose() {
    firstName.dispose(); lastName.dispose();
    email.dispose(); confirmEmail.dispose();
    password.dispose(); confirmPassword.dispose();
    super.dispose();
  }

  Future<void> signup() async {
    if (firstName.text.isEmpty || lastName.text.isEmpty || email.text.isEmpty) {
      showMsg('Fill in all fields'); return;
    }
    if (password.text.length < 6) {
      showMsg('Password must be at least 6 characters'); return;
    }
    if (dob == null) {
      showMsg('Select a date of birth'); return;
    }
    if (!service.isAtLeast13(dob!)) {
      showMsg('Must be at least 13 years old'); return;
    }
    if (email.text != confirmEmail.text) {
      showMsg('Emails do not match'); return;
    }
    if (password.text != confirmPassword.text) {
      showMsg('Passwords do not match'); return;
    }

    setState(() => _loading = true);
    try {
      await service.signup(
        firstName: firstName.text.trim(),
        lastName:  lastName.text.trim(),
        dob:       dob!,
        email:     email.text.trim(),
        password:  password.text,
      );
      if (mounted) {
        showMsg('Account created! Please log in.');
        Navigator.pop(context); // go back to LoginPage
      }
    } catch (e) {
      if (mounted) showMsg(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void showMsg(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      initialDate: DateTime(2000),
    );
    if (picked != null) setState(() => dob = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        title: const Text('Create Account', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: ListView(
          children: [
            _field(firstName, 'First name'),
            const SizedBox(height: 12),
            _field(lastName, 'Last name'),
            const SizedBox(height: 12),
            // Date of birth picker
            GestureDetector(
              onTap: pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  border: Border.all(color: Colors.white24),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      dob == null ? 'Date of birth' : dob.toString().split(' ')[0],
                      style: TextStyle(
                        color: dob == null ? Colors.white54 : Colors.white,
                        fontSize: 16,
                      ),
                    ),
                    const Icon(Icons.calendar_today, color: Colors.white54, size: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            _field(email, 'Email', type: TextInputType.emailAddress),
            const SizedBox(height: 12),
            _field(confirmEmail, 'Confirm Email', type: TextInputType.emailAddress),
            const SizedBox(height: 12),
            _field(password, 'Password', obscure: true),
            const SizedBox(height: 12),
            _field(confirmPassword, 'Confirm Password', obscure: true),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _loading ? null : signup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1DB954),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                ),
                child: _loading
                    ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                    : const Text('Create Account',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Already have an account?', style: TextStyle(color: Colors.white70)),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Login', style: TextStyle(color: Color(0xFF1DB954))),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label,
      {bool obscure = false, TextInputType type = TextInputType.text}) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      keyboardType: type,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
        focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF1DB954))),
        filled: true,
        fillColor: const Color(0xFF1E1E1E),
      ),
    );
  }
}