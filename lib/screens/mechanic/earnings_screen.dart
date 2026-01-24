import 'package:flutter/material.dart';

class EarningsScreen extends StatelessWidget {
  const EarningsScreen({super.key});

  // ---------------- DUMMY EARNINGS DATA ----------------
  List<Map<String, dynamic>> get _earnings => [
        {
          "date": "12 Sep 2025",
          "jobs": 3,
          "amount": 1600,
        },
        {
          "date": "11 Sep 2025",
          "jobs": 2,
          "amount": 900,
        },
        {
          "date": "10 Sep 2025",
          "jobs": 4,
          "amount": 2150,
        },
        {
          "date": "09 Sep 2025",
          "jobs": 1,
          "amount": 450,
        },
      ];

  int get _totalEarnings =>
      _earnings.fold(0, (sum, e) => sum + e["amount"] as int);

  int get _totalJobs =>
      _earnings.fold(0, (sum, e) => sum + e["jobs"] as int);

  @override
  Widget build(BuildContext context) {
    final yellow = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Earnings"),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // ---------------- SUMMARY CARD ----------------
          Container(
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
                  "₹$_totalEarnings",
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Completed Jobs: $_totalJobs",
                  style: const TextStyle(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),

          // ---------------- DAILY BREAKDOWN ----------------
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

          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(14),
              itemCount: _earnings.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final e = _earnings[i];

                return Card(
                  color: const Color(0xFF1C1C1C),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
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
                                e["date"],
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "${e["jobs"]} jobs completed",
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
                          "₹${e["amount"]}",
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
            ),
          ),
        ],
      ),
    );
  }
}
