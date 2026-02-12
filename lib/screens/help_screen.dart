import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../utils/snackbar_helper.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

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
    final scheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ================= HEADER =================
          Card(
            color: scheme.surfaceContainerHighest,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: scheme.primary, size: 40),
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
                            color: scheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "We're here 24/7 to assist you during vehicle breakdowns",
                          style: TextStyle(
                            color: scheme.onSurface.withOpacity(0.7),
                            fontSize: 13,
                          ),
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
          Text(
            "Quick Actions",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              _actionButton(
                context: context,
                icon: Icons.phone,
                label: "Call Support",
                background: scheme.primaryContainer,
                foreground: scheme.onPrimaryContainer,
                onTap: () => _callSupport(),
              ),
              const SizedBox(width: 12),
              _actionButton(
                context: context,
                icon: Icons.email,
                label: "Email Us",
                background: scheme.secondaryContainer,
                foreground: scheme.onSecondaryContainer,
                onTap: () => _emailSupport(),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              _actionButton(
                context: context,
                icon: Icons.bug_report,
                label: "Report Issue",
                background: scheme.tertiaryContainer,
                foreground: scheme.onTertiaryContainer,
                onTap: () {
                  SnackBarHelper.showInfo(
                    context,
                    "Opening issue report form...",
                  );
                },
              ),
              const SizedBox(width: 12),
              _actionButton(
                context: context,
                icon: Icons.video_library,
                label: "Tutorials",
                background: scheme.primaryContainer,
                foreground: scheme.onPrimaryContainer,
                onTap: () {
                  SnackBarHelper.showInfo(
                    context,
                    "Opening video tutorials...",
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ================= FAQ =================
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Frequently Asked Questions",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: scheme.onSurface,
                ),
              ),
              TextButton(
                onPressed: () {
                  SnackBarHelper.showInfo(
                    context,
                    "Opening full FAQ page...",
                  );
                },
                child: const Text("View All"),
              ),
            ],
          ),
          const SizedBox(height: 8),

          _faqTile(
            context,
            "How do I request a mechanic?",
            "1. Go to Home screen\n2. Browse nearby mechanics or search by filters\n3. Select a mechanic\n4. Tap 'Request Service'\n5. Fill in your vehicle details and issue\n6. Confirm your location\n7. Submit the request",
            Icons.build,
          ),
          _faqTile(
            context,
            "How is distance calculated?",
            "Distance is calculated using GPS coordinates between your current location and the mechanic's workshop. Make sure location services are enabled for accurate results.",
            Icons.location_on,
          ),
          _faqTile(
            context,
            "Can I add multiple vehicles?",
            "Yes! Open the menu by tapping your profile icon, select 'My Vehicles', and add unlimited vehicles. You can switch between them when creating service requests.",
            Icons.directions_car,
          ),
          _faqTile(
            context,
            "What should I do in an emergency?",
            "1. Tap the SOS button (red button in menu)\n2. Your location will be shared automatically\n3. Emergency contacts will be notified\n4. Nearest mechanics will be alerted\n5. Stay calm and safe in your vehicle",
            Icons.emergency,
          ),
          _faqTile(
            context,
            "How do payments work?",
            "All payments are processed securely through the app. You can pay via UPI, cards, or wallets after the service is completed. Cash payments are also accepted at the mechanic's discretion.",
            Icons.payment,
          ),
          _faqTile(
            context,
            "Can I cancel a request?",
            "Yes, you can cancel before the mechanic accepts it. Go to My Requests → Select request → Tap 'Cancel'. Cancellation charges may apply if mechanic has already started traveling.",
            Icons.cancel,
          ),

          const SizedBox(height: 24),

          // ================= SAFETY TIPS =================
          Text(
            "Emergency & Safety",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),

          Card(
            color: scheme.errorContainer,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: scheme.error),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning_amber, color: scheme.onErrorContainer),
                      const SizedBox(width: 8),
                      Text(
                        "Safety Guidelines",
                        style: TextStyle(
                          color: scheme.onErrorContainer,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "• If stranded in an unsafe location, stay inside your vehicle with doors locked\n"
                    "• Turn on hazard lights and use warning triangles if available\n"
                    "• Use the SOS Call feature for immediate emergency assistance\n"
                    "• Never share OTPs, passwords, or banking details with anyone\n"
                    "• Verify mechanic ID and rating before accepting service\n"
                    "• All payments should be done through the app only\n"
                    "• Take photos of damage before and after repair\n"
                    "• Keep emergency numbers saved in your phone",
                    style: TextStyle(
                      color: scheme.onErrorContainer.withOpacity(0.9),
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // ================= CONTACT INFO =================
          Text(
            "Contact Information",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),

          Card(
            color: scheme.surfaceContainerHighest,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _contactTile(
                  context,
                  Icons.email,
                  "Email Support",
                  "support@mechresq.com",
                  () => _emailSupport(),
                ),
                Divider(height: 1, color: scheme.outlineVariant),
                _contactTile(
                  context,
                  Icons.phone,
                  "Phone Support",
                  "+91 74113 32462",
                  () => _callSupport(),
                ),
                Divider(height: 1, color: scheme.outlineVariant),
                _contactTile(
                  context,
                  Icons.access_time,
                  "Support Hours",
                  "24/7 Emergency Support",
                  null,
                ),
                Divider(height: 1, color: scheme.outlineVariant),
                _contactTile(
                  context,
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
                backgroundColor: scheme.primary,
                foregroundColor: scheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                SnackBarHelper.showInfo(
                  context,
                  "Opening support ticket form...",
                );
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
                  style: TextStyle(
                    color: scheme.onSurface.withOpacity(0.5),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "© 2026 MechResQ. All rights reserved.",
                  style: TextStyle(
                    color: scheme.onSurface.withOpacity(0.4),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ================= HELPERS =================

  static Widget _faqTile(
    BuildContext context,
    String q,
    String a,
    IconData icon,
  ) {
    final scheme = Theme.of(context).colorScheme;
    
    return Card(
      color: scheme.surfaceContainerHighest,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: ExpansionTile(
        leading: Icon(
          icon,
          color: scheme.onSurface.withOpacity(0.7),
          size: 20,
        ),
        title: Text(
          q,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: scheme.onSurface,
          ),
        ),
        iconColor: scheme.onSurface,
        collapsedIconColor: scheme.onSurface.withOpacity(0.7),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        children: [
          Text(
            a,
            style: TextStyle(
              color: scheme.onSurface.withOpacity(0.7),
              height: 1.5,
            ),
          )
        ],
      ),
    );
  }

  static Widget _contactTile(
    BuildContext context,
    IconData icon,
    String title,
    String text,
    VoidCallback? onTap,
  ) {
    final scheme = Theme.of(context).colorScheme;
    
    return ListTile(
      leading: Icon(
        icon,
        color: scheme.onSurface.withOpacity(0.7),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          color: scheme.onSurface.withOpacity(0.6),
        ),
      ),
      subtitle: Text(
        text,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: scheme.onSurface,
        ),
      ),
      trailing: onTap != null
          ? Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: scheme.onSurface.withOpacity(0.4),
            )
          : null,
      onTap: onTap,
    );
  }

  static Widget _actionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color background,
    required Color foreground,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: foreground.withOpacity(0.5),
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: foreground, size: 32),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: foreground,
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
}