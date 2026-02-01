import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/request_firestore_service.dart';

class EarningsScreen extends StatelessWidget {
  const EarningsScreen({super.key});

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return "${date.day} ${months[date.month - 1]} ${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    final yellow = Theme.of(context).colorScheme.primary;
    final mechanicId = FirebaseAuth.instance.currentUser?.uid;
    final service = RequestFirestoreService();

    if (mechanicId == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            "Mechanic not logged in",
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Earnings"),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // ================= SUMMARY =================
          StreamBuilder<double>(
            stream: service.getTotalEarningsStream(mechanicId),
            builder: (context, earningsSnapshot) {
              final totalEarnings = earningsSnapshot.data ?? 0;

              return StreamBuilder<int>(
                stream: service.getCompletedRequestsCountStream(mechanicId),
                builder: (context, jobsSnapshot) {
                  final totalJobs = jobsSnapshot.data ?? 0;

                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      // ignore: deprecated_member_use
                      color: yellow.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: yellow),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          "Total Earnings",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "₹${totalEarnings.toStringAsFixed(0)}",
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "Completed Jobs: $totalJobs",
                          style: const TextStyle(
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),

          // ================= DAILY BREAKDOWN TITLE =================
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Daily Breakdown",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // ================= DAILY LIST =================
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: service.getDailyEarningsStream(mechanicId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      snapshot.error.toString(),
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  );
                }

                final earnings = snapshot.data ?? [];

                if (earnings.isEmpty) {
                  return const Center(
                    child: Text(
                      "No earnings yet",
                      style: TextStyle(color: Colors.white70),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(14),
                  itemCount: earnings.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final e = earnings[i];
                    final date = e['date'] as DateTime;
                    final jobs = e['jobs'] as int;
                    final amount = e['amount'] as double;

                    return Card(
                      color: const Color(0xFF1C1C1C),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            // DATE ICON
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: yellow,
                              child: const Icon(
                                Icons.calendar_today,
                                color: Colors.black,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),

                            // INFO
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _formatDate(date),
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "$jobs jobs completed",
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // AMOUNT
                            Text(
                              "₹${amount.toStringAsFixed(0)}",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.greenAccent,
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
          ),
        ],
      ),
    );
  }
}
