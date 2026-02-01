import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpWidget extends StatelessWidget {
  const HelpWidget({super.key});

  // Launch phone dialer
  Future<void> _callSupport() async {
    final Uri phoneUri = Uri(scheme: 'tel', path: '+917411332462');
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  // Launch email client
  Future<void> _emailSupport() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'support@mechresq.com',
      queryParameters: {
        'subject': 'MechResQ Support Request',
      },
    );
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final yellow = Theme.of(context).colorScheme.primary;

    return Scaffold(
      // ✅ ONLY "Help & Support" - no menu, no actions
      appBar: AppBar(
        title: const Text('Help & Support'),
        centerTitle: true,
        automaticallyImplyLeading: false, // ✅ Removes menu/back button
        actions: const [], // ✅ No actions
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ================= HEADER =================
            Card(
              color: const Color(0xFF1C1C1C),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: yellow, size: 40),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Need Help?",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: yellow,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            "We're here 24/7 to assist you during vehicle breakdowns",
                            style: TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ================= QUICK ACTIONS =================
            const Text(
              "Quick Actions",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                _actionButton(
                  icon: Icons.phone,
                  label: "Call Support",
                  color: Colors.green,
                  onTap: () => _callSupport(),
                ),
                const SizedBox(width: 12),
                _actionButton(
                  icon: Icons.email,
                  label: "Email Us",
                  color: Colors.blue,
                  onTap: () => _emailSupport(),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                _actionButton(
                  icon: Icons.bug_report,
                  label: "Report Issue",
                  color: Colors.orange,
                  onTap: () {
                    _showSnack(context, "Opening issue report form...");
                  },
                ),
                const SizedBox(width: 12),
                _actionButton(
                  icon: Icons.video_library,
                  label: "Tutorials",
                  color: Colors.purple,
                  onTap: () {
                    _showSnack(context, "Opening video tutorials...");
                  },
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ================= FAQ =================
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Frequently Asked Questions",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {
                    _showSnack(context, "Opening full FAQ page...");
                  },
                  child: const Text("View All"),
                ),
              ],
            ),
            const SizedBox(height: 8),

            _faqTile(
              "How do I request a mechanic?",
              "1. Go to Home screen\n2. Browse nearby mechanics or search by filters\n3. Select a mechanic\n4. Tap 'Request Service'\n5. Fill in your vehicle details and issue\n6. Confirm your location\n7. Submit the request",
              Icons.build,
            ),
            _faqTile(
              "How is distance calculated?",
              "Distance is calculated using GPS coordinates between your current location and the mechanic's workshop. Make sure location services are enabled for accurate results.",
              Icons.location_on,
            ),
            _faqTile(
              "Can I add multiple vehicles?",
              "Yes! Go to Menu → My Vehicles → Tap '+' button. You can add unlimited vehicles and switch between them when creating service requests.",
              Icons.directions_car,
            ),
            _faqTile(
              "What should I do in an emergency?",
              "1. Tap the SOS button (red button in menu)\n2. Your location will be shared automatically\n3. Emergency contacts will be notified\n4. Nearest mechanics will be alerted\n5. Stay calm and safe in your vehicle",
              Icons.emergency,
            ),
            _faqTile(
              "How do payments work?",
              "All payments are processed securely through the app. You can pay via UPI, cards, or wallets after the service is completed. Cash payments are also accepted at the mechanic's discretion.",
              Icons.payment,
            ),
            _faqTile(
              "Can I cancel a request?",
              "Yes, you can cancel before the mechanic accepts it. Go to My Requests → Select request → Tap 'Cancel'. Cancellation charges may apply if mechanic has already started traveling.",
              Icons.cancel,
            ),

            const SizedBox(height: 24),

            // ================= SAFETY TIPS =================
            const Text(
              "Emergency & Safety",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            Card(
              color: Colors.red.shade900.withOpacity(0.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.red.shade700),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning_amber, color: Colors.red.shade400),
                        const SizedBox(width: 8),
                        Text(
                          "Safety Guidelines",
                          style: TextStyle(
                            color: Colors.red.shade300,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "• If stranded in an unsafe location, stay inside your vehicle with doors locked\n"
                      "• Turn on hazard lights and use warning triangles if available\n"
                      "• Use the SOS Call feature for immediate emergency assistance\n"
                      "• Never share OTPs, passwords, or banking details with anyone\n"
                      "• Verify mechanic ID and rating before accepting service\n"
                      "• All payments should be done through the app only\n"
                      "• Take photos of damage before and after repair\n"
                      "• Keep emergency numbers saved in your phone",
                      style: TextStyle(color: Colors.white70, height: 1.6),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ================= APP FEATURES =================
            const Text(
              "App Features Guide",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            _featureTile(
              Icons.home,
              "Home",
              "Browse nearby mechanics, view ratings, and distance",
            ),
            _featureTile(
              Icons.history,
              "My Requests",
              "Track active and past service requests with status updates",
            ),
            _featureTile(
              Icons.directions_car,
              "My Vehicles",
              "Manage your vehicles with photos, documents, and service history",
            ),
            _featureTile(
              Icons.star,
              "Ratings",
              "Rate mechanics after service to help other users",
            ),
            _featureTile(
              Icons.notifications,
              "Notifications",
              "Get real-time updates on request status and mechanic arrival",
            ),

            const SizedBox(height: 24),

            // ================= CONTACT INFO =================
            const Text(
              "Contact Information",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            Card(
              color: const Color(0xFF1C1C1C),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _contactTile(
                    Icons.email,
                    "Email Support",
                    "support@mechresq.com",
                    () => _emailSupport(),
                  ),
                  const Divider(height: 1, color: Colors.white12),
                  _contactTile(
                    Icons.phone,
                    "Phone Support",
                    "+91 74113 32462",
                    () => _callSupport(),
                  ),
                  const Divider(height: 1, color: Colors.white12),
                  _contactTile(
                    Icons.access_time,
                    "Support Hours",
                    "24/7 Emergency Support",
                    null,
                  ),
                  const Divider(height: 1, color: Colors.white12),
                  _contactTile(
                    Icons.location_on,
                    "Location",
                    "India (All Major Cities)",
                    null,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ================= SUBMIT TICKET =================
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: yellow,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  _showSnack(context, "Opening support ticket form...");
                },
                icon: const Icon(Icons.support_agent),
                label: const Text(
                  "Submit a Support Ticket",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            const SizedBox(height: 30),

            // ================= FOOTER =================
            Center(
              child: Column(
                children: [
                  Text(
                    "MechResQ • Version 1.0.0",
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "© 2026 MechResQ. All rights reserved.",
                    style: TextStyle(color: Colors.grey[700], fontSize: 11),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
      // ✅ NO FloatingActionButton (+ button removed)
    );
  }

  // ================= HELPERS =================

  static Widget _faqTile(String q, String a, IconData icon) {
    return Card(
      color: const Color(0xFF1C1C1C),
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: ExpansionTile(
        leading: Icon(icon, color: Colors.white70, size: 20),
        title: Text(
          q,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        children: [
          Text(
            a,
            style: const TextStyle(color: Colors.white70, height: 1.5),
          )
        ],
      ),
    );
  }

  static Widget _featureTile(IconData icon, String title, String desc) {
    return Card(
      color: const Color(0xFF1C1C1C),
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.white70),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          desc,
          style: const TextStyle(color: Colors.white60, fontSize: 12),
        ),
      ),
    );
  }

  static Widget _contactTile(
      IconData icon, String title, String text, VoidCallback? onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70),
      title: Text(
        title,
        style: const TextStyle(fontSize: 13, color: Colors.white60),
      ),
      subtitle: Text(
        text,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      ),
      trailing: onTap != null
          ? const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white38)
          : null,
      onTap: onTap,
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
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.5)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
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