import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:flutter/services.dart';

class BiometricService {
  // Fix: Changed invalid constructor syntax to a valid private named constructor
  BiometricService._();
  static final BiometricService instance = BiometricService._();

  final LocalAuthentication _auth   = LocalAuthentication();
  final FlutterSecureStorage _store = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _kEmail = 'bio_email';
  static const _kPwd   = 'bio_pwd';

  Future<bool> get isAvailable async {
    try {
      final canCheck    = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      if (!canCheck || !isSupported) return false;

      // Fix: Changed 'auth' to '_auth'
      final enrolled = await _auth.getAvailableBiometrics();
      return enrolled.isNotEmpty;
    } catch (e) {
      // Added print statement to help catch underlying issues in the logs
      print("Biometrics check failed: $e");
      return false;
    }
  }

  Future<bool> get hasSavedCredentials async {
    final email = await _store.read(key: _kEmail);
    return email != null && email.isNotEmpty;
  }

  Future<void> saveCredentials(String email, String password) async {
    await _store.write(key: _kEmail, value: email);
    await _store.write(key: _kPwd,   value: password);
  }

  Future<({String email, String password})?> getCredentials() async {
    final email = await _store.read(key: _kEmail);
    final pwd   = await _store.read(key: _kPwd);
    if (email == null || pwd == null) return null;
    return (email: email, password: pwd);
  }

  Future<void> clearCredentials() async {
    await _store.delete(key: _kEmail);
    await _store.delete(key: _kPwd);
  }

  Future<bool> authenticate({String reason = 'Confirm your identity to log in'}) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(biometricOnly: true, stickyAuth: true),
      );
    } on PlatformException catch (e) {
      print("Authentication error: $e");
      if (e.code == auth_error.notEnrolled ||
          e.code == auth_error.notAvailable ||
          e.code == auth_error.lockedOut ||
          e.code == auth_error.permanentlyLockedOut) {
        return false;
      }
      rethrow;
    }
  }
}