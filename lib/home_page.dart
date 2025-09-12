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
  String? name;
  String? gender;

  @override
  void initState() {
    super.initState();
    _getUserData();
  }

  /// Fetch role from Users collection & profile from infouser
  Future<void> _getUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final userDoc =
    await FirebaseFirestore.instance.collection("Users").doc(uid).get();

    if (userDoc.exists) {
      role = userDoc['role'];
      email = userDoc['email'];
    }

    final infoDoc =
    await FirebaseFirestore.instance.collection("infouser").doc(uid).get();

    if (infoDoc.exists) {
      name = infoDoc['name'];
      gender = infoDoc['gender'];
    }

    setState(() {});
  }

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, '/');
  }

  void _editProfile() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    // Default name = part before @ if empty
    String defaultName = name ?? (email != null ? email!.split("@")[0] : "");

    TextEditingController nameController =
    TextEditingController(text: defaultName);
    String selectedGender = gender ?? "Other";

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Edit Profile"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Email field (read-only)
              TextField(
                readOnly: true,
                decoration: InputDecoration(
                  labelText: "Email",
                  hintText: email,
                ),
              ),
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: "Name"),
              ),
              DropdownButtonFormField<String>(
                value: selectedGender,
                items: ["Male", "Female", "Other"]
                    .map((g) => DropdownMenuItem(
                  value: g,
                  child: Text(g),
                ))
                    .toList(),
                onChanged: (val) {
                  if (val != null) selectedGender = val;
                },
                decoration: InputDecoration(labelText: "Gender"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection("infouser")
                    .doc(uid)
                    .set({
                  "email": email,
                  "name": nameController.text.trim(),
                  "gender": selectedGender,
                }, SetOptions(merge: true));

                Navigator.pop(context);
                _getUserData(); // Refresh UI
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
    if (role == null || email == null) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Dashboard"),
        backgroundColor: Colors.blueGrey,
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            tooltip: "Edit Profile",
            onPressed: _editProfile,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: role == "admin" ? _buildAdminScreen() : _buildAnalystScreen(),
      ),

      // --- Bottom Navigation Bar ---
      bottomNavigationBar: BottomAppBar(
        color: Colors.blueGrey.shade100,
        shape: const CircularNotchedRectangle(),
        notchMargin: 6.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // Left button - Create Report
            IconButton(
              icon: const Icon(Icons.add_chart, color: Colors.blueGrey),
              onPressed: () {
                Navigator.pushNamed(context, "/create_report");
              },
            ),

            // Middle button - Home
            IconButton(
              icon: const Icon(Icons.home, color: Colors.blueGrey),
              onPressed: () {
                // refresh same page
                Navigator.pushReplacementNamed(context, "/home");
              },
            ),

            // Right button - Logout
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.redAccent),
              onPressed: () => _logout(context),
            ),
          ],
        ),
      ),
    );
  }

  /// Analyst screen
  Widget _buildAnalystScreen() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.analytics_outlined, size: 70, color: Colors.blueGrey),
        SizedBox(height: 20),
        Text("Analyst Dashboard",
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
        SizedBox(height: 10),
        Text("Welcome, $email",
            style: TextStyle(fontSize: 16, color: Colors.grey[700])),
        if (name != null) Text("Name: $name"),
        if (gender != null) Text("Gender: $gender"),
      ],
    );
  }

  /// Admin screen
  Widget _buildAdminScreen() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Admin Dashboard",
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
        SizedBox(height: 10),
        Text("Logged in as: $email",
            style: TextStyle(fontSize: 16, color: Colors.grey[700])),
        if (name != null) Text("Name: $name"),
        if (gender != null) Text("Gender: $gender"),
        SizedBox(height: 20),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection("Users")
                .where("role", isEqualTo: "analyst")
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Center(child: CircularProgressIndicator());
              }

              final analysts = snapshot.data!.docs;

              if (analysts.isEmpty) {
                return Center(
                    child: Text("No analysts registered yet.",
                        style: TextStyle(color: Colors.grey, fontSize: 16)));
              }

              return ListView.builder(
                itemCount: analysts.length,
                itemBuilder: (context, index) {
                  final analyst = analysts[index];
                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 3,
                    margin: EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blueGrey,
                        child: Icon(Icons.person, color: Colors.white),
                      ),
                      title: Text(analyst['email'],
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text("Role: ${analyst['role']}",
                          style: TextStyle(color: Colors.black54)),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
