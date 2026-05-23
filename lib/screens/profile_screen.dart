// lib/screens/profile_screen.dart
// ── Sawtq brand theme ──────────────────────────────────────────────────────
// Original profile_screen.dart logic preserved; only visual tokens updated.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';

const _kBg      = Color(0xFF0D0B08);
const _kSurface = Color(0xFF13100C);
const _kCard    = Color(0xFF1C1710);
const _kBorder  = Color(0xFF2A241C);
const _kGold    = Color(0xFFC49A3C);
const _kCream   = Color(0xFFF0EDE6);
const _kMuted   = Color(0xFF9B8A6A);
const _kDim     = Color(0xFF7A7060);
const _kGreen   = Color(0xFF4A7C59);
const _kRed     = Color(0xFF8B3A3A);

// Avatar colour options that fit the Sawtq palette
const _kAvatarColors = [
  Color(0xFFC49A3C), // gold
  Color(0xFF4A7C59), // janna green
  Color(0xFF8B6B9A), // twilight purple
  Color(0xFF2A5F8B), // steel blue
  Color(0xFF7A5A2A), // warm amber
  Color(0xFF9B8A6A), // sand
];

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _picker   = ImagePicker();

  String?  _imagePath;
  Color    _avatarColor = _kGold;
  bool     _loading     = true;
  bool     _saving      = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final prefs    = await SharedPreferences.getInstance();
    final name     = prefs.getString('profile_name') ?? '';
    final colorVal = prefs.getInt('profile_color') ?? 0xFFC49A3C;
    final path     = prefs.getString('profile_image_path');
    if (mounted) {
      setState(() {
        _nameCtrl.text = name;
        _avatarColor   = Color(colorVal);
        _imagePath     = path;
        _loading       = false;
      });
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_name', _nameCtrl.text.trim());
    await prefs.setInt('profile_color', _avatarColor.value);
    if (_imagePath != null) {
      await prefs.setString('profile_image_path', _imagePath!);
    }
    if (mounted) {
      setState(() => _saving = false);
      _showMsg('Profile saved');
    }
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
        source: ImageSource.gallery, imageQuality: 80);
    if (picked != null && mounted) {
      setState(() => _imagePath = picked.path);
    }
  }

  Future<void> _removeImage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('profile_image_path');
    if (mounted) setState(() => _imagePath = null);
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _kSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: _kBorder),
        ),
        title: const Text('Sign out',
            style: TextStyle(color: _kCream, fontWeight: FontWeight.w600)),
        content: const Text('Are you sure you want to sign out?',
            style: TextStyle(color: _kMuted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: _kDim)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _kRed,
              foregroundColor: _kCream,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await FirebaseAuth.instance.signOut();
    }
  }

  void _showMsg(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg, style: const TextStyle(color: _kCream)),
        backgroundColor: _kCard,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: _kBorder),
        ),
      ));

  // ── Avatar builder ───────────────────────────────────────────────────────

  Widget _buildAvatar() {
    final letter = _nameCtrl.text.trim().isNotEmpty
        ? _nameCtrl.text.trim()[0].toUpperCase()
        : 'U';
    final hasImage = _imagePath != null &&
        _imagePath!.isNotEmpty &&
        File(_imagePath!).existsSync();

    return Center(
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _kGold.withOpacity(0.4), width: 2),
            ),
            child: CircleAvatar(
              radius: 52,
              backgroundColor: _avatarColor,
              backgroundImage:
              hasImage ? FileImage(File(_imagePath!)) : null,
              child: hasImage
                  ? null
                  : Text(
                letter,
                style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w300,
                    color: _kBg),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: _kGold,
                  shape: BoxShape.circle,
                  border: Border.all(color: _kBg, width: 2),
                ),
                child: const Icon(Icons.camera_alt_rounded,
                    size: 16, color: _kBg),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: _kCream, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Profile',
          style: TextStyle(
              color: _kCream, fontSize: 18, fontWeight: FontWeight.w500),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: _kGold))
                : const Text(
              'Save',
              style: TextStyle(
                  color: _kGold, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(
          child: CircularProgressIndicator(color: _kGold, strokeWidth: 2))
          : ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        children: [
          // Avatar
          _buildAvatar(),
          if (_imagePath != null &&
              _imagePath!.isNotEmpty &&
              File(_imagePath!).existsSync())
            Center(
              child: TextButton.icon(
                onPressed: _removeImage,
                icon: const Icon(Icons.delete_outline,
                    size: 16, color: _kDim),
                label: const Text('Remove photo',
                    style: TextStyle(color: _kDim, fontSize: 13)),
              ),
            ),

          const SizedBox(height: 32),

          // ── Display name ──────────────────────────────────────
          _FieldLabel(label: 'Display name'),
          const SizedBox(height: 8),
          TextField(
            controller: _nameCtrl,
            style: const TextStyle(color: _kCream, fontSize: 15),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Your name',
              hintStyle: const TextStyle(color: _kDim),
              prefixIcon: const Icon(Icons.person_outline,
                  color: _kDim, size: 20),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _kBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                const BorderSide(color: _kGold, width: 1.5),
              ),
              filled: true,
              fillColor: _kSurface,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 16),
            ),
          ),

          const SizedBox(height: 28),

          // ── Avatar colour ──────────────────────────────────────
          _FieldLabel(label: 'Avatar colour'),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: _kAvatarColors.map((c) {
              final isSelected = c.value == _avatarColor.value;
              return GestureDetector(
                onTap: () => setState(() => _avatarColor = c),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 40,
                  height: 40,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? _kCream : Colors.transparent,
                      width: 2.5,
                    ),
                    boxShadow: isSelected
                        ? [
                      BoxShadow(
                        color: c.withOpacity(0.4),
                        blurRadius: 8,
                        spreadRadius: 1,
                      )
                    ]
                        : null,
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 36),

          // ── Account info ───────────────────────────────────────
          _FieldLabel(label: 'Account'),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _kSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _kBorder, width: 0.5),
            ),
            child: Row(
              children: [
                const Icon(Icons.mail_outline, color: _kDim, size: 18),
                const SizedBox(width: 12),
                Text(
                  FirebaseAuth.instance.currentUser?.email ?? '—',
                  style: const TextStyle(color: _kMuted, fontSize: 14),
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),

          // ── Sign out ───────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: _signOut,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFE07070),
                side: const BorderSide(color: _kRed, width: 0.8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text('Sign out',
                  style: TextStyle(fontWeight: FontWeight.w500)),
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel({required this.label});
  @override
  Widget build(BuildContext context) => Text(
    label.toUpperCase(),
    style: const TextStyle(
      color: _kDim,
      fontSize: 11,
      letterSpacing: 0.9,
      fontWeight: FontWeight.w500,
    ),
  );
}