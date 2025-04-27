import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final LocalAuthentication _localAuth = LocalAuthentication();
  
  // Check if face authentication is available
  Future<bool> isFaceAuthAvailable() async {
    try {
      // First check if device supports biometrics at all
      bool canCheckBiometrics = await _localAuth.canCheckBiometrics;
      bool deviceSupported = await _localAuth.isDeviceSupported();
      
      if (!canCheckBiometrics || !deviceSupported) {
        return false;
      }
      
      // Then specifically check for face biometric
      List<BiometricType> availableBiometrics = await _localAuth.getAvailableBiometrics();
      
      // Check if face authentication is available
      return availableBiometrics.contains(BiometricType.face) || 
             availableBiometrics.contains(BiometricType.strong);
    } on PlatformException catch (e) {
      print('Error checking face availability: $e');
      return false;
    }
  }
  
  // Authenticate user with face
  Future<bool> authenticateWithFace(String action) async {
    bool authenticated = false;
    
    try {
      // First check if face authentication is available
      if (!await isFaceAuthAvailable()) {
        return false;
      }
      
      // Get reason text based on action
      String reason = 'Scan your face to $action';
      
      authenticated = await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } on PlatformException catch (e) {
      print('Error authenticating with face: $e');
      return false;
    }
    return authenticated;
  }
  
  // Register user face
  Future<bool> registerFace() async {
    bool authenticated = await authenticateWithFace('register');
    if (authenticated) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isRegistered', true);
      return true;
    }
    return false;
  }
  
  // Login with face
  Future<bool> loginWithFace() async {
    return await authenticateWithFace('login');
  }
  
  // Check if user is registered
  Future<bool> isUserRegistered() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isRegistered') ?? false;
  }
}