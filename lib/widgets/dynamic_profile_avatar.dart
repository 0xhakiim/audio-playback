// lib/widgets/dynamic_profile_avatar.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DynamicProfileAvatar extends StatefulWidget {
  final double radius;
  const DynamicProfileAvatar({super.key, this.radius = 16});

  @override
  State<DynamicProfileAvatar> createState() => DynamicProfileAvatarState();
}

class DynamicProfileAvatarState extends State<DynamicProfileAvatar> {
  String _nameLetter = 'U';
  Color _avatarColor = const Color(0xFF1DB954);
  String? _imagePath;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  // Exposed method so parent screens can refresh the avatar upon returning
  Future<void> loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final name = prefs.getString('profile_name') ?? 'User';
      final colorVal = prefs.getInt('profile_color') ?? 0xFF1DB954;
      final path = prefs.getString('profile_image_path');

      if (mounted) {
        setState(() {
          _nameLetter = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : 'U';
          _avatarColor = Color(colorVal);
          _imagePath = path;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return CircleAvatar(
        radius: widget.radius,
        backgroundColor: Colors.white10,
        child: SizedBox(
          width: widget.radius,
          height: widget.radius,
          child: const CircularProgressIndicator(strokeWidth: 1.5, color: Color(0xFF1DB954)),
        ),
      );
    }

    // 1. Render picked image from local storage path if it exists
    if (_imagePath != null && _imagePath!.isNotEmpty) {
      final file = File(_imagePath!);
      if (file.existsSync()) {
        return CircleAvatar(
          radius: widget.radius,
          backgroundImage: FileImage(file),
          backgroundColor: Colors.transparent,
        );
      }
    }

    // 2. Fallback to Letter and custom background color
    return CircleAvatar(
      radius: widget.radius,
      backgroundColor: _avatarColor,
      child: Text(
        _nameLetter,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: widget.radius * 0.8,
          color: Colors.black,
        ),
      ),
    );
  }
}