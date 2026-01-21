import 'package:flutter/material.dart';
import 'package:get/get.dart';

class OrderDetailsPage extends StatelessWidget {
  final Map<String, dynamic> orderData;
  const OrderDetailsPage({super.key, required this.orderData});

  @override
  Widget build(BuildContext context) {
    // Extract data safety
    final order = orderData['order'] ?? orderData;
    final items = order['items'] as List? ?? [];
    final customer = order['customer'] ?? {};
    final drop = order['drop'] ?? {};

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          "Order Details",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildStatusHeader(order['status'] ?? "Picked Up"),
            _buildInfoCard("Customer Details", [
              _infoRow(Icons.person, customer['name'] ?? "Customer Name"),
              _infoRow(Icons.phone, customer['mobile'] ?? "Not available"),
              _infoRow(Icons.location_on, drop['address'] ?? "Drop Address"),
            ]),
            _buildInfoCard(
              "Order Items",
              items
                  .map((item) {
                    return _itemRow(
                      item['name'] ?? "Unknown Item",
                      item['quantity']?.toString() ?? "1",
                      "₹${item['price'] ?? '0'}",
                    );
                  })
                  .toList()
                  .cast<Widget>(),
            ),
            _buildInfoCard("Payment Summary", [
              _paymentRow("Item Total", "₹${order['item_total'] ?? '0'}"),
              _paymentRow(
                "Shipping Fee",
                "₹${order['shipping_charger'] ?? '0'}",
              ),
              const Divider(),
              _paymentRow(
                "Total Amount",
                "₹${order['total_amount'] ?? '0'}",
                isTotal: true,
              ),
            ]),
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ElevatedButton(
                onPressed: () =>
                    Get.offAllNamed('/dashboard'), // Or wherever to go back
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  "BACK TO DASHBOARD",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeader(String status) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          const Icon(Icons.check_circle, size: 64, color: Colors.green),
          const SizedBox(height: 12),
          Text(
            status.toUpperCase(),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Order ID: #${orderData['orderId'] ?? '---'}",
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade400),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  Widget _itemRow(String name, String qty, String price) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("$name x$qty", style: const TextStyle(fontSize: 14)),
          Text(
            price,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _paymentRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
