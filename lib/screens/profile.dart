import 'package:flutter/material.dart';
import '../auth/login.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../auth/api_helper.dart';
import '../auth/edit_profile.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final Color primaryColor = const Color(0xFF1E3A8A); // Deep Blue
  final Color accentColor = const Color(0xFF3B82F6); // Lighter Blue
  final Color successColor = const Color(0xFF10B981); // Emerald Green
  final Color warningColor = const Color(0xFFF59E0B); // Amber
  final Color dangerColor = const Color(0xFFEF4444); // Red

  String userName = "User";
  String userPhone = "Not available";
  String userEmail = "Not available";
  String userCity = "Not available";
  String userVehicle = "Not available";
  bool isLoadingProfile = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _fetchLatestProfile();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString('user_name') ?? "User";
      userEmail = prefs.getString('user_email') ?? "Not available";
      userCity = prefs.getString('user_city') ?? "Not available";
      userVehicle = prefs.getString('user_vehicle') ?? "Not available";

      String? savedPhone =
          prefs.getString('user_phone') ?? prefs.getString('last_logged_in');
      if (savedPhone != null && savedPhone.isNotEmpty) {
        userPhone = savedPhone;
        if (!userPhone.startsWith('+')) {
          userPhone = "+91 $userPhone";
        }
      }
    });
  }

  Future<void> _fetchLatestProfile() async {
    if (isLoadingProfile) return;
    setState(() => isLoadingProfile = true);
    try {
      // 1. Fetch Cities first to resolve names from IDs
      final cityRes = await ApiHelper.get("/delivery/auth/cities");
      Map<String, String> cityMap = {};
      if (cityRes["success"] == true && cityRes["data"] is List) {
        for (var c in cityRes["data"]) {
          if (c["_id"] != null && c["name"] != null) {
            cityMap[c["_id"].toString()] = c["name"].toString();
          }
        }
      }

      // 2. Fetch Profile
      // Attempting a few likely endpoints if the first one fails
      var res = await ApiHelper.get(
        "/food-delivery/profile",
      ); // Try food-delivery prefix first
      if (res["success"] != true) {
        res = await ApiHelper.get("/delivery/profile/my-profile");
      }

      if (res["success"] == true && res["data"] != null) {
        final data = res["data"];
        final partner =
            data["deliveryPartner"] ??
            data; // Some APIs return the partner directly
        final user = data["user"];

        final prefs = await SharedPreferences.getInstance();

        String? name =
            partner?["name"]?.toString() ?? user?["name"]?.toString();
        String? email =
            partner?["email"]?.toString() ?? user?["email"]?.toString();
        String? phone =
            partner?["mobile"]?.toString() ??
            user?["mobile"]?.toString() ??
            user?["phone"]?.toString();

        String? city;
        final cityData = partner?["city"];
        if (cityData is Map) {
          city = cityData["name"]?.toString();
        } else if (cityData != null) {
          final cityId = cityData.toString();
          city =
              cityMap[cityId] ??
              cityId; // Resolve from map or keep ID if not found
        }

        String? vehicle;
        if (partner?["vehicleModel"] != null) {
          vehicle =
              "${partner["vehicleModel"]} (${partner["vehicleNo"] ?? ""})";
        }

        setState(() {
          if (name != null) userName = name;
          if (email != null && email != "null") userEmail = email;
          if (city != null && city != "null") userCity = city;
          if (vehicle != null && vehicle != "null") userVehicle = vehicle;
          if (phone != null) {
            userPhone = phone;
            if (!userPhone.startsWith('+')) userPhone = "+91 $userPhone";
          }
        });

        // Sync back to prefs
        await prefs.setString('user_name', userName);
        await prefs.setString('user_email', userEmail);
        await prefs.setString('user_city', userCity);
        await prefs.setString('user_vehicle', userVehicle);
        if (phone != null) await prefs.setString('user_phone', phone);
      } else {
        // If profile fetch fails, at least try to resolve the city ID from SharedPreferences
        if (cityMap.containsKey(userCity)) {
          setState(() {
            userCity = cityMap[userCity]!;
          });
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_city', userCity);
        }
      }
    } catch (e) {
      print("Error fetching profile: $e");
    } finally {
      if (mounted) setState(() => isLoadingProfile = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // Header Section with Gradient
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [primaryColor, accentColor],
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(50),
                      bottomRight: Radius.circular(50),
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 20,
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const SizedBox(
                                width: 40,
                              ), // Placeholder to center title
                              const Text(
                                "Profile",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.white,
                                ),
                                onPressed: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const EditProfilePage(),
                                    ),
                                  );
                                  if (result == true) {
                                    _loadUserData(); // Refresh data if edited
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -50,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: CircleAvatar(
                      radius: 55,
                      backgroundColor: Colors.grey.shade200,
                      child: Icon(
                        Icons.person_rounded,
                        size: 70,
                        color: primaryColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 60),

            // Name and Status
            Text(
              userName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Delivery Partner",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: successColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, color: successColor, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    "Online",
                    style: TextStyle(
                      color: successColor,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Stats Quick View
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatItem(
                    "4.8",
                    "Rating",
                    Icons.star_rounded,
                    Colors.amber,
                  ),
                  _buildStatItem(
                    "126",
                    "Deliveries",
                    Icons.shopping_bag_rounded,
                    accentColor,
                  ),
                  _buildStatItem(
                    "₹12.3k",
                    "Earnings",
                    Icons.account_balance_wallet_rounded,
                    successColor,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Profile Sections
            _buildSectionHeader("Personal Information"),
            _buildSectionContainer([
              _buildMenuItem(
                Icons.phone_iphone_rounded,
                "Mobile Number",
                userPhone,
                null,
              ),
              _buildMenuItem(
                Icons.email_outlined,
                "Email Address",
                userEmail,
                null,
              ),
              _buildMenuItem(
                Icons.location_city_rounded,
                "Current City",
                userCity,
                null,
              ),
              _buildMenuItem(
                Icons.motorcycle_rounded,
                "Vehicle Details",
                userVehicle,
                null,
              ),
            ]),

            const SizedBox(height: 20),

            _buildSectionHeader("Performance & Finance"),
            _buildSectionContainer([
              _buildMenuItem(
                Icons.bar_chart_rounded,
                "Performance Summary",
                null,
                () {},
              ),
              _buildMenuItem(
                Icons.history_rounded,
                "Payout History",
                null,
                () {},
              ),
              _buildMenuItem(
                Icons.account_balance_rounded,
                "Bank Account Details",
                "SBI ****3421",
                () {},
              ),
            ]),

            const SizedBox(height: 20),

            _buildSectionHeader("Support & Settings"),
            _buildSectionContainer([
              _buildMenuItem(
                Icons.help_outline_rounded,
                "Help & Support",
                null,
                () {},
              ),
              _buildMenuItem(
                Icons.settings_suggest_rounded,
                "Settings",
                null,
                () {},
              ),
              _buildMenuItem(
                Icons.info_outline_rounded,
                "About Zamboree",
                "v 1.0.2",
                () {},
              ),
            ]),

            const SizedBox(height: 30),

            // Logout Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _handleLogout,
                  icon: const Icon(Icons.logout_rounded, color: Colors.white),
                  label: const Text(
                    "Logout Account",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: dangerColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    String value,
    String label,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 16),
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
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: Colors.grey.shade400,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionContainer(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildMenuItem(
    IconData icon,
    String title,
    String? subtitle,
    VoidCallback? onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: primaryColor, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (onTap != null)
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.grey.shade300,
                  size: 14,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    }
  }
}
