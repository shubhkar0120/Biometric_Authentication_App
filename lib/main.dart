// main.dart
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'dart:convert';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  runApp(FaceAuthApp(cameras: cameras));
}

class FaceAuthApp extends StatelessWidget {
  final List<CameraDescription> cameras;
  
  const FaceAuthApp({Key? key, required this.cameras}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Remove debug banner
      title: 'Face Authentication',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
          primary: Colors.blue,
          secondary: Colors.blueAccent,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
          primary: Colors.blue,
          secondary: Colors.blueAccent,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      themeMode: ThemeMode.system,
      home: SplashScreen(cameras: cameras),
    );
  }
}

class SplashScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  
  const SplashScreen({Key? key, required this.cameras}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  bool isRegistered = false;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
    checkIfRegistered();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> checkIfRegistered() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isRegistered = prefs.getBool('face_registered') ?? false;
    });
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
              Theme.of(context).colorScheme.primary.withOpacity(0.8),
              Theme.of(context).colorScheme.primary.withOpacity(0.2),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FadeTransition(
                  opacity: _animation,
                  child: ScaleTransition(
                    scale: _animation,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.face,
                        size: 120,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                FadeTransition(
                  opacity: _animation,
                  child: Text(
                    'Face Authentication',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onBackground,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                FadeTransition(
                  opacity: _animation,
                  child: Text(
                    'Secure access with facial recognition',
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 60),
                FadeTransition(
                  opacity: _animation,
                  child: ElevatedButton(
                    onPressed: () {
                      if (isRegistered) {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) => FaceAuthenticationScreen(cameras: widget.cameras),
                          ),
                        );
                      } else {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) => FaceRegistrationScreen(cameras: widget.cameras),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    ),
                    child: Text(
                      isRegistered ? 'Login with Face' : 'Register Face',
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ),
                if (isRegistered)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: TextButton.icon(
                      onPressed: () async {
                        // Show confirmation dialog
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Reset Registration'),
                            content: const Text('Are you sure you want to delete your face data and register again?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () async {
                                  final prefs = await SharedPreferences.getInstance();
                                  await prefs.remove('face_registered');
                                  await prefs.remove('face_data');
                                  setState(() {
                                    isRegistered = false;
                                  });
                                  Navigator.pop(context);
                                },
                                child: const Text('Reset'),
                              ),
                            ],
                          ),
                        );
                      },
                      icon: const Icon(Icons.restart_alt),
                      label: const Text('Reset Registration'),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class FaceRegistrationScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  
  const FaceRegistrationScreen({Key? key, required this.cameras}) : super(key: key);

  @override
  _FaceRegistrationScreenState createState() => _FaceRegistrationScreenState();
}

