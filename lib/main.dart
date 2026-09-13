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
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF64B5F6),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF7FAFC),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Color(0xFF16324F),
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(18),
            ),
          ),
        ),
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
  final ImagePicker _picker = ImagePicker();

  XFile? _selectedImage;
  bool _isAnalyzing = false;
  ReportAnalysis? _analysisResult;

  final List<ReportAnalysis> _submittedReports = [];

  static const String _reportsStorageKey = 'submitted_reports';

  Future<void> _loadReports() async {
    final prefs = await SharedPreferences.getInstance();
    final savedReports = prefs.getString(_reportsStorageKey);

    if (savedReports == null) return;

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

  Future<void> _saveReports() async {
    final prefs = await SharedPreferences.getInstance();

    final encodedReports = jsonEncode(
      _submittedReports.map((report) => report.toJson()).toList(),
    );

    await prefs.setString(
      _reportsStorageKey,
      encodedReports,
    );

  }

  Future<void> _updateReportStatus(
      ReportAnalysis updatedReport,
      ) async {
    final index = _submittedReports.indexWhere(
          (report) => report.id == updatedReport.id,
    );

    if (index == -1) return;

    setState(() {
      _submittedReports[index] = updatedReport;
    });

    await _saveReports();

  }

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(
      source: source,
      imageQuality: 85,
    );

    if (image == null) return;

    setState(() {
      _selectedImage = image;
    });

    _analyzeImage();

  }

  Future<void> _analyzeImage() async {
    if (_selectedImage == null) return;

    setState(() {
      _isAnalyzing = true;
    });

    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final analysis = ReportAnalysis(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      status: 'Submitted',
      category: 'Pothole',
      severity: 'High',
      description: 'A large pothole is present on the road surface.',
      confidence: 0.98,
      location: 'North Nazimabad, Karachi, Pakistan',
      imagePath: _selectedImage!.path,
      dateTime: DateTime.now(),
    );

    setState(() {
      _analysisResult = analysis;
      _isAnalyzing = false;
    });

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AnalysisResultScreen(
          analysis: _analysisResult!,
          onSubmit: (report) async {
            setState(() {
              _submittedReports.add(report);
            });

            await _saveReports();
          },
        ),
      ),
    );

  }

  void _openReportOptions() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              24,
              8,
              24,
              28,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Report an Issue',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF16324F),
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Choose how you want to add a photo.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black54,
                  ),
                ),

                const SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(
                      child: _ActionTile(
                        icon: Icons.camera_alt_rounded,
                        title: 'Take Photo',
                        color: const Color(0xFF42A5F5),
                        onTap: () {
                          Navigator.pop(context);
                          _pickImage(ImageSource.camera);
                        },
                      ),
                    ),

                    const SizedBox(width: 14),

                    Expanded(
                      child: _ActionTile(
                        icon: Icons.photo_library_rounded,
                        title: 'Gallery',
                        color: const Color(0xFF26A69A),
                        onTap: () {
                          Navigator.pop(context);
                          _pickImage(ImageSource.gallery);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

  }

  void _openMyReports() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MyReportsScreen(
          reports: _submittedReports,
        ),
      ),
    );
  }

  void _openAdminView() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminViewScreen(
          reports: _submittedReports,
          onStatusChanged: _updateReportStatus,
        ),
      ),
    );
  }

  void _openAboutTeam() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AboutMeScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final recentReports =
    _submittedReports.reversed.take(3).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFC),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF7FAFC),
        foregroundColor: const Color(0xFF16324F),

        title: const Text(
          'FixMyCity',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),

        leading: Builder(
          builder: (context) {
            return IconButton(
              icon: const Icon(
                Icons.menu_rounded,
              ),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
      ),

      // ==========================================
      // SIDE DRAWER
      // ==========================================

      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(
                  24,
                  30,
                  24,
                  26,
                ),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF42A5F5),
                      Color(0xFF64B5F6),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),

                child: const Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,

                      child: Icon(
                        Icons.location_city_rounded,
                        size: 32,
                        color: Color(0xFF42A5F5),
                      ),
                    ),

                    SizedBox(height: 14),

                    Text(
                      'FixMyCity',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    SizedBox(height: 4),

                    Text(
                      'Report. Improve. Connect.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              ListTile(
                leading: const Icon(
                  Icons.home_rounded,
                  color: Color(0xFF42A5F5),
                ),

                title: const Text(
                  'Home',
                ),

                selected: true,

                selectedTileColor:
                const Color(0xFFE3F2FD),

                shape: RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(12),
                ),

                onTap: () {
                  Navigator.pop(context);
                },
              ),

              ListTile(
                leading: const Icon(
                  Icons.assignment_rounded,
                ),

                title: const Text(
                  'My Reports',
                ),

                onTap: () {
                  Navigator.pop(context);
                  _openMyReports();
                },
              ),

              ListTile(
                leading: const Icon(
                  Icons.admin_panel_settings_rounded,
                ),

                title: const Text(
                  'Admin View',
                ),

                onTap: () {
                  Navigator.pop(context);
                  _openAdminView();
                },
              ),

              const Divider(
                height: 28,
                indent: 20,
                endIndent: 20,
              ),

              ListTile(
                leading: const Icon(
                  Icons.groups_rounded,
                ),

                title: const Text(
                  'About the Team',
                ),

                onTap: () {
                  Navigator.pop(context);
                  _openAboutTeam();
                },
              ),

              const Spacer(),

              const Padding(
                padding: EdgeInsets.all(20),

                child: Text(
                  'Making cities better, one report at a time.',
                  textAlign: TextAlign.center,

                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

      // ==========================================
      // HOME BODY
      // ==========================================

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            20,
            10,
            20,
            30,
          ),

          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,

            children: [
              const Text(
                'Make your city better.',
                style: TextStyle(
                  fontSize: 29,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF16324F),
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Spot a problem? Report it and help your community take action.',
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: Colors.black54,
                ),
              ),

              const SizedBox(height: 24),

              // ==========================================
              // REPORT CARD
              // ==========================================

              Container(
                width: double.infinity,

                padding: const EdgeInsets.all(22),

                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF42A5F5),
                      Color(0xFF64B5F6),
                    ],

                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),

                  borderRadius:
                  BorderRadius.circular(24),

                  boxShadow: [
                    BoxShadow(
                      color: const Color(
                        0xFF42A5F5,
                      ).withOpacity(0.25),

                      blurRadius: 20,

                      offset: const Offset(
                        0,
                        8,
                      ),
                    ),
                  ],
                ),

                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,

                  children: [
                    Container(
                      padding:
                      const EdgeInsets.all(11),

                      decoration: BoxDecoration(
                        color: Colors.white
                            .withOpacity(0.20),

                        borderRadius:
                        BorderRadius.circular(
                          14,
                        ),
                      ),

                      child: const Icon(
                        Icons.camera_alt_rounded,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),

                    const SizedBox(height: 16),

                    const Text(
                      'See something that needs fixing?',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      'Take a photo and let AI identify the issue for you.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,

                      child: FilledButton.icon(
                        onPressed:
                        _openReportOptions,

                        icon: const Icon(
                          Icons.add_a_photo_rounded,
                        ),

                        label: const Text(
                          'Report an Issue',
                        ),

                        style:
                        FilledButton.styleFrom(
                          backgroundColor:
                          Colors.white,

                          foregroundColor:
                          const Color(
                            0xFF1976D2,
                          ),

                          padding:
                          const EdgeInsets
                              .symmetric(
                            vertical: 14,
                          ),

                          shape:
                          RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius
                                .circular(
                              14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // ==========================================
              // QUICK ACCESS
              // ==========================================

              const Text(
                'Quick Access',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF16324F),
                ),
              ),

              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: _QuickActionCard(
                      icon:
                      Icons.assignment_rounded,

                      title: 'My Reports',

                      subtitle:
                      '${_submittedReports.length} submitted',

                      color:
                      const Color(0xFF42A5F5),

                      onTap: _openMyReports,
                    ),
                  ),

                  const SizedBox(width: 14),

                  Expanded(
                    child: _QuickActionCard(
                      icon: Icons
                          .admin_panel_settings_rounded,

                      title: 'Admin View',

                      subtitle:
                      'Manage reports',

                      color:
                      const Color(0xFF26A69A),

                      onTap: _openAdminView,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // ==========================================
              // RECENT REPORTS
              // ==========================================

              Row(
                mainAxisAlignment:
                MainAxisAlignment.spaceBetween,

                children: [
                  const Text(
                    'Recent Reports',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF16324F),
                    ),
                  ),

                  if (_submittedReports
                      .isNotEmpty)
                    TextButton(
                      onPressed:
                      _openMyReports,

                      child: const Text(
                        'View all',
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 12),

              if (recentReports.isEmpty)
                Container(
                  width: double.infinity,

                  padding:
                  const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 30,
                  ),

                  decoration: BoxDecoration(
                    color: Colors.white,

                    borderRadius:
                    BorderRadius.circular(
                      20,
                    ),

                    border: Border.all(
                      color:
                      const Color(0xFFE2EDF5),
                    ),
                  ),

                  child: const Column(
                    children: [
                      Icon(
                        Icons
                            .assignment_outlined,
                        size: 44,
                        color:
                        Color(0xFF90CAF9),
                      ),

                      SizedBox(height: 12),

                      Text(
                        'No reports yet',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight:
                          FontWeight.w600,
                          color:
                          Color(0xFF16324F),
                        ),
                      ),

                      SizedBox(height: 5),

                      Text(
                        'Your submitted reports will appear here.',
                        textAlign:
                        TextAlign.center,

                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...recentReports.map(
                      (report) =>
                      _RecentReportCard(
                        report: report,
                        onTap: _openMyReports,
                      ),
                ),
            ],
          ),
        ),
      ),
    );

  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: color.withOpacity(0.18),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: color,
            ),

            const SizedBox(height: 10),

            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );

  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFFE2EDF5),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
              ),
            ),

            const SizedBox(height: 12),

            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              subtitle,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );

  }
}

