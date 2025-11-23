// lib/auth/signup_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  String? errorMessage;
  bool _obscurePassword = true;

  // ---------------------------------------------------
  // EMAIL SIGNUP
  // ---------------------------------------------------
  Future<void> registerUser() async {
    try {
      String email = emailController.text.trim();
      String fullName = fullNameController.text.trim();
      String password = passwordController.text.trim();

      if (email.isEmpty || password.isEmpty || fullName.isEmpty) {
        setState(() => errorMessage = "All fields are required");
        return;
      }

      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      final uid = userCredential.user!.uid;

      await FirebaseFirestore.instance.collection('Users').doc(uid).set({
        'email': email,
        'fullName': fullName,
        'role': "analyst",
        'status': "pending_verification",
        'createdAt': FieldValue.serverTimestamp(),
      });

      emailController.clear();
      fullNameController.clear();
      passwordController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Analyst Registered Successfully")),
      );

      Navigator.pushReplacementNamed(context, '/');

    } on FirebaseAuthException catch (e) {
      setState(() => errorMessage = e.message);
    } catch (e) {
      setState(() => errorMessage = "Error: $e");
    }
  }

  // ---------------------------------------------------
  // GOOGLE SIGNUP
  Future<void> googleSignUp() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(scopes: ['email']);

      // IMPORTANT: FORCE SIGN-OUT FIRST SO USER CAN CHOOSE ACCOUNT
      await googleSignIn.signOut();
      await FirebaseAuth.instance.signOut();

      // Now start fresh Google login
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) return; // user cancelled

      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );

      final UserCredential userCred =
      await FirebaseAuth.instance.signInWithCredential(credential);

      final User? user = userCred.user;
      if (user == null) return;

      // Check Firestore for user existance
      final docCheck = await FirebaseFirestore.instance
          .collection("Users")
          .doc(user.uid)
          .get();

      if (!docCheck.exists) {
        await FirebaseFirestore.instance.collection("Users").doc(user.uid).set({
          "email": user.email,
          "fullName": user.displayName ?? "",
          "role": "analyst",
          "status": "pending_verification",
          "createdAt": FieldValue.serverTimestamp(),
        });
      }

      Navigator.pushReplacementNamed(context, "/");

    } catch (e) {
      setState(() => errorMessage = "Google Sign-In Failed. Try Again.");
    }
  }

  // ---------------------------------------------------
  // UI DESIGN
  // ---------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],

      appBar: AppBar(
        title: const Text("User Registration"),
        backgroundColor: Colors.grey[900],
        centerTitle: true,
        elevation: 2,
      ),

      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
          child: Card(
            color: Colors.grey[200],
            elevation: 6,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),

            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Register Analyst",
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 8),
                  const Text(
                    "Create your account to access the dashboard",
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                  ),

                  const SizedBox(height: 24),

                  // FULL NAME
                  TextField(
                    controller: fullNameController,
                    decoration: InputDecoration(
                      labelText: "Full Name",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.person_outline),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // EMAIL
                  TextField(
                    controller: emailController,
                    decoration: InputDecoration(
                      labelText: "Email",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.email_outlined),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),

                  const SizedBox(height: 16),

                  // PASSWORD
                  TextField(
                    controller: passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: "Password",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () =>
                            setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // EMAIL SIGN UP BUTTON
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: registerUser,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[800],
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                      child: const Text(
                        "Sign Up",
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // GOOGLE SIGNUP BUTTON
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: googleSignUp,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: Colors.grey.shade700),
                        backgroundColor: Colors.white,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset("assets/google.png", height: 22),
                          const SizedBox(width: 10),
                          const Text(
                            "Sign Up with Google",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // BACK TO LOGIN
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () =>
                          Navigator.pushReplacementNamed(context, '/'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade600),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        "Back to Login",
                        style:
                        TextStyle(fontSize: 16, color: Colors.grey[800]),
                      ),
                    ),
                  ),

                  if (errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
