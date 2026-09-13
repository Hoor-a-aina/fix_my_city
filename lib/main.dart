import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;



// Represents the structured result returned by the AI analysis.
//
// The report stores a reference to the local photo used for analysis
// and the date/time when the report was created.
//
// Only the image path is stored. The actual image bytes are NOT stored
// in SharedPreferences.
class ReportAnalysis {
  final String id;
  final String status;
  final String category;
  final String severity;
  final String description;
  final double confidence;
  final String location;
  final String imagePath;
  final DateTime dateTime;

  const ReportAnalysis({
    required this.id,
    required this.status,
    required this.category,
    required this.severity,
    required this.description,
    required this.confidence,
    required this.location,
    required this.imagePath,
    required this.dateTime,
  });

  // Converts the report into a JSON-compatible map for local storage.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'status': status,
      'category': category,
      'severity': severity,
      'description': description,
      'confidence': confidence,
      'location': location,

      // Saves only the local image path, not the image itself.
      'imagePath': imagePath,

      // Stores the report creation date/time as an ISO string.
      'dateTime': dateTime.toIso8601String(),
    };
  }

  // Rebuilds a report from data loaded from local storage.
  factory ReportAnalysis.fromJson(Map<String, dynamic> json) {
    return ReportAnalysis(
      id: json['id'] as String,
      status: json['status'] as String,
      category: json['category'] as String,
      severity: json['severity'] as String,
      description: json['description'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      location: json['location'] as String,

      // Reads the saved image reference.
      imagePath: json['imagePath'] as String,

      // Reads the saved report date/time.
      //
      // The fallback protects older reports that were saved before
      // the dateTime field was introduced.
      dateTime: json['dateTime'] != null
          ? DateTime.parse(json['dateTime'] as String)
          : DateTime.now(),
    );
  }
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
  // ImagePicker handles both camera capture and gallery selection.
  final ImagePicker _picker = ImagePicker();

  // Stores the currently selected/captured image for preview.
  XFile? _selectedImage;

  // Tracks whether the AI analysis is currently running.
  bool _isAnalyzing = false;

  // Stores the AI analysis result after processing the image.
  ReportAnalysis? _analysisResult;

  // Stores reports submitted during the current app session.
  final List<ReportAnalysis> _submittedReports = [];

  // Key used to store submitted reports in local storage.
  static const String _reportsStorageKey = 'submitted_reports';

  // Loads previously submitted reports from local storage.
  Future<void> _loadReports() async {
    final prefs = await SharedPreferences.getInstance();

    // Reads the saved JSON string, if one exists.
    final savedReports = prefs.getString(_reportsStorageKey);

    if (savedReports == null) return;

    // Converts the saved JSON string back into a list of reports.
    final List<dynamic> decodedReports = jsonDecode(savedReports);

    if (!mounted) return;

    setState(() {
      _submittedReports
        ..clear()
        ..addAll(
          decodedReports.map(
                (item) => ReportAnalysis.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          ),
        );
    });
  }

  // Saves all submitted reports to local storage.
  Future<void> _saveReports() async {
    final prefs = await SharedPreferences.getInstance();

    // Converts each report into JSON and stores the complete list.
    final encodedReports = jsonEncode(
      _submittedReports.map((report) => report.toJson()).toList(),
    );

    await prefs.setString(
      _reportsStorageKey,
      encodedReports,
    );
  }

  // Updates an existing submitted report.
  //
  // The updated report already contains the original ID, image path,
  // and date/time. This method simply replaces the matching report
  // and persists the updated data.
  Future<void> _updateReportStatus(
      ReportAnalysis updatedReport,
      ) async {
    final index = _submittedReports.indexWhere(
          (report) => report.id == updatedReport.id,
    );

    // Stops if the report cannot be found.
    if (index == -1) return;

    // Replaces the old report with the updated version.
    setState(() {
      _submittedReports[index] = updatedReport;
    });

    // Saves the updated report to local storage.
    await _saveReports();
  }

  @override
  void initState() {
    super.initState();

    // Loads previously saved reports when the Home screen starts.
    _loadReports();
  }

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
  Future<void> _analyzeImage() async {
    if (_selectedImage == null) return;

    setState(() {
      _isAnalyzing = true;
    });

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('http://192.168.1.6:5000/analyze'),

      );

      // Attach the selected image.
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          _selectedImage!.path,
        ),
      );

      // Send the location to the Flask API.
      request.fields['location'] =
      'North Nazimabad, Karachi, Pakistan';

      print('Sending image to Flask API...');

      final streamedResponse = await request.send();

      final response = await http.Response.fromStream(
        streamedResponse,
      );

      print('API Status: ${response.statusCode}');
      print('API Response: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception(
          'API returned status ${response.statusCode}: '
              '${response.body}',
        );
      }

      final data = jsonDecode(response.body);

      final analysis = ReportAnalysis(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        status: 'Submitted',
        category: data['category'] ?? 'Other',
        severity: data['severity'] ?? 'Medium',
        description: data['description'] ?? '',
        confidence: (data['confidence'] as num?)?.toDouble() ?? 0.0,
        location: data['location'] ?? '',
        imagePath: _selectedImage!.path,
        dateTime: DateTime.now(),
      );

      if (!mounted) return;

      setState(() {
        _analysisResult = analysis;
        _isAnalyzing = false;
      });

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AnalysisResultScreen(
            analysis: analysis,
            onSubmit: (report) async {
              setState(() {
                _submittedReports.add(report);
              });

              await _saveReports();
            },
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isAnalyzing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not analyze image: $e',
          ),
          duration: const Duration(seconds: 5),
        ),
      );

      print('Analysis error: $e');
    }
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
        // Allows the screen to scroll when content is taller than
        // the available space, especially on smaller Android phones.
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

              // Show the selected/captured photo only after the user
              // chooses or captures an image.
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
                // We will add the real analysis flow in a later checkpoint.
                FilledButton.icon(
                  onPressed: _isAnalyzing ? null : _analyzeImage,
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('Analyze'),
                ),

                const SizedBox(height: 12),
              ],

              // Fixed spacing replaces Spacer because this screen
              // now uses a scrollable Column.
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

              // Opens the authority/admin workflow.
              // Admin View receives the same submitted reports and the
              // existing status-update function used by HomeScreen.
              TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AdminViewScreen(
                        reports: _submittedReports,
                        onStatusChanged: _updateReportStatus,
                      ),
                    ),
                  );
                },
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
  // Handles report submission and waits for local storage to complete.
  final Future<void> Function(ReportAnalysis) onSubmit;



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
                onPressed: () async {
                  // Sends the reviewed report back to HomeScreen and waits for it to save.
                  await onSubmit(analysis);

                  if (!context.mounted) return;

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
  void initState() {
    super.initState();

    // Starts the editable fields with the AI-generated report data.
    _categoryController = TextEditingController(
      text: widget.analysis.category,
    );

    _severityController = TextEditingController(
      text: widget.analysis.severity,
    );

    _descriptionController = TextEditingController(
      text: widget.analysis.description,
    );

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
    // Creates the edited report while preserving important existing data.
    //
    // The report ID, status, confidence, image reference, and original
    // report date/time are deliberately preserved.
    final updatedAnalysis = ReportAnalysis(
      id: widget.analysis.id,
      status: widget.analysis.status,
      category: _categoryController.text.trim(),
      severity: _severityController.text.trim(),
      description: _descriptionController.text.trim(),
      confidence: widget.analysis.confidence,
      location: _locationController.text.trim(),

      // Keeps the same photo attached when the citizen edits the report.
      imagePath: widget.analysis.imagePath,

      // Keeps the original report creation time.
      dateTime: widget.analysis.dateTime,
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
// Displays reports submitted by the citizen.
// Citizens can view report information and status,
// but they cannot change the status.
class MyReportsScreen extends StatefulWidget {
  final List<ReportAnalysis> reports;

  const MyReportsScreen({
    super.key,
    required this.reports,
  });

  @override
  State<MyReportsScreen> createState() => _MyReportsScreenState();
}

// Manages the My Reports screen.
// Citizens can view their submitted reports and current status,
// but they cannot change the status from this screen.
class _MyReportsScreenState extends State<MyReportsScreen> {
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
        child: widget.reports.isEmpty
            ? const Center(
          child: Text('No reports submitted yet.'),
        )
            : ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: widget.reports.length,
          itemBuilder: (context, index) {
            final report = widget.reports[index];

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                onTap: () async {
                  // Opens report details in citizen view.
                  // No status-changing callback is passed here,
                  // so citizens can only view the report.
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ReportDetailsScreen(
                        report: report,
                      ),
                    ),
                  );

                  // Refreshes My Reports after returning.
                  setState(() {});
                },
                title: Text(report.category),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${report.severity} • ${report.location}',
                    ),
                    const SizedBox(height: 6),

                    // The citizen can see the current status.
                    // Status changes are handled only by Admin View.
                    Chip(
                      label: Text(report.status),
                      backgroundColor: report.status == 'Resolved'
                          ? Colors.green.shade100
                          : report.status == 'Under Review'
                          ? Colors.blue.shade100
                          : Colors.orange.shade100,
                      labelStyle: TextStyle(
                        color: report.status == 'Resolved'
                            ? Colors.green.shade800
                            : report.status == 'Under Review'
                            ? Colors.blue.shade800
                            : Colors.orange.shade800,
                        fontWeight: FontWeight.w600,
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
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


// Displays the full details of a submitted report.
//
// This is the citizen-facing version of Report Details.
// Citizens can view the current status, but they cannot change it.
// Status changes are handled through Admin View.
// Displays the full details of a submitted report.
//
// This is the citizen-facing version of Report Details.
// Citizens can view the current status, report photo, and report
// date/time, but they cannot change the status.
class ReportDetailsScreen extends StatelessWidget {
  final ReportAnalysis report;

  const ReportDetailsScreen({
    super.key,
    required this.report,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Report Details',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Displays the original submitted photo.
            if (report.imagePath.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(report.imagePath),
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 220,
                      color: Colors.grey.shade200,
                      alignment: Alignment.center,
                      child: const Text(
                        'Report photo is no longer available.',
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),
            ],

            Text(
              report.category,
              style: Theme.of(context).textTheme.headlineSmall,
            ),

            const SizedBox(height: 16),

            Text(
              'Severity: ${report.severity}',
            ),

            const SizedBox(height: 12),

            // Status is read-only on the citizen side.
            // Only Admin View can change it.
            InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(),
              ),
              child: Text(
                report.status,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            const SizedBox(height: 12),

            Text(
              'Description: ${report.description}',
            ),

            const SizedBox(height: 12),

            Text(
              'Location: ${report.location}',
            ),

            const SizedBox(height: 12),

            Text(
              'Confidence: '
                  '${(report.confidence * 100).toStringAsFixed(0)}%',
            ),

            const SizedBox(height: 12),

            // Shows when the report was originally created.
            Text(
              'Reported: ${report.dateTime.toLocal()}',
            ),
          ],
        ),
      ),
    );
  }
}


// Displays the authority/admin workflow.
//
// Admins can view submitted reports and update their status.
// Status changes are sent back to HomeScreen so they are also
// saved through the existing SharedPreferences persistence logic.
class AdminViewScreen extends StatefulWidget {
  final List<ReportAnalysis> reports;

  // Allows Admin View to use HomeScreen's existing persistence logic.
  final Future<void> Function(ReportAnalysis) onStatusChanged;

  const AdminViewScreen({
    super.key,
    required this.reports,
    required this.onStatusChanged,
  });

  @override
  State<AdminViewScreen> createState() => _AdminViewScreenState();
}

class _AdminViewScreenState extends State<AdminViewScreen> {
  late List<ReportAnalysis> _reports;

  @override
  void initState() {
    super.initState();

    // Creates a local copy so the Admin screen can update immediately.
    _reports = List<ReportAnalysis>.from(widget.reports);
  }

  // Changes the report status while preserving all existing report data.
  //
  // The report ID, image reference, and original date/time remain
  // unchanged when an admin updates only the status.
  Future<void> _changeStatus(
      ReportAnalysis report,
      String newStatus,
      ) async {
    final updatedReport = ReportAnalysis(
      id: report.id,
      status: newStatus,
      category: report.category,
      severity: report.severity,
      description: report.description,
      confidence: report.confidence,
      location: report.location,

      // Keeps the original submitted photo attached to the report.
      imagePath: report.imagePath,

      // Keeps the original report creation time.
      dateTime: report.dateTime,
    );

    // Saves the updated report through HomeScreen.
    await widget.onStatusChanged(updatedReport);

    if (!mounted) return;

    // Updates the Admin screen immediately after saving.
    setState(() {
      final index = _reports.indexWhere(
            (existingReport) => existingReport.id == updatedReport.id,
      );

      if (index != -1) {
        _reports[index] = updatedReport;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Admin View',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: _reports.isEmpty
            ? const Center(
          child: Text('No submitted reports yet.'),
        )
            : ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _reports.length,
          itemBuilder: (context, index) {
            final report = _reports[index];

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Displays the submitted photo in Admin View.
                    if (report.imagePath.isNotEmpty) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(report.imagePath),
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (
                              context,
                              error,
                              stackTrace,
                              ) {
                            return Container(
                              height: 180,
                              color: Colors.grey.shade200,
                              alignment: Alignment.center,
                              child: const Text(
                                'Report photo is no longer available.',
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 12),
                    ],

                    Text(
                      report.category,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      '${report.severity} • ${report.location}',
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'Reported: ${report.dateTime.toLocal()}',
                    ),

                    const SizedBox(height: 12),

                    Text(
                      report.description,
                    ),

                    const SizedBox(height: 16),

                    // Admin/authority can change the report status.
                    DropdownButtonFormField<String>(
                      initialValue: report.status,
                      decoration: const InputDecoration(
                        labelText: 'Update Status',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Submitted',
                          child: Text('Submitted'),
                        ),
                        DropdownMenuItem(
                          value: 'Under Review',
                          child: Text('Under Review'),
                        ),
                        DropdownMenuItem(
                          value: 'Resolved',
                          child: Text('Resolved'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null ||
                            value == report.status) {
                          return;
                        }

                        _changeStatus(report, value);
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}



