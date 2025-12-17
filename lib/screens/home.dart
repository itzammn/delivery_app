import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../auth/login.dart';
import 'earning.dart';
import 'myshift.dart';  // Add this line
import 'delivered.dart';
import 'profile.dart';

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

  bool showToday = true; //  add this line here


  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  // ✅ Toggle Logic (Online / Offline)
  void _toggleOnlineStatus() {
    setState(() {
      if (isOnline) {
        isOnline = false;
        isSearching = false;
        hasDelivery = false;
        _timer?.cancel();
      } else {
        isOnline = true;
        isSearching = true;
      }
    });
    if (isOnline) _startSearchCycle();
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

  Widget _buildBody(BuildContext context) {
    switch (_selectedIndex) {
      case 0:
        return _dashboardBody(context);
      case 1:
        return const EarningsPage();
      case 2: // ✅ My Shift tab
        return const MyShiftPage();
      case 3:
        return const DeliveredPage();
      case 4:
        return const ProfilePage();
      default:
        return _dashboardBody(context);
    }
  }

  Widget _dashboardBody(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔝 Top Row (Toggle + Icons)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Switch(
                    value: isOnline,
                    activeColor: Colors.green,
                    inactiveThumbColor: Colors.white,
                    inactiveTrackColor: Colors.grey.shade400,
                    onChanged: (val) => _toggleOnlineStatus(),
                  ),
                  Text(
                    isOnline ? "Online" : "Offline",
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ],
              ),
              Row(
                children: [
                  const SizedBox(width: 14),

                  // 🔔 Notification Icon (Clickable)
                  IconButton(
                    icon: const Icon(Icons.notifications_none_outlined,
                        color: Colors.black87, size: 26),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const NotificationPage()),
                      );
                    },
                  ),

                  const SizedBox(width: 14),

                  // 🎧 Support Icon (Clickable)
                  IconButton(
                    icon: const Icon(Icons.headphones_outlined,
                        color: Colors.black87, size: 26),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SupportPage()),
                      );
                    },
                  ),
                ],
              )

            ],
          ),

          const SizedBox(height: 15),

          // 🚚 Card Section (Functional)
          Center(child: _buildCardContent(size)),

          const SizedBox(height: 25),

          // 🧾 My Progress Card Section (New Styled Card)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "MY PROGRESS",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black87),
                ),

                const SizedBox(height: 14),

                // Tabs (Today / This Week)
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              showToday = true;
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: showToday ? Colors.black : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            alignment: Alignment.center,
                            child: Text(
                              "Today",
                              style: TextStyle(
                                  color: showToday ? Colors.white : Colors.black87,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              showToday = false;
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: !showToday ? Colors.black : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            alignment: Alignment.center,
                            child: Text(
                              "This Week",
                              style: TextStyle(
                                  color: !showToday ? Colors.white : Colors.black87,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

// 3 stats: Earnings / Login hours / Orders
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _ProgressItem(
                        label: "Earnings",
                        value: showToday ? "₹723" : "₹2,340",
                        icon: Icons.currency_rupee),
                    _ProgressItem(
                        label: "Login hours",
                        value: showToday ? "4:00 hrs" : "38:20 hrs",
                        icon: Icons.access_time),
                    _ProgressItem(
                        label: "Orders",
                        value: showToday ? "5" : "46",
                        icon: Icons.list_alt),
                  ],
                ),

                const SizedBox(height: 25),

// 💰 Daily Incentive Section
                const Text(
                  "Daily Incentive Today",
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Colors.green),
                ),

                const SizedBox(height: 6),
                const Text(
                  "Earn ₹220 more to get ₹85",
                  style: TextStyle(fontSize: 15, color: Colors.black87),
                ),

                const SizedBox(height: 12),

                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        _IncentiveCircle(label: "₹85"),
                        _IncentiveCircle(label: "₹110"),
                        _IncentiveCircle(label: "₹150"),
                        _IncentiveCircle(label: "₹950", isFinal: true),
                      ],
                    ),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: 0.2,
                      color: Colors.redAccent,
                      backgroundColor: Colors.grey.shade300,
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text("₹220", style: TextStyle(fontSize: 12)),
                        Text("₹290", style: TextStyle(fontSize: 12)),
                        Text("₹360", style: TextStyle(fontSize: 12)),
                        Text("+3 more", style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const IncentivePage()),
                      );
                    },
                    child: const Text(
                      "View all incentives",
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),



                const SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
    ); //  closes SingleChildScrollView properly
  }


