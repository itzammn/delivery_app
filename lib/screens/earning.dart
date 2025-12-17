import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class EarningsPage extends StatelessWidget {
  const EarningsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: CustomScrollView(
        slivers: [
          // 🔹 Collapsing AppBar + Monthly Earnings
          SliverAppBar(
            backgroundColor: Colors.white,
            pinned: true,
            automaticallyImplyLeading: false, // ✅ Hide back icon
            expandedHeight: 180, // 🔹 Reduced height
            flexibleSpace: FlexibleSpaceBar(
              background: Padding(
                padding: const EdgeInsets.only(top: 40, left: 18, right: 18),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12.withOpacity(0.1),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text(
                        "This Month Earnings",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "₹12,350",
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFB30606),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        "+8% from last month",
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 🔹 Earnings by Day (Chart Section)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12.withOpacity(0.08),
                      blurRadius: 6,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      "Earnings by Day",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 160,
                      child: BarChart(
                        BarChartData(
                          gridData: FlGridData(show: false),
                          borderData: FlBorderData(show: false),
                          titlesData: FlTitlesData(
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, _) {
                                  const days = [
                                    "Mon",
                                    "Tue",
                                    "Wed",
                                    "Thu",
                                    "Fri",
                                    "Sat",
                                    "Sun"
                                  ];
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 5),
                                    child: Text(
                                      days[value.toInt() % days.length],
                                      style: const TextStyle(
                                        color: Colors.black54,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 12,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            rightTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            topTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                          ),
                          barGroups: [
                            _bar(0, 9),
                            _bar(1, 6),
                            _bar(2, 8),
                            _bar(3, 10),
                            _bar(4, 7),
                            _bar(5, 12),
                            _bar(6, 5),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 🔹 Recent Earnings Title
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              alignment: Alignment.centerLeft,
              child: const Text(
                "Recent Earnings",
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: Color(0xFF19676E),
                ),
              ),
            ),
          ),

          // 🔹 Scrollable Earnings List
          SliverList(
            delegate: SliverChildBuilderDelegate(
                  (context, index) {
                final List<Map<String, dynamic>> data = [
                  {"date": "Nov 27, 2025", "deliveries": 8, "amount": "₹480.00"},
                  {"date": "Nov 26, 2025", "deliveries": 6, "amount": "₹365.00"},
                  {"date": "Nov 25, 2025", "deliveries": 10, "amount": "₹590.00"},
                  {"date": "Nov 24, 2025", "deliveries": 5, "amount": "₹310.00"},
                  {"date": "Nov 23, 2025", "deliveries": 9, "amount": "₹520.00"},
                  {"date": "Nov 22, 2025", "deliveries": 7, "amount": "₹420.00"},
                  {"date": "Nov 21, 2025", "deliveries": 11, "amount": "₹630.00"},
                ];

                final item = data[index];
                return _earningTile(
                  date: item["date"] as String,
                  deliveries: item["deliveries"] as int,
                  amount: item["amount"] as String,
                );
              },
              childCount: 7,
            ),
          ),
        ],
      ),
    );
  }

  // 🔹 Bar Data Helper
  static BarChartGroupData _bar(int x, double y) {
    return BarChartGroupData(x: x, barRods: [
      BarChartRodData(
        toY: y,
        color: const Color(0xFF22308E),
        width: 16,
        borderRadius: BorderRadius.circular(6),
        backDrawRodData: BackgroundBarChartRodData(
          show: true,
          toY: 12,
          color: Colors.grey.shade200,
        ),
      ),
    ]);
  }
}

// 🔹 Earnings ListTile
class _earningTile extends StatelessWidget {
  final String date;
  final int deliveries;
  final String amount;

  const _earningTile({
    required this.date,
    required this.deliveries,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      child: Card(
        elevation: 1.5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF40A798).withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.calendar_today,
                color: Color(0xFFDC0606), size: 22),
          ),
          title: Text(
            date,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          subtitle: Text(
            "$deliveries deliveries",
            style: const TextStyle(color: Colors.black54, fontSize: 13),
          ),
          trailing: Text(
            amount,
            style: const TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }
}
 