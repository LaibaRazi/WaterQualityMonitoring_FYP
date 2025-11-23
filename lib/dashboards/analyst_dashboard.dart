import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

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

  /// OPEN ALERT PAGE
  void _openAlertsPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AlertsListPage()),
    );
  }

  /// STATUS COLOR
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

  /// EDIT NOTES
  void _editNotesDialog(String docId, String currentNotes) {
    TextEditingController notesController =
    TextEditingController(text: currentNotes);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Notes"),
        content: TextField(
          controller: notesController,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: "Update your notes...",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              await _firestore.collection("Reports").doc(docId).update({
                "notes": notesController.text.trim(),
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Notes updated")));
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  /// DELETE REPORT
  void _deleteReport(String docId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Report"),
        content: const Text("Are you sure you want to delete this report?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              await _firestore.collection("Reports").doc(docId).delete();
              Navigator.pop(context);
              ScaffoldMessenger.of(context)
                  .showSnackBar(const SnackBar(content: Text("Report deleted")));
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userEmail = _user?.email?.trim().toLowerCase() ?? "";

    return Scaffold(
      appBar: AppBar(
        title: const Text("Analyst Dashboard"),
        backgroundColor: Colors.blueAccent,
        actions: [
          IconButton(
            icon: const Icon(Icons.notification_important),
            onPressed: _openAlertsPage,
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            const Text(
              "Your Reports",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
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
                    return Center(child: Text("Error: ${snapshot.error}"));
                  }

                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final reports = snapshot.data!.docs;

                  if (reports.isEmpty) {
                    return const Center(
                      child: Text(
                        "No reports found",
                        style: TextStyle(color: Colors.grey),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: reports.length,
                    itemBuilder: (context, index) {
                      final report = reports[index];
                      final data = report.data() as Map<String, dynamic>;

                      final status = data["status"] ?? "pending";
                      final isApproved = status.toLowerCase() == "approved";

                      final timestamp = data["timestamp"] as Timestamp?;
                      final dateString = timestamp != null
                          ? DateFormat("yyyy-MM-dd HH:mm")
                          .format(timestamp.toDate())
                          : "--";

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 3,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              /// -------------------------
                              /// BASE64 IMAGE DISPLAY
                              /// -------------------------
                              if (data["imageBase64"] != null &&
                                  data["imageBase64"].toString().isNotEmpty)
                                Container(
                                  height: 180,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    image: DecorationImage(
                                      image: MemoryImage(
                                        base64Decode(data["imageBase64"]),
                                      ),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                )
                              else
                                Container(
                                  height: 180,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    color: Colors.grey[300],
                                  ),
                                  child: const Center(
                                      child: Text("No Image Available")),
                                ),

                              const SizedBox(height: 12),

                              /// STATUS + DATE
                              Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color:
                                      _statusColor(status).withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      status,
                                      style: TextStyle(
                                          color: _statusColor(status),
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  Text(dateString,
                                      style: const TextStyle(
                                          fontSize: 12, color: Colors.grey)),
                                ],
                              ),

                              const SizedBox(height: 10),

                              /// REPORT DATA
                              Text(
                                "Analysis: ${data["analysis"]}",
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold),
                              ),
                              Text(
                                  "Contamination Level: ${data["contaminationLevel"]}"),
                              Text(
                                  "Location: Lat ${data["latitude"]}, Lng ${data["longitude"]}"),
                              Text("Notes: ${data["notes"]}"),

                              const SizedBox(height: 12),

                              /// EDIT + DELETE (hidden for approved)
                              if (!isApproved)
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit,
                                          color: Colors.blue),
                                      onPressed: () => _editNotesDialog(
                                        report.id,
                                        data["notes"] ?? "",
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Colors.red),
                                      onPressed: () =>
                                          _deleteReport(report.id),
                                    ),
                                  ],
                                ),
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

      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        onTap: (i) {
          if (i == 0) Navigator.pushNamed(context, "/create_report");
          if (i == 1) Navigator.pushReplacementNamed(context, "/home");
          if (i == 2) _logout();
        },
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.add), label: "Create Report"),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.logout), label: "Logout"),
        ],
      ),
    );
  }
}

/// ----------------------------------------------------------
///     ALERT LIST SCREEN
/// ----------------------------------------------------------
class AlertsListPage extends StatelessWidget {
  const AlertsListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text("All Alerts"),
        backgroundColor: Colors.redAccent,
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: firestore
            .collection("Alerts")
            .orderBy("createdAt", descending: true)
            .snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final alerts = snap.data!.docs;

          if (alerts.isEmpty) {
            return const Center(
              child: Text(
                "No Alerts Generated Yet",
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: alerts.length,
            itemBuilder: (context, i) {
              final data = alerts[i].data() as Map<String, dynamic>;

              final Timestamp? t = data["createdAt"];
              final time = t != null
                  ? DateFormat("yyyy-MM-dd HH:mm").format(t.toDate())
                  : "--";

              return Card(
                elevation: 4,
                child: ListTile(
                  title: Text(
                    data["title"] ?? "Alert",
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.red),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data["message"] ?? ""),
                      const SizedBox(height: 4),
                      Text("Time: $time",
                          style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
