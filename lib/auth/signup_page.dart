import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignUpPage extends StatefulWidget {
  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  String? errorMessage = '';
  bool adminExists = false; // track if admin already created

  @override
  void initState() {
    super.initState();
    _checkIfAdminExists();
  }

  /// Check if admin@gmail.com exists in Firestore
  Future<void> _checkIfAdminExists() async {
    final adminDoc = await FirebaseFirestore.instance
        .collection('Users')
        .where('email', isEqualTo: 'admin@gmail.com')
        .get();

    setState(() {
      adminExists = adminDoc.docs.isNotEmpty;
    });
  }

  /// Register user in Firebase Authentication + Firestore
  Future<void> registerUser() async {
    try {
      String email = emailController.text.trim();
      String password = passwordController.text.trim();

      // If no admin yet, enforce admin creation first
      if (!adminExists) {
        if (email != "admin@gmail.com" || password != "admin123") {
          setState(() {
            errorMessage = "⚠️ First account must be admin@gmail.com / admin123";
          });
          return;
        }
      }

      // Create user in Firebase Authentication
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = userCredential.user!.uid;

      // ✅ Assign role
      String role = (email == "admin@gmail.com") ? "admin" : "analyst";

      // Store user profile in Firestore
      await FirebaseFirestore.instance.collection('Users').doc(uid).set({
        'email': email,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Refresh admin check
      await _checkIfAdminExists();

      // Clear input fields
      setState(() {
        emailController.clear();
        passwordController.clear();
        errorMessage = '';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ $role Registered Successfully!")),
      );

      // Redirect after short delay
      Future.delayed(const Duration(milliseconds: 500), () {
        Navigator.pushReplacementNamed(context, '/');
      });
    } on FirebaseAuthException catch (e) {
      setState(() {
        errorMessage = e.message;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error: ${e.message}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(title: const Text("Sign Up")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (adminExists) ...[
              // Normal signup form (analysts only)
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: "Email"),
                keyboardType: TextInputType.emailAddress,
              ),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(labelText: "Password"),
                obscureText: true,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: registerUser,
                child: const Text("Sign Up"),
              ),
            ] else ...[
              // Only show admin creation form
              const Text(
                "⚠️ First user must be Admin\n(admin@gmail.com / admin123)",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red, fontSize: 16),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: "Admin Email"),
                keyboardType: TextInputType.emailAddress,
              ),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(labelText: "Admin Password"),
                obscureText: true,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: registerUser,
                child: const Text("Create Admin"),
              ),
            ],

            if (errorMessage != null && errorMessage!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
