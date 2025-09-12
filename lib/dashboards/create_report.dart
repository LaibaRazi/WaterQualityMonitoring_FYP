import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

class CreateReportPage extends StatefulWidget {
  const CreateReportPage({super.key});

  @override
  State<CreateReportPage> createState() => _CreateReportPageState();
}

class _CreateReportPageState extends State<CreateReportPage> {
  File? _selectedImage; // For temporary analysis only
  bool _isLoading = false;
  String? _analysis;
  String? _contaminationLevel;

  String? _selectedSource; // Dropdown: Camera / Gallery / URL
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();

  /// Pick image from camera or gallery
  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source);

    if (picked != null) {
      setState(() {
        _selectedImage = File(picked.path);
        _runAnalysisOnImage();
      });
    }
  }

  /// Process image from URL
  Future<void> _processUrl(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final tempDir = Directory.systemTemp;
        final tempFile = File(
            '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg');
        await tempFile.writeAsBytes(response.bodyBytes);
        setState(() {
          _selectedImage = tempFile;
          _runAnalysisOnImage();
        });
      } else {
        throw Exception("Failed to load image from URL");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("URL error: $e")),
      );
    }
  }

  /// Run analysis on the selected image (mocked)
  void _runAnalysisOnImage() {
    final r = Random().nextInt(100);
    if (r < 60) _analysis = "Safe Water";
    else if (r < 90) _analysis = "Moderately Contaminated";
    else _analysis = "Highly Contaminated";

    _contaminationLevel = _analysis;
  }

  /// Submit report (without saving image)
  Future<void> _submitReport() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You must be logged in to submit reports")),
      );
      return;
    }

    if (_analysis == null || _contaminationLevel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please run analysis first")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance.collection("Reports").add({
        "userId": user.uid,
        "email": user.email ?? "",
        "analysis": _analysis ?? "",
        "contaminationLevel": _contaminationLevel ?? "",
        "latitude": _latitudeController.text.trim(),
        "longitude": _longitudeController.text.trim(),
        "notes": _notesController.text.trim(),
        "timestamp": FieldValue.serverTimestamp(),
        "status": "pending",
        "synced": true,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Report submitted successfully ✅")),
      );

      // Clear fields after submission
      setState(() {
        _selectedImage = null;
        _analysis = null;
        _contaminationLevel = null;
        _notesController.clear();
        _urlController.clear();
        _latitudeController.clear();
        _longitudeController.clear();
        _selectedSource = null;
      });
    } catch (e) {
      debugPrint("Firestore error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to save report: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Report"), backgroundColor: Colors.blue),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        DropdownButtonFormField<String>(
                          value: _selectedSource,
                          decoration: const InputDecoration(
                              labelText: "Select Source", border: OutlineInputBorder()),
                          items: ["Camera", "Gallery", "URL"]
                              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                              .toList(),
                          onChanged: (val) => setState(() => _selectedSource = val),
                        ),
                        const SizedBox(height: 16),

                        if (_selectedSource == "Camera" || _selectedSource == "Gallery")
                          ElevatedButton.icon(
                            onPressed: () => _pickImage(
                                _selectedSource == "Camera" ? ImageSource.camera : ImageSource.gallery),
                            icon: const Icon(Icons.camera_alt),
                            label: Text(
                                _selectedSource == "Camera" ? "Capture Image" : "Upload Image"),
                          ),

                        if (_selectedSource == "URL")
                          TextField(
                            controller: _urlController,
                            decoration: const InputDecoration(
                              labelText: "Paste Image URL",
                              border: OutlineInputBorder(),
                            ),
                          ),
                        const SizedBox(height: 16),

                        if (_selectedImage != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(_selectedImage!, height: 200, fit: BoxFit.cover),
                          ),
                        const SizedBox(height: 16),

                        if (_analysis != null)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Analysis: $_analysis",
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              Text("Contamination Level: $_contaminationLevel"),
                            ],
                          ),
                        const SizedBox(height: 16),

                        TextField(
                          controller: _latitudeController,
                          decoration: const InputDecoration(
                            labelText: "Latitude (optional)",
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),

                        TextField(
                          controller: _longitudeController,
                          decoration: const InputDecoration(
                            labelText: "Longitude (optional)",
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),

                        TextField(
                          controller: _notesController,
                          decoration: const InputDecoration(
                            labelText: "Notes (optional)",
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 16),

                        _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : ElevatedButton.icon(
                          onPressed: _submitReport,
                          icon: const Icon(Icons.send),
                          label: const Text("Submit Report"),
                        ),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
