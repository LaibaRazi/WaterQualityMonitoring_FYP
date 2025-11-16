import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class CreateReportPage extends StatefulWidget {
  const CreateReportPage({super.key});

  @override
  State<CreateReportPage> createState() => _CreateReportPageState();
}

class _CreateReportPageState extends State<CreateReportPage> {
  File? _selectedImage;
  bool _isLoading = false;

  Interpreter? _interpreter;
  bool _modelLoaded = false;

  final List<String> _labels = [
    "Safe Water",
    "Moderately Contaminated",
    "Highly Contaminated"
  ];

  String? _analysis;
  String? _contaminationLevel;

  String? _selectedSource;

  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();

  // ==========================
  // LOAD MODEL
  // ==========================
  Future<void> _loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset("water_model.tflite");
      setState(() => _modelLoaded = true);
      print("MODEL LOADED SUCCESSFULLY");
    } catch (e) {
      print("ERROR LOADING MODEL: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    _loadModel();
  }

  // ==========================
  // PICK IMAGE
  // ==========================
  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source);

    if (picked != null) {
      setState(() => _selectedImage = File(picked.path));
      await _runTFLiteModel();
    }
  }

  // ==========================
  // URL IMAGE
  // ==========================
  Future<void> _processUrl(String url) async {
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final temp = File(
            "${Directory.systemTemp.path}/${DateTime.now().millisecondsSinceEpoch}.jpg");
        await temp.writeAsBytes(response.bodyBytes);

        setState(() => _selectedImage = temp);
        await _runTFLiteModel();
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("URL Error: $e")));
    }
  }

  // ==========================
  // RUN MODEL
  // ==========================
  Future<void> _runTFLiteModel() async {
    if (!_modelLoaded || _selectedImage == null) return;

    try {
      final bytes = await _selectedImage!.readAsBytes();
      img.Image? decoded = img.decodeImage(bytes);

      if (decoded == null) return;

      img.Image resized = img.copyResize(decoded, width: 224, height: 224);

      List<List<List<List<double>>>> input = [
        List.generate(
          224,
              (y) => List.generate(
            224,
                (x) {
              final p = resized.getPixel(x, y);

              // FIXED PIXEL EXTRACTION
              final r = img.Pixel.r(p);
              final g = img.Pixel.g(p);
              final b = img.Pixel.b(p);

              return [
                r / 255.0,
                g / 255.0,
                b / 255.0,
              ];
            },
          ),
        ),
      ];

      List<List<double>> output = [
        [0.0, 0.0, 0.0]
      ];

      _interpreter!.run(input, output);

      double highest = -1;
      int index = 0;

      for (int i = 0; i < output[0].length; i++) {
        if (output[0][i] > highest) {
          highest = output[0][i];
          index = i;
        }
      }

      setState(() {
        _analysis = _labels[index];
        _contaminationLevel = _labels[index];
      });

    } catch (e) {
      print("PREDICTION ERROR: $e");
    }
  }

  // ==========================
  // SUBMIT REPORT
  // ==========================
  Future<void> _submitReport() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("You must be logged in")));
      return;
    }

    if (_analysis == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Analyze image first")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance.collection("Reports").add({
        "userId": user.uid,
        "email": user.email,
        "analysis": _analysis,
        "contaminationLevel": _contaminationLevel,
        "latitude": _latitudeController.text,
        "longitude": _longitudeController.text,
        "notes": _notesController.text,
        "timestamp": FieldValue.serverTimestamp(),
        "status": "pending",
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Report Submitted")));
    } catch (e) {
      print("Firestore Error: $e");
    }

    setState(() => _isLoading = false);
  }

  // ==========================
  // UI
  // ==========================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Report"), backgroundColor: Colors.blue),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                value: _selectedSource,
                decoration: const InputDecoration(
                    labelText: "Select Source", border: OutlineInputBorder()),
                items: ["Camera", "Gallery", "URL"]
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedSource = v),
              ),

              const SizedBox(height: 16),

              if (_selectedSource == "Camera" || _selectedSource == "Gallery")
                ElevatedButton.icon(
                  onPressed: () => _pickImage(
                      _selectedSource == "Camera"
                          ? ImageSource.camera
                          : ImageSource.gallery),
                  icon: const Icon(Icons.camera_alt),
                  label: Text(_selectedSource == "Camera"
                      ? "Capture Image"
                      : "Upload Image"),
                ),

              if (_selectedSource == "URL")
                TextField(
                  controller: _urlController,
                  decoration: const InputDecoration(
                      labelText: "Paste Image URL", border: OutlineInputBorder()),
                ),

              const SizedBox(height: 16),

              if (_selectedImage != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(_selectedImage!, height: 200),
                ),

              const SizedBox(height: 16),

              if (_analysis != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Analysis: $_analysis",
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    Text("Contamination: $_contaminationLevel"),
                  ],
                ),

              const SizedBox(height: 16),

              TextField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                    labelText: "Notes", border: OutlineInputBorder()),
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
      ),
    );
  }
}
