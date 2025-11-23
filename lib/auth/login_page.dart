import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  String? errorMessage;

  /// GOOGLE SIGN-IN
  Future<void> loginWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(scopes: ['email']);

      // IMPORTANT: FORCE SIGN-OUT FIRST
      await googleSignIn.signOut();
      await FirebaseAuth.instance.signOut();

      // Now user will see account chooser
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );

      UserCredential userCredential =
      await FirebaseAuth.instance.signInWithCredential(credential);

      String uid = userCredential.user!.uid;

      // Check if user doc exists
      DocumentSnapshot userDoc =
      await FirebaseFirestore.instance.collection("Users").doc(uid).get();

      if (!userDoc.exists) {
        // Register first-time Google login as analyst
        await FirebaseFirestore.instance.collection("Users").doc(uid).set({
          "email": userCredential.user!.email,
          "fullName": userCredential.user!.displayName ?? "Unknown User",
          "role": "analyst",
          "status": "pending_verification",
          "createdAt": FieldValue.serverTimestamp(),
        });
      }

      // Read role
      userDoc =
      await FirebaseFirestore.instance.collection("Users").doc(uid).get();
      String role = userDoc["role"];

      if (role == "admin") {
        Navigator.pushReplacementNamed(context, "/admin");
      } else {
        Navigator.pushReplacementNamed(context, "/analyst");
      }

    } catch (e) {
      setState(() {
        errorMessage = "Google Sign-in failed: $e";
      });
    }
  }


  /// EMAIL/PASSWORD LOGIN
  Future<void> loginUser() async {
    try {
      String email = emailController.text.trim();
      String password = passwordController.text.trim();

      if (email.isEmpty || password.isEmpty) {
        setState(() => errorMessage = "Email and password cannot be empty");
        return;
      }

      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      // Fetch Role
      final doc = await FirebaseFirestore.instance
          .collection("Users")
          .doc(userCredential.user!.uid)
          .get();

      if (doc.exists) {
        String role = doc["role"];

        if (role == "admin") {
          Navigator.pushReplacementNamed(context, "/admin");
        } else {
          Navigator.pushReplacementNamed(context, "/analyst");
        }
      } else {
        setState(() => errorMessage = "User role not found in database");
      }
    } on FirebaseAuthException catch (e) {
      setState(() => errorMessage = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Login"),
        backgroundColor: Colors.grey[900],
        centerTitle: true,
      ),

      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
          child: Card(
            color: Colors.grey[200],
            elevation: 6,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text("Welcome Back",
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text("Log in to access your dashboard",
                    style: TextStyle(fontSize: 16, color: Colors.black54)),
                const SizedBox(height: 24),

                // Email
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                      labelText: "Email",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.email_outlined)),
                ),
                const SizedBox(height: 16),

                // Password
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                      labelText: "Password",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.lock_outline)),
                ),

                const SizedBox(height: 16),

                /// LOGIN BUTTON
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: loginUser,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[800],
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("Login",
                        style: TextStyle(fontSize: 16, color: Colors.white)),
                  ),
                ),

                const SizedBox(height: 20),

                /// GOOGLE SIGN-IN
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: loginWithGoogle,
                    icon: Image.asset("assets/google.png", height: 22),
                    label: const Text(
                      "Sign in with Google",
                      style: TextStyle(fontSize: 16),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: Colors.grey.shade700),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                /// SIGN UP BUTTON
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () =>
                        Navigator.pushReplacementNamed(context, "/signup"),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: Colors.grey.shade700),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("Create Account",
                        style: TextStyle(fontSize: 16)),
                  ),
                ),

                if (errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(errorMessage!,
                        style: const TextStyle(color: Colors.red)),
                  ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