class _RecentReportCard extends StatelessWidget {
  final ReportAnalysis report;
  final VoidCallback onTap;

  const _RecentReportCard({
    required this.report,
    required this.onTap,
  });

  Color _statusColor() {
    switch (report.status) {
      case 'Resolved':
        return Colors.green;
      case 'Under Review':
        return Colors.blue;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 6,
        ),
        tileColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(
            color: Color(0xFFE2EDF5),
          ),
        ),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFE3F2FD),
          child: const Icon(
            Icons.location_on_rounded,
            color: Color(0xFF42A5F5),
          ),
        ),
        title: Text(
          report.category,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          report.location,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 9,
            vertical: 5,
          ),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            report.status,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );

  }
}

// Displays the AI analysis result on a dedicated screen.
class AnalysisResultScreen extends StatelessWidget {
  final ReportAnalysis analysis;

  final Future<void> Function(ReportAnalysis) onSubmit;

  const AnalysisResultScreen({
    super.key,
    required this.analysis,
    required this.onSubmit,
  });

  Color _severityColor() {
    switch (analysis.severity) {
      case 'High':
        return Colors.red;
      case 'Medium':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    final severityColor = _severityColor();

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
          padding: const EdgeInsets.all(20),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [

              // Header
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(24),
                ),

                child: const Column(
                  children: [
                    Icon(
                      Icons.auto_awesome_rounded,
                      size: 46,
                      color: Color(0xFF64B5F6),
                    ),

                    SizedBox(height: 12),

                    Text(
                      'Issue Identified',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF16324F),
                      ),
                    ),

                    SizedBox(height: 6),

                    Text(
                      'AI has analyzed your submitted image.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // Category
              _resultCard(
                icon: Icons.category_rounded,
                title: 'Category',
                value: analysis.category,
              ),

              const SizedBox(height: 12),

              // Severity
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: const Color(0xFFE2EDF5),
                  ),
                ),

                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: severityColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.warning_amber_rounded,
                        color: severityColor,
                      ),
                    ),

                    const SizedBox(width: 14),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Severity',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey,
                            ),
                          ),

                          const SizedBox(height: 4),

                          Text(
                            analysis.severity,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: severityColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Description
              _resultCard(
                icon: Icons.description_rounded,
                title: 'Description',
                value: analysis.description,
              ),

              const SizedBox(height: 12),

              // Confidence
              _resultCard(
                icon: Icons.analytics_rounded,
                title: 'AI Confidence',
                value:
                '${(analysis.confidence * 100).toStringAsFixed(0)}%',
              ),

              const SizedBox(height: 12),

              // Location
              _resultCard(
                icon: Icons.location_on_rounded,
                title: 'Location',
                value: analysis.location,
              ),

              const SizedBox(height: 26),

              // Edit button
              OutlinedButton.icon(
                onPressed: () async {
                  final updatedAnalysis =
                  await Navigator.push<ReportAnalysis>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditReportScreen(
                        analysis: analysis,
                      ),
                    ),
                  );

                  if (!context.mounted || updatedAnalysis == null) {
                    return;
                  }

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

                icon: const Icon(Icons.edit_rounded),

                label: const Text(
                  'Edit Report',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),

                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF42A5F5),
                  side: const BorderSide(
                    color: Color(0xFF64B5F6),
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 15,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Submit button
              FilledButton.icon(
                onPressed: () async {
                  await onSubmit(analysis);

                  if (!context.mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Report submitted successfully!',
                      ),
                    ),
                  );
                },

                icon: const Icon(Icons.send_rounded),

                label: const Text(
                  'Submit Report',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF64B5F6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              const Text(
                'Review the AI results before submitting your report.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );


  }

  Widget _resultCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE2EDF5),
        ),
      ),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF42A5F5),
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF16324F),
                  ),
                ),
              ],
            ),
          ),
        ],
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
    final updatedAnalysis = ReportAnalysis(
      id: widget.analysis.id,
      status: widget.analysis.status,
      category: _categoryController.text.trim(),
      severity: _severityController.text.trim(),
      description: _descriptionController.text.trim(),
      confidence: widget.analysis.confidence,
      location: _locationController.text.trim(),
      imagePath: widget.analysis.imagePath,
      dateTime: widget.analysis.dateTime,
    );

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
          padding: const EdgeInsets.all(20),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [

              // Header
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(24),
                ),

                child: const Column(
                  children: [
                    Icon(
                      Icons.edit_note_rounded,
                      size: 46,
                      color: Color(0xFF64B5F6),
                    ),

                    SizedBox(height: 12),

                    Text(
                      'Review Your Report',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF16324F),
                      ),
                    ),

                    SizedBox(height: 6),

                    Text(
                      'Review and update the information before submitting.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              _buildField(
                controller: _categoryController,
                label: 'Category',
                hint: 'Enter issue category',
                icon: Icons.category_rounded,
              ),

              const SizedBox(height: 18),

              _buildField(
                controller: _severityController,
                label: 'Severity',
                hint: 'Enter issue severity',
                icon: Icons.warning_amber_rounded,
              ),

              const SizedBox(height: 18),

              _buildField(
                controller: _descriptionController,
                label: 'Description',
                hint: 'Describe the issue',
                icon: Icons.description_rounded,
                maxLines: 5,
              ),

              const SizedBox(height: 18),

              _buildField(
                controller: _locationController,
                label: 'Location',
                hint: 'Enter issue location',
                icon: Icons.location_on_rounded,
              ),

              const SizedBox(height: 28),

              // Save button
              FilledButton.icon(
                onPressed: _saveChanges,
                icon: const Icon(Icons.save_rounded),
                label: const Text(
                  'Save Changes',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF64B5F6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              const Text(
                'Your changes will be reflected in the final report.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );


  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xFF16324F),
          ),
        ),

        const SizedBox(height: 8),

        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Padding(
              padding: EdgeInsets.only(
                bottom: maxLines > 1 ? 70 : 0,
              ),
              child: Icon(
                icon,
                color: const Color(0xFF64B5F6),
              ),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: Color(0xFFE2EDF5),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: Color(0xFF64B5F6),
                width: 2,
              ),
            ),
          ),
        ),
      ],
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

