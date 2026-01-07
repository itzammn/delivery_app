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
  List<dynamic> gigs = [];
  List<DateTime> gigDates = [];
  Set<String> selectedGigIds = {};
  Set<String> bookedGigIds = {};
  bool isLoading = true;
  bool isBooking = false; // New loading state for booking action
  String? errorMsg;
  String? currentUserId; // To track the logged-in user

  // Navigation state
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
          // Use base64Url since JWT payloads are URL encoded
          final normalized = base64.normalize(payload);
          final decoded = utf8.decode(base64.decode(normalized));
          final map = jsonDecode(decoded);
          setState(() {
            currentUserId = map["_id"]?.toString();
          });
          print("👤 Detected User ID: $currentUserId");
        }
      }
    } catch (e) {
      print("❌ Error decoding token: $e");
    }
  }

  /// ================= GIG ID HELPER =================
  String getGigId(dynamic gig) {
    // API response uses _id as the primary key
    return (gig["_id"] ?? gig["id"])?.toString() ??
        "${gig["startTime"]}_${gig["endTime"]}";
  }

  /// ================= CHECK IF GIG IS BOOKED =================
  bool isGigBooked(dynamic gig) {
    // 1. Check if ANY booking in the 'bookings' array belongs to the current user
    if (currentUserId != null && gig["bookings"] != null) {
      final List bookingsList = gig["bookings"] is List ? gig["bookings"] : [];
      final hasMyBooking = bookingsList.any(
        (b) => b["deliveryPartner"]?.toString() == currentUserId,
      );
      if (hasMyBooking) return true;
    }

    // 2. Fallback for server-provided status flags
    final status = gig["status"]?.toString().toUpperCase();
    final gigStatus = gig["gigStatus"]?.toString().toUpperCase();

    return gig["isBooked"] == true ||
        gig["booked"] == true ||
        status == "BOOKED" ||
        status == "CONFIRMED" ||
        gigStatus == "BOOKED" ||
        gigStatus == "CONFIRMED";
  }

  /// ================= FETCH GIGS =================
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
          errorMsg = "No gigs available";
          isLoading = false;
        });
        return;
      }

      /// 🔹 UNIQUE DATES (UTC → LOCAL)
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

        // Populate bookedGigIds immediately
        bookedGigIds = fetchedGigs
            .where((g) => isGigBooked(g))
            .map((g) => getGigId(g))
            .where((id) => id.isNotEmpty)
            .toSet();
      });

      print("Fetched ${gigs.length} gigs, ${bookedGigIds.length} booked");
    } catch (e) {
      setState(() {
        errorMsg = e.toString();
        isLoading = false;
      });
    }
  }

  /// ================= INIT BOOKED STATE =================
  void initializeBookedState() {
    if (!mounted) return;
    setState(() {
      selectedGigIds = {};
      bookedGigIds = gigs
          .where((g) => isGigBooked(g))
          .map((g) => getGigId(g))
          .where((id) => id.isNotEmpty)
          .toSet();
    });
  }

  /// ================= FILTER BY DATE =================
  List<dynamic> getGigsForSelectedDate() {
    if (selectedDate == null) return [];

    return gigs.where((g) {
      final d = DateTime.parse(g["gigDate"]).toLocal();
      return d.year == selectedDate!.year &&
          d.month == selectedDate!.month &&
          d.day == selectedDate!.day;
    }).toList();
  }

  /// ================= FILTER BY TAB =================
  List<dynamic> getFilteredGigs(List<dynamic> dateGigs) {
    if (selectedTab == "All") {
      return dateGigs; // Show all gigs
    }
    // Booked = only booked gigs
    return dateGigs.where((g) {
      // Re-evaluate booked status directly from gig data for accuracy
      return isGigBooked(g) || bookedGigIds.contains(getGigId(g));
    }).toList();
  }

  /// ================= TIME FORMAT =================
  String formatTime(String iso) {
    final dt = DateTime.parse(iso).toLocal();
    final hour = dt.hour;
    final minute = dt.minute;
    final period = hour >= 12 ? 'pm' : 'am';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final displayMinute = minute.toString().padLeft(2, '0');
    return "$displayHour:$displayMinute$period";
  }

  /// ================= TIME SLOT LABEL =================
  String getTimeSlotLabel(String isoTime) {
    final hour = DateTime.parse(isoTime).toLocal().hour;

    if (hour >= 5 && hour < 12) return "Morning";
    if (hour >= 12 && hour < 17) return "Lunch gigs";
    if (hour >= 17 && hour < 21) return "Evening Gigs";
    return "Night";
  }

  /// ================= ICON FOR TIME SLOT =================
  IconData getTimeSlotIcon(String label) {
    if (label.contains("Lunch")) return Icons.wb_sunny;
    if (label.contains("Evening")) return Icons.nights_stay_outlined;
    if (label.contains("Night")) return Icons.nights_stay;
    return Icons.wb_sunny;
  }

  /// ================= GROUP BY TIME =================
  Map<String, List<dynamic>> groupShiftsByTime(List<dynamic> shifts) {
    final Map<String, List<dynamic>> grouped = {};

    for (var gig in shifts) {
      final label = getTimeSlotLabel(gig["startTime"]);
      if (!grouped.containsKey(label)) {
        grouped[label] = [];
      }
      grouped[label]!.add(gig);
    }

    return grouped;
  }

  /// ================= DATE LABEL =================
  String _label(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    if (d == today) return "Today";
    if (d == tomorrow) return "Tomorrow";

    return ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"][d.weekday - 1];
  }

  /// ================= MONTH LABEL =================
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

  /// ================= BUILD UI =================
  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey.shade50,
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFF00C853)),
        ),
      );
    }

    if (errorMsg != null) {
      return Scaffold(
        backgroundColor: Colors.grey.shade50,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(errorMsg!, style: TextStyle(color: Colors.grey.shade600)),
            ],
          ),
        ),
      );
    }

    // Step 1: Date Selection
    if (selectedDate == null) {
      return _buildDateSelectionPage();
    }

    // Step 2: Gig Details
    return _buildGigDetailsPage();
  }

  /// ================= STEP 1: DATE SELECTION (NO BACK BUTTON) =================
  Widget _buildDateSelectionPage() {
    // Group dates by month
    Map<String, List<DateTime>> datesByMonth = {};
    for (var date in gigDates) {
      final monthKey = _monthLabel(date);
      if (!datesByMonth.containsKey(monthKey)) {
        datesByMonth[monthKey] = [];
      }
      datesByMonth[monthKey]!.add(date);
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false, // NO BACK BUTTON
        title: const Text(
          "Gigs",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey.shade200, height: 1),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: datesByMonth.entries.map((entry) {
          final month = entry.key;
          final dates = entry.value;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  month,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              ...dates.map((date) => _buildDateCard(date)),
              const SizedBox(height: 8),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDateCard(DateTime date) {
    final gigsForDate = gigs.where((g) {
      final d = DateTime.parse(g["gigDate"]).toLocal();
      return d.year == date.year && d.month == date.month && d.day == date.day;
    }).length;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            setState(() {
              selectedDate = date;
              selectedTab = "All"; // Reset to All tab
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00C853),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "${date.day}",
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        _label(date),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Booking open",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.star_border,
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              "Book Star Gigs to improve your medal",
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.grey.shade400),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// ================= STEP 2: GIG DETAILS (WITH BACK BUTTON) =================
  Widget _buildGigDetailsPage() {
    final dateGigs = getGigsForSelectedDate();
    final filteredGigs = getFilteredGigs(dateGigs);
    final groupedGigs = groupShiftsByTime(filteredGigs);

    final selectedGigs = dateGigs.where((g) {
      return selectedGigIds.contains(getGigId(g));
    }).toList();

    final minPayout = selectedGigs.fold<double>(0, (sum, gig) {
      final start = DateTime.parse(gig["startTime"]).toLocal();
      final end = DateTime.parse(gig["endTime"]).toLocal();
      final hours = end.difference(start).inHours.toDouble();
      final rate = double.tryParse(gig["minPrice"]?.toString() ?? "85") ?? 85;
      return sum + (hours * rate);
    });

    final maxPayout = selectedGigs.fold<double>(0, (sum, gig) {
      final start = DateTime.parse(gig["startTime"]).toLocal();
      final end = DateTime.parse(gig["endTime"]).toLocal();
      final hours = end.difference(start).inHours.toDouble();
      final rate = double.tryParse(gig["maxPrice"]?.toString() ?? "125") ?? 125;
      return sum + (hours * rate);
    });

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            setState(() {
              selectedDate = null;
              selectedTab = "All";
            });
          },
        ),
        title: Text(
          "Gigs, ${selectedDate!.day} ${_monthLabel(selectedDate!).substring(0, 3)}",
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey.shade200, height: 1),
        ),
      ),
      body: Column(
        children: [
          // ONLY 2 TABS: All and Booked
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _buildTab("All"),
                const SizedBox(width: 12),
                _buildTab("Booked"),
              ],
            ),
          ),
          // Gigs List
          Expanded(
            child: groupedGigs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event_busy,
                          size: 64,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          selectedTab == "Booked"
                              ? "No booked gigs yet"
                              : "No gigs available",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: groupedGigs.entries.map((entry) {
                      return _buildTimeGroup(entry.key, entry.value);
                    }).toList(),
                  ),
          ),
          // Bottom Bar - Only show when there are selected gigs
          if (selectedGigs.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1976D2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "Estimated payout",
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "₹${minPayout.toInt()} - ₹${maxPayout.toInt()}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "Selected Gigs",
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${selectedGigs.length} Gig${selectedGigs.length > 1 ? 's' : ''} (${selectedGigs.fold<int>(0, (sum, gig) => sum + DateTime.parse(gig["endTime"]).difference(DateTime.parse(gig["startTime"])).inHours)} hours)",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          // Book Button
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: selectedGigs.isNotEmpty && !isBooking
                      ? () async {
                          setState(() {
                            isBooking = true;
                          });

                          try {
                            // Extract only the IDs for booking
                            final List<String> gigIdsToBook = selectedGigs
                                .map((g) => getGigId(g).toString())
                                .toList();

                            final result = await ApiHelper.post(
                              "/food-delivery/gigs/booking",
                              {"gigId": gigIdsToBook},
                            );

                            if (result["success"] == true ||
                                result["status"] == true) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Row(
                                      children: [
                                        Icon(
                                          Icons.check_circle,
                                          color: Colors.white,
                                        ),
                                        SizedBox(width: 12),
                                        Text("Shifts booked successfully!"),
                                      ],
                                    ),
                                    backgroundColor: Colors.green.shade600,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                );
                              }

                              // Refresh the list from server to get correct booked status
                              await fetchGigs();

                              if (mounted) {
                                setState(() {
                                  selectedGigIds
                                      .clear(); // Clear selections after booking
                                });
                              }
                            } else {
                              throw Exception(
                                result["message"] ?? "Booking failed",
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("Error: ${e.toString()}"),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                            }
                          } finally {
                            if (mounted) {
                              setState(() {
                                isBooking = false;
                              });
                            }
                          }
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00C853),
                    disabledBackgroundColor: Colors.grey.shade300,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: isBooking
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          "Book",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
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
        onTap: () {
          setState(() {
            selectedTab = label;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF37474F) : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade700,
                fontWeight: FontWeight.w600,
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
        Container(
          margin: const EdgeInsets.only(bottom: 12, top: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF455A64),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(getTimeSlotIcon(timeLabel), color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Text(
                timeLabel,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              Text(
                "${gigsList.length} Gig${gigsList.length > 1 ? 's' : ''}",
                style: const TextStyle(fontSize: 14, color: Colors.white70),
              ),
            ],
          ),
        ),
        ...gigsList.map((gig) => _buildGigCard(gig)),
        const SizedBox(height: 16),
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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (isSelected || isAlreadyBooked)
              ? const Color(0xFF00C853)
              : Colors.grey.shade200,
          width: (isSelected || isAlreadyBooked) ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      if (gig["isStarGig"] == true) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.stars, color: Colors.amber, size: 18),
                      ],
                      if (isAlreadyBooked) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Text(
                            "BOOKED",
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "₹${gig["minPrice"] ?? 85} - ₹${gig["maxPrice"] ?? 125} per hour",
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                  if (gig["areaName"] != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            gig["areaName"],
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            // Only checkbox is clickable if not already booked
            if (!isAlreadyBooked)
              InkWell(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      selectedGigIds.remove(gigId);
                    } else {
                      selectedGigIds.add(gigId);
                    }
                  });
                },
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: isSelected
                      ? const Icon(
                          Icons.check_circle,
                          color: Color(0xFF00C853),
                          size: 24,
                        )
                      : Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.grey.shade400,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                ),
              )
            else
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Icon(
                  Icons.check_circle,
                  color: Color(0xFF00C853),
                  size: 24,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
