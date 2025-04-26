// lib/services/auth_service.dart
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final LocalAuthentication _localAuth = LocalAuthentication();
  
  // Check if device supports biometric authentication
  Future<bool> isBiometricAvailable() async {
    bool canCheckBiometrics = false;
    try {
      canCheckBiometrics = await _localAuth.canCheckBiometrics;
    } on PlatformException catch (e) {
      print(e);
    }
    return canCheckBiometrics;
  }
  
  // Get available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    List<BiometricType> availableBiometrics = [];
    try {
      availableBiometrics = await _localAuth.getAvailableBiometrics();
    } on PlatformException catch (e) {
      print(e);
    }
    return availableBiometrics;
  }
  
  // Authenticate user with face ID
  Future<bool> authenticateWithBiometrics(String action) async {
    bool authenticated = false;
    try {
      authenticated = await _localAuth.authenticate(
        localizedReason: 'Scan your Biometric to $action',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } on PlatformException catch (e) {
      print(e);
      return false;
    }
    return authenticated;
  }
  
  // Register user by setting a flag in shared preferences
  Future<bool> registerUser() async {
    bool authenticated = await authenticateWithBiometrics('register');
    if (authenticated) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isRegistered', true);
      return true;
    }
    return false;
  }
  
  // Login user
  Future<bool> loginUser() async {
    return await authenticateWithBiometrics('login');
  }
  
  // Logout user
  Future<void> logout() async {
    // We're not removing the registration, just logging out
    // In a real app, you might want to handle this differently
  }
  
  // Check if user is registered
  Future<bool> isUserRegistered() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isRegistered') ?? false;
  }
}