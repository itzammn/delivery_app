import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zamboree/auth/api_helper.dart';

class MyShiftPage extends StatefulWidget {
  const MyShiftPage({super.key});

  @override
  State<MyShiftPage> createState() => _MyShiftPageState();
}

class _MyShiftPageState extends State<MyShiftPage> {
  // Theme Colors
  final Color primaryColor = const Color(0xFF1E3A8A); // Deep Blue
  final Color accentColor = const Color(0xFF3B82F6); // Lighter Blue
  final Color successColor = const Color(0xFF10B981); // Emerald Green
  final Color warningColor = const Color(0xFFF59E0B); // Amber
  final Color dangerColor = const Color(0xFFEF4444); // Red

  List<dynamic> gigs = [];
  List<DateTime> gigDates = [];
  Set<String> selectedGigIds = {};
  Set<String> bookedGigIds = {};
  bool isLoading = true;
  bool isBooking = false;
  String? errorMsg;
  String? currentUserId;

  DateTime? selectedDate;
  String selectedTab = "All"; // All or Booked

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    await _extractUserId();
    await fetchGigs();
  }

  Future<void> _extractUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token != null && token.isNotEmpty) {
        final parts = token.split('.');
        if (parts.length >= 2) {
          final payload = parts[1];
          final normalized = base64.normalize(payload);
          final decoded = utf8.decode(base64.decode(normalized));
          final map = jsonDecode(decoded);
          setState(() {
            currentUserId = map["_id"]?.toString();
          });
        }
      }
    } catch (e) {
      debugPrint("❌ Error decoding token: $e");
    }
  }

  String getGigId(dynamic gig) {
    return (gig["_id"] ?? gig["id"])?.toString() ??
        "${gig["startTime"]}_${gig["endTime"]}";
  }

  bool _areGigsOverlapping(dynamic g1, dynamic g2) {
    try {
      final s1 = DateTime.parse(g1["startTime"]).toLocal();
      final e1 = DateTime.parse(g1["endTime"]).toLocal();
      final s2 = DateTime.parse(g2["startTime"]).toLocal();
      final e2 = DateTime.parse(g2["endTime"]).toLocal();
      return s1.isBefore(e2) && s2.isBefore(e1);
    } catch (e) {
      return false;
    }
  }

  bool isGigBooked(dynamic gig) {
    if (currentUserId != null && gig["bookings"] != null) {
      final List bookingsList = gig["bookings"] is List ? gig["bookings"] : [];
      final hasMyBooking = bookingsList.any(
        (b) => b["deliveryPartner"]?.toString() == currentUserId,
      );
      if (hasMyBooking) return true;
    }
    final status = gig["status"]?.toString().toUpperCase();
    final gigStatus = gig["gigStatus"]?.toString().toUpperCase();
    return gig["isBooked"] == true ||
        gig["booked"] == true ||
        status == "BOOKED" ||
        status == "CONFIRMED" ||
        gigStatus == "BOOKED" ||
        gigStatus == "CONFIRMED";
  }

  Future<void> fetchGigs() async {
    setState(() {
      isLoading = true;
      errorMsg = null;
    });

    try {
      final result = await ApiHelper.get("/food-delivery/gigs");
      if (result["success"] != true || result["data"] == null) {
        throw Exception(result["message"] ?? "Failed to load gigs");
      }
      final List<dynamic> fetchedGigs = result["data"];
      if (fetchedGigs.isEmpty) {
        setState(() {
          errorMsg = "No gigs available for your location";
          isLoading = false;
        });
        return;
      }

      final Set<String> dateSet = {};
      final List<DateTime> tempDates = [];
      for (var g in fetchedGigs) {
        final d = DateTime.parse(g["gigDate"]).toLocal();
        final key = "${d.year}-${d.month}-${d.day}";
        if (!dateSet.contains(key)) {
          dateSet.add(key);
          tempDates.add(DateTime(d.year, d.month, d.day));
        }
      }
      tempDates.sort();

      setState(() {
        gigs = fetchedGigs;
        gigDates = tempDates;
        isLoading = false;
        bookedGigIds = fetchedGigs
            .where((g) => isGigBooked(g))
            .map((g) => getGigId(g))
            .where((id) => id.isNotEmpty)
            .toSet();
      });
    } catch (e) {
      setState(() {
        errorMsg = e.toString();
        isLoading = false;
      });
    }
  }

  List<dynamic> getGigsForSelectedDate() {
    if (selectedDate == null) return [];
    return gigs.where((g) {
      final d = DateTime.parse(g["gigDate"]).toLocal();
      return d.year == selectedDate!.year &&
          d.month == selectedDate!.month &&
          d.day == selectedDate!.day;
    }).toList();
  }

  List<dynamic> getFilteredGigs(List<dynamic> dateGigs) {
    if (selectedTab == "Booked") {
      return dateGigs
          .where((g) => isGigBooked(g) || bookedGigIds.contains(getGigId(g)))
          .toList();
    }
    final activeGigs = dateGigs.where((g) {
      final id = getGigId(g);
      return selectedGigIds.contains(id) || bookedGigIds.contains(id);
    }).toList();
    if (activeGigs.isEmpty) return dateGigs;
    return dateGigs.where((g) {
      final id = getGigId(g);
      if (selectedGigIds.contains(id) || bookedGigIds.contains(id)) return true;
      for (var active in activeGigs) {
        if (_areGigsOverlapping(g, active)) return false;
      }
      return true;
    }).toList();
  }

  String formatTime(String iso) {
    final dt = DateTime.parse(iso).toLocal();
    final hour = dt.hour;
    final minute = dt.minute;
    final period = hour >= 12 ? 'pm' : 'am';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final displayMinute = minute.toString().padLeft(2, '0');
    return "$displayHour:$displayMinute$period";
  }

  String getTimeSlotLabel(String isoTime) {
    final hour = DateTime.parse(isoTime).toLocal().hour;
    if (hour >= 5 && hour < 12) return "Morning Slots";
    if (hour >= 12 && hour < 17) return "Lunch Gigs";
    if (hour >= 17 && hour < 21) return "Evening Gigs";
    return "Night Shifts";
  }

  IconData getTimeSlotIcon(String label) {
    if (label.contains("Lunch")) return Icons.wb_sunny_rounded;
    if (label.contains("Evening")) return Icons.wb_twilight_rounded;
    if (label.contains("Night")) return Icons.nights_stay_rounded;
    return Icons.wb_sunny_rounded;
  }

  Map<String, List<dynamic>> groupShiftsByTime(List<dynamic> shifts) {
    final Map<String, List<dynamic>> grouped = {};
    for (var gig in shifts) {
      final label = getTimeSlotLabel(gig["startTime"]);
      grouped.putIfAbsent(label, () => []).add(gig);
    }
    return grouped;
  }

  String _label(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    if (d == today) return "Today";
    if (d == tomorrow) return "Tomorrow";
    return ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"][d.weekday - 1];
  }

  String _monthLabel(DateTime d) {
    const months = [
      "JANUARY",
      "FEBRUARY",
      "MARCH",
      "APRIL",
      "MAY",
      "JUNE",
      "JULY",
      "AUGUST",
      "SEPTEMBER",
      "OCTOBER",
      "NOVEMBER",
      "DECEMBER",
    ];
    return months[d.month - 1];
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey.shade50,
        body: Center(child: CircularProgressIndicator(color: accentColor)),
      );
    }

    if (errorMsg != null) {
      return Scaffold(
        backgroundColor: Colors.grey.shade50,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: dangerColor.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                errorMsg!,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              TextButton(
                onPressed: fetchGigs,
                child: Text("Try Again", style: TextStyle(color: accentColor)),
              ),
            ],
          ),
        ),
      );
    }

    return selectedDate == null
        ? _buildDateSelectionPage()
        : _buildGigDetailsPage();
  }

  Widget _buildDateSelectionPage() {
    Map<String, List<DateTime>> datesByMonth = {};
    for (var date in gigDates) {
      final monthKey = _monthLabel(date);
      datesByMonth.putIfAbsent(monthKey, () => []).add(date);
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Stack(
        children: [
          Container(
            height: 220,
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
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 20,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Available Gigs",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.calendar_month_rounded,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate(
                      datesByMonth.entries.expand((entry) {
                        return [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 8,
                            ),
                            child: Text(
                              entry.key,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: Colors.white.withOpacity(0.8),
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                          ...entry.value.map((date) => _buildDateCard(date)),
                        ];
                      }).toList(),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 30)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateCard(DateTime date) {
    final gigsCount = gigs.where((g) {
      final d = DateTime.parse(g["gigDate"]).toLocal();
      return d.year == date.year && d.month == date.month && d.day == date.day;
    }).length;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            setState(() {
              selectedDate = date;
              selectedTab = "All";
              selectedGigIds.clear();
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 65,
                  height: 65,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        accentColor.withOpacity(0.1),
                        accentColor.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "${date.day}",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      Text(
                        _label(date).substring(0, 3).toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          color: accentColor,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Gig Selection Open",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.local_shipping_rounded,
                            size: 14,
                            color: successColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "$gigsCount Slots Available",
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.grey.shade300,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGigDetailsPage() {
    final dateGigs = getGigsForSelectedDate();
    final filteredGigs = getFilteredGigs(dateGigs);
    final groupedGigs = groupShiftsByTime(filteredGigs);

    final selectedGigs = dateGigs
        .where((g) => selectedGigIds.contains(getGigId(g)))
        .toList();

    double minPayout = 0;
    double maxPayout = 0;
    int totalHours = 0;

    for (var gig in selectedGigs) {
      final start = DateTime.parse(gig["startTime"]).toLocal();
      final end = DateTime.parse(gig["endTime"]).toLocal();
      final hours = end.difference(start).inHours;
      totalHours += hours;
      minPayout +=
          (hours *
          (double.tryParse(gig["minPrice"]?.toString() ?? "85") ?? 85));
      maxPayout +=
          (hours *
          (double.tryParse(gig["maxPrice"]?.toString() ?? "125") ?? 125));
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Stack(
        children: [
          Container(
            height: 200,
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
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                        ),
                        onPressed: () => setState(() => selectedDate = null),
                      ),
                      Expanded(
                        child: Text(
                          "Slots: ${selectedDate!.day} ${_monthLabel(selectedDate!).substring(0, 3)}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 10,
                  ),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(children: [_buildTab("All"), _buildTab("Booked")]),
                ),
                Expanded(
                  child: filteredGigs.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.event_busy_rounded,
                                size: 80,
                                color: Colors.grey.shade300,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                selectedTab == "Booked"
                                    ? "No booked gigs yet"
                                    : "No gigs available for this day",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade500,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView(
                          padding: const EdgeInsets.all(20),
                          physics: const BouncingScrollPhysics(),
                          children: groupedGigs.entries
                              .map(
                                (entry) =>
                                    _buildTimeGroup(entry.key, entry.value),
                              )
                              .toList(),
                        ),
                ),
                if (selectedGigs.isNotEmpty)
                  _buildBottomBar(
                    minPayout,
                    maxPayout,
                    selectedGigs.length,
                    totalHours,
                  ),
                _buildConfirmButton(selectedGigs.isNotEmpty),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String label) {
    final isSelected = selectedTab == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedTab = label),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? primaryColor : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeGroup(String timeLabel, List<dynamic> gigsList) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 12, top: 10),
          child: Row(
            children: [
              Icon(getTimeSlotIcon(timeLabel), color: primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                timeLabel.toUpperCase(),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: primaryColor,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
        ...gigsList.map((gig) => _buildGigCard(gig)),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildGigCard(dynamic gig) {
    final gigId = getGigId(gig);
    final isSelected = selectedGigIds.contains(gigId);
    final isAlreadyBooked = bookedGigIds.contains(gigId);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: (isSelected || isAlreadyBooked) ? successColor : Colors.white,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: isAlreadyBooked
              ? null
              : () {
                  setState(() {
                    if (isSelected) {
                      selectedGigIds.remove(gigId);
                    } else {
                      selectedGigIds.add(gigId);
                    }
                  });
                },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            "${formatTime(gig["startTime"])} - ${formatTime(gig["endTime"])}",
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          if (gig["isStarGig"] == true) ...[
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.stars_rounded,
                              color: Colors.amber,
                              size: 20,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.currency_rupee_rounded,
                            size: 14,
                            color: successColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "₹${gig["minPrice"] ?? 85} - ₹${gig["maxPrice"] ?? 125} / hr",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      if (gig["areaName"] != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Row(
                            children: [
                              Icon(
                                Icons.location_on_rounded,
                                size: 14,
                                color: dangerColor.withOpacity(0.6),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                gig["areaName"],
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade500,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                _buildSelectionIndicator(isSelected, isAlreadyBooked),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionIndicator(bool isSelected, bool isAlreadyBooked) {
    if (isAlreadyBooked) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: successColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          "BOOKED",
          style: TextStyle(
            color: successColor,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelected ? successColor : Colors.transparent,
        border: Border.all(
          color: isSelected ? successColor : Colors.grey.shade300,
          width: 2,
        ),
      ),
      child: isSelected
          ? const Icon(Icons.check, color: Colors.white, size: 18)
          : null,
    );
  }

  Widget _buildBottomBar(double min, double max, int count, int hours) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "ESTIMATED PAYOUT",
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "₹${min.toInt()} - ₹${max.toInt()}",
                style: TextStyle(
                  color: primaryColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "TOTAL DURATION",
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "$hours Hours / $count slots",
                style: TextStyle(
                  color: accentColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmButton(bool enabled) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      color: Colors.white,
      child: SizedBox(
        width: double.infinity,
        height: 60,
        child: ElevatedButton(
          onPressed: enabled && !isBooking ? _handleBooking : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            disabledBackgroundColor: Colors.grey.shade200,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 0,
          ),
          child: isBooking
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text(
                  "Confirm & Book Slots",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }

  Future<void> _handleBooking() async {
    setState(() => isBooking = true);
    try {
      final List<String> gigIdsToBook = gigs
          .where((g) => selectedGigIds.contains(getGigId(g)))
          .map((g) => getGigId(g).toString())
          .toList();
      final result = await ApiHelper.post("/food-delivery/gigs/booking", {
        "gigId": gigIdsToBook,
      });
      if (result["success"] == true || result["status"] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("Gigs booked successfully! Keep it up."),
              backgroundColor: successColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          );
        }
        await fetchGigs();
        if (mounted) setState(() => selectedGigIds.clear());
      } else {
        throw Exception(result["message"] ?? "Booking failed");
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: dangerColor),
        );
    } finally {
      if (mounted) setState(() => isBooking = false);
    }
  }
}