// ✅ Functional Card Section
  Widget _buildCardContent(Size size) {
    final double cardWidth = size.width * 0.85;
    const double fixedHeight = 200.0;

    if (!isOnline) {
      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: cardWidth,
        height: fixedHeight,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black12.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/fast-shipping.png', height: 55),
            const SizedBox(height: 12),

            // 👇 Welcome text with username
            const Text(
              "Welcome, Aman!",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),

            const SizedBox(height: 18),

            // 👇 Highlighted Button-style message
            ElevatedButton.icon(
              onPressed: () {
                // you can later use this to go online or trigger toggle
              },
              icon: const Icon(Icons.wifi_tethering, color: Colors.white, size: 22),
              label: const Text(
                "Go Online to Start Receiving Deliveries",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
              ),
            ),
          ],
        ),
      );
    } else if (isSearching && !hasDelivery) {
      return Container(
        width: cardWidth,
        height: fixedHeight,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black12.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.orange),
            SizedBox(height: 12),
            Text(
              "Searching for nearby deliveries...",
              style: TextStyle(
                  color: Colors.black87, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    } else if (hasDelivery) {
      return Container(
        width: cardWidth,
        height: fixedHeight,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black12.withOpacity(0.25),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("₹22.50",
                    style:
                    TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                IconButton(
                    onPressed: _rejectDelivery,
                    icon: const Icon(Icons.close, color: Colors.redAccent))
              ],
            ),
            const Text("⭐ 4.87", style: TextStyle(color: Colors.black54)),
            const SizedBox(height: 6),
            const Text("Pickup: Pizza Planet (2.3 km)",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            const Text("Drop: Green Park Colony (4.8 km)",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            const Spacer(),
            LinearProgressIndicator(
              value: _progress / 100,
              color: Colors.green,
              backgroundColor: Colors.orange.withOpacity(0.2),
              minHeight: 6,
              borderRadius: BorderRadius.circular(8),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 35,
              child: ElevatedButton(
                onPressed: () {
                  _timer?.cancel();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const DummyMapPage(
                        pickup: "Pizza Planet",
                        distance: "2.3 km",
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10))),
                child: const Text("Accept",
                    style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  @override

  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: false, // prevents gradient from going behind status bar globally
      backgroundColor: Colors.white,  // default background for other pages
      body: _selectedIndex == 0
          ? Stack(
        children: [
          // Gradient only for Dashboard
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color.fromARGB(220, 30, 80, 200),
                  Color.fromARGB(80, 255, 255, 255),
                  Color.fromARGB(255, 255, 255, 255),
                ],
              ),
            ),
          ),
          SafeArea(child: _buildBody(context)),
        ],
      )
          : SafeArea(child: _buildBody(context)), // no gradient for other pages
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.white,
          elevation: 10,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          selectedItemColor: Colors.black,
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w600, fontSize: 13),
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
            BottomNavigationBarItem(
                icon: Icon(Icons.account_balance_wallet), label: 'Earnings'),
            BottomNavigationBarItem(
                icon: Icon(Icons.schedule_rounded), label: 'My Shift'),
            BottomNavigationBarItem(
                icon: Icon(Icons.task_alt_rounded), label: 'Delivered'),
            BottomNavigationBarItem(
                icon: Icon(Icons.person_outline), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}

// 📊 Small Widgets for Stats and Incentives

class _ProgressItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _ProgressItem(
      {required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.black87, size: 22),
        const SizedBox(height: 6),
        Text(value,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black)),
        const SizedBox(height: 3),
        Text(label,
            style: const TextStyle(
                fontSize: 13, color: Colors.black54, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _IncentiveCircle extends StatelessWidget {
  final String label;
  final bool isFinal;
  const _IncentiveCircle({required this.label, this.isFinal = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isFinal ? Colors.black : Colors.orange,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.currency_rupee, color: Colors.white, size: 18),
        ),
        const SizedBox(height: 6),
        Text(label,
            style: const TextStyle(
                fontSize: 13, color: Colors.black, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

// 🌍 Dummy Map Page
class DummyMapPage extends StatelessWidget {
  final String pickup;
  final String distance;

  const DummyMapPage({super.key, required this.pickup, required this.distance});

  @override
  Widget build(BuildContext context) {
    final LatLng pickupLocation = LatLng(26.8467, 80.9462);
    return Scaffold(
      appBar: AppBar(
        title: const Text("Delivery Route"),
        backgroundColor: Colors.white,
      ),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: pickupLocation,
          initialZoom: 13.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
            subdomains: const ['a', 'b', 'c'],
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: pickupLocation,
                width: 60,
                height: 60,
                child: const Icon(Icons.location_pin,
                    color: Colors.red, size: 40),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// 🔔 Notification Page
class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
        backgroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          ListTile(
            leading: Icon(Icons.notifications_active, color: Colors.redAccent),
            title: Text("Order #12345 has been delivered"),
            subtitle: Text("2 hours ago"),
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.local_offer, color: Colors.green),
            title: Text("New incentive: Earn ₹100 extra today!"),
            subtitle: Text("5 hours ago"),
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.info_outline, color: Colors.blue),
            title: Text("System maintenance scheduled tonight"),
            subtitle: Text("1 day ago"),
          ),
        ],
      ),
    );
  }
}

// 🎧 Support Page
class SupportPage extends StatelessWidget {
  const SupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Support"),
        backgroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Need help?",
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            const SizedBox(height: 10),
            const Text(
              "You can chat with our support team or call us for urgent issues.",
              style: TextStyle(fontSize: 15, color: Colors.black87),
            ),
            const SizedBox(height: 25),

            // 📞 Call Button
            ElevatedButton.icon(
              onPressed: () {
                // TODO: integrate call support feature
              },
              icon: const Icon(Icons.call, color: Colors.white),
              label: const Text("Call Support",
                  style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 14),

            // 💬 Chat Button
            ElevatedButton.icon(
              onPressed: () {
                // TODO: integrate chat support feature
              },
              icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
              label: const Text("Chat with Support",
                  style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 💰 All Incentives Page
class IncentivePage extends StatelessWidget {
  const IncentivePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("All Incentives"),
        backgroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          ListTile(
            leading: Icon(Icons.star, color: Colors.orange),
            title: Text("Earn ₹85 by completing 5 orders"),
            subtitle: Text("Target: ₹500 | Status: ₹280 completed"),
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.star_half, color: Colors.redAccent),
            title: Text("Earn ₹150 by completing 10 orders"),
            subtitle: Text("Target: ₹800 | Status: ₹420 completed"),
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.stars, color: Colors.green),
            title: Text("Earn ₹300 by completing 20 orders"),
            subtitle: Text("Target: ₹1200 | Status: ₹950 completed"),
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.local_offer, color: Colors.blue),
            title: Text("Weekly Bonus ₹500"),
            subtitle: Text("Complete 50 orders this week"),
          ),
        ],
      ),
    );
  }
}


