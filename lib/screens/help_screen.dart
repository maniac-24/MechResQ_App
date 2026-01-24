import 'package:flutter/material.dart';

class HelpWidget extends StatelessWidget {
  const HelpWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final yellow = Theme.of(context).colorScheme.primary;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ================= HEADER =================
          Text(
            "Help & Support",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: yellow,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            "We’re here to help you during vehicle breakdowns.",
            style: TextStyle(color: Colors.white70),
          ),

          const SizedBox(height: 24),

          // ================= QUICK ACTIONS =================
          const Text(
            "Quick Actions",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              _actionButton(
                icon: Icons.phone,
                label: "Call Support",
                color: Colors.green,
                onTap: () {
                  _showSnack(context, "Calling support coming soon");
                },
              ),
              const SizedBox(width: 12),
              _actionButton(
                icon: Icons.chat,
                label: "Live Chat",
                color: Colors.blue,
                onTap: () {
                  _showSnack(context, "Live chat coming soon");
                },
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ================= FAQ =================
          const Text(
            "Frequently Asked Questions",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          _faqTile(
            "How do I request a mechanic?",
            "Go to Home screen, select a mechanic and tap on Request.",
          ),
          _faqTile(
            "How is distance calculated?",
            "Distance is calculated using your live GPS location.",
          ),
          _faqTile(
            "Can I add multiple vehicles?",
            "Yes, you can manage multiple vehicles from My Vehicles.",
          ),
          _faqTile(
            "What should I do in an emergency?",
            "Open the menu and use the SOS Call option immediately.",
          ),

          const SizedBox(height: 24),

          // ================= SAFETY =================
          const Text(
            "Emergency & Safety",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          Card(
            color: const Color(0xFF1C1C1C),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                "• If stranded in an unsafe location, stay inside your vehicle.\n"
                "• Use SOS Call for immediate assistance.\n"
                "• Never share OTPs or personal details.\n"
                "• Payments should be done only through official channels.",
                style: TextStyle(color: Colors.white70, height: 1.5),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // ================= CONTACT INFO =================
          const Text(
            "Contact Information",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          _contactTile(Icons.email, "support@mechresq.com"),
          _contactTile(Icons.phone, "+91 74113 32462"),
          _contactTile(Icons.location_on, "India"),

          const SizedBox(height: 30),

          // ================= FOOTER =================
          Center(
            child: Text(
              "MechResQ • Version 1.0.0",
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  // ================= HELPERS =================

  static Widget _faqTile(String q, String a) {
    return Card(
      color: const Color(0xFF1C1C1C),
      child: ExpansionTile(
        title: Text(q),
        childrenPadding: const EdgeInsets.all(12),
        children: [
          Text(
            a,
            style: const TextStyle(color: Colors.white70),
          )
        ],
      ),
    );
  }

  static Widget _contactTile(IconData icon, String text) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70),
      title: Text(text),
    );
  }

  static Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void _showSnack(BuildContext context, String text) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(text)));
  }
}
