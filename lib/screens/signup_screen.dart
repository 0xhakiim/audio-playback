// lib/screens/signup_screen.dart
// ── Sawtq brand theme ──────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import '../services/auth_service.dart';

const _kBg      = Color(0xFF0D0B08);
const _kSurface = Color(0xFF13100C);
const _kBorder  = Color(0xFF2A241C);
const _kGold    = Color(0xFFC49A3C);
const _kCream   = Color(0xFFF0EDE6);
const _kMuted   = Color(0xFF9B8A6A);
const _kDim     = Color(0xFF7A7060);

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
  bool _loading      = false;
  bool _showPassword = false;

  @override
  void dispose() {
    firstName.dispose(); lastName.dispose();
    email.dispose();     confirmEmail.dispose();
    password.dispose();  confirmPassword.dispose();
    super.dispose();
  }

  Future<void> signup() async {
    if (firstName.text.isEmpty || lastName.text.isEmpty || email.text.isEmpty) {
      showMsg('Fill in all fields'); return;
    }
    if (password.text.length < 6) {
      showMsg('Password must be at least 6 characters'); return;
    }
    if (dob == null) { showMsg('Select a date of birth'); return; }
    if (!service.isAtLeast13(dob!)) { showMsg('Must be at least 13 years old'); return; }
    if (email.text != confirmEmail.text) { showMsg('Emails do not match'); return; }
    if (password.text != confirmPassword.text) { showMsg('Passwords do not match'); return; }

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
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) showMsg(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void showMsg(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg, style: const TextStyle(color: _kCream)),
        backgroundColor: const Color(0xFF1C1710),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: _kBorder),
        ),
      ));

  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      initialDate: DateTime(2000),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: _kGold,
            onPrimary: _kBg,
            surface: Color(0xFF1C1710),
            onSurface: _kCream,
          ),
          dialogBackgroundColor: const Color(0xFF13100C),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => dob = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: _kCream, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Create account',
          style: TextStyle(color: _kCream, fontSize: 18, fontWeight: FontWeight.w500),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
        children: [
          // ── Step indicator ─────────────────────────────────────────────
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: _kSurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _kBorder),
              ),
              child: const Text(
                'Join Sawtq · صوتق',
                style: TextStyle(color: _kGold, fontSize: 12, letterSpacing: 0.8),
              ),
            ),
          ),

          const SizedBox(height: 28),

          // ── Name row ───────────────────────────────────────────────────
          Row(
            children: [
              Expanded(child: _labeledField(firstName, 'First name')),
              const SizedBox(width: 12),
              Expanded(child: _labeledField(lastName, 'Last name')),
            ],
          ),

          const SizedBox(height: 18),

          // ── Date of birth ──────────────────────────────────────────────
          _FieldLabel(label: 'Date of birth'),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: pickDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: _kSurface,
                border: Border.all(color: dob != null ? _kGold.withOpacity(0.5) : _kBorder),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    dob == null
                        ? 'Select date'
                        : dob.toString().split(' ')[0],
                    style: TextStyle(
                      color: dob == null ? _kDim : _kCream,
                      fontSize: 15,
                    ),
                  ),
                  const Icon(Icons.calendar_today_outlined,
                      color: _kDim, size: 18),
                ],
              ),
            ),
          ),

          const SizedBox(height: 18),

          _labeledField(email, 'Email',
              type: TextInputType.emailAddress, icon: Icons.mail_outline),
          const SizedBox(height: 14),
          _labeledField(confirmEmail, 'Confirm email',
              type: TextInputType.emailAddress, icon: Icons.mail_outline),
          const SizedBox(height: 14),

          _labeledField(password, 'Password',
              obscure: !_showPassword, icon: Icons.lock_outline,
              suffix: IconButton(
                icon: Icon(
                    _showPassword ? Icons.visibility_off : Icons.visibility,
                    color: _kDim, size: 20),
                onPressed: () =>
                    setState(() => _showPassword = !_showPassword),
              )),
          const SizedBox(height: 14),
          _labeledField(confirmPassword, 'Confirm password',
              obscure: !_showPassword, icon: Icons.lock_outline),

          const SizedBox(height: 32),

          // ── Create account button ──────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _loading ? null : signup,
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
                'Create account',
                style: TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 16),
              ),
            ),
          ),

          const SizedBox(height: 20),

          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Already have an account?',
                    style: TextStyle(color: _kMuted, fontSize: 14)),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(foregroundColor: _kGold),
                  child: const Text('Sign in',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _labeledField(
      TextEditingController ctrl,
      String label, {
        bool obscure = false,
        TextInputType type = TextInputType.text,
        IconData? icon,
        Widget? suffix,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(label: label),
        const SizedBox(height: 8),
        TextField(
          controller: ctrl,
          obscureText: obscure,
          keyboardType: type,
          style: const TextStyle(color: _kCream, fontSize: 15),
          decoration: InputDecoration(
            hintText: label,
            hintStyle: const TextStyle(color: _kDim, fontSize: 14),
            prefixIcon: icon != null
                ? Icon(icon, color: _kDim, size: 20)
                : null,
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
          ),
        ),
      ],
    );
  }
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