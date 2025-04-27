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
      title: 'Face Authentication',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
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

class _SplashScreenState extends State<SplashScreen> {
  bool isRegistered = false;

  @override
  void initState() {
    super.initState();
    checkIfRegistered();
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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.face, size: 100, color: Colors.blue),
            const SizedBox(height: 20),
            const Text(
              'Face Authentication',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 50),
            ElevatedButton(
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
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              ),
              child: Text(isRegistered ? 'Login with Face' : 'Register Face'),
            ),
            if (isRegistered)
              TextButton(
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.remove('face_registered');
                  await prefs.remove('face_data');
                  setState(() {
                    isRegistered = false;
                  });
                },
                child: const Text('Reset Registration'),
              ),
          ],
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No face detected. Please try again.'))
        );
        setState(() {
          _isProcessing = false;
        });
        return;
      }
      
      if (faces.length > 1) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Multiple faces detected. Please ensure only one face is in the frame.'))
        );
        setState(() {
          _isProcessing = false;
        });
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
      
      // Show success message
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Face registered successfully!'))
      );
      
      // Navigate to login screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => FaceAuthenticationScreen(cameras: widget.cameras),
        ),
      );
    } catch (e) {
      print('Error registering face: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error registering face: $e'))
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Face Registration')),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<void>(
              future: _initializeControllerFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return CameraPreview(_controller);
                } else {
                  return const Center(child: CircularProgressIndicator());
                }
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const Text(
                  'Position your face in the center of the frame',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isProcessing ? null : _registerFace,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                  ),
                  child: _isProcessing
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Register Face'),
                ),
              ],
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

class _FaceAuthenticationScreenState extends State<FaceAuthenticationScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  bool _isProcessing = false;
  Map<String, dynamic>? _registeredFaceData;
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No face detected. Please try again.'))
      );
      setState(() {
        _isProcessing = false;
      });
      return;
    }
    
    if (faces.length > 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Multiple faces detected. Please ensure only one face is in the frame.'))
      );
      setState(() {
        _isProcessing = false;
      });
      return;
    }
    
    // Compare with registered face
    final face = faces.first;
    final registered = _registeredFaceData!;
    
    final similarity = _calculateFaceSimilarity(face, registered);
    
    if (similarity > 0.7) { // Threshold for matching
      // Authentication successful
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => HomeScreen(),
        ),
      );
    } else {
      // Authentication failed
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Authentication failed. Please try again.'))
      );
    }
  } catch (e) {
    print('Error authenticating face: $e');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error authenticating face: $e'))
      );
    }
  } finally {
    if (mounted) {
      setState(() {
        _isProcessing = false;
      });
    }
  }
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
      appBar: AppBar(title: const Text('Face Authentication')),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<void>(
              future: _initializeControllerFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return CameraPreview(_controller);
                } else {
                  return const Center(child: CircularProgressIndicator());
                }
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const Text(
                  'Position your face in the center of the frame',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isProcessing ? null : _authenticateFace,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                  ),
                  child: _isProcessing
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Authenticate Face'),
                ),
                TextButton(
                  onPressed: () async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.remove('face_registered');
                    await prefs.remove('face_data');
                    
                    if (!mounted) return;
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => FaceRegistrationScreen(cameras: widget.cameras),
                      ),
                    );
                  },
                  child: const Text('Reset Registration'),
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
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 100,
            ),
            const SizedBox(height: 20),
            const Text(
              'Authentication Successful!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'You are now logged in',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
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
      ),
    );
  }
}