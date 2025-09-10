import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? role;
  String? email;

  @override
  void initState() {
    super.initState();
    _getUserRole();
  }

  /// Fetch current user's role from Firestore
  Future<void> _getUserRole() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final doc =
    await FirebaseFirestore.instance.collection("Users").doc(uid).get();

    if (doc.exists) {
      setState(() {
        role = doc['role'];
        email = doc['email'];
      });
    }
  }

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, '/');
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
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            tooltip: "Logout",
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: role == "admin"
            ? _buildAdminScreen()
            : _buildAnalystScreen(),
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
        Text(
          "Analyst Dashboard",
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10),
        Text(
          "Welcome, $email",
          style: TextStyle(fontSize: 16, color: Colors.grey[700]),
        ),
      ],
    );
  }

  /// Admin screen: list of analysts
  Widget _buildAdminScreen() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Admin Dashboard",
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10),
        Text(
          "Logged in as: $email",
          style: TextStyle(fontSize: 16, color: Colors.grey[700]),
        ),
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
                    child: Text(
                      "No analysts registered yet.",
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ));
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
                      title: Text(
                        analyst['email'],
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        "Role: ${analyst['role']}",
                        style: TextStyle(color: Colors.black54),
                      ),
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
