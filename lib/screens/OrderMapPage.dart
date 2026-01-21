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
    double lat = double.tryParse(pickup?['lat']?.toString() ?? "0") ?? 0;
    double lng = double.tryParse(pickup?['lng']?.toString() ?? "0") ?? 0;
    pickupLocation = LatLng(lat, lng);
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

  /// 🔔 CONFIRMATION DIALOG
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
          TextButton(onPressed: () => Get.back(), child: const Text("No")),
          ElevatedButton(
            onPressed: () {
              Get.back();
              _callReachedApi();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text("Yes"),
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

            Positioned(
              top: 50,
              left: 20,
              child: CircleAvatar(
                backgroundColor: Colors.white,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () => Get.back(),
                ),
              ),
            ),

            Align(
              alignment: Alignment.bottomCenter,
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
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.storefront,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.order['pickup']?['name'] ??
                                    "Pickup Location",
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                widget.order['pickup']?['address'] ??
                                    "Address details...",
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
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              distanceText,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            const Text(
                              "Away",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _launchNavigation,
                            icon: const Icon(Icons.navigation_outlined),
                            label: const Text("Start Navigation"),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: const BorderSide(color: Colors.black),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: isReachedLoading
                                ? null
                                : _confirmReachedLocation,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade700,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
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
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ],
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
