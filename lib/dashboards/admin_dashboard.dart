import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  int _currentIndex = 0;

  Future<void> _logout() async {
    await _auth.signOut();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/');
  }

  Future<void> _deleteAnalyst(String uid) async {
    try {
      await _firestore.collection('Users').doc(uid).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Analyst deleted successfully")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error deleting analyst: $e")),
      );
    }
  }

  Future<void> _updateVerification(String uid, bool value) async {
    try {
      await _firestore.collection('Users').doc(uid).update({
        "status": value ? "verified" : "pending_verification",
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error updating status: $e")),
      );
    }
  }

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
        title: const Text("Admin Dashboard"),
        backgroundColor: Colors.blueAccent,
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('Users')
            .where('role', isEqualTo: 'analyst')  // ONLY ANALYSTS
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text("No analysts found."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final uid = docs[index].id;

              final verification = data['status'] ?? "pending_verification";

              return Card(
                elevation: 4,
                margin: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),

                child: Padding(
                  padding: const EdgeInsets.all(16.0),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// FULL NAME
                      Text(
                        data['fullName'] ?? "Unnamed Analyst",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 5),

                      /// EMAIL
                      Text(
                        "Email: ${data['email'] ?? 'N/A'}",
                        style: const TextStyle(color: Colors.black87),
                      ),

                      const SizedBox(height: 10),

                      /// VERIFICATION TOGGLE
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Verification Status:",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: verification == "verified"
                                  ? Colors.green
                                  : Colors.orange,
                            ),
                          ),

                          Switch(
                            value: verification == "verified",
                            activeColor: Colors.green,
                            onChanged: (value) {
                              _updateVerification(uid, value);
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      /// DELETE BUTTON
                      Align(
                        alignment: Alignment.centerRight,
                        child: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text("Confirm Delete"),
                                content:
                                const Text("Are you sure you want to delete this analyst?"),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: const Text("Cancel"),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(ctx);
                                      _deleteAnalyst(uid);
                                    },
                                    child: const Text(
                                      "Delete",
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
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
