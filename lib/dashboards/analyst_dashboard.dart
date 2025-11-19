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

  /// COLORS FOR STATUS
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

  /// EDIT NOTES DIALOG
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

  /// DELETE REPORT CONFIRMATION
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
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Report deleted")));
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
      ),

      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            const Text(
              "Your Reports",
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold),
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
                      child: Text("Error: ${snapshot.error}"),
                    );
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
                              /// TOP ROW - STATUS + DATE
                              Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _statusColor(
                                          data["status"] ?? "pending")
                                          .withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      data["status"] ?? "pending",
                                      style: TextStyle(
                                          color: _statusColor(
                                              data["status"] ?? "pending"),
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  Text(
                                    dateString,
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.grey),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 10),

                              /// MAIN DETAILS
                              Text(
                                "Analysis: ${data["analysis"]}",
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                  "Contamination Level: ${data["contaminationLevel"]}"),
                              const SizedBox(height: 4),
                              Text(
                                  "Location: Lat ${data["latitude"]}, Lng ${data["longitude"]}"),
                              const SizedBox(height: 4),
                              Text("Notes: ${data["notes"]}"),

                              const SizedBox(height: 12),

                              /// ACTION BUTTONS
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  /// EDIT
                                  IconButton(
                                    icon: const Icon(Icons.edit,
                                        color: Colors.blue),
                                    onPressed: () => _editNotesDialog(
                                      report.id,
                                      data["notes"] ?? "",
                                    ),
                                  ),

                                  /// DELETE
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () =>
                                        _deleteReport(report.id),
                                  ),
                                ],
                              )
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
          BottomNavigationBarItem(
              icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(
              icon: Icon(Icons.logout), label: "Logout"),
        ],
      ),
    );
  }
}
