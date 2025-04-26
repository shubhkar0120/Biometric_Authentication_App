// lib/screens/register_screen.dart
import 'package:biometric_login_system/services/auth_services.dart' show AuthService;
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart' show BiometricType;


class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  String _statusMessage = 'Register your Biometric to continue';

  Future<void> _registerFace() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Setting up biometric recognition...';
    });

    try {
      // Check if biometrics are available
      bool isBiometricAvailable = await _authService.isBiometricAvailable();
      if (!isBiometricAvailable) {
        _showErrorDialog('Biometric authentication not available on this device');
        setState(() {
          _isLoading = false;
          _statusMessage = 'Biometric authentication not available';
        });
        return;
      }

      // Get available biometrics
      List<BiometricType> availableBiometrics = await _authService.getAvailableBiometrics();
      if (!availableBiometrics.contains(BiometricType.face) && 
          !availableBiometrics.contains(BiometricType.strong)) {
        _showErrorDialog('Biometric authentication is not available on this device');
        setState(() {
          _isLoading = false;
          _statusMessage = 'Biometric authentication not available';
        });
        return;
      }

      // Register user
      bool success = await _authService.registerUser();
      
      if (success) {
        // Navigate to home page on successful registration
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      } else {
        setState(() {
          _isLoading = false;
          _statusMessage = 'Registration failed. Please try again.';
        });
      }
    } catch (e) {
      _showErrorDialog('Error: ${e.toString()}');
      setState(() {
        _isLoading = false;
        _statusMessage = 'An error occurred. Please try again.';
      });
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade300,
              Colors.blue.shade600,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.face,
                    size: 120,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 40),
                  const Text(
                    'Face Authentication',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _statusMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 50),
                  _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : ElevatedButton(
                          onPressed: _registerFace,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.blue,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 40,
                              vertical: 15,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: const Text(
                            'Register Face',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}