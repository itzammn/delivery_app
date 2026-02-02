import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zamboree/Controller/LocationController.dart';
import 'package:zamboree/auth/api_helper.dart';
import 'package:zamboree/screens/PickupOtpPage.dart';

class OrderMapPage extends StatefulWidget {
  final Map<String, dynamic> order;
  const OrderMapPage({super.key, required this.order});

  @override
  State<OrderMapPage> createState() => _OrderMapPageState();
}

class _OrderMapPageState extends State<OrderMapPage> {
  final locationController = Get.find<LocationController>();
  GoogleMapController? mapController;

  Set<Marker> markers = {};
  Set<Polyline> polylines = {};
  double distanceInKm = 0.0;
  String distanceText = "Calculating...";

  late LatLng userLocation;
  late LatLng pickupLocation;

  bool isReachedLoading = false;
  bool isCancelLoading = false;

  final List<String> cancelReasons = [
    "Vehicle Breakdown",
    "Personal Emergency",
    "Heavy Traffic",
    "Accident",
    "Long Distance",
    "Store Closed / Busy",
    "Other",
  ];

  @override
  void initState() {
    super.initState();
    _initLocations();
    _calculateDistance();
    _setupMap();
  }

  void _initLocations() {
    userLocation = LatLng(
      locationController.latitude.value,
      locationController.longitude.value,
    );

    final pickup = widget.order['pickup'];
    final location = pickup?['location'];
    final coords = location?['coordinates'];

    double lat = 0.0;
    double lng = 0.0;

    if (coords != null && coords is List && coords.length >= 2) {
      lng = double.tryParse(coords[0].toString()) ?? 0.0;
      lat = double.tryParse(coords[1].toString()) ?? 0.0;
    } else {
      lat = double.tryParse(pickup?['lat']?.toString() ?? "0") ?? 0;
      lng = double.tryParse(pickup?['lng']?.toString() ?? "0") ?? 0;
    }

    pickupLocation = LatLng(lat, lng);
    debugPrint("📍 PICKUP LOCATION: $lat, $lng");
  }

  void _calculateDistance() {
    double distanceInMeters = Geolocator.distanceBetween(
      userLocation.latitude,
      userLocation.longitude,
      pickupLocation.latitude,
      pickupLocation.longitude,
    );

    distanceInKm = distanceInMeters / 1000;
    if (distanceInMeters < 1000) {
      distanceText = "${distanceInMeters.toStringAsFixed(0)} m";
    } else {
      distanceText = "${distanceInKm.toStringAsFixed(1)} km";
    }
  }

  void _setupMap() {
    markers = {
      Marker(
        markerId: const MarkerId('user_location'),
        position: userLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: const InfoWindow(title: 'Your Location'),
      ),
      Marker(
        markerId: const MarkerId('pickup_location'),
        position: pickupLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(
          title: 'Pickup: ${widget.order['pickup']?['name'] ?? "Store"}',
        ),
      ),
    };

    polylines = {
      Polyline(
        polylineId: const PolylineId('route'),
        points: [userLocation, pickupLocation],
        color: Colors.blue,
        width: 5,
        patterns: [PatternItem.dash(20), PatternItem.gap(10)],
      ),
    };
  }

  Future<void> _launchNavigation() async {
    final url =
        "https://www.google.com/maps/dir/?api=1&origin=${userLocation.latitude},${userLocation.longitude}&destination=${pickupLocation.latitude},${pickupLocation.longitude}&travelmode=driving";
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      Get.snackbar("Error", "Could not launch maps");
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    _fitBounds();
  }

  void _fitBounds() {
    if (mapController == null) return;

    LatLngBounds bounds;
    if (userLocation.latitude > pickupLocation.latitude) {
      bounds = LatLngBounds(
        southwest: LatLng(
          pickupLocation.latitude,
          userLocation.longitude < pickupLocation.longitude
              ? userLocation.longitude
              : pickupLocation.longitude,
        ),
        northeast: LatLng(
          userLocation.latitude,
          userLocation.longitude > pickupLocation.longitude
              ? userLocation.longitude
              : pickupLocation.longitude,
        ),
      );
    } else {
      bounds = LatLngBounds(
        southwest: LatLng(
          userLocation.latitude,
          userLocation.longitude < pickupLocation.longitude
              ? userLocation.longitude
              : pickupLocation.longitude,
        ),
        northeast: LatLng(
          pickupLocation.latitude,
          userLocation.longitude > pickupLocation.longitude
              ? userLocation.longitude
              : pickupLocation.longitude,
        ),
      );
    }

    mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
  }

