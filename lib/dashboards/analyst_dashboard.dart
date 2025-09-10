import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:geolocator/geolocator.dart';

class AnalystDashboard extends StatefulWidget {
  const AnalystDashboard({super.key});

  @override
  State<AnalystDashboard> createState() => _AnalystDashboardState();
}

class _AnalystDashboardState extends State<AnalystDashboard> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  File? _selectedImage;
  String? _analysisResult;
  bool _loading = false;
  String? _error;

  // --- IMAGE PICKER ---
  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(source: source);
    if (!mounted) return;
    setState(() {
      if (pickedFile != null) {
        _selectedImage = File(pickedFile.path);
      }
    });
  }

  // --- IMAGE UPLOAD ---
  Future<String?> _uploadImage(File image, String reportId) async {
    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('Reports/${DateTime.now().millisecondsSinceEpoch}.jpg');
      await storageRef.putFile(image);
      return await storageRef.getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  // --- ANALYSIS ---
  Future<void> _analyzeImage() async {
    if (_selectedImage == null) {
      if (!mounted) return;
      setState(() => _error = "Please capture or select an image first.");
      return;
    }

    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    await Future.delayed(const Duration(milliseconds: 700)); // fake delay

    // Random result
    final r = Random().nextInt(100);
    String result;
    if (r < 60) {
      result = "Safe Water";
    } else if (r < 90) {
      result = "Moderately Contaminated";
    } else {
      result = "Highly Contaminated";
    }

    if (!mounted) return;
    setState(() {
      _analysisResult = result;
      _loading = false;
    });
  }

  // --- GET LOCATION ---
  Future<GeoPoint?> _tryGetLocation() async {
    try {
      final pos = await Geolocator.getCurrentPosition();
      return GeoPoint(pos.latitude, pos.longitude);
    } catch (_) {
      return null;
    }
  }

  // --- SUBMIT REPORT ---
  Future<void> _submitReport() async {
    if (_selectedImage == null) {
      if (!mounted) return;
      setState(() {
        _error = "Please select or capture an image before submitting.";
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    final user = _auth.currentUser;
    if (user == null) {
      if (!mounted) return;
      setState(() {
        _error = "You must be logged in to submit a report.";
        _loading = false;
      });
      return;
    }

    final reportDoc = _firestore.collection('Reports').doc();
    final reportId = reportDoc.id;

    GeoPoint? location = await _tryGetLocation();
    String? imageUrl = await _uploadImage(_selectedImage!, reportId);

    final data = {
      'createdBy': user.uid,
      'email': user.email ?? '',
      'analysis': _analysisResult ?? 'Unknown',
      'imageUrl': imageUrl ?? '',
      'location': location,
      'contaminationLevel': _analysisResult ?? 'Unknown',
      'createdAt': FieldValue.serverTimestamp(),
      'synced': (imageUrl != null),
    };

    try {
      await reportDoc.set(data);
      if (!mounted) return;
      setState(() {
        _selectedImage = null;
        _analysisResult = null;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Report submitted successfully")),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = "Failed to save report: $e";
      });
    }

    if (!mounted) return;
    setState(() {
      _loading = false;
    });
  }

  // --- LOGOUT ---
  Future<void> _logout() async {
    await _auth.signOut();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/login');
  }

  // --- UI ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Analyst Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_error != null)
              Text(
                _error!,
                style: const TextStyle(color: Colors.red),
              ),
            const SizedBox(height: 10),

            // image preview
            _selectedImage != null
                ? Image.file(
              _selectedImage!,
              height: 200,
              fit: BoxFit.cover,
            )
                : Container(
              height: 200,
              color: Colors.grey[300],
              child: const Center(child: Text("No image selected")),
            ),

            const SizedBox(height: 10),

            // buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.camera_alt),
                  label: const Text("Capture"),
                  onPressed: () => _pickImage(ImageSource.camera),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.photo),
                  label: const Text("Gallery"),
                  onPressed: () => _pickImage(ImageSource.gallery),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // analyze button
            ElevatedButton.icon(
              icon: const Icon(Icons.science),
              label: const Text("Analyze"),
              onPressed: _loading ? null : _analyzeImage,
            ),

            const SizedBox(height: 10),

            if (_loading) const CircularProgressIndicator(),

            if (_analysisResult != null)
              Text(
                "Result: $_analysisResult",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

            const SizedBox(height: 20),

            ElevatedButton.icon(
              icon: const Icon(Icons.upload),
              label: const Text("Submit Report"),
              onPressed: _loading ? null : _submitReport,
            ),
          ],
        ),
      ),
    );
  }
}
