// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'services/now_playing_service.dart';
import 'providers/player_provider.dart';
import 'services/audio_handler.dart';
import 'services/auth_service.dart';
import 'services/biometric_service.dart';

import 'screens/auth_gate.dart';
import 'screens/home_screen.dart';
import 'screens/search_screen.dart';
import 'screens/library_screen.dart';
import 'screens/profile_screen.dart';

import 'widgets/mini_player.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  await Firebase.initializeApp();
  await NowPlayingNotificationService.instance.init();
  runApp(
    ChangeNotifierProvider(
      create: (_) => PlayerProvider(AppAudioPlayer()),
      child: const SpotifyCloneApp(),
    ),
  );
}

class SpotifyCloneApp extends StatelessWidget {
  const SpotifyCloneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Media App',
      debugShowCheckedModeBanner: false,
      theme: _buildDarkTheme(),
      // Point home back to AuthGate so logged-out users bypass biometrics
      home: const AuthGate(),
    );
  }

  ThemeData _buildDarkTheme() {
    const green      = Color(0xFF1DB954);
    const background = Color(0xFF121212);
    const surface    = Color(0xFF1E1E1E);
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: green,
      colorScheme: const ColorScheme.dark(primary: green, surface: surface, secondary: green),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF0A0A0A),
        selectedItemColor: Colors.white,
        unselectedItemColor: Color(0xFF6B6B6B),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: Colors.white,
        inactiveTrackColor: Color(0xFF4D4D4D),
        thumbColor: Colors.white,
        overlayColor: Colors.transparent,
        trackHeight: 3,
        thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
      ),
    );
  }
}

// ── App Lock Gate ─────────────────────────────────────────────────────────────
class AppLockGate extends StatefulWidget {
  final Widget child;
  const AppLockGate({super.key, required this.child});

  @override
  State<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends State<AppLockGate> {
  bool _unlocked = false;
  bool _isChecking = true;
  final _bio = BiometricService.instance;

  @override
  void initState() {
    super.initState();
    _authenticate();
  }

  Future<void> _authenticate() async {
    setState(() => _isChecking = true);

    final available = await _bio.isAvailable;
    if (!available) {
      setState(() {
        _unlocked = true;
        _isChecking = false;
      });
      return;
    }

    final authenticated = await _bio.authenticate(
      reason: 'Please scan your fingerprint to access the app.',
    );

    setState(() {
      _unlocked = authenticated;
      _isChecking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    const kBg      = Color(0xFF0D0B08);
    const kCream   = Color(0xFFF0EDE6);
    const kGold    = Color(0xFFC49A3C);
    const kMuted   = Color(0xFF9B8A6A);

    if (_isChecking) {
      return const Scaffold(
        backgroundColor: kBg,
        body: Center(
          child: CircularProgressIndicator(color: kGold),
        ),
      );
    }

    if (!_unlocked) {
      return Scaffold(
        backgroundColor: kBg,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline, size: 64, color: kGold),
                const SizedBox(height: 24),
                const Text(
                  'Sawtq is Locked',
                  style: TextStyle(
                    color: kCream,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Use your fingerprint to keep your listening experience secure.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: kMuted, fontSize: 14),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kGold,
                      foregroundColor: kBg,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26),
                      ),
                    ),
                    onPressed: _authenticate,
                    icon: const Icon(Icons.fingerprint),
                    label: const Text(
                      'Unlock App',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return widget.child;
  }
}

// ── Main scaffold — only shown when logged in ─────────────────────────────────
class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});
  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _tab = 0;
  final _screens = const [HomeScreen(), SearchScreen(), LibraryScreen()];

  @override
  Widget build(BuildContext context) {
    // Wrap the logged-in scaffold with the AppLockGate
    return AppLockGate(
      child: Scaffold(
        body: Stack(
          children: [
            IndexedStack(index: _tab, children: _screens),
          ],
        ),
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MiniPlayer(), // Removed const to prevent compilation errors
            BottomNavigationBar(
              currentIndex: _tab,
              onTap: (i) => setState(() => _tab = i),
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
                BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
                BottomNavigationBarItem(icon: Icon(Icons.library_music_outlined), activeIcon: Icon(Icons.library_music), label: 'Library'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}