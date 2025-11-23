import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:geolocator/geolocator.dart';

import '../tflite_helper.dart';

class CreateReportPage extends StatefulWidget {
  const CreateReportPage({super.key});

  @override
  State<CreateReportPage> createState() => _CreateReportPageState();
}

class _CreateReportPageState extends State<CreateReportPage> {
  File? _selectedImage;
  File? _localImageCopy;
  bool _isLoading = false;

  WaterQualityModel? _model;
  bool _modelLoaded = false;

  final List<String> labels = [
    "Safe Water",
    "Moderately Contaminated",
    "Highly Contaminated",
  ];

  String? _analysis;
  String? _contamination;
  String? _selectedSource;

  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadModel();
    _requestLocationPermission();
  }

  // LOAD MODEL
  Future<void> _loadModel() async {
    _model = await WaterQualityModel.create();
    setState(() => _modelLoaded = true);
  }

  // PERMISSION ONLY
  Future<void> _requestLocationPermission() async {
    await Geolocator.requestPermission();
  }

  // GET LOCATION
  Future<void> _getLocation() async {
    try {
      bool enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        await Geolocator.openLocationSettings();
        return;
      }

      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) return;

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _latitudeController.text = pos.latitude.toString();
      _longitudeController.text = pos.longitude.toString();
      setState(() {});
    } catch (e) {
      print("Location error: $e");
    }
  }

  // COPY IMAGE TO TEMP
  Future<File> _copyToLocalDirectory(File original) async {
    final dir = await getTemporaryDirectory();
    final newFile = File("${dir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg");
    return await original.copy(newFile.path);
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await ImagePicker().pickImage(source: source);
      if (picked == null) return;

      _selectedImage = File(picked.path);
      _localImageCopy = await _copyToLocalDirectory(_selectedImage!);

      await _getLocation();
      await _runModel();

      setState(() {});
    } catch (e) {
      print("Image pick error: $e");
    }
  }

  // PROCESS URL IMAGE
  Future<void> _processUrl(String url) async {
    try {
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        final temp = File(
            "${Directory.systemTemp.path}/${DateTime.now().millisecondsSinceEpoch}.jpg");

        await temp.writeAsBytes(res.bodyBytes);

        _selectedImage = temp;
        _localImageCopy = await _copyToLocalDirectory(temp);

        await _getLocation();
        await _runModel();
        setState(() {});
      }
    } catch (e) {
      print("URL error: $e");
    }
  }

  // AI PREDICTION
  Future<void> _runModel() async {
    if (!_modelLoaded || _localImageCopy == null) return;

    final result = _model!.predictClass(_localImageCopy!.path);

    if (result == "safe") {
      _analysis = labels[0];
      _contamination = labels[0];
    } else if (result == "moderate") {
      _analysis = labels[1];
      _contamination = labels[1];
    } else {
      _analysis = labels[2];
      _contamination = labels[2];
    }

    setState(() {});
  }

  // Convert image to Base64 and return string
  Future<String?> _convertImageToBase64() async {
    if (_localImageCopy == null) return null;
    try {
      final bytes = await _localImageCopy!.readAsBytes();
      return base64Encode(bytes);
    } catch (e) {
      print("Base64 error: $e");
      return null;
    }
  }

  // RESET FORM
  void _resetForm() {
    _notesController.clear();
    _urlController.clear();
    _latitudeController.clear();
    _longitudeController.clear();
    _selectedImage = null;
    _localImageCopy = null;
    _analysis = null;
    _contamination = null;
    _selectedSource = null;
    setState(() {});
  }

  // SUBMIT REPORT
  Future<void> _submitReport() async {
    final user = FirebaseAuth.instance.currentUser;

    if (!canSubmit) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Complete all steps first")));
      return;
    }

    setState(() => _isLoading = true);

    String? base64Image = await _convertImageToBase64();

    await FirebaseFirestore.instance.collection("Reports").add({
      "userId": user!.uid,
      "email": user.email,
      "analysis": _analysis,
      "contaminationLevel": _contamination,
      "latitude": _latitudeController.text,
      "longitude": _longitudeController.text,
      "notes": _notesController.text,
      "imageBase64": base64Image, // STORED HERE
      "timestamp": FieldValue.serverTimestamp(),
      "status": "pending",
    });

    setState(() => _isLoading = false);

    _resetForm();

    Navigator.pushReplacementNamed(context, "/analyst");

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Report Submitted")));
  }

  // ALLOW SUBMIT?
  bool get canSubmit {
    return _analysis != null &&
        _localImageCopy != null &&
        _latitudeController.text.isNotEmpty &&
        _longitudeController.text.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Report")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: _selectedSource,
              items: ["Camera", "Gallery", "URL"]
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedSource = v),
              decoration: const InputDecoration(labelText: "Select Source"),
            ),

            const SizedBox(height: 16),

            if (_selectedSource == "Camera" || _selectedSource == "Gallery")
              ElevatedButton(
                onPressed: () => _pickImage(
                    _selectedSource == "Camera"
                        ? ImageSource.camera
                        : ImageSource.gallery),
                child: Text(_selectedSource == "Camera"
                    ? "Capture Image"
                    : "Upload Image"),
              ),

            if (_selectedSource == "URL") ...[
              TextField(
                controller: _urlController,
                decoration: const InputDecoration(labelText: "Paste Image URL"),
              ),
              ElevatedButton(
                onPressed: () => _processUrl(_urlController.text.trim()),
                child: const Text("Load Image"),
              ),
            ],

            if (_localImageCopy != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Image.file(_localImageCopy!, height: 220),
              ),

            if (_analysis != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Analysis: $_analysis",
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  Text("Contamination: $_contamination"),
                ],
              ),

            const SizedBox(height: 20),

            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: "Notes"),
            ),

            const SizedBox(height: 20),

            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton.icon(
              onPressed: canSubmit ? _submitReport : null,
              icon: const Icon(Icons.send),
              label: const Text("Submit Report"),
            ),
          ],
        ),
      ),
    );
  }
}