class _FaceRegistrationScreenState extends State<FaceRegistrationScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  bool _isProcessing = false;
  final FaceDetector _faceDetector = GoogleMlKit.vision.faceDetector(
    FaceDetectorOptions(
      enableClassification: true,
      minFaceSize: 0.1,
      performanceMode: FaceDetectorMode.accurate,
    ),
  );

  @override
  void initState() {
    super.initState();
    // Use the front camera for face detection
    final frontCamera = widget.cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => widget.cameras.first,
    );
    
    _controller = CameraController(
      frontCamera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    _faceDetector.close();
    super.dispose();
  }

  Future<void> _registerFace() async {
    if (_isProcessing) return;
    
    setState(() {
      _isProcessing = true;
    });

    try {
      await _initializeControllerFuture;
      
      // Add a small delay to ensure the camera surface is fully ready
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Check if controller is still active before taking picture
      if (!_controller.value.isInitialized) {
        throw Exception('Camera controller not initialized');
      }
      
      // Capture an image from the camera
      final XFile image = await _controller.takePicture();
      
      final inputImage = InputImage.fromFilePath(image.path);
      final faces = await _faceDetector.processImage(inputImage);
      
      if (faces.isEmpty) {
        _showErrorSnackBar('No face detected. Please try again.');
        return;
      }
      
      if (faces.length > 1) {
        _showErrorSnackBar('Multiple faces detected. Please ensure only one face is in the frame.');
        return;
      }
      
      // Store the face data
      final face = faces.first;
      final faceData = {
        'boundingBox': {
          'left': face.boundingBox.left,
          'top': face.boundingBox.top,
          'right': face.boundingBox.right,
          'bottom': face.boundingBox.bottom,
        },
        'headEulerAngleY': face.headEulerAngleY,
        'headEulerAngleZ': face.headEulerAngleZ,
        'imagePath': image.path,
      };
      
      // Save face data to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('face_data', jsonEncode(faceData));
      await prefs.setBool('face_registered', true);
      
      // Show success message and navigate to login screen
      if (!mounted) return;
      
      // Show success animation before navigating
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  color: Colors.green,
                  size: 70,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Registration Successful!',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Your face has been registered successfully.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      );
      
      // Wait a bit before navigating
      await Future.delayed(const Duration(seconds: 2));
      
      if (!mounted) return;
      Navigator.of(context).pop(); // Close the dialog
      
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => FaceAuthenticationScreen(cameras: widget.cameras),
        ),
      );
    } catch (e) {
      print('Error registering face: $e');
      _showErrorSnackBar('Error registering face: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      )
    );
    setState(() {
      _isProcessing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Face Registration'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<void>(
              future: _initializeControllerFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      CameraPreview(_controller),
                      // Overlay to help user align face
                      Center(
                        child: Container(
                          width: 250,
                          height: 250,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.blue, width: 2),
                            borderRadius: BorderRadius.circular(125),
                          ),
                        ),
                      ),
                      // Instructions overlay
                      Positioned(
                        top: 20,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          color: Colors.black54,
                          child: const Text(
                            'Position your face within the circle',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  );
                } else {
                  return Container(
                    color: Colors.black,
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Registration Steps:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStepText('1. Keep your face centered'),
                      _buildStepText('2. Ensure good lighting'),
                      _buildStepText('3. Look directly at the camera'),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isProcessing ? null : _registerFace,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    disabledBackgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.6),
                  ),
                  child: _isProcessing
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.0,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Register Face', style: TextStyle(fontSize: 18)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepText(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            size: 16,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class FaceAuthenticationScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  
  const FaceAuthenticationScreen({Key? key, required this.cameras}) : super(key: key);

  @override
  _FaceAuthenticationScreenState createState() => _FaceAuthenticationScreenState();
}

class _FaceAuthenticationScreenState extends State<FaceAuthenticationScreen> with SingleTickerProviderStateMixin {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  bool _isProcessing = false;
  Map<String, dynamic>? _registeredFaceData;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  final FaceDetector _faceDetector = GoogleMlKit.vision.faceDetector(
    FaceDetectorOptions(
      enableClassification: true,
      minFaceSize: 0.1,
      performanceMode: FaceDetectorMode.accurate,
    ),
  );

  @override
  void initState() {
    super.initState();
    _loadRegisteredFaceData();
    
    // Create pulse animation for the face overlay
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    // Use the front camera for face detection
    final frontCamera = widget.cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => widget.cameras.first,
    );
    
    _controller = CameraController(
      frontCamera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    _initializeControllerFuture = _controller.initialize();
  }

