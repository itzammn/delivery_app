import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:zamboree/screens/DropMapPage.dart';

class OrderDetailsPage extends StatefulWidget {
  final Map<String, dynamic> orderData;
  const OrderDetailsPage({super.key, required this.orderData});

  @override
  State<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage>
    with SingleTickerProviderStateMixin {
  double _dragProgress = 0.0; // 0.0 to 1.0 (Responsive)
  bool _isNavigating = false;

  void _onHorizontalDragUpdate(DragUpdateDetails details, double maxDrag) {
    if (_isNavigating) return;
    setState(() {
      _dragProgress += details.delta.dx / maxDrag;
      _dragProgress = _dragProgress.clamp(0.0, 1.0);
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (_isNavigating) return;
    if (_dragProgress > 0.8) {
      setState(() {
        _dragProgress = 1.0;
        _isNavigating = true;
      });
      // Navigate to DropMapPage
      Future.delayed(const Duration(milliseconds: 200), () {
        Get.to(() => DropMapPage(order: widget.orderData))?.then((_) {
          if (mounted) {
            setState(() {
              _dragProgress = 0.0;
              _isNavigating = false;
            });
          }
        });
      });
    } else {
      // Snap back
      setState(() {
        _dragProgress = 0.0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("✅ ORDER DETAILS PAGE DATA: ${widget.orderData}");

    final Map<String, dynamic> order = widget.orderData;
    final List products = order['products'] ?? [];
    final Map address = order['address'] ?? {};

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Clean background
      appBar: AppBar(
        title: const Text(
          "Order Details",
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Get.back(),
        ),
      ),
      body: Stack(
        children: [
          /// MAIN CONTENT - Full Screen Scrollable
          Positioned.fill(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              // Bottom padding ensures content isn't hidden by the slider
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom + 120,
              ),
              child: Column(
                children: [
                  /// 1. STATUS HEADER
                  _buildStatusHeader(order),

                  const SizedBox(height: 16),

                  /// 2. DELIVERY TIMELINE
                  _buildDeliveryTimeline(),

                  const SizedBox(height: 16),

                  /// 3. CUSTOMER DETAILS CARD
                  _buildModernCard(
                    icon: Icons.person_pin_circle_outlined,
                    iconColor: const Color(0xFF4A6CF7),
                    title: "Customer Information",
                    children: [
                      _modernInfoRow(
                        Icons.account_circle_outlined,
                        "Contact Name",
                        address['customer_name']?.toString() ?? "N/A",
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(height: 1, thickness: 0.5),
                      ),
                      _modernInfoRow(
                        Icons.phone_iphone_outlined,
                        "Mobile Number",
                        address['mobile']?.toString() ?? "N/A",
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.call,
                            color: Colors.green,
                            size: 20,
                          ),
                          onPressed: () {}, // Implementation placeholder
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(height: 1, thickness: 0.5),
                      ),
                      _modernInfoRow(
                        Icons.location_on_outlined,
                        "Delivery Address",
                        "${address['addressLine1'] ?? ""}, ${address['city'] ?? ""}",
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  /// 4. ORDER ITEMS
                  _buildModernCard(
                    icon: Icons.receipt_outlined,
                    iconColor: const Color(0xFFFF4D4D),
                    title: "Order Items (${products.length})",
                    children: products.isEmpty
                        ? [
                            const Center(
                              child: Text(
                                "No items found",
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          ]
                        : products.map<Widget>((item) {
                            return _modernItemRow(
                              item['productName'] ?? "Item",
                              item['quantity'].toString(),
                              item['price']?.toString() ?? "0",
                            );
                          }).toList(),
                  ),

                  const SizedBox(height: 16),

                  /// 5. BILLING SUMMARY
                  _buildModernCard(
                    icon: Icons.account_balance_wallet_outlined,
                    iconColor: const Color(0xFF00B894),
                    title: "Payment Summary",
                    children: [
                      _paymentRow(
                        "Payment Method",
                        order['pay_method'] ?? "N/A",
                      ),
                      const SizedBox(height: 12),
                      const Divider(thickness: 1),
                      const SizedBox(height: 12),
                      _paymentRow(
                        "Amount to Collect",
                        "₹${order['amount'] ?? 0}",
                        isTotal: true,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          /// BOTTOM ACTION AREA (FIXED)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                MediaQuery.of(context).padding.bottom + 20,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.0),
                    Colors.white.withOpacity(0.9),
                    Colors.white,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.3, 1.0],
                ),
              ),
              child: _buildResponsiveSlidingButton(),
            ),
          ),
        ],
      ),
    );
  }

  // ================= UI HELPERS =================

  Widget _buildStatusHeader(Map<String, dynamic> order) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.inventory_2_rounded,
              size: 56,
              color: Color(0xFF10B981),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "ORDER PICKED UP",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Color(0xFF10B981),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Order ID: #${order['_id']?.toString().substring(0, 8) ?? 'N/A'}",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryTimeline() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          _timelineStep(Icons.check_circle, "Picked", true, true),
          Expanded(child: _timelineLine(true)),
          _timelineStep(Icons.local_shipping, "On Way", true, false),
          Expanded(child: _timelineLine(false)),
          _timelineStep(Icons.location_on, "Drop", false, false),
        ],
      ),
    );
  }

  Widget _timelineStep(
    IconData icon,
    String label,
    bool isActive,
    bool isDone,
  ) {
    return Column(
      children: [
        Icon(
          icon,
          size: 24,
          color: isDone
              ? const Color(0xFF10B981)
              : (isActive ? const Color(0xFF4A6CF7) : Colors.grey.shade300),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: isActive ? Colors.black87 : Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _timelineLine(bool isActive) {
    return Container(
      height: 2,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: isActive ? const Color(0xFF10B981) : Colors.grey.shade200,
    );
  }

  Widget _buildModernCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: iconColor),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _modernInfoRow(
    IconData icon,
    String label,
    String value, {
    Widget? trailing,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade500),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _modernItemRow(String name, String qty, String price) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              qty,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.orange.shade800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            "₹$price",
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
          ),
        ],
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
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.w800 : FontWeight.w500,
            color: isTotal ? Colors.black87 : Colors.grey.shade600,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 20 : 15,
            fontWeight: isTotal ? FontWeight.w900 : FontWeight.w700,
            color: isTotal ? const Color(0xFF10B981) : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildResponsiveSlidingButton() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxWidth = constraints.maxWidth;
        final double circleSize = 60.0;
        final double innerPadding = 5.0;
        final double maxDrag = maxWidth - circleSize - (innerPadding * 2);

        final isCompleted = _dragProgress > 0.8;

        return Container(
          height: 70,
          width: maxWidth,
          decoration: BoxDecoration(
            color: isCompleted
                ? const Color(0xFF10B981)
                : const Color(0xFF1A1D21),
            borderRadius: BorderRadius.circular(35),
            boxShadow: [
              BoxShadow(
                color: (isCompleted ? const Color(0xFF10B981) : Colors.black)
                    .withOpacity(0.2),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              /// SLIDE TEXT
              AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _dragProgress > 0.5 ? 0.0 : 1.0,
                child: const Text(
                  "SLIDE TO DROP LOCATION",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.1,
                  ),
                ),
              ),

              if (isCompleted)
                const Text(
                  "READY TO GO!",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),

              /// DRAGGABLE CIRCLE
              Positioned(
                left: innerPadding + (_dragProgress * maxDrag),
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) =>
                      _onHorizontalDragUpdate(details, maxDrag),
                  onHorizontalDragEnd: (details) =>
                      _onHorizontalDragEnd(details),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 100),
                    width: circleSize,
                    height: circleSize,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      _isNavigating
                          ? Icons.check
                          : Icons.arrow_forward_ios_rounded,
                      color: isCompleted
                          ? const Color(0xFF10B981)
                          : const Color(0xFF1A1D21),
                      size: 24,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
