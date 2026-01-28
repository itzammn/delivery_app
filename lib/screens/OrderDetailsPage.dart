import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:zamboree/screens/DropMapPage.dart';

class OrderDetailsPage extends StatelessWidget {
  final Map<String, dynamic> orderData;
  const OrderDetailsPage({super.key, required this.orderData});

  @override
  Widget build(BuildContext context) {
    debugPrint("✅ ORDER DETAILS PAGE DATA: $orderData");

    ///  BACKEND STRUCTURE KE HISAB SE DATA
    final Map<String, dynamic> order = orderData;
    final List products = order['products'] ?? [];
    final Map address = order['address'] ?? {};

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
            /// STATUS
            _buildStatusHeader(order),

            /// CUSTOMER DETAILS
            _buildInfoCard("Customer Details", [
              _infoRow(
                Icons.person,
                address['customer_name']?.toString() ?? "N/A",
              ),
              _infoRow(Icons.phone, address['mobile']?.toString() ?? "N/A"),
              _infoRow(
                Icons.location_on,
                "${address['addressLine1'] ?? ""}, ${address['city'] ?? ""}",
              ),
            ]),

            /// ORDER ITEMS
            _buildInfoCard(
              "Order Items",
              products.isEmpty
                  ? [const Text("No items found")]
                  : products.map<Widget>((item) {
                      return _itemRow(
                        item['productName'] ?? "Item",
                        item['quantity'].toString(),
                      );
                    }).toList(),
            ),

            /// PAYMENT SUMMARY
            _buildInfoCard("Payment Summary", [
              _paymentRow("Payment Method", order['pay_method'] ?? "N/A"),
              const Divider(),
              _paymentRow(
                "Total Amount",
                "₹${order['amount'] ?? 0}",
                isTotal: true,
              ),
            ]),

            const SizedBox(height: 30),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ElevatedButton(
                onPressed: () {
                  Get.to(() => DropMapPage(order: order));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 13, 14, 13),
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  "GO TO DROP LOCATION",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Padding(
            //   padding: const EdgeInsets.symmetric(horizontal: 20),
            //   child: OutlinedButton(
            //     onPressed: () => Get.offAllNamed('/dashboard'),
            //     style: OutlinedButton.styleFrom(
            //       minimumSize: const Size(double.infinity, 56),
            //       side: const BorderSide(color: Color(0xFF1E3A8A)),
            //       shape: RoundedRectangleBorder(
            //         borderRadius: BorderRadius.circular(16),
            //       ),
            //     ),
            //     child: const Text(
            //       "BACK TO HOME",
            //       style: TextStyle(
            //         fontSize: 16,
            //         fontWeight: FontWeight.bold,
            //         color: Color(0xFF1E3A8A),
            //       ),
            //     ),
            //   ),
            // ),
            // const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ================= UI HELPERS =================

  Widget _buildStatusHeader(Map<String, dynamic> order) {
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
          const Text(
            "PICKED UP",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10),
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
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Widget _itemRow(String name, String qty) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text("$name x$qty"), const Text("✔")],
      ),
    );
  }

  Widget _paymentRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