class _MyReportsScreenState extends State<MyReportsScreen> {
  Color _statusColor(String status) {
    switch (status) {
      case 'Resolved':
        return Colors.green;
      case 'Under Review':
        return const Color(0xFF42A5F5);
      default:
        return Colors.orange;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'Resolved':
        return Icons.check_circle_rounded;
      case 'Under Review':
        return Icons.hourglass_top_rounded;
      default:
        return Icons.pending_rounded;
    }
  }

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
            ? _buildEmptyState()
            : ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF64B5F6),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.assignment_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),

                  const SizedBox(width: 16),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Your Reports',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF16324F),
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          '${widget.reports.length} '
                              '${widget.reports.length == 1 ? 'report' : 'reports'} submitted',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Submitted Issues',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF16324F),
              ),
            ),

            const SizedBox(height: 14),

            ...widget.reports.reversed.map(
                  (report) => _buildReportCard(
                context,
                report,
              ),
            ),
          ],
        ),
      ),
    );


  }

  Widget _buildReportCard(
      BuildContext context,
      ReportAnalysis report,
      ) {
    final statusColor = _statusColor(report.status);
    final statusIcon = _statusIcon(report.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE2EDF5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),

      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ReportDetailsScreen(
                report: report,
              ),
            ),
          );

          if (mounted) {
            setState(() {});
          }
        },

        child: Padding(
          padding: const EdgeInsets.all(16),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // Top row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.location_on_rounded,
                      color: Color(0xFF42A5F5),
                      size: 28,
                    ),
                  ),

                  const SizedBox(width: 14),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          report.category,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF16324F),
                          ),
                        ),

                        const SizedBox(height: 5),

                        Text(
                          report.location,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.grey,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              const Divider(
                height: 1,
                color: Color(0xFFEFF3F6),
              ),

              const SizedBox(height: 14),

              // Severity + status
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          size: 18,
                          color: Colors.orange,
                        ),

                        const SizedBox(width: 6),

                        Text(
                          'Severity: ${report.severity}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),

                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          statusIcon,
                          size: 15,
                          color: statusColor,
                        ),

                        const SizedBox(width: 5),

                        Text(
                          report.status,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );


  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Icon(
                Icons.assignment_outlined,
                size: 52,
                color: Color(0xFF64B5F6),
              ),
            ),

            const SizedBox(height: 22),

            const Text(
              'No Reports Yet',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF16324F),
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'When you report a civic issue, '
                  'your submitted reports will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Colors.black54,
              ),
            ),

            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Report an issue from the Home screen',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF1976D2),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
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

  Color _statusColor() {
    switch (report.status) {
      case 'Resolved':
        return Colors.green;
      case 'Under Review':
        return const Color(0xFF42A5F5);
      default:
        return Colors.orange;
    }
  }

  IconData _statusIcon() {
    switch (report.status) {
      case 'Resolved':
        return Icons.check_circle_rounded;
      case 'Under Review':
        return Icons.hourglass_top_rounded;
      default:
        return Icons.pending_rounded;
    }
  }

  Color _severityColor() {
    switch (report.severity) {
      case 'High':
        return Colors.red;
      case 'Medium':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor();
    final severityColor = _severityColor();

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
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
          children: [

            // Report image
            if (report.imagePath.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Image.file(
                  File(report.imagePath),
                  height: 240,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 240,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3F2FD),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      alignment: Alignment.center,
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.image_not_supported_outlined,
                            size: 44,
                            color: Color(0xFF64B5F6),
                          ),

                          SizedBox(height: 10),

                          Text(
                            'Report photo is no longer available.',
                            style: TextStyle(
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 22),
            ],

            // Category header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(22),
              ),

              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: const Color(0xFF64B5F6),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(
                      Icons.location_on_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),

                  const SizedBox(width: 14),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Reported Issue',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.black54,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          report.category,
                          style: const TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF16324F),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Status and severity
            Row(
              children: [
                Expanded(
                  child: _infoCard(
                    icon: _statusIcon(),
                    title: 'Status',
                    value: report.status,
                    color: statusColor,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: _infoCard(
                    icon: Icons.warning_amber_rounded,
                    title: 'Severity',
                    value: report.severity,
                    color: severityColor,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // Description
            _detailCard(
              icon: Icons.description_rounded,
              title: 'Description',
              child: Text(
                report.description,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: Color(0xFF16324F),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Location
            _detailCard(
              icon: Icons.location_on_rounded,
              title: 'Location',
              child: Text(
                report.location,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.4,
                  color: Color(0xFF16324F),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // AI confidence
            _detailCard(
              icon: Icons.auto_awesome_rounded,
              title: 'AI Confidence',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${(report.confidence * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF16324F),
                    ),
                  ),

                  const SizedBox(height: 10),

                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: report.confidence,
                      minHeight: 8,
                      backgroundColor: const Color(0xFFE3F2FD),
                      valueColor:
                      const AlwaysStoppedAnimation<Color>(
                        Color(0xFF64B5F6),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Report date
            _detailCard(
              icon: Icons.calendar_today_rounded,
              title: 'Reported On',
              child: Text(
                _formatDate(report.dateTime),
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF16324F),
                ),
              ),
            ),

            const SizedBox(height: 22),

            // Read-only notice
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F9FC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFE2EDF5),
                ),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: Color(0xFF64B5F6),
                  ),

                  SizedBox(width: 10),

                  Expanded(
                    child: Text(
                      'Report status is managed by the administrator. '
                          'You can view the latest status here.',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.5,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );


  }

  Widget _infoCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE2EDF5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              icon,
              color: color,
              size: 21,
            ),
          ),

          const SizedBox(height: 12),

          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );


  }

  Widget _detailCard({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE2EDF5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF42A5F5),
                  size: 20,
                ),
              ),

              const SizedBox(width: 10),

              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF16324F),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          child,
        ],
      ),
    );


  }

  String _formatDate(DateTime dateTime) {
    final local = dateTime.toLocal();

    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year.toString();

    final hour = local.hour == 0
        ? 12
        : local.hour > 12
        ? local.hour - 12
        : local.hour;

    final minute = local.minute.toString().padLeft(2, '0');

    final period = local.hour >= 12 ? 'PM' : 'AM';

    return '$day/$month/$year • $hour:$minute $period';


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

    _reports = List<ReportAnalysis>.from(widget.reports);

    _sortReports();
  }

  // Sorts reports by priority:
  // High -> Medium -> Low
  // Newest reports appear first within the same severity.
  void _sortReports() {
    const severityPriority = {
      'High': 0,
      'Medium': 1,
      'Low': 2,
    };

    _reports.sort((a, b) {
      final severityA = severityPriority[a.severity] ?? 3;
      final severityB = severityPriority[b.severity] ?? 3;

      if (severityA != severityB) {
        return severityA.compareTo(severityB);
      }

      return b.dateTime.compareTo(a.dateTime);
    });
  }

  // Changes the report status while preserving all existing report data.
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
      imagePath: report.imagePath,
      dateTime: report.dateTime,
    );

    await widget.onStatusChanged(updatedReport);

    if (!mounted) return;

    setState(() {
      final index = _reports.indexWhere(
            (existingReport) => existingReport.id == updatedReport.id,
      );

      if (index != -1) {
        _reports[index] = updatedReport;
      }

      _sortReports();
    });
  }

  Color _severityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Resolved':
        return Colors.green;
      case 'Under Review':
        return Colors.blue;
      default:
        return Colors.orange;
    }
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

            final severityColor =
            _severityColor(report.severity);

            final statusColor =
            _statusColor(report.status);

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.stretch,
                  children: [
                    // Report photo
                    if (report.imagePath.isNotEmpty) ...[
                      ClipRRect(
                        borderRadius:
                        BorderRadius.circular(14),
                        child: Image.file(
                          File(report.imagePath),
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (context, error, stackTrace) {
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
                      const SizedBox(height: 14),
                    ],

                    // Category + severity
                    Row(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            report.category,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                              fontWeight:
                              FontWeight.bold,
                            ),
                          ),
                        ),

                        Container(
                          padding:
                          const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: severityColor
                                .withOpacity(0.1),
                            borderRadius:
                            BorderRadius.circular(20),
                          ),
                          child: Text(
                            report.severity,
                            style: TextStyle(
                              color: severityColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 18,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            report.location,
                            style: const TextStyle(
                              color: Colors.black54,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    Row(
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          size: 18,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            'Reported: '
                                '${report.dateTime.toLocal()}',
                            style: const TextStyle(
                              color: Colors.black54,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    Text(
                      report.description,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Current status
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.08),
                        borderRadius:
                        BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: statusColor,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Current Status: ',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: statusColor,
                            ),
                          ),
                          Text(
                            report.status,
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Admin status control
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

class _AdminInfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _AdminInfoChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
            size: 21,
          ),

          const SizedBox(width: 8),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


class AboutMeScreen extends StatelessWidget {
  const AboutMeScreen({super.key});

  static const Color primaryBlue = Color(0xFF42A5F5);
  static const Color lightBlue = Color(0xFFEAF6FF);
  static const Color darkText = Color(0xFF16324F);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'About the Team',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ==========================================
            // TEAM HEADER
            // ==========================================

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),

              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF42A5F5),
                    Color(0xFF64B5F6),
                  ],

                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),

                borderRadius: BorderRadius.circular(26),

                boxShadow: [
                  BoxShadow(
                    color: primaryBlue.withOpacity(0.20),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),

              child: Column(
                children: [

                  // Team icon
                  Container(
                    width: 82,
                    height: 82,

                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.20),
                      shape: BoxShape.circle,
                    ),

                    child: const Icon(
                      Icons.groups_rounded,
                      color: Colors.white,
                      size: 44,
                    ),
                  ),

                  const SizedBox(height: 16),

                  const Text(
                    'FixMyCity Team',
                    textAlign: TextAlign.center,

                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Working together to make civic reporting '
                        'smarter, faster and easier.',
                    textAlign: TextAlign.center,

                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // ==========================================
            // OUR TEAM
            // ==========================================

            const Text(
              'Our Team',

              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
                color: darkText,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              'Meet the people behind FixMyCity.',

              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),

            const SizedBox(height: 16),

            // Muhammad Safi
            _teamMemberCard(
              name: 'Muhammad Safi',
              role: 'Team Leader • AI API Development',
              icon: Icons.psychology_rounded,
            ),

            const SizedBox(height: 12),

            // Alishba Khan
            _teamMemberCard(
              name: 'Alishba Khan',
              role: 'Presentation • Documentation',
              icon: Icons.description_rounded,
            ),

            const SizedBox(height: 12),

            // Hoor Aina
            _teamMemberCard(
              name: 'Hoor Aina',
              role: 'Application Development',
              icon: Icons.phone_android_rounded,
            ),

            const SizedBox(height: 12),

            // Safa Hanif
            _teamMemberCard(
              name: 'Safa Hanif',
              role: 'Testing • Software Quality Assurance',
              icon: Icons.verified_rounded,
            ),

            const SizedBox(height: 30),

            // ==========================================
            // ABOUT PROJECT
            // ==========================================

            const Text(
              'About FixMyCity',

              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
                color: darkText,
              ),
            ),

            const SizedBox(height: 14),

            _AboutCard(
              icon: Icons.auto_awesome_rounded,
              title: 'AI-Powered Reporting',
              text:
              'FixMyCity uses AI to analyze images and identify '
                  'common road and civic issues.',
            ),

            const SizedBox(height: 12),

            _AboutCard(
              icon: Icons.camera_alt_rounded,
              title: 'Simple Reporting',
              text:
              'Users can take or select a photo of an issue and '
                  'submit it for analysis in just a few steps.',
            ),

            const SizedBox(height: 12),

            _AboutCard(
              icon: Icons.location_on_rounded,
              title: 'Built for Communities',
              text:
              'The application helps citizens highlight problems '
                  'in their surroundings and contribute to better cities.',
            ),

            const SizedBox(height: 30),

            // ==========================================
            // FOOTER
            // ==========================================

            Center(
              child: Column(
                children: [

                  Icon(
                    Icons.location_city_rounded,
                    color: primaryBlue.withOpacity(0.7),
                    size: 28,
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'FixMyCity',

                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: darkText,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    'Report. Improve. Connect.',

                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // TEAM MEMBER CARD
  // ==========================================

  Widget _teamMemberCard({
    required String name,
    required String role,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(18),

        border: Border.all(
          color: const Color(0xFFE2EDF5),
        ),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),

      child: Row(
        children: [

          // Icon
          Container(
            width: 54,
            height: 54,

            decoration: BoxDecoration(
              color: lightBlue,
              borderRadius: BorderRadius.circular(16),
            ),

            child: const Icon(
              Icons.person_rounded,
              color: primaryBlue,
              size: 28,
            ),
          ),

          const SizedBox(width: 15),

          // Name + role
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [

                Text(
                  name,

                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: darkText,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  role,

                  style: TextStyle(
                    fontSize: 13,
                    height: 1.3,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),

          // Small role icon
          Icon(
            icon,
            color: primaryBlue.withOpacity(0.75),
            size: 22,
          ),
        ],
      ),
    );
  }
}


class _AboutCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;

  const _AboutCard({
    required this.icon,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(18),

        border: Border.all(
          color: const Color(0xFFE2EDF5),
        ),
      ),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          // Icon
          Container(
            width: 46,
            height: 46,

            decoration: BoxDecoration(
              color: const Color(0xFFEAF6FF),
              borderRadius: BorderRadius.circular(14),
            ),

            child: Icon(
              icon,
              color: const Color(0xFF42A5F5),
              size: 23,
            ),
          ),

          const SizedBox(width: 14),

          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [

                Text(
                  title,

                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF16324F),
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  text,

                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}



