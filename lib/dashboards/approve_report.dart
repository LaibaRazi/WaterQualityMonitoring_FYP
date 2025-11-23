import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ApproveReportPage extends StatefulWidget {
  const ApproveReportPage({super.key});

  @override
  State<ApproveReportPage> createState() => _ApproveReportPageState();
}

class _ApproveReportPageState extends State<ApproveReportPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  int _currentIndex = 1; // REPORTS TAB

  Future<void> _logout() async {
    await _auth.signOut();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/');
  }

  Future<void> _updateStatus(String docId, String status) async {
    try {
      await _firestore.collection("Reports").doc(docId).update({"status": status});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Status updated to $status")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  void _showStatusDropdown(String docId, String currentStatus) {
    showDialog(
      context: context,
      builder: (context) {
        String newStatus = currentStatus;

        return AlertDialog(
          title: const Text("Update Status"),
          content: DropdownButtonFormField<String>(
            value: newStatus,
            items: ["pending", "pendingAnalysis", "approved"]
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (value) => newStatus = value!,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                _updateStatus(docId, newStatus);
                Navigator.pop(context);
              },
              child: const Text("Update"),
            ),
          ],
        );
      },
    );
  }

  void _showCreateAlertDialog(String reportId) {
    final TextEditingController _title = TextEditingController();
    final TextEditingController _msg = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Create Alert"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _title,
                decoration: const InputDecoration(labelText: "Alert Title"),
              ),
              TextField(
                controller: _msg,
                decoration: const InputDecoration(labelText: "Alert Message"),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel")
            ),
            ElevatedButton(
              onPressed: () {
                _createAlert(reportId, _title.text.trim(), _msg.text.trim());
                Navigator.pop(context);
              },
              child: const Text("Save Alert"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _createAlert(
      String reportId,
      String title,
      String msg
      ) async {

    if (title.isEmpty || msg.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter title & message")),
      );
      return;
    }

    try {
      await _firestore.collection("Alerts").add({
        "createdAt": Timestamp.now(),
        "title": title,
        "message": msg,
        "reportId": _firestore.collection("Reports").doc(reportId)
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Alert created successfully")),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case "approved":
        return Colors.green;
      case "pendingAnalysis":
        return Colors.orange;
      default:
        return Colors.red;
    }
  }

  // ------------------ NAVIGATION BAR FUNCTION ------------------
  void _onNavBarTapped(int index) {
    setState(() => _currentIndex = index);

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/admin');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/approve_report');
        break;
      case 2:
        _logout();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Approve Reports"),
        backgroundColor: Colors.blueAccent,
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection("Reports")
            .orderBy("timestamp", descending: true)
            .snapshots(),

        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          final reports = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final report = reports[index];
              final data = report.data() as Map<String, dynamic>;

              String status = data["status"] ?? "pending";

              final Timestamp? t = data["timestamp"];
              final time = t != null
                  ? t.toDate().toLocal().toString().split(".")[0]
                  : "Unknown";

              return Card(
                elevation: 4,
                margin: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)
                ),

                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      /// IMAGE DISPLAY
                      if (data["imageBase64"] != null &&
                          data["imageBase64"].toString().isNotEmpty)
                        Container(
                          height: 200,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
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
                          height: 200,
                          width: double.infinity,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.grey[300],
                          ),
                          child: const Text("No Image Available"),
                        ),

                      const SizedBox(height: 12),

                      /// EMAIL + STATUS
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            data["email"] ?? "Unknown",
                            style: const TextStyle(
                                fontSize: 17, fontWeight: FontWeight.bold),
                          ),
                          GestureDetector(
                            onTap: () => _showStatusDropdown(
                                report.id, data["status"]),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: _statusColor(status).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    status,
                                    style: TextStyle(
                                        color: _statusColor(status),
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const Icon(Icons.arrow_drop_down),
                                ],
                              ),
                            ),
                          )
                        ],
                      ),

                      const SizedBox(height: 8),

                      Text("Submitted: $time",
                          style: const TextStyle(color: Colors.grey)),

                      const SizedBox(height: 10),

                      Text("Analysis: ${data["analysis"]}",
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),

                      Text("Contamination Level: ${data["contaminationLevel"]}",
                          style: const TextStyle(color: Colors.redAccent)),

                      const SizedBox(height: 10),

                      Text("📍 Location:"),
                      Text("Latitude: ${data["latitude"]}"),
                      Text("Longitude: ${data["longitude"]}"),

                      const SizedBox(height: 10),

                      Text("Notes:", style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(data["notes"] ?? "---"),

                      const SizedBox(height: 15),

                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            _showCreateAlertDialog(report.id);
                          },
                          icon: const Icon(Icons.notification_important),
                          label: const Text("Create Alert"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),

      // ---------- BOTTOM NAV BAR (ADMIN) ----------
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onNavBarTapped,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.report), label: "Reports"),
          BottomNavigationBarItem(icon: Icon(Icons.logout), label: "Sign Out"),
        ],
      ),
    );
  }
}
