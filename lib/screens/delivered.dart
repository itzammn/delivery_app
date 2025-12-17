import 'package:flutter/material.dart';

class DeliveredPage extends StatelessWidget {
  const DeliveredPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),

          // 🔹 Header
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 18),
            child: Text(
              "Today's Delivered Orders",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF19676E),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // 🔹 Summary Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  _summaryTile("Total Orders", "6", Icons.list_alt_rounded,
                      Color(0xFF40A798)),
                  _summaryTile("Earnings", "₹1240", Icons.account_balance_wallet,
                      Colors.amber),
                  _summaryTile("Trip", "12.5 km", Icons.pin_drop_rounded,
                      Colors.redAccent),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // 🔹 Delivered Orders List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              children: const [
                _deliveredCard(
                  orderId: "#ORD4589",
                  customer: "Rahul Sharma",
                  address: "Green Park Colony",
                  amount: "₹220.00",
                  distance: "2.3 km",
                  time: "10:45 AM",
                ),
                _deliveredCard(
                  orderId: "#ORD4590",
                  customer: "Priya Verma",
                  address: "City Mall, Sector 9",
                  amount: "₹185.00",
                  distance: "1.8 km",
                  time: "11:10 AM",
                ),
                _deliveredCard(
                  orderId: "#ORD4591",
                  customer: "Amit Kumar",
                  address: "Lake View Apartments",
                  amount: "₹260.00",
                  distance: "3.1 km",
                  time: "12:00 PM",
                ),
                _deliveredCard(
                  orderId: "#ORD4592",
                  customer: "Neha Singh",
                  address: "Sunshine Tower",
                  amount: "₹175.00",
                  distance: "1.5 km",
                  time: "12:45 PM",
                ),
                _deliveredCard(
                  orderId: "#ORD4593",
                  customer: "Ravi Mehta",
                  address: "Galaxy Heights",
                  amount: "₹220.00",
                  distance: "2.0 km",
                  time: "1:20 PM",
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// 🔹 Summary Tile Widget
class _summaryTile extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _summaryTile(this.title, this.value, this.icon, this.color, {super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.black,
          ),
        ),
        Text(
          title,
          style: const TextStyle(
            color: Colors.black54,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// 🔹 Delivered Order Card Widget
class _deliveredCard extends StatelessWidget {
  final String orderId;
  final String customer;
  final String address;
  final String amount;
  final String distance;
  final String time;

  const _deliveredCard({
    required this.orderId,
    required this.customer,
    required this.address,
    required this.amount,
    required this.distance,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  orderId,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Color(0xFF19676E),
                  ),
                ),
                Row(
                  children: [
                    const Icon(Icons.access_time,
                        color: Colors.black45, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      time,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Customer Name
            Text(
              customer,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),

            const SizedBox(height: 4),

            // Address
            Row(
              children: [
                const Icon(Icons.location_on_outlined,
                    color: Colors.redAccent, size: 16),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    address,
                    style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 13,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Footer Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Distance: $distance",
                  style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 13,
                      fontWeight: FontWeight.w500),
                ),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF40A798).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    amount,
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),

            // Status Chip
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  "Delivered",
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
