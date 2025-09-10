import 'package:flutter/material.dart';
import 'auth/login_page.dart';
import 'auth/signup_page.dart';
import 'home_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dashboards/analyst_dashboard.dart';
import 'dashboards/admin_dashboard.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Run the app immediately so UI doesn't freeze
  runApp(MyApp());

  // Run admin check in background
  _ensureAdminExists();
}

/// Ensures that a default Admin account exists
Future<void> _ensureAdminExists() async {
  try {
    final firestore = FirebaseFirestore.instance;

    // Check if an admin exists in Firestore
    final query = await firestore
        .collection('Users')
        .where('role', isEqualTo: 'admin')
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      try {
        // Try to create the admin in Auth
        UserCredential adminUser =
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: "admin@gmail.com",
          password: "admin123",
        );

        // Save to Firestore
        await firestore.collection('Users').doc(adminUser.user!.uid).set({
          'email': "admin@gmail.com",
          'role': "admin",
          'createdAt': FieldValue.serverTimestamp(),
        });

        debugPrint("✅ Admin account created successfully.");
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          // Admin exists in Auth but not Firestore → Fix by re-inserting Firestore doc
          final existingUser = await FirebaseAuth.instance
              .signInWithEmailAndPassword(
              email: "admin@gmail.com", password: "admin123");

          await firestore.collection('Users').doc(existingUser.user!.uid).set({
            'email': "admin@gmail.com",
            'role': "admin",
            'createdAt': FieldValue.serverTimestamp(),
          });

          debugPrint(
              "⚠️ Admin already existed in Auth. Firestore entry recreated.");
        } else {
          debugPrint("❌ Error creating admin: ${e.message}");
        }
      }
    } else {
      debugPrint("✅ Admin already exists, skipping creation.");
    }
  } catch (e) {
    debugPrint("❌ Error ensuring admin exists: $e");
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // <- removes the debug banner
      title: 'AI Water Quality',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/',
      routes: {
        '/': (context) => LoginPage(),
        '/signup': (context) => SignUpPage(),
        '/home': (context) => HomePage(),
        '/analyst': (context) => AnalystDashboard(),
        '/admin': (context) => AdminDashboard(),
      },
    );
  }
}