  Future<void> _loadRegisteredFaceData() async {
    final prefs = await SharedPreferences.getInstance();
    final faceDataString = prefs.getString('face_data');
    if (faceDataString != null) {
      setState(() {
        _registeredFaceData = jsonDecode(faceDataString);
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _faceDetector.close();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _authenticateFace() async {
    if (_isProcessing || _registeredFaceData == null) return;
    
    setState(() {
      _isProcessing = true;
    });

    try {
      // Ensure camera is initialized
      await _initializeControllerFuture;
      
      // Add a small delay to ensure the camera surface is fully ready
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Check if controller is still active before taking picture
      if (!_controller.value.isInitialized) {
        throw Exception('Camera controller not initialized');
      }
      
      // Capture an image from the camera
      final XFile image = await _controller.takePicture();
      
      // Process the image with ML Kit
      final inputImage = InputImage.fromFilePath(image.path);
      final faces = await _faceDetector.processImage(inputImage);
        
      if (faces.isEmpty) {
        _showErrorSnackBar('No face detected. Please try again.');
        return;
      }
      
      if (faces.length > 1) {
        _showErrorSnackBar('Multiple faces detected. Please ensure only one face is in the frame.');
        return;
      }
      
      // Compare with registered face
      final face = faces.first;
      final registered = _registeredFaceData!;
      
      final similarity = _calculateFaceSimilarity(face, registered);
      
      if (similarity > 0.7) { // Threshold for matching
        // Authentication successful
        if (!mounted) return;
        
        // Show success animation before navigating
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: Colors.white,
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 70,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Authentication Successful!',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'You will be redirected to the home screen.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          },
        );
        
        // Wait a bit before navigating
        await Future.delayed(const Duration(seconds: 2));
        
        if (!mounted) return;
        Navigator.of(context).pop(); // Close the dialog
        
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => HomeScreen(),
          ),
        );
      } else {
        // Authentication failed
        if (!mounted) return;
        
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Authentication Failed'),
              content: const Text('Face verification failed. Please try again.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      print('Error authenticating face: $e');
      _showErrorSnackBar('Error authenticating face: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      )
    );
    setState(() {
      _isProcessing = false;
    });
  }

  double _calculateFaceSimilarity(Face face, Map<String, dynamic> registered) {
    // In a real application, you would use a more sophisticated comparison algorithm
    // This is a simplified example
    
    // Compare bounding box proportions
    final regBox = registered['boundingBox'];
    final regWidth = regBox['right'] - regBox['left'];
    final regHeight = regBox['bottom'] - regBox['top'];
    
    final detWidth = face.boundingBox.width;
    final detHeight = face.boundingBox.height;
    
    final widthRatio = detWidth / regWidth;
    final heightRatio = detHeight / regHeight;
    
    // Compare head pose
    final yAngleDiff = (face.headEulerAngleY! - registered['headEulerAngleY']).abs();
    final zAngleDiff = (face.headEulerAngleZ! - registered['headEulerAngleZ']).abs();
    
    // Calculate similarity score (higher is better)
    final aspectRatioSimilarity = 1.0 - (widthRatio - heightRatio).abs();
    final poseSimilarity = 1.0 - (yAngleDiff / 45.0) - (zAngleDiff / 45.0);
    
    return (aspectRatioSimilarity + poseSimilarity) / 2.0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Face Authentication'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<void>(
              future: _initializeControllerFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      CameraPreview(_controller),
                      // Animated overlay for user face alignment
                      Center(
                        child: AnimatedBuilder(
                          animation: _pulseAnimation,
                          builder: (context, child) {
                            return Container(
                              width: 250 * _pulseAnimation.value,
                              height: 250 * _pulseAnimation.value,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(125 * _pulseAnimation.value),
                              ),
                            );
                          },
                        ),
                      ),
                      // Instructions overlay
                      Positioned(
                        top: 20,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          color: Colors.black54,
                          child: const Text(
                            'Position your face for authentication',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  );
                } else {
                  return Container(
                    color: Colors.black,
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Ready to authenticate',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isProcessing ? null : _authenticateFace,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    disabledBackgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.6),
                  ),
                  child: _isProcessing
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.0,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Verify Face', style: TextStyle(fontSize: 18)),
                ),
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: () async {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Reset Registration'),
                        content: const Text('Are you sure you want to delete your face data and register again?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () async {
                              final prefs = await SharedPreferences.getInstance();
                              await prefs.remove('face_registered');
                              await prefs.remove('face_data');
                              
                              if (!mounted) return;
                              Navigator.pop(context); // Close dialog
                              
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (context) => FaceRegistrationScreen(cameras: widget.cameras),
                                ),
                              );
                            },
                            child: const Text('Reset'),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.restart_alt),
                  label: const Text('Reset Registration'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome'),
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
              Theme.of(context).colorScheme.primary.withOpacity(0.05),
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 100,
              ),
            ),
            const SizedBox(height: 30),
            Text(
              'Authentication Successful!',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onBackground,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'You are now securely logged in',
              style: TextStyle(
                fontSize: 18,
                color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 50),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const ListTile(
                      leading: Icon(Icons.security, color: Colors.green),
                      title: Text('Secured by Face ID'),
                      subtitle: Text('Your session is protected by facial recognition'),
                    ),
                    const Divider(),
                    const ListTile(
                      leading: Icon(Icons.access_time),
                      title: Text('Session Info'),
                      //subtitle: Text('Login time: ${_getCurrentTime()}'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              icon: const Icon(Icons.logout),
              label: const Text('Log Out'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                minimumSize: const Size.fromHeight(56),
              ),
              onPressed: () {
                // Show logout confirmation
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Log Out'),
                    content: const Text('Are you sure you want to log out?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context); // Close dialog
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (context) => SplashScreen(
                                cameras: [],
                              ),
                            ),
                          );
                        },
                        child: const Text('Log Out'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
  
  // Helper method to get current time string
  static String _getCurrentTime() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} ${now.day}/${now.month}/${now.year}';
  }
}