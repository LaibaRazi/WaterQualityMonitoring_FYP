import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? role;
  String? email;
  String? fullName;

  @override
  void initState() {
    super.initState();
    _getUserData();
  }

  /// Fetch user data from Users collection
  Future<void> _getUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final userDoc =
    await FirebaseFirestore.instance.collection("Users").doc(uid).get();

    if (userDoc.exists) {
      role = userDoc['role'];
      email = userDoc['email'];
      fullName = userDoc['fullName'];
    }

    setState(() {});
  }

  /// LOGOUT
  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, '/');
  }

  /// EDIT PROFILE POPUP
  void _editProfile() {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    TextEditingController nameController =
    TextEditingController(text: fullName ?? "");

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title:
          Text("Edit Profile", style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              /// EMAIL (READ ONLY)
              TextField(
                readOnly: true,
                decoration: InputDecoration(
                  labelText: "Email",
                  hintText: email,
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 10),

              /// FULL NAME
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: "Full Name",
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context), child: Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection("Users")
                    .doc(uid)
                    .update({
                  "fullName": nameController.text.trim(),
                });

                Navigator.pop(context);
                _getUserData();
              },
              child: Text("Save"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (role == null) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Dashboard"),
        backgroundColor: Colors.blueAccent,
        actions: [
          if (role == "analyst")
            IconButton(
              icon: Icon(Icons.edit),
              tooltip: "Edit Profile",
              onPressed: _editProfile,
            ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: role == "admin" ? _buildAdminScreen() : _buildFancyAnalystScreen(),
      ),

      // ANALYST NAV BAR
      bottomNavigationBar: role == "analyst"
          ? BottomNavigationBar(
        currentIndex: 1,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        onTap: (i) {
          if (i == 0) Navigator.pushNamed(context, "/create_report");
          if (i == 1)
            Navigator.pushReplacementNamed(context, "/analyst");
          if (i == 2) _logout(context);
        },
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.add_chart), label: "Create Report"),
          BottomNavigationBarItem(
              icon: Icon(Icons.list_alt), label: "My Reports"),
          BottomNavigationBarItem(
              icon: Icon(Icons.logout), label: "Logout"),
        ],
      )
          : null,
    );
  }

  /// ⭐ BEAUTIFUL ANALYST PROFILE CARD
  Widget _buildFancyAnalystScreen() {
    return Center(
      child: Card(
        elevation: 8,
        shadowColor: Colors.blueAccent.withOpacity(0.4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              /// PROFILE IMAGE
              CircleAvatar(
                radius: 45,
                backgroundColor: Colors.blueAccent,
                child: Icon(Icons.person, size: 50, color: Colors.white),
              ),
              SizedBox(height: 15),

              /// FULL NAME
              Text(
                fullName ?? "No Name",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),

              SizedBox(height: 8),

              /// EMAIL
              Text(email!,
                  style: TextStyle(fontSize: 16, color: Colors.grey[700])),

              SizedBox(height: 20),

              /// 🔵 HELP & SUPPORT BUTTON
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/help');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: Icon(Icons.help_outline, color: Colors.white),
                  label: Text(
                    "Help & Support",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ADMIN SCREEN
  Widget _buildAdminScreen() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Admin Dashboard",
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
        SizedBox(height: 15),
        Text("Logged in as: $email",
            style: TextStyle(fontSize: 16, color: Colors.grey[700])),
        SizedBox(height: 15),
      ],
    );
  }
}
