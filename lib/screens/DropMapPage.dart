import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zamboree/Controller/LocationController.dart';
import 'package:zamboree/auth/api_helper.dart';
import 'package:zamboree/screens/DeliveryOtpPage.dart';

class DropMapPage extends StatefulWidget {
  final Map<String, dynamic> order;
  const DropMapPage({super.key, required this.order});

  @override
  State<DropMapPage> createState() => _DropMapPageState();
}

class _DropMapPageState extends State<DropMapPage> {
  final locationController = Get.find<LocationController>();
  GoogleMapController? mapController;

  Set<Marker> markers = {};
  Set<Polyline> polylines = {};
  double distanceInKm = 0.0;
  String distanceText = "Calculating...";

  late LatLng userLocation;
  late LatLng dropLocation;

  bool isArrivedLoading = false;

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

    // Extracting from address -> location -> coordinates [lng, lat]
    final address = widget.order['address'];
    final location = address?['location'];
    final coords = location?['coordinates'];

    double lat = 0.0;
    double lng = 0.0;

    if (coords != null && coords is List && coords.length >= 2) {
      lng = double.tryParse(coords[0].toString()) ?? 0.0;
      lat = double.tryParse(coords[1].toString()) ?? 0.0;
    } else {
      // Fallback to direct lat/lng if available
      lat = double.tryParse(address?['lat']?.toString() ?? "0") ?? 0;
      lng = double.tryParse(address?['lng']?.toString() ?? "0") ?? 0;
    }

    dropLocation = LatLng(lat, lng);
    debugPrint("📍 DROP LOCATION: $lat, $lng");
  }

  void _calculateDistance() {
    double distanceInMeters = Geolocator.distanceBetween(
      userLocation.latitude,
      userLocation.longitude,
      dropLocation.latitude,
      dropLocation.longitude,
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
        markerId: const MarkerId('drop_location'),
        position: dropLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(
          title:
              'Drop: ${widget.order['address']?['customer_name'] ?? "Customer"}',
        ),
      ),
    };

    polylines = {
      Polyline(
        polylineId: const PolylineId('route'),
        points: [userLocation, dropLocation],
        color: Colors.blue,
        width: 5,
        patterns: [PatternItem.dash(20), PatternItem.gap(10)],
      ),
    };
  }

  Future<void> _launchNavigation() async {
    final url =
        "https://www.google.com/maps/dir/?api=1&origin=${userLocation.latitude},${userLocation.longitude}&destination=${dropLocation.latitude},${dropLocation.longitude}&travelmode=driving";
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      Get.snackbar("Error", "Could not launch maps");
    }
  }

  void _makeCall() async {
    final phone = widget.order['address']?['mobile']?.toString();
    if (phone != null) {
      final url = "tel:$phone";
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      } else {
        Get.snackbar("Error", "Could not launch dialer");
      }
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    _fitBounds();
  }

  void _fitBounds() {
    if (mapController == null) return;

    LatLngBounds bounds;
    if (userLocation.latitude > dropLocation.latitude) {
      bounds = LatLngBounds(
        southwest: LatLng(
          dropLocation.latitude,
          userLocation.longitude < dropLocation.longitude
              ? userLocation.longitude
              : dropLocation.longitude,
        ),
        northeast: LatLng(
          userLocation.latitude,
          userLocation.longitude > dropLocation.longitude
              ? userLocation.longitude
              : dropLocation.longitude,
        ),
      );
    } else {
      bounds = LatLngBounds(
        southwest: LatLng(
          userLocation.latitude,
          userLocation.longitude < dropLocation.longitude
              ? userLocation.longitude
              : dropLocation.longitude,
        ),
        northeast: LatLng(
          dropLocation.latitude,
          userLocation.longitude > dropLocation.longitude
              ? userLocation.longitude
              : dropLocation.longitude,
        ),
      );
    }

    mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
  }

  void _confirmArrival() {
    Get.dialog(
      AlertDialog(
        title: const Text(
          "Confirm Arrival",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text("Have you reached the customer's drop location?"),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text(
              "No",
              style: TextStyle(
                color: Colors.black, // ❌ No = Black
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              _callArrivedApi();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black, // Button color
              foregroundColor: Colors.white, // ✅ Text color (BEST way)
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              "Yes",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),

      barrierDismissible: false,
    );
  }

  Future<void> _callArrivedApi() async {
    // Debugging ke liye full data print karein
    debugPrint("🔍 Full Order Data: ${widget.order}");

    // Har sambhav jagah par ID check karein
    final orderId =
        widget.order['orderId'] ??
        widget.order['_id'] ??
        widget.order['id'] ??
        widget.order['order']?['_id'] ??
        widget.order['order']?['orderId'];

    if (orderId == null || orderId.toString().isEmpty) {
      Get.snackbar("Error", "Invalid order ID. Check console for logs.");
      return;
    }

    try {
      setState(() => isArrivedLoading = true);

      // 1. Call Order Arrived API
      final resArrived = await ApiHelper.orderArrived(
        orderId: orderId.toString(),
        lat: userLocation.latitude,
        lng: userLocation.longitude,
      );

      if (resArrived["success"] == true) {
        // 2. Call Order OTP API to send OTP to customer
        final resOtp = await ApiHelper.sendOrderOtp(orderId.toString());

        if (resOtp["success"] == true) {
          Get.snackbar(
            "Arrived",
            "OTP has been sent to the customer",
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
          Get.to(
            () => DeliveryOtpPage(
              orderId: orderId.toString(),
              phoneNumber: widget.order['address']?['mobile']?.toString(),
            ),
          );
        } else {
          Get.snackbar("Error", resOtp["message"] ?? "Failed to send OTP");
        }
      } else {
        Get.snackbar(
          "Error",
          resArrived["message"] ?? "Failed to update arrival",
        );
      }
    } catch (e) {
      Get.snackbar("Error", "Something went wrong");
    } finally {
      setState(() => isArrivedLoading = false);
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
              alignment: const Alignment(0, 0.90), // ✅ BOTTOM SE UPAR SHIFTED
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
                            color: Colors.green.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.person_pin_circle,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.order['address']?['customer_name'] ??
                                    "Customer Name",
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                "${widget.order['address']?['addressLine1'] ?? ""}, ${widget.order['address']?['city'] ?? ""}",
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
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _makeCall,
                            icon: const Icon(Icons.call, color: Colors.white),
                            label: const Text("Call"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade700,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              // Message functionality (could be WhatsApp or SMS)
                              final phone = widget.order['address']?['mobile'];
                              if (phone != null) {
                                launchUrl(Uri.parse("sms:$phone"));
                              }
                            },
                            icon: const Icon(
                              Icons.message_outlined,
                              color: Colors.black,
                            ),
                            label: const Text(
                              "Message",
                              style: TextStyle(color: Colors.black),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: const BorderSide(color: Colors.black),
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
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _launchNavigation,
                            icon: const Icon(Icons.navigation_outlined),
                            label: const Text("Navigate"),
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
                            onPressed: isArrivedLoading
                                ? null
                                : _confirmArrival,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromARGB(
                                255,
                                11,
                                12,
                                11,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: isArrivedLoading
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    "Arrived at Drop",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
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
