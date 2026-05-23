// lib/screens/auth_gate.dart
// ── Sawtq brand theme ──────────────────────────────────────────────────────

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/player_provider.dart';
import 'login_screen.dart';
import '../main.dart';

const _kBg   = Color(0xFF0D0B08);
const _kGold = Color(0xFFC49A3C);
const _kDim  = Color(0xFF7A7060);

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _SplashScreen();
        }

        if (snapshot.hasData) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.read<PlayerProvider>().loadLibrary();
          });
          return const MainScaffold();
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.read<PlayerProvider>().clearLibrary();
        });
        return const LoginPage();
      },
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Gold logo mark
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _kGold,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.library_music,
                color: Color(0xFF0D0B08),
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Sawtq',
              style: TextStyle(
                color: Color(0xFFF0EDE6),
                fontSize: 28,
                fontWeight: FontWeight.w300,
                letterSpacing: -0.8,
              ),
            ),
            const Text(
              'صوتق',
              style: TextStyle(
                color: _kGold,
                fontSize: 14,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: _kGold.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Loading your library…',
              style: TextStyle(color: _kDim, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}