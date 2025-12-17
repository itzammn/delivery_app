import 'package:flutter/material.dart';

class MyShiftPage extends StatefulWidget {
  const MyShiftPage({super.key});

  @override
  State<MyShiftPage> createState() => _MyShiftPageState();
}

class _MyShiftPageState extends State<MyShiftPage> {
  int selectedDateIndex = 0;
  Map<String, List<bool>> selectedShifts = {};
  Map<String, List<bool>> bookedShifts = {};
  Map<String, List<Map<String, String>>> shifts = {};

  final List<String> days = ["Today", "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
  final List<String> sections = ["Breakfast", "Lunch", "Dinner", "Late Night"];

  @override
  void initState() {
    super.initState();
    _initializeShifts();
  }

  void _initializeShifts() {
    shifts = {
      "Breakfast": [
        {"time": "9:00 AM - 12:00 PM", "tag": "", "level": "HIGH"},
      ],
      "Lunch": [
        {"time": "12:00 PM - 4:00 PM", "tag": "PEAK", "level": "HIGH"},
        {"time": "1:00 PM - 3:00 PM", "tag": "PEAK", "level": "HIGH"},
        {"time": "3:00 PM - 4:00 PM", "tag": "", "level": ""},
      ],
      "Dinner": [
        {"time": "6:00 PM - 9:00 PM", "tag": "PEAK", "level": "HIGH"},
        {"time": "7:00 PM - 9:00 PM", "tag": "", "level": ""},
      ],
      "Late Night": [
        {"time": "10:00 PM - 1:00 AM", "tag": "", "level": ""},
      ],
    };

    selectedShifts.clear();
    bookedShifts.clear();

    for (var section in sections) {
      final count = shifts[section]?.length ?? 0;
      selectedShifts[section] = List.generate(count, (_) => false);
      bookedShifts[section] = List.generate(count, (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "You can choose your shift here",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),

        ),
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        elevation: 1,
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.person_outline, color: Colors.black87)),
          IconButton(onPressed: () {}, icon: const Icon(Icons.help_outline, color: Colors.black87)),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 📅 Date Tabs
            SizedBox(
              height: 70,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: days.length,
                itemBuilder: (context, index) {
                  bool isSelected = index == selectedDateIndex;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedDateIndex = index;
                        _initializeShifts(); // Reset both selected & booked for new date
                      });
                    },
                    child: Container(
                      width: 70,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.redAccent : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            days[index],
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (index == 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                "30",
                                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // 🔹 Shift Sections
            Expanded(
              child: ListView.builder(
                itemCount: sections.length,
                itemBuilder: (context, secIndex) {
                  String section = sections[secIndex];
                  final sectionShifts = shifts[section] ?? [];

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(section, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Column(
                        children: List.generate(sectionShifts.length, (index) {
                          final shift = sectionShifts[index];
                          bool isChecked = selectedShifts[section]?[index] ?? false;
                          bool isBooked = bookedShifts[section]?[index] ?? false;

                          return Card(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            color: isBooked ? Colors.green.shade50 : Colors.grey.shade100,
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            child: ListTile(
                              title: Text(shift["time"] ?? ""),
                              trailing: isBooked
                                  ? Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text("Booked", style: TextStyle(color: Colors.white)),
                              )
                                  : Checkbox(
                                value: isChecked,
                                onChanged: (val) {
                                  setState(() {
                                    selectedShifts[section]?[index] = val ?? false;
                                  });
                                },
                              ),
                              subtitle: Row(
                                children: [
                                  if (shift["level"] != null && shift["level"]!.isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      margin: const EdgeInsets.only(right: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.blue,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        shift["level"]!,
                                        style: const TextStyle(color: Colors.white, fontSize: 10),
                                      ),
                                    ),
                                  if (shift["tag"] != null && shift["tag"]!.isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        shift["tag"]!,
                                        style: const TextStyle(color: Colors.white, fontSize: 10),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 8),

                      // ✅ Book Slot Button
                      ElevatedButton(
                        onPressed: (selectedShifts[section]?.contains(true) ?? false)
                            ? () {
                          if (selectedShifts[section] == null || bookedShifts[section] == null) return;

                          setState(() {
                            for (int i = 0; i < selectedShifts[section]!.length; i++) {
                              if (selectedShifts[section]![i]) {
                                bookedShifts[section]![i] = true;
                                selectedShifts[section]![i] = false;
                              }
                            }
                          });

                          Future.delayed(const Duration(milliseconds: 150), () {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("✅ Your selected time slots are booked!"),
                                  backgroundColor: Colors.red,
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          });
                        }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          minimumSize: const Size(double.infinity, 45),
                        ),
                        child: const Text(
                          "Book Slot",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
