import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_storage/firebase_storage.dart';
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
    _getLocation(); // AUTO LOCATION FETCH
  }

  // Load Model
  Future<void> _loadModel() async {
    _model = await WaterQualityModel.create();
    setState(() => _modelLoaded = true);
    print("MODEL READY");
  }

  // Request Permission
  Future<void> _requestLocationPermission() async {
    await Geolocator.requestPermission();
  }

  // Get Location
  Future<void> _getLocation() async {
    try {
      bool enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        print("❌ Location OFF — Opening Settings");
        await Geolocator.openLocationSettings();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        print("❌ Location Permanently Denied");
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _latitudeController.text = pos.latitude.toString();
      _longitudeController.text = pos.longitude.toString();

      print("📍 LOCATION FETCHED = ${pos.latitude}, ${pos.longitude}");

      setState(() {});

    } catch (e) {
      print("LOCATION ERROR: $e");
    }
  }

  // Copy file to temp folder
  Future<File> _copyToLocalDirectory(File original) async {
    final dir = await getTemporaryDirectory();
    final newFile = File("${dir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg");
    print("📁 SAVING LOCAL COPY → ${newFile.path}");
    return await original.copy(newFile.path);
  }

  // Pick Image
  Future<void> _pickImage(ImageSource source) async {
    final picked = await ImagePicker().pickImage(source: source);
    if (picked != null) {
      _selectedImage = File(picked.path);
      _localImageCopy = await _copyToLocalDirectory(_selectedImage!);

      await _runModel();
      setState(() {});
    }
  }

  // Load from URL
  Future<void> _processUrl(String url) async {
    try {
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        final temp = File(
            "${Directory.systemTemp.path}/${DateTime.now().millisecondsSinceEpoch}.jpg");

        await temp.writeAsBytes(res.bodyBytes);

        _selectedImage = temp;
        _localImageCopy = await _copyToLocalDirectory(temp);

        await _runModel();
        setState(() {});
      }
    } catch (e) {
      print("URL ERROR: $e");
    }
  }

  // Run TFLite Model
  Future<void> _runModel() async {
    if (!_modelLoaded || _localImageCopy == null) {
      print("❌ MODEL NOT READY OR IMAGE NULL");
      return;
    }

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

    print("🔍 FINAL PREDICTION = $_analysis");
  }

  // Upload Image
  Future<String?> _uploadImage() async {
    if (_localImageCopy == null) {
      print("❌ No local image to upload");
      return null;
    }

    try {
      final ref = FirebaseStorage.instance.ref(
          "ReportImages/${DateTime.now().millisecondsSinceEpoch}.jpg");

      print("⬆ Uploading to: ${ref.fullPath}");
      print("📄 Local Exists: ${_localImageCopy!.existsSync()}");

      await ref.putFile(_localImageCopy!);

      String url = await ref.getDownloadURL();
      print("✅ UPLOADED → $url");
      return url;

    } catch (e) {
      print("❌ IMAGE UPLOAD ERROR: $e");
      return null;
    }
  }

  // Save Report
  Future<void> _submitReport() async {
    final user = FirebaseAuth.instance.currentUser;

    if (_analysis == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Analyze image first")));
      return;
    }

    setState(() => _isLoading = true);

    String? imgUrl = await _uploadImage();

    await FirebaseFirestore.instance.collection("Reports").add({
      "userId": user!.uid,
      "email": user.email,
      "analysis": _analysis,
      "contaminationLevel": _contamination,
      "latitude": _latitudeController.text,
      "longitude": _longitudeController.text,
      "notes": _notesController.text,
      "imageURL": imgUrl,
      "timestamp": FieldValue.serverTimestamp(),
      "status": "pending",
    });

    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Report Submitted")));
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
                child: Text(
                    _selectedSource == "Camera" ? "Capture Image" : "Upload Image"),
              ),

            if (_selectedSource == "URL") ...[
              TextField(
                controller: _urlController,
                decoration:
                const InputDecoration(labelText: "Paste Image URL"),
              ),
              ElevatedButton(
                  onPressed: () =>
                      _processUrl(_urlController.text.trim()),
                  child: const Text("Load Image")),
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
              onPressed: _submitReport,
              icon: const Icon(Icons.send),
              label: const Text("Submit Report"),
            ),
          ],
        ),
      ),
    );
  }
}
