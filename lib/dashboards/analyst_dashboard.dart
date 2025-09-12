import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AnalystDashboard extends StatefulWidget {
  const AnalystDashboard({super.key});

  @override
  State<AnalystDashboard> createState() => _AnalystDashboardState();
}

class _AnalystDashboardState extends State<AnalystDashboard> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _user;

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser;
  }

  Future<void> _logout() async {
    await _auth.signOut();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, "/");
  }

  @override
  Widget build(BuildContext context) {
    final userEmail = _user?.email ?? "";

    return Scaffold(
      appBar: AppBar(
        title: const Text("Analyst Dashboard"),
        backgroundColor: Colors.blueGrey,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              "Your Reports",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // --- Reports List ---
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection("Reports")
                    .where("email", isEqualTo: userEmail)
                    .orderBy("createdAt", descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text("No reports submitted yet."));
                  }

                  final reports = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: reports.length,
                    itemBuilder: (context, index) {
                      final report = reports[index];
                      final timestamp = report['createdAt'] as Timestamp?;
                      final dateString = timestamp != null
                          ? timestamp.toDate().toString()
                          : "Unknown Date";

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          leading: report['imageUrl'] != null && report['imageUrl'] != ""
                              ? Image.network(
                            report['imageUrl'],
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          )
                              : const Icon(Icons.image_not_supported),
                          title: Text(report['contaminationLevel'] ?? "Unknown"),
                          subtitle: Text("Submitted: $dateString"),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),

      // --- Bottom Navigation Bar ---
      bottomNavigationBar: BottomAppBar(
        color: Colors.blueGrey.shade100,
        shape: const CircularNotchedRectangle(),
        notchMargin: 6.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // Create Report
            IconButton(
              icon: const Icon(Icons.add_chart, color: Colors.blueGrey),
              onPressed: () {
                Navigator.pushNamed(context, "/create_report");
              },
            ),

            // Home
            IconButton(
              icon: const Icon(Icons.home, color: Colors.blueGrey),
              onPressed: () {
                Navigator.pushReplacementNamed(context, "/home");
              },
            ),

            // Logout
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.redAccent),
              onPressed: _logout,
            ),
          ],
        ),
      ),
    );
  }
}
