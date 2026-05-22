// lib/screens/profile_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final authService = AuthService();
  final ImagePicker _imagePicker = ImagePicker();

  String _displayName = 'Listener Profile';
  Color _avatarColor = const Color(0xFF1DB954);
  IconData _avatarIcon = Icons.person;
  String? _imagePath;
  bool _isLoading = true;

  final List<Color> _availableColors = [
    const Color(0xFF1DB954),
    Colors.purple,
    Colors.blueAccent,
    Colors.orangeAccent,
    Colors.redAccent,
    Colors.pinkAccent,
  ];

  final List<IconData> _availableIcons = [
    Icons.person,
    Icons.music_note,
    Icons.headset,
    Icons.stars_rounded,
    Icons.graphic_eq_rounded,
    Icons.favorite,
  ];

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _displayName = prefs.getString('profile_name') ?? 'Listener Profile';

        final colorVal = prefs.getInt('profile_color') ?? 0xFF1DB954;
        _avatarColor = Color(colorVal);

        final iconCode = prefs.getInt('profile_icon') ?? Icons.person.codePoint;
        _avatarIcon = IconData(iconCode, fontFamily: 'MaterialIcons');

        _imagePath = prefs.getString('profile_image_path');

        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  // Method to select an image from the device gallery
  Future<void> _pickImage() async {
    try {
      final XFile? selected = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (selected != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('profile_image_path', selected.path);
        setState(() {
          _imagePath = selected.path;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to import image: $e')),
      );
    }
  }

  // Clear selected image to fallback to standard letter/color
  Future<void> _clearImage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('profile_image_path');
    setState(() {
      _imagePath = null;
    });
  }

  Future<void> _saveProfileName(String newName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_name', newName);
    setState(() {
      _displayName = newName;
    });
  }

  Future<void> _saveProfileColor(Color color) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('profile_color', color.value);
    setState(() {
      _avatarColor = color;
    });
  }

  Future<void> _saveProfileIcon(IconData icon) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('profile_icon', icon.codePoint);
    setState(() {
      _avatarIcon = icon;
    });
  }

  void _showEditNameDialog() {
    final controller = TextEditingController(text: _displayName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Edit Name', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Enter your name',
            hintStyle: TextStyle(color: Colors.white30),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF1DB954))),
          ),
          maxLength: 25,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white38)),
          ),
          TextButton(
            onPressed: () {
              final val = controller.text.trim();
              if (val.isNotEmpty) {
                _saveProfileName(val);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save', style: TextStyle(color: Color(0xFF1DB954))),
          ),
        ],
      ),
    );
  }

  void _showEditAvatarSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Customize Avatar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 20),

              // Gallery import button
              ListTile(
                leading: const Icon(Icons.photo_library, color: Color(0xFF1DB954)),
                title: const Text('Import from Storage', style: TextStyle(color: Colors.white)),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _pickImage();
                },
              ),
              if (_imagePath != null)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.redAccent),
                  title: const Text('Remove profile picture', style: TextStyle(color: Colors.redAccent)),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await _clearImage();
                  },
                ),
              const Divider(color: Colors.white10),
              const SizedBox(height: 12),

              const Text('Theme Color (Fallback)', style: TextStyle(color: Colors.white54, fontSize: 13)),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: _availableColors.map((color) => GestureDetector(
                  onTap: () {
                    _saveProfileColor(color);
                    setModalState(() {});
                  },
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: color,
                    child: _avatarColor.value == color.value
                        ? const Icon(Icons.check, color: Colors.white, size: 18)
                        : null,
                  ),
                )).toList(),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetailedStats() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Detailed Analytics', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 20),
            _buildDetailRow('Most Listened Artist', 'Mishary Alafasy'),
            _buildDetailRow('Top Podcast Series', 'The Islamic History Podcast'),
            _buildDetailRow('Most Active Hour', '10:00 PM - 11:00 PM'),
            _buildDetailRow('Average Listening Session', '42 minutes'),
            _buildDetailRow('Favorite Track/Surah', 'Surah Al-Kahf'),
            _buildDetailRow('Active Listening Streak', '5 consecutive days'),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 14)),
          Flexible(
            child: Text(value,
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF121212),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF1DB954))),
      );
    }

    // Determine current avatar widget
    Widget avatarChild;
    if (_imagePath != null && _imagePath!.isNotEmpty && File(_imagePath!).existsSync()) {
      avatarChild = CircleAvatar(
        radius: 50,
        backgroundImage: FileImage(File(_imagePath!)),
        backgroundColor: Colors.transparent,
      );
    } else {
      avatarChild = CircleAvatar(
        radius: 50,
        backgroundColor: _avatarColor,
        child: Text(
          _displayName.trim().isNotEmpty ? _displayName.trim()[0].toUpperCase() : 'U',
          style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.black),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        title: const Text('Profile', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Center(
              child: GestureDetector(
                onTap: _showEditAvatarSheet,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    avatarChild,
                    const CircleAvatar(
                      radius: 14,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.edit, size: 14, color: Colors.black),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(width: 32),
                Text(
                  _displayName,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, size: 16, color: Colors.white54),
                  onPressed: _showEditNameDialog,
                  tooltip: 'Edit name',
                ),
              ],
            ),
            const SizedBox(height: 32),

            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Your Stats',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            const SizedBox(height: 16),

            _buildStatCard(
              icon: Icons.access_time_filled,
              title: 'Listening Time',
              value: '42.5 hours',
              subtitle: 'Active this month',
            ),
            const SizedBox(height: 12),
            _buildStatCard(
              icon: Icons.stars_rounded,
              title: 'Listening Rank',
              value: 'Top 5% Listener',
              subtitle: 'Keep it up!',
            ),
            const SizedBox(height: 12),
            _buildStatCard(
              icon: Icons.audiotrack_rounded,
              title: 'Top Genre',
              value: 'Quran & Podcasts',
              subtitle: 'Based on recent activity',
            ),
            const SizedBox(height: 16),

            TextButton.icon(
              onPressed: _showDetailedStats,
              icon: const Icon(Icons.analytics_rounded, color: Color(0xFF1DB954)),
              label: const Text('See Details', style: TextStyle(color: Color(0xFF1DB954), fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: const Color(0xFF1E1E1E),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      title: const Text('Logout', style: TextStyle(color: Colors.white)),
                      content: const Text('Are you sure you want to log out?', style: TextStyle(color: Colors.white70)),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel', style: TextStyle(color: Colors.white38)),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Logout', style: TextStyle(color: Colors.redAccent)),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                    await authService.logout();
                  }
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  side: const BorderSide(color: Colors.redAccent, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                ),
                icon: const Icon(Icons.logout),
                label: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Icon(icon, color: _avatarColor, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}