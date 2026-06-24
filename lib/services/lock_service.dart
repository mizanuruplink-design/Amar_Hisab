import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

class LockService {
  static const String _pinKey = 'app_pin';
  static const String _lockEnabledKey = 'lock_enabled';
  static const String _lockTypeKey = 'lock_type';
  static const String _biometricEnabledKey = 'biometric_enabled';
  // ✅ নতুন কী
  static const String _securityQuestionKey = 'security_question';
  static const String _securityAnswerKey = 'security_answer';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final LocalAuthentication _localAuth = LocalAuthentication();

  // ========== PIN Management ==========
  Future<void> savePin(String pin) async {
    await _storage.write(key: _pinKey, value: pin);
    await setLockEnabled(true);
  }

  Future<bool> verifyPin(String enteredPin) async {
    try {
      final stored = await _storage.read(key: _pinKey);
      return stored == enteredPin;
    } catch (e) {
      return false; // এরর এলেও ক্র্যাশ করবে না
    }
  }

  Future<bool> hasPin() async {
    final pin = await _storage.read(key: _pinKey);
    return pin != null && pin.isNotEmpty;
  }

  Future<String?> getPin() async {
    return await _storage.read(key: _pinKey);
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
      print('canCheckBiometrics error: $e');
      return false;
    }
  }

  Future<bool> authenticateWithBiometric({required String reason}) async {
    final isAvailable = await isBiometricAvailable();
    if (!isAvailable) {
      print('⚠️ Biometric not available');
      return false;
    }

    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
      return authenticated;
    } on PlatformException catch (e) {
      print('❌ Biometric error: ${e.code} - ${e.message}');
      if (e.code == 'NotEnrolled') {
        return false;
      } else if (e.code == 'LockedOut') {
        return false;
      }
      return false;
    } catch (e) {
      print('❌ Unexpected error: $e');
      return false;
    }
  }

  // ========== Biometric Enabled (legacy) ==========
  Future<void> setBiometricEnabled(bool enabled) async {
    await _storage.write(key: _biometricEnabledKey, value: enabled.toString());
  }

  Future<bool> isBiometricEnabled() async {
    final value = await _storage.read(key: _biometricEnabledKey);
    return value == 'true';
  }

  // ========== ✅ Security Question ==========
  /// নিরাপত্তা প্রশ্ন ও উত্তর সংরক্ষণ করে
  Future<void> saveSecurityQuestion(String question, String answer) async {
    await _storage.write(key: _securityQuestionKey, value: question);
    await _storage.write(key: _securityAnswerKey, value: answer);
  }

  /// সংরক্ষিত নিরাপত্তা প্রশ্ন পড়ে
  Future<String?> getSecurityQuestion() async {
    return await _storage.read(key: _securityQuestionKey);
  }

  /// সংরক্ষিত উত্তর পড়ে
  Future<String?> getSecurityAnswer() async {
    return await _storage.read(key: _securityAnswerKey);
  }

  /// ইনপুট করা উত্তর যাচাই করে
  Future<bool> verifySecurityAnswer(String input) async {
    final stored = await getSecurityAnswer();
    if (stored == null) return false;
    return input.trim().toLowerCase() == stored.trim().toLowerCase();
  }

  // ========== Clear all lock settings ==========
  Future<void> clearLock() async {
    await _storage.delete(key: _pinKey);
    await _storage.delete(key: _lockEnabledKey);
    await _storage.delete(key: _lockTypeKey);
    await _storage.delete(key: _biometricEnabledKey);
    // ✅ নিরাপত্তা প্রশ্নও ডিলিট করুন
    await _storage.delete(key: _securityQuestionKey);
    await _storage.delete(key: _securityAnswerKey);
  }
}