  /// CONFIRMATION DIALOG
  void _confirmReachedLocation() {
    Get.dialog(
      AlertDialog(
        title: const Text(
          "Confirm Arrival",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "Are you sure you have reached the pickup location?",
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          /// ❌ NO BUTTON → Black text
          TextButton(
            onPressed: () => Get.back(),
            child: const Text(
              "No",
              style: TextStyle(
                color: Colors.black, // ✅ BLACK TEXT
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          /// ✅ YES BUTTON → Black background + White text
          ElevatedButton(
            onPressed: () {
              Get.back();
              _callReachedApi();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black, // ✅ BLACK BG
              foregroundColor: Colors.white, // ✅ WHITE TEXT
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              "Yes",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  /// 📍 REACHED LOCATION API
  Future<void> _callReachedApi() async {
    // Check for both 'orderId' and '_id' keys just in case
    final orderId = widget.order['orderId'] ?? widget.order['_id'];

    if (orderId == null || orderId.toString().isEmpty) {
      print("❌ Order Data: ${widget.order}"); // Debug print
      Get.snackbar("Error", "Invalid order ID");
      return;
    }

    try {
      setState(() => isReachedLoading = true);

      final res = await ApiHelper.orderReached(
        orderId: orderId,
        lat: userLocation.latitude,
        lng: userLocation.longitude,
      );

      if (res["success"] == true) {
        Get.snackbar(
          "Reached Location",
          "OTP has been sent to the restaurant",
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );

        // Navigate to OTP Verification Page
        Get.to(() => PickupOtpPage(orderId: orderId.toString()));
      } else {
        Get.snackbar(
          "Failed",
          res["message"] ?? "Failed to update status",
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        "Error",
        "Something went wrong",
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() => isReachedLoading = false);
    }
  }

  Future<void> _makeCall() async {
    final phone = widget.order['pickup']?['mobile']?.toString();
    if (phone != null && phone.isNotEmpty) {
      final url = "tel:$phone";
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      } else {
        Get.snackbar("Error", "Could not launch dialer");
      }
    } else {
      Get.snackbar("Not Available", "Phone number not available");
    }
  }

  /// 🚫 CANCEL ORDER API
  Future<void> _cancelOrder(String reason) async {
    // Robust Order ID Extraction
    final orderId =
        widget.order['orderId'] ??
        widget.order['_id'] ??
        widget.order['id'] ??
        widget.order['order']?['orderId'] ??
        widget.order['order']?['_id'];

    debugPrint("🔥 CANCEL REQUEST INITIATED");
    debugPrint("🆔 Order ID: $orderId");
    debugPrint("💬 Reason: $reason");

    if (orderId == null || orderId.toString().isEmpty) {
      Get.snackbar(
        "Invalid Order",
        "Cannot cancel: Order ID is missing.",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    try {
      setState(() => isCancelLoading = true);

      final res = await ApiHelper.orderCancel(
        orderId: orderId.toString(),
        reason: reason,
      );

      debugPrint("📥 CANCEL API RESPONSE: $res");

      if (res["success"] == true) {
        Get.snackbar(
          "Success",
          res["message"] ?? "Order cancelled successfully",
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        // Refresh home after small delay
        Future.delayed(const Duration(seconds: 1), () {
          Get.offAllNamed('/dashboard');
        });
      } else {
        Get.snackbar(
          "Cancellation Failed",
          res["message"] ?? "Server rejected the cancellation",
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 5),
        );
      }
    } catch (e) {
      debugPrint("🚨 CANCEL ERROR: $e");
      Get.snackbar(
        "Connection Error",
        "Could not reach server. Please check internet.",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      if (mounted) setState(() => isCancelLoading = false);
    }
  }

  void _showCancelSheet() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Select Cancel Reason",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: cancelReasons.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      cancelReasons[index],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: Colors.grey,
                    ),
                    onTap: () {
                      Get.back();
                      _confirmCancel(cancelReasons[index]);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  void _confirmCancel(String reason) {
    Get.dialog(
      AlertDialog(
        title: const Text(
          "Confirm Cancellation",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text("Are you sure you want to cancel for reason: '$reason'?"),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text(
              "No",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              _cancelOrder(reason);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              "Yes, Cancel",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        userLocation = LatLng(
          locationController.latitude.value,
          locationController.longitude.value,
        );
        _calculateDistance();
        _setupMap();

        return Stack(
          children: [
            GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: userLocation,
                zoom: 14,
              ),
              markers: markers,
              polylines: polylines,
              myLocationEnabled: true,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
            ),

            // ✅ MODERN TOP BAR (As per screenshot)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 10,
                  bottom: 15,
                  left: 20,
                  right: 20,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Get.back(),
                      child: const Icon(
                        Icons.keyboard_arrow_down,
                        size: 30,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(width: 15),
                    const Expanded(
                      child: Text(
                        "Reach pickup",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    // HELP BUTTON
                    GestureDetector(
                      onTap: _showCancelSheet,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: isCancelLoading
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.black,
                                ),
                              )
                            : const Text(
                                "CANCEL",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.black,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Align(
              alignment: const Alignment(0, 0.90), // ✅ UPAR SHIFTED
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            "PICK UP",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.order['pickup']?['address'] ??
                                    widget.order['pickup']?['name'] ??
                                    "Pickup Location",
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.order['pickup']?['address'] != null
                                    ? "Source pickup point"
                                    : "Address details...",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              distanceText,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: Colors.green,
                              ),
                            ),
                            const Text(
                              "Away",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _makeCall,
                            icon: const Icon(Icons.call, size: 20),
                            label: const Text("Call"),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: BorderSide(color: Colors.grey.shade300),
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _launchNavigation,
                            icon: const Icon(
                              Icons.navigation_outlined,
                              size: 20,
                            ),
                            label: const Text("Map"),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: BorderSide(color: Colors.grey.shade300),
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isReachedLoading
                            ? null
                            : _confirmReachedLocation,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 0, 0, 0),
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: isReachedLoading
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                "Reached Location",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}
