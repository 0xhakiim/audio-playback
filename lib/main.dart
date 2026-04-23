// lib/main.dart
// App entry point — sets up theme, Provider, and bottom navigation

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'providers/player_provider.dart';
import 'screens/home_screen.dart';
import 'screens/search_screen.dart';
import 'screens/library_screen.dart';
import 'widgets/mini_player.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Lock to portrait mode
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      // PlayerProvider is now available anywhere in the widget tree
      create: (_) => PlayerProvider(),
      child: MaterialApp(
        title: 'Music App',
        debugShowCheckedModeBanner: false,
        theme: _buildDarkTheme(),
        home: const MainScaffold(),
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    const spotifyGreen = Color(0xFF1DB954);
    const background = Color(0xFF121212);
    const surface = Color(0xFF1E1E1E);
    const onSurface = Color(0xFFFFFFFF);

    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: spotifyGreen,
      colorScheme: const ColorScheme.dark(
        primary: spotifyGreen,
        surface: surface,
        onSurface: onSurface,
        secondary: spotifyGreen,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF0A0A0A),
        selectedItemColor: Colors.white,
        unselectedItemColor: Color(0xFF6B6B6B),
        selectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
        unselectedLabelStyle: TextStyle(fontSize: 11),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24),
        headlineMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
        titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16),
        titleMedium: TextStyle(color: Colors.white, fontSize: 14),
        bodyMedium: TextStyle(color: Color(0xFFB3B3B3), fontSize: 13),
        bodySmall: TextStyle(color: Color(0xFF6B6B6B), fontSize: 12),
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: Colors.white,
        inactiveTrackColor: Color(0xFF4D4D4D),
        thumbColor: Colors.white,
        overlayColor: Colors.transparent,
        trackHeight: 3,
        thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
      ),
      iconTheme: const IconThemeData(color: Colors.white),
    );
  }
}

// ── Main Scaffold with BottomNavigationBar ────────────────────────────────────

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentTab = 0;

  // Using IndexedStack keeps all screens alive (preserves scroll state)
  final List<Widget> _screens = const [
    HomeScreen(),
    SearchScreen(),
    LibraryScreen(),
  ];

  void _onTabTapped(int index) {
    setState(() => _currentTab = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentTab,
        children: _screens,
      ),
      // Mini player + bottom nav stacked at the bottom
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Mini player (only shows when a song is loaded)
          const MiniPlayer(),
          // Bottom nav bar
          BottomNavigationBar(
            currentIndex: _currentTab,
            onTap: _onTabTapped,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.search),
                label: 'Search',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.library_music_outlined),
                activeIcon: Icon(Icons.library_music),
                label: 'Your Library',
              ),
            ],
          ),
        ],
      ),
    );
  }
}