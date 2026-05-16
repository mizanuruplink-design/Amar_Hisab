import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

class LockService {
  static const String _pinKey = 'app_pin';
  static const String _lockEnabledKey = 'lock_enabled';
  static const String _lockTypeKey = 'lock_type';
  static const String _biometricEnabledKey = 'biometric_enabled';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final LocalAuthentication _localAuth = LocalAuthentication();

  // ========== PIN Management ==========
  Future<void> savePin(String pin) async {
    await _storage.write(key: _pinKey, value: pin);
    await setLockEnabled(true);
  }

  Future<bool> verifyPin(String enteredPin) async {
    final stored = await _storage.read(key: _pinKey);
    return stored == enteredPin;
  }

  // ========== Lock Enabled ==========
  Future<void> setLockEnabled(bool enabled) async {
    await _storage.write(key: _lockEnabledKey, value: enabled.toString());
  }

  Future<bool> isLockEnabled() async {
    final value = await _storage.read(key: _lockEnabledKey);
    return value == 'true';
  }

  // ========== Lock Type (pin, biometric, both) ==========
  Future<void> setLockType(String type) async {
    await _storage.write(key: _lockTypeKey, value: type);
  }

  Future<String> getLockType() async {
    final value = await _storage.read(key: _lockTypeKey);
    return value ?? 'pin';
  }

  // ========== Biometric Availability & Authentication ==========
  Future<bool> isBiometricAvailable() async {
    try {
      return await _localAuth.canCheckBiometrics;
    } catch (e) {
      return false;
    }
  }

  Future<bool> authenticateWithBiometric({required String reason}) async {
    final isAvailable = await isBiometricAvailable();
    if (!isAvailable) return false;
    try {
      return await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } catch (e) {
      return false;
    }
  }

  // ========== Biometric Enabled (legacy, for compatibility) ==========
  Future<void> setBiometricEnabled(bool enabled) async {
    await _storage.write(key: _biometricEnabledKey, value: enabled.toString());
  }

  Future<bool> isBiometricEnabled() async {
    final value = await _storage.read(key: _biometricEnabledKey);
    return value == 'true';
  }

  // ========== Clear all lock settings ==========
  Future<void> clearLock() async {
    await _storage.delete(key: _pinKey);
    await _storage.delete(key: _lockEnabledKey);
    await _storage.delete(key: _lockTypeKey);
    await _storage.delete(key: _biometricEnabledKey);
  }
}