import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:zamboree/Controller/LocationController.dart';
import 'package:zamboree/screens/EditMapPageLocation.dart';
import 'package:zamboree/screens/ZoneMapPage.dart';
import 'package:zamboree/auth/api_helper.dart';
import 'earning.dart';
import 'myshift.dart';
import 'delivered.dart';
import 'profile.dart';
import 'notifications.dart';
import 'support.dart';
import 'incentives.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key, required this.title});
  final String title;

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  int _selectedIndex = 0;
  bool isOnline = false;
  bool isSearching = false;
  bool hasDelivery = false;
  int _progress = 100;
  Timer? _timer;
  bool _isCheckingZone = false;
  bool showToday = true;
  String userName = "Aman"; // Default fallback

  final Color primaryColor = const Color(0xFF1E3A8A); // Deep Blue
  final Color accentColor = const Color(0xFF3B82F6); // Lighter Blue
  final Color successColor = const Color(0xFF10B981); // Emerald Green
  final Color warningColor = const Color(0xFFF59E0B); // Amber
  final Color dangerColor = const Color(0xFFEF4444); // Red

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    String? storedName = prefs.getString('user_name');
    if (storedName != null && storedName.isNotEmpty) {
      if (mounted) {
        setState(() {
          userName = storedName.split(' ')[0]; // Use only first name for header
        });
      }
    }
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  Future<void> _toggleOnlineStatus() async {
    if (isOnline) {
      setState(() {
        isOnline = false;
        isSearching = false;
        hasDelivery = false;
        _timer?.cancel();
      });
      if (mounted) {
        _showSnackBar("You are now offline", dangerColor);
      }
      return;
    }

    double currentLat = locationController.latitude.value;
    double currentLng = locationController.longitude.value;

    setState(() => _isCheckingZone = true);

    try {
      final res = await ApiHelper.checkZone(currentLat, currentLng);
      bool isSuccess = res["success"] == true;
      int statusCode = res["statusCode"] ?? 0;

      if (statusCode == 401) {
        if (mounted) {
          _showSnackBar("Please login first to check zone", dangerColor);
        }
        return;
      }

      if (!isSuccess || statusCode >= 400) {
        if (mounted) {
          _showSnackBar(res['message'] ?? "Failed to check zone", dangerColor);
        }
        return;
      }

      dynamic data = res["data"];
      bool isInside = false;

      if (data is Map) {
        isInside =
            data["isInsideZone"] == true ||
            data["isInsideZone"]?.toString().toLowerCase() == "true";
      }

      if (isSuccess && isInside) {
        setState(() {
          isOnline = true;
          isSearching = true;
        });
        _startSearchCycle();
        if (mounted) {
          _showSnackBar("You are now online!", successColor);
        }
      } else {
        _showOutOfZoneSheet(res);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar("Error checking zone: $e", dangerColor);
      }
    } finally {
      if (mounted) setState(() => _isCheckingZone = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(10),
      ),
    );
  }

  void _showOutOfZoneSheet(Map<String, dynamic> data) {
    final zoneData = data["data"];
    final zoneInfo = zoneData?["zone"] ?? zoneData?["nearestZone"];
    String zoneName = "Service Zone";
    if (zoneInfo != null && zoneInfo is Map) {
      zoneName = zoneInfo["name"] ?? "Service Zone";
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: dangerColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.location_off_rounded,
                color: dangerColor,
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Out of Service Zone",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              zoneData != null
                  ? "You are currently outside your assigned delivery area ($zoneName). Please move inside the zone to go online."
                  : "No service zone found nearby. Please contact support for assistance.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 30),
            if (zoneData != null) ...[
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  Get.to(() => ZoneMapPage(zoneData: zoneData));
                },
                icon: const Icon(
                  Icons.navigation_outlined,
                  color: Colors.white,
                ),
                label: const Text(
                  "Navigate to Zone",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
              ),
              const SizedBox(height: 12),
            ],
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Dismiss",
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _startSearchCycle() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && isOnline) {
        setState(() {
          isSearching = false;
          hasDelivery = true;
        });
        _startDeliveryTimer();
      }
    });
  }

  void _startDeliveryTimer() {
    _progress = 100;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted) return;
      setState(() => _progress -= 1);
      if (_progress <= 0) {
        timer.cancel();
        _rejectDelivery();
      }
    });
  }

  void _rejectDelivery() {
    _timer?.cancel();
    setState(() {
      hasDelivery = false;
      isSearching = true;
    });
    if (isOnline) _startSearchCycle();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: _selectedIndex == 0 ? _dashboardContent() : _buildPageContent(),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildPageContent() {
    switch (_selectedIndex) {
      case 1:
        return const EarningsPage();
      case 2:
        return const MyShiftPage();
      case 3:
        return const DeliveredPage();
      case 4:
        return const ProfilePage();
      default:
        return _dashboardContent();
    }
  }

  Widget _dashboardContent() {
    return Stack(
      children: [
        // Background Gradient
        Container(
          height: 300,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [primaryColor, accentColor],
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(40),
              bottomRight: Radius.circular(40),
            ),
          ),
        ),
        SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 25),
                _buildMainCard(),
                const SizedBox(height: 30),
                _buildProgressSection(),
                const SizedBox(height: 100), // Space for bottom nav
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Welcome Back,",
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                Text(
                  "$userName 👋",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                _circularIconButton(
                  Icons.notifications_none_rounded,
                  () => Get.to(() => const NotificationPage()),
                ),
                const SizedBox(width: 12),
                _circularIconButton(
                  Icons.headset_mic_outlined,
                  () => Get.to(() => const SupportPage()),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: () => Get.to(() => const EditMapPage()),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.location_on_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Obx(
                    () => Text(
                      locationController.locationText.value,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Colors.white70),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _circularIconButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }

  Widget _buildMainCard() {
    final size = MediaQuery.of(context).size;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Stack(
          children: [
            PositionRectangle(
              color: accentColor.withOpacity(0.03),
              size: 150,
              top: -50,
              right: -50,
            ),
            PositionRectangle(
              color: accentColor.withOpacity(0.03),
              size: 100,
              bottom: -20,
              left: -20,
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  _buildStatusToggle(),
                  const SizedBox(height: 24),
                  _buildDynamicContent(size),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusToggle() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(child: _statusButton("Offline", !isOnline, dangerColor)),
          Expanded(child: _statusButton("Online", isOnline, successColor)),
        ],
      ),
    );
  }

  Widget _statusButton(String title, bool active, Color color) {
    return GestureDetector(
      onTap: _isCheckingZone ? null : _toggleOnlineStatus,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        alignment: Alignment.center,
        child: _isCheckingZone && active && title == "Online"
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.green,
                ),
              )
            : Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: active ? color : Colors.grey.shade500,
                ),
              ),
      ),
    );
  }

  Widget _buildDynamicContent(Size size) {
    if (!isOnline) {
      return Column(
        children: [
          Image.asset(
            'assets/images/fast-shipping.png',
            height: 80,
            errorBuilder: (c, e, s) =>
                Icon(Icons.moped_rounded, size: 80, color: primaryColor),
          ),
          const SizedBox(height: 16),
          const Text(
            "Ready to earn?",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            "Go online to start receiving delivery requests in your area.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
        ],
      );
    } else if (isSearching && !hasDelivery) {
      return Column(
        children: [
          const SizedBox(height: 20),
          TweenAnimationBuilder(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(seconds: 2),
            onEnd: () {},
            builder: (context, double value, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 100,
                    height: 100,
                    child: CircularProgressIndicator(
                      strokeWidth: 8,
                      valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                      backgroundColor: accentColor.withOpacity(0.1),
                    ),
                  ),
                  Icon(Icons.radar_rounded, color: accentColor, size: 40),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          const Text(
            "Searching for orders...",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            "Best orders are being picked for you",
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      );
    } else if (hasDelivery) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: successColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  "NEW ORDER",
                  style: TextStyle(
                    color: successColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const Text(
                "⭐ 4.87",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            "₹22.50",
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _deliveryInfoRow(
            Icons.storefront_rounded,
            "Pickup: Pizza Planet",
            "2.3 km",
          ),
          const SizedBox(height: 10),
          _deliveryInfoRow(
            Icons.location_on_rounded,
            "Drop: Green Park Colony",
            "4.8 km",
          ),
          const SizedBox(height: 24),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: _progress / 100,
              minHeight: 10,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(successColor),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _rejectDelivery,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    "Decline",
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () {
                    _timer?.cancel();
                    Get.to(
                      () => const DummyMapPage(
                        pickup: "Pizza Planet",
                        distance: "2.3 km",
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    "Accept Order",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  Widget _deliveryInfoRow(IconData icon, String title, String distance) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade400),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          ),
        ),
        Text(
          distance,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildProgressSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "MY PROGRESS",
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  letterSpacing: 1.2,
                ),
              ),
              _buildTabToggle(),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _statItem(
                showToday ? "₹723" : "₹2,340",
                "Earnings",
                Icons.account_balance_wallet_rounded,
                accentColor,
              ),
              _statItem(
                showToday ? "4:00" : "38:20",
                "Hours",
                Icons.timer_rounded,
                warningColor,
              ),
              _statItem(
                showToday ? "5" : "46",
                "Orders",
                Icons.shopping_bag_rounded,
                successColor,
              ),
            ],
          ),
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Daily Incentive",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              Text(
                "₹85 Reward",
                style: TextStyle(
                  color: successColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            "Earn ₹220 more to reach next milestone",
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 20),
          _buildIncentiveBar(),
          const SizedBox(height: 24),
          Center(
            child: TextButton(
              onPressed: () => Get.to(() => const IncentivePage()),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "View all incentives",
                    style: TextStyle(
                      color: accentColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 16,
                    color: accentColor,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [_tabItem("Today", showToday), _tabItem("Week", !showToday)],
      ),
    );
  }

  Widget _tabItem(String title, bool active) {
    return GestureDetector(
      onTap: () => setState(() => showToday = title == "Today"),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                  ),
                ]
              : [],
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: active ? Colors.black : Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _statItem(String value, String label, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 12),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildIncentiveBar() {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              height: 10,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 1000),
              height: 10,
              width: MediaQuery.of(context).size.width * 0.4,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [accentColor, successColor]),
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text(
              "₹0",
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
            Text(
              "₹220",
              style: TextStyle(
                fontSize: 12,
                color: Colors.blue,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              "₹360",
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
            Text(
              "₹950",
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBottomNav() {
    return Container(
      height: 72,
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 45),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 25,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(0, Icons.dashboard_rounded, "Home"),
          _navItem(1, Icons.account_balance_wallet_rounded, "Earnings"),
          _navItem(2, Icons.schedule_rounded, "Shifts"),
          _navItem(3, Icons.task_alt_rounded, "Orders"),
          _navItem(4, Icons.person_rounded, "Profile"),
        ],
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label) {
    bool active = _selectedIndex == index;

    return GestureDetector(
      onTap: () => _onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active ? accentColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 24,
              color: active ? accentColor : Colors.grey.shade400,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: active ? accentColor : Colors.grey.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PositionRectangle extends StatelessWidget {
  final Color color;
  final double size;
  final double? top;
  final double? bottom;
  final double? left;
  final double? right;

  const PositionRectangle({
    super.key,
    required this.color,
    required this.size,
    this.top,
    this.bottom,
    this.left,
    this.right,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}

// 🌍 Dummy Map Page (Preserved functionality)
class DummyMapPage extends StatefulWidget {
  final String pickup;
  final String distance;
  const DummyMapPage({super.key, required this.pickup, required this.distance});

  @override
  State<DummyMapPage> createState() => _DummyMapPageState();
}

class _DummyMapPageState extends State<DummyMapPage> {
  static const LatLng _pickupLocation = LatLng(26.8467, 80.9462);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Delivery Route",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: GoogleMap(
        initialCameraPosition: const CameraPosition(
          target: _pickupLocation,
          zoom: 14.0,
        ),
        markers: {
          const Marker(
            markerId: MarkerId('pickup'),
            position: _pickupLocation,
            infoWindow: InfoWindow(title: 'Pickup: Pizza Planet'),
          ),
        },
        myLocationEnabled: true,
      ),
    );
  }
}

final locationController = Get.find<LocationController>();
