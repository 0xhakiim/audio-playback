import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/player_provider.dart';
import 'login_screen.dart';
import '../main.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Firebase still restoring session — show splash
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _SplashScreen();
        }

        if (snapshot.hasData) {
          // ✅ User is confirmed logged in — NOW it's safe to load the library
          // because FirebaseAuth.instance.currentUser is guaranteed non-null.
          // We use addPostFrameCallback so the widget tree finishes building first.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.read<PlayerProvider>().loadLibrary();
          });
          return const MainScaffold();
        }

        // Not logged in — clear any leftover in-memory library state
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
    return const Scaffold(
      backgroundColor: Color(0xFF121212),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.library_music, size: 72, color: Color(0xFF1DB954)),
            SizedBox(height: 24),
            CircularProgressIndicator(color: Color(0xFF1DB954)),
          ],
        ),
      ),
    );
  }
}