// lib/screens/request_completion_screen.dart

import 'package:flutter/material.dart';

import '../utils/snackbar_helper.dart';

class RequestCompletionScreen extends StatefulWidget {
  final String requestId;
  final String mechanicName;
  final String vehicleType;
  final String issueDescription;
  final double totalAmount;

  const RequestCompletionScreen({
    super.key,
    required this.requestId,
    required this.mechanicName,
    required this.vehicleType,
    required this.issueDescription,
    this.totalAmount = 850.0,
  });

  @override
  State<RequestCompletionScreen> createState() =>
      _RequestCompletionScreenState();
}

class _RequestCompletionScreenState extends State<RequestCompletionScreen>
    with SingleTickerProviderStateMixin {
  // Rating state
  int _rating = 0;
  final _feedbackController = TextEditingController();

  // Check-mark animation
  late AnimationController _animCtrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _scaleAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutBack);
    // play once on mount
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  // -----------------------------------------------------------------------
  // BUILD
  // -----------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Service Complete"),
        centerTitle: true,
        // no back button — user must submit or dismiss explicitly
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ===================== ANIMATED CHECK =====================
            AnimatedBuilder(
              animation: _scaleAnim,
              builder: (_, __) => Transform.scale(
                scale: _scaleAnim.value,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: scheme.secondaryContainer,
                    border: Border.all(color: scheme.secondary, width: 3),
                  ),
                  child: Icon(
                    Icons.check,
                    size: 52,
                    color: scheme.onSecondaryContainer,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),
            Text(
              "Service Completed!",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Thank you for using MechResQ",
              style: TextStyle(
                fontSize: 14,
                color: scheme.onSurface.withOpacity(0.6),
              ),
            ),

            const SizedBox(height: 28),

            // ===================== SERVICE SUMMARY =====================
            _card(
              context,
              title: "Service Summary",
              icon: Icons.receipt_long_outlined,
              children: [
                _row(context, "Request ID", widget.requestId),
                _row(context, "Mechanic", widget.mechanicName),
                _row(context, "Vehicle", widget.vehicleType),
                _rowMulti(context, "Issue", widget.issueDescription),
              ],
            ),

            const SizedBox(height: 16),

            // ===================== PAYMENT =====================
            _card(
              context,
              title: "Payment",
              icon: Icons.payment_outlined,
              children: [
                _row(
                  context,
                  "Service Charge",
                  "₹${widget.totalAmount.toStringAsFixed(0)}",
                ),
                _row(
                  context,
                  "Tax (5%)",
                  "₹${(widget.totalAmount * 0.05).toStringAsFixed(0)}",
                ),
                Divider(color: scheme.outlineVariant, height: 16),
                _row(
                  context,
                  "Total",
                  "₹${(widget.totalAmount * 1.05).toStringAsFixed(0)}",
                  bold: true,
                  highlight: true,
                ),
                const SizedBox(height: 8),
                _row(context, "Payment Method", "UPI / Cash at site"),
              ],
            ),

            const SizedBox(height: 24),

            // ===================== RATE MECHANIC =====================
            _card(
              context,
              title: "Rate Your Mechanic",
              icon: Icons.star_outline,
              children: [
                const SizedBox(height: 4),
                // star row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    5,
                    (i) => GestureDetector(
                      onTap: () => setState(() => _rating = i + 1),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(
                          _rating > i ? Icons.star : Icons.star_outline,
                          size: 36,
                          color: _rating > i
                              ? scheme.tertiary
                              : scheme.onSurface.withOpacity(0.3),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                // label under stars
                Text(
                  _ratingLabel(),
                  style: TextStyle(
                    fontSize: 13,
                    color: scheme.onSurface.withOpacity(0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // feedback textfield
                TextField(
                  controller: _feedbackController,
                  maxLines: 3,
                  style: TextStyle(color: scheme.onSurface),
                  decoration: InputDecoration(
                    hintText: "Write your feedback (optional)…",
                    hintStyle: TextStyle(
                      color: scheme.onSurface.withOpacity(0.5),
                    ),
                    filled: true,
                    fillColor: scheme.surfaceContainerHigh,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: scheme.outlineVariant),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: scheme.primary, width: 2),
                    ),
                    contentPadding: const EdgeInsets.all(14),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // ===================== SUBMIT =====================
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: scheme.primary,
                  foregroundColor: scheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _rating > 0 ? _submit : null,
                child: const Text(
                  "Submit & Close",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // skip link
            TextButton(
              onPressed: () {
                if (!context.mounted) return;
                Navigator.popUntil(context, (route) => !route.canPop);
              },
              child: Text(
                "Skip for now",
                style: TextStyle(
                  color: scheme.onSurface.withOpacity(0.6),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // -----------------------------------------------------------------------
  void _submit() {
    SnackBarHelper.showSuccess(
      context,
      "Thank you for your feedback! 🙏",
    );

    // navigate back to home / request list
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      Navigator.popUntil(context, (route) => !route.canPop);
    });
  }

  String _ratingLabel() => switch (_rating) {
        1 => "Poor",
        2 => "Fair",
        3 => "Good",
        4 => "Very Good",
        5 => "Excellent!",
        _ => "Tap a star to rate",
      };

  // -----------------------------------------------------------------------
  // REUSABLE WIDGETS
  // -----------------------------------------------------------------------
  static Widget _card(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    final scheme = Theme.of(context).colorScheme;
    
    return Card(
      color: scheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: scheme.primary, size: 18),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: scheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      ),
    );
  }

  static Widget _row(
    BuildContext context,
    String label,
    String value, {
    bool bold = false,
    bool highlight = false,
  }) {
    final scheme = Theme.of(context).colorScheme;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: bold
                  ? scheme.onSurface
                  : scheme.onSurface.withOpacity(0.6),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: bold ? FontWeight.bold : FontWeight.w500,
              color: highlight
                  ? scheme.secondary
                  : scheme.onSurface.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _rowMulti(
    BuildContext context,
    String label,
    String value,
  ) {
    final scheme = Theme.of(context).colorScheme;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: scheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: scheme.onSurface.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}