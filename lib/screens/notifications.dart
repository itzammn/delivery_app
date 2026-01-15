import 'package:flutter/material.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          "Notifications",
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Color(0xFF1A1A1A),
            size: 18,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: () {},
            child: const Text(
              "Clear all",
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        children: [
          _buildSectionHeader("Today"),
          const SizedBox(height: 12),
          _buildModernNotificationCard(
            title: "Order #12345 Delivered",
            message:
                "Great job! You just successfully delivered the pizza order to Green Park.",
            time: "2 mins ago",
            icon: Icons.check_circle_rounded,
            iconColor: Colors.green,
            isNew: true,
          ),
          const SizedBox(height: 12),
          _buildModernNotificationCard(
            title: "New Bonus Opportunity",
            message:
                "Earn an extra ₹150 by completing 5 more deliveries before 9 PM tonight!",
            time: "45 mins ago",
            icon: Icons.stars_rounded,
            iconColor: Colors.orange,
            isNew: true,
          ),
          const SizedBox(height: 24),
          _buildSectionHeader("Yesterday"),
          const SizedBox(height: 12),
          _buildModernNotificationCard(
            title: "System Update Complete",
            message:
                "The Zamboree app has been updated to version 2.4.0 with smoother map navigation.",
            time: "Yesterday, 04:30 PM",
            icon: Icons.system_update_rounded,
            iconColor: Colors.blueAccent,
            
            isNew: false,
          ),
          const SizedBox(height: 12),
          _buildModernNotificationCard(
            title: "KYC Verified",
            message:
                "Your document verification process is now complete. Happy delivering!",
            time: "Yesterday, 10:15 AM",
            icon: Icons.verified_user_rounded,
            iconColor: Colors.purple,
            isNew: false,
          ),
          const SizedBox(height: 12),
          _buildModernNotificationCard(
            title: "Payment Received",
            message:
                "Weekly payout of ₹4,250 has been credited to your bank account.",
            time: "2 days ago",
            icon: Icons.account_balance_wallet_rounded,
            iconColor: Colors.teal,
            isNew: false,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w800,
        color: Color(0xFF8E8E93),
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildModernNotificationCard({
    required String title,
    required String message,
    required String time,
    required IconData icon,
    required Color iconColor,
    required bool isNew,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          if (isNew)
            Positioned(
              top: 15,
              right: 15,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.redAccent,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isNew
                              ? const Color(0xFF1A1A1A)
                              : const Color(0xFF4A4A4A),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        message,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF8A8A8E),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        time,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFC7C7CC),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
