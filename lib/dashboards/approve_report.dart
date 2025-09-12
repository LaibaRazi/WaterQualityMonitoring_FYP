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

  int _currentIndex = 1; // Reports page

  /// 🔹 Update report status
  Future<void> _updateStatus(String docId, String status) async {
    try {
      await _firestore.collection("Reports").doc(docId).update({
        "status": status,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Status updated to $status ✅")),
      );
    } catch (e) {
      debugPrint("Error updating status: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to update status: $e")),
      );
    }
  }

  /// 🔹 Show dialog to choose new status
  void _showEditDialog(String docId, String currentStatus) {
    showDialog(
      context: context,
      builder: (context) {
        String selectedStatus = currentStatus;
        return AlertDialog(
          title: const Text("Update Report Status"),
          content: DropdownButtonFormField<String>(
            value: selectedStatus,
            items: ["pending", "pendingAnalysis", "approved"]
                .map((status) => DropdownMenuItem(
              value: status,
              child: Text(status),
            ))
                .toList(),
            onChanged: (val) {
              if (val != null) selectedStatus = val;
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                _updateStatus(docId, selectedStatus);
                Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  /// 🔹 Bottom navigation actions
  void _onNavBarTapped(int index) {
    setState(() {
      _currentIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/admin');
        break;
      case 1:
      // Already on approve_report
        break;
      case 2:
        _logout();
        break;
    }
  }

  /// 🔹 Logout
  Future<void> _logout() async {
    await _auth.signOut();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Approve Reports"),
        backgroundColor: Colors.blue,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection("Reports")
            .orderBy("createdAt", descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No reports available."));
          }

          final reports = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final report = reports[index];
              final createdAt = (report['createdAt'] as Timestamp?)?.toDate();
              final dateString =
              createdAt != null ? "${createdAt.toLocal()}" : "Unknown Date";

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  // ✅ Use 'analysis' instead of 'title'
                  title: Text(report['analysis'] ?? "Water Sample - Test"),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          "Contamination: ${report['contaminationLevel'] ?? 'Unknown'}"),
                      Text("Status: ${report['status'] ?? 'pending'}"),
                      Text("Created At: $dateString"),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () =>
                        _showEditDialog(report.id, report['status'] ?? 'pending'),
                  ),
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onNavBarTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.report, size: 30),
            label: "Reports",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.logout),
            label: "Sign Out",
          ),
        ],
      ),
    );
  }
}
