import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  String? errorMessage = '';

  /// Login user with Firebase Auth
  Future<void> loginUser() async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      // Success
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Login Successful!")),
      );

      // Navigate to home (you’ll later replace with role-based redirect)
      Navigator.pushReplacementNamed(context, '/home');
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
    return Scaffold(
      appBar: AppBar(title: const Text("Login")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
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
              onPressed: loginUser,
              child: const Text("Login"),
            ),

            if (errorMessage != null && errorMessage!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),

            const SizedBox(height: 20),

            // 👇 New Sign Up button
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/signup');
              },
              child: const Text(
                "Don't have an account? Sign Up",
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
