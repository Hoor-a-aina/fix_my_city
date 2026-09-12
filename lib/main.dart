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
  final String id;


  const ReportAnalysis({
    required this.id,
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
  final List<ReportAnalysis> _submittedReports = [];


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
        id: 'mock-report-1',
        category: 'Pothole',
        severity: 'High',
        description: 'A large pothole is present on the road surface.',
        confidence: 0.98,
        location: 'North Nazimabad, Karachi, Pakistan',
      );

      _isAnalyzing = false;
    });
    // Opens the result screen after the mock analysis completes.
    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AnalysisResultScreen(
          analysis: _analysisResult!,
          onSubmit: (report) {
            _submittedReports.add(report);
          },

        ),
      ),
    );



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
                onPressed: () {
                  // Opens the user's submitted reports.
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MyReportsScreen(
                        reports: _submittedReports,
                      ),
                    ),
                  );
                },

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
// Displays the AI analysis result on a dedicated screen.
class AnalysisResultScreen extends StatelessWidget {
  final ReportAnalysis analysis;
  final void Function(ReportAnalysis) onSubmit;


  const AnalysisResultScreen({
    super.key,
    required this.analysis,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'AI Analysis Result',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Category: ${analysis.category}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              Text(
                'Severity: ${analysis.severity}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 12),

              Text(
                'Description: ${analysis.description}',
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 12),

              Text(
                'Confidence: ${(analysis.confidence * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 12),

              Text(
                'Location: ${analysis.location}',
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 24),

              // Allows the user to review and edit AI-generated information.
              OutlinedButton.icon(
                onPressed: () async {
                  // Opens the edit screen and waits for the updated report.
                  final updatedAnalysis = await Navigator.push<ReportAnalysis>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditReportScreen(
                        analysis: analysis,
                      ),
                    ),
                  );

                  if (!context.mounted || updatedAnalysis == null) return;

                  // Replaces the current result with the user's edited report.
                  Navigator.pushReplacement(

                  context,
                    MaterialPageRoute(
                      builder: (context) => AnalysisResultScreen(
                        analysis: updatedAnalysis,
                        onSubmit: onSubmit,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.edit),
                label: const Text('Edit Report'),
              ),
              const SizedBox(height: 12),

// Allows the user to submit the reviewed report.
              FilledButton.icon(
                onPressed: () {
                  // Sends the reviewed report back to HomeScreen for storage.
                  onSubmit(analysis);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Report submitted successfully!'),
                    ),
                  );
                },
                icon: const Icon(Icons.send),
                label: const Text('Submit Report'),
              ),

            ],
          ),
        ),
      ),
    );
  }
}
// Allows the user to review and edit the AI-generated report.
class EditReportScreen extends StatefulWidget {
  final ReportAnalysis analysis;

  const EditReportScreen({
    super.key,
    required this.analysis,
  });

  @override
  State<EditReportScreen> createState() => _EditReportScreenState();
}

class _EditReportScreenState extends State<EditReportScreen> {
  late final TextEditingController _categoryController;
  late final TextEditingController _severityController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _locationController;

  @override
  @override
  void initState() {
    super.initState();

    // Starts the editable field with the AI-generated category.
    _categoryController = TextEditingController(
      text: widget.analysis.category,
    );

    // Starts the editable field with the AI-generated severity.
    _severityController = TextEditingController(
      text: widget.analysis.severity,
    );

    // Starts the editable field with the AI-generated description.
    _descriptionController = TextEditingController(
      text: widget.analysis.description,
    );
    // Starts the editable field with the AI-generated location.
    _locationController = TextEditingController(
      text: widget.analysis.location,
    );

  }

  @override
  void dispose() {
    _categoryController.dispose();
    _severityController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();

    super.dispose();
  }

  void _saveChanges() {
    final updatedAnalysis = ReportAnalysis(
      id: widget.analysis.id,
      category: _categoryController.text.trim(),
      severity: _severityController.text.trim(),
      description: _descriptionController.text.trim(),
      confidence: widget.analysis.confidence,
      location: _locationController.text.trim(),
    );

    // Returns the edited report to the result screen.
    Navigator.pop(context, updatedAnalysis);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Edit Report',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Category',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 8),

              TextField(
                controller: _categoryController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter issue category',
                ),
              ),
              const SizedBox(height: 20),

              const Text(
                'Severity',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 8),

              TextField(
                controller: _severityController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter issue severity',
                ),
              ),
              const SizedBox(height: 20),

              const Text(
                'Description',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 8),

              TextField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Describe the issue',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 20),

              const Text(
                'Location',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 8),

              TextField(
                controller: _locationController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter issue location',
                ),
              ),
              const SizedBox(height: 28),

// Saves the user's reviewed report information.
              FilledButton.icon(
                onPressed: _saveChanges,
                icon: const Icon(Icons.save),
                label: const Text('Save Changes'),
              ),

            ],
          ),
        ),
      ),
    );
  }
}

// Displays reports submitted by the user.
class MyReportsScreen extends StatelessWidget {
  final List<ReportAnalysis> reports;

  const MyReportsScreen({
    super.key,
    required this.reports,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Reports',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: reports.isEmpty
            ? const Center(
          child: Text('No reports submitted yet.'),
        )
            : ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: reports.length,
          itemBuilder: (context, index) {
            final report = reports[index];

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text(report.category),
                subtitle: Text(
                  '${report.severity} • ${report.location}',
                ),
                trailing: const Icon(Icons.chevron_right),
              ),
            );
          },
        ),
      ),

    );
  }
}



