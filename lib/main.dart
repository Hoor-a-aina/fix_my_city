import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

// Represents the structured result returned by the AI analysis.
class ReportAnalysis {
  final String category;
  final String severity;
  final String description;
  final double confidence;
  final String location;

  const ReportAnalysis({
    required this.category,
    required this.severity,
    required this.description,
    required this.confidence,
    required this.location,
  });
}


void main() {
  runApp(const FixMyCityApp());
}

class FixMyCityApp extends StatelessWidget {
  const FixMyCityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FixMyCity',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1565C0),
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  // ImagePicker handles both camera capture and gallery selection
  final ImagePicker _picker = ImagePicker();

  // Stores the currently selected/captured image for preview.
  XFile? _selectedImage;

// Tracks whether the AI analysis is currently running.
  bool _isAnalyzing = false;

// Stores the AI analysis result after processing the image.
  ReportAnalysis? _analysisResult;

  // Opens either the camera or gallery based on the supplied source.
  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(
      source: source,
      imageQuality: 85,
    );

    // User may cancel the camera/gallery without selecting an image.
    if (image == null) {
      return;
    }

    setState(() {
      _selectedImage = image;
    });
  }

  // Starts the local analysis process.
// Backend integration will replace this mock process later.
  Future<void> _analyzeImage() async {
    setState(() {
      _isAnalyzing = true;
    });

    // Temporary delay to simulate AI analysis.
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    setState(() {
      _analysisResult = const ReportAnalysis(
        category: 'Pothole',
        severity: 'High',
        description: 'A large pothole is present on the road surface.',
        confidence: 0.98,
        location: 'North Nazimabad, Karachi, Pakistan',
      );

      _isAnalyzing = false;
    });

  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'FixMyCity',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        // Allows the screen to scroll when content is taller than the available space, especially on smaller Android phones.
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),

              const Icon(
                Icons.location_city,
                size: 80,
                color: Color(0xFF1565C0),
              ),

              const SizedBox(height: 24),

              const Text(
                'Report. Improve. Connect.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              const Text(
                'Help identify road problems in your city '
                    'using AI-powered reporting.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            // Show the selected/captured photo only after the user chooses or captures an image.
              if (_selectedImage != null) ...[
                const SizedBox(height: 24),

                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(
                    File(_selectedImage!.path),
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.contain,
                  ),
                ),

                const SizedBox(height: 24),

                // Analyze is intentionally not connected to the backend yet.
                // We will add the analysis flow in a later checkpoint.
                FilledButton.icon(
                  onPressed: _isAnalyzing ? null : _analyzeImage,
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('Analyze'),
                ),

                const SizedBox(height: 12),
              ],

              // Displays the AI analysis result after the image is analyzed.
              if (_analysisResult != null) ...[
                const SizedBox(height: 24),

                const Text(
                  'AI Analysis Result',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  'Category: ${_analysisResult!.category}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Severity: ${_analysisResult!.severity}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Description: ${_analysisResult!.description}',
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),
                Text(
                  'Confidence: ${(_analysisResult!.confidence * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),
                Text(
                  'Location: ${_analysisResult!.location}',
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),


              ],


              // Fixed spacing replaces Spacer because this screen now uses a scrollable Column.
              const SizedBox(height: 32),

              FilledButton.icon(
                onPressed: () => _pickImage(ImageSource.camera),
                icon: const Icon(Icons.camera_alt),
                label: const Text('Take Photo'),
              ),

              const SizedBox(height: 12),

              OutlinedButton.icon(
                onPressed: () => _pickImage(ImageSource.gallery),
                icon: const Icon(Icons.photo_library),
                label: const Text('Choose from Gallery'),
              ),

              const SizedBox(height: 12),

              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.assignment),
                label: const Text('My Reports'),
              ),

              const SizedBox(height: 12),

              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.admin_panel_settings),
                label: const Text('Admin View'),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
