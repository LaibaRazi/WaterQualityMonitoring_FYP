import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // For formatting timestamps

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

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case "approved":
        return Colors.green;
      case "pendinganalysis":
        return Colors.orange;
      case "pending":
      default:
        return Colors.redAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final userEmail = _user?.email?.trim().toLowerCase() ?? "";

    return Scaffold(
      appBar: AppBar(
        title: const Text("Analyst Dashboard"),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            const Text(
              "Your Reports",
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection("Reports")
                    .where("email", isEqualTo: userEmail)
                    .orderBy("timestamp", descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        "Error loading reports.\n${snapshot.error}",
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final reports = snapshot.data?.docs ?? [];

                  if (reports.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.report, size: 60, color: Colors.grey),
                          SizedBox(height: 12),
                          Text(
                            "No reports submitted yet.",
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.only(top: 8),
                    itemCount: reports.length,
                    itemBuilder: (context, index) {
                      final report = reports[index];
                      final data = report.data() as Map<String, dynamic>;

                      final timestamp = data['timestamp'] as Timestamp?;
                      final dateString = timestamp != null
                          ? DateFormat('yyyy-MM-dd HH:mm:ss')
                          .format(timestamp.toDate().toLocal())
                          : "Unknown Date";

                      final status = data['status'] ?? "pending";

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                        shadowColor: Colors.grey.withOpacity(0.3),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Document ID
                              Text(
                                "Report ID: ${report.id}",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: Colors.grey),
                              ),
                              const SizedBox(height: 4),

                              // Status badge
                              Row(
                                children: [
                                  const Text("Status: "),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: _statusColor(status).withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      status,
                                      style: TextStyle(
                                          color: _statusColor(status),
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    dateString,
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.grey),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // Analysis
                              Text(
                                "Analysis: ${data['analysis'] ?? 'N/A'}",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(height: 4),

                              // Contamination Level
                              Text(
                                  "Contamination: ${data['contaminationLevel'] ?? 'N/A'}"),
                              const SizedBox(height: 4),

                              // Location
                              Text(
                                  "Location: Lat ${data['latitude'] ?? 'N/A'}, Lng ${data['longitude'] ?? 'N/A'}"),
                              const SizedBox(height: 4),

                              // Notes
                              Text("Notes: ${data['notes'] ?? 'N/A'}"),
                            ],
                          ),
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
      bottomNavigationBar: BottomAppBar(
        color: Colors.blueGrey.shade50,
        shape: const CircularNotchedRectangle(),
        notchMargin: 6.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: const Icon(Icons.add_chart, color: Colors.blueAccent),
              onPressed: () {
                Navigator.pushNamed(context, "/create_report");
              },
            ),
            IconButton(
              icon: const Icon(Icons.person, color: Colors.blueAccent),
              onPressed: () {
                Navigator.pushNamed(context, "/analyst"); // New middle button
              },
            ),
            IconButton(
              icon: const Icon(Icons.home, color: Colors.blueAccent),
              onPressed: () {
                Navigator.pushReplacementNamed(context, "/home");
              },
            ),
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
