import 'package:flutter/material.dart';

class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Help & Support"),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
        elevation: 2,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // HEADER SECTION
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blueAccent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Need Help?",
                    style: TextStyle(fontSize: 26, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 6),
                  Text(
                    "Find answers, tutorials, and support options.",
                    style: TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // FAQ SECTION
            const Text(
              "Frequently Asked Questions",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            _faqItem(
              "How do I create a report?",
              "Go to the Create Report section, upload an image, add details, and submit your analysis.",
            ),
            _faqItem(
              "Why is my status pending verification?",
              "The admin must verify your account. This usually takes a short time.",
            ),
            _faqItem(
              "How do I edit my profile?",
              "Tap the Edit Profile icon on your dashboard to update your name or details.",
            ),

            const SizedBox(height: 25),

            // TUTORIAL SECTION
            const Text(
              "Tutorials & Guides",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            _tutorialCard(
              "How to Analyze Water Quality",
              "Step-by-step guide to analyzing water quality using the app.",
              Icons.water_drop,
            ),
            _tutorialCard(
              "Uploading Images Correctly",
              "Learn how to take clear images for accurate AI analysis.",
              Icons.camera_alt,
            ),
            _tutorialCard(
              "Understanding Analysis Results",
              "Guidelines on reading AI predictions and report scores.",
              Icons.analytics,
            ),

            const SizedBox(height: 25),

            // CONTACT SUPPORT
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) {
                      return AlertDialog(
                        title: const Text("Contact Support"),
                        content: const Text(
                            "Email: support@waterquality.com\nPhone: +1-234-567-890"),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text("Close"),
                          ),
                        ],
                      );
                    },
                  );
                },
                icon: const Icon(Icons.support_agent),
                label: const Text("Contact Support"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  /// FAQ EXPANSION ITEM
  Widget _faqItem(String question, String answer) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        title: Text(question, style: const TextStyle(fontWeight: FontWeight.w600)),
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(answer, style: const TextStyle(color: Colors.black87)),
          )
        ],
      ),
    );
  }

  /// TUTORIAL CARD
  Widget _tutorialCard(String title, String subtitle, IconData icon) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: Colors.blueAccent.withOpacity(0.2),
          child: Icon(icon, color: Colors.blueAccent),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          // You can open a detailed tutorial page here later
        },
      ),
    );
  }
}
