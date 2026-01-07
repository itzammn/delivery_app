import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zamboree/Controller/LocationController.dart';

class ZoneMapPage extends StatefulWidget {
  final Map<String, dynamic>? zoneData;
  const ZoneMapPage({super.key, this.zoneData});

  @override
  State<ZoneMapPage> createState() => _ZoneMapPageState();
}

class _ZoneMapPageState extends State<ZoneMapPage> {
  final controller = Get.find<LocationController>();
  GoogleMapController? mapController;

  // Default Zone Center (Lucknow Center as placeholder)
  LatLng zoneCenter = const LatLng(26.8467, 80.9462);
  List<LatLng> polygonPoints = [];
  bool hasPolygon = false;
  Set<Polygon> polygons = {};
  Set<Marker> markers = {};
  Set<Polyline> polylines = {}; // ✅ For route line

  double distanceInKm = 0.0;
  bool isInsideZone = false;
  bool hasZoneData = false;

  // ✅ For animated arrow
  Timer? _arrowAnimationTimer;
  double _arrowAnimationValue = 0.0;
  LatLng? _closestZonePoint;

  @override
  void initState() {
    super.initState();

    print("═══════════════════════════════════════════════════════════");
    print("📦 COMPLETE API RESPONSE RECEIVED:");
    print("═══════════════════════════════════════════════════════════");
    print(widget.zoneData);
    print("═══════════════════════════════════════════════════════════");

    _parseZoneData();
    _calculateDistance();
    _setupMapElements();
    _startArrowAnimation(); // ✅ Start arrow animation
  }

  void _parseZoneData() {
    print("\n═══════════════════════════════════════════════════════════");
    print("🔍 PARSING ZONE DATA IN ZoneMapPage");
    print("═══════════════════════════════════════════════════════════");

    if (widget.zoneData == null) {
      print("❌ widget.zoneData is NULL");
      hasZoneData = false;
      return;
    }

    try {
      print("📦 Received zoneData:");
      print(jsonEncode(widget.zoneData));

      isInsideZone = widget.zoneData?['isInsideZone'] == true;
      print("\n📍 isInsideZone: $isInsideZone");

      final zoneObject =
          widget.zoneData?['zone'] ?? widget.zoneData?['nearestZone'];

      print("🗺️ Zone Object: $zoneObject");
      print("   Type: ${zoneObject?.runtimeType}");

      if (zoneObject == null || zoneObject is! Map) {
        print(
          "⚠️ Zone is NULL or not a Map - User is outside all service zones!",
        );
        hasZoneData = false;
        isInsideZone = false;
        return;
      }

      hasZoneData = true;
      print("✅ Zone data exists");

      final polygonData = zoneObject['polygon'];
      print("\n🔺 Polygon Data:");
      print("   Type: ${polygonData?.runtimeType}");
      print("   Content: $polygonData");

      if (polygonData == null) {
        print("⚠️ Polygon data is NULL");
        hasPolygon = false;
        return;
      }

      if (polygonData is! List) {
        print("⚠️ Polygon data is not a List, it's ${polygonData.runtimeType}");
        hasPolygon = false;
        return;
      }

      if (polygonData.isEmpty) {
        print("⚠️ Polygon data is empty");
        hasPolygon = false;
        return;
      }

      print("✅ Polygon has ${polygonData.length} points");

      polygonPoints = [];
      for (var i = 0; i < polygonData.length; i++) {
        var item = polygonData[i];

        if (item == null || item is! Map) {
          print("⚠️ Point $i is invalid: $item");
          continue;
        }

        double lat = 0.0;
        double lng = 0.0;

        if (item.containsKey('lat')) {
          lat = (item['lat'] is num)
              ? (item['lat'] as num).toDouble()
              : double.tryParse(item['lat'].toString()) ?? 0.0;
        } else if (item.containsKey('latitude')) {
          lat = (item['latitude'] is num)
              ? (item['latitude'] as num).toDouble()
              : double.tryParse(item['latitude'].toString()) ?? 0.0;
        }

        if (item.containsKey('lng')) {
          lng = (item['lng'] is num)
              ? (item['lng'] as num).toDouble()
              : double.tryParse(item['lng'].toString()) ?? 0.0;
        } else if (item.containsKey('longitude')) {
          lng = (item['longitude'] is num)
              ? (item['longitude'] as num).toDouble()
              : double.tryParse(item['longitude'].toString()) ?? 0.0;
        }

        if (lat != 0.0 && lng != 0.0) {
          print("   ✅ Point $i: ($lat, $lng)");
          polygonPoints.add(LatLng(lat, lng));
        } else {
          print("   ⚠️ Point $i has zero coordinates: ($lat, $lng)");
        }
      }

      if (polygonPoints.isEmpty) {
        print("❌ No valid polygon points found");
        hasPolygon = false;
        return;
      }

      hasPolygon = true;
      print("\n✅ Successfully parsed ${polygonPoints.length} polygon points");

      if (polygonPoints.first.latitude != polygonPoints.last.latitude ||
          polygonPoints.first.longitude != polygonPoints.last.longitude) {
        polygonPoints.add(polygonPoints.first);
        print("🔄 Polygon closed by adding first point at end");
      }

      zoneCenter = _calculatePolygonCenter(polygonPoints);
      print("🎯 Calculated Zone Center: $zoneCenter");

      print("\n═══════════════════════════════════════════════════════════");
      print("✅ PARSING COMPLETE:");
      print("   • Has Zone Data: $hasZoneData");
      print("   • Has Polygon: $hasPolygon");
      print("   • Total Points: ${polygonPoints.length}");
      print("   • Zone Center: $zoneCenter");
      print("   • Inside Zone: $isInsideZone");
      print("═══════════════════════════════════════════════════════════\n");
    } catch (e, stackTrace) {
      print("❌ ERROR PARSING ZONE DATA:");
      print("   Error: $e");
      print("   Stack trace: $stackTrace");
      hasZoneData = false;
      hasPolygon = false;
    }
  }

  LatLng _calculatePolygonCenter(List<LatLng> points) {
    if (points.isEmpty) return const LatLng(26.8467, 80.9462);

    int n = points.length;
    if (n > 1 &&
        points.first.latitude == points.last.latitude &&
        points.first.longitude == points.last.longitude) {
      n--;
    }

    double latitude = 0;
    double longitude = 0;

    for (int i = 0; i < n; i++) {
      latitude += points[i].latitude;
      longitude += points[i].longitude;
    }

    return LatLng(latitude / n, longitude / n);
  }

  // ✅ Get zone center as target point
  LatLng _getTargetZonePoint() {
    // Always return zone center instead of closest boundary point
    return zoneCenter;
  }

  // ✅ Create route polyline from user to zone CENTER
  void _createRouteLine() {
    if (!hasZoneData || isInsideZone) {
      polylines.clear();
      return;
    }

    final userLocation = LatLng(
      controller.latitude.value,
      controller.longitude.value,
    );

    // Use zone center as target
    _closestZonePoint = _getTargetZonePoint();

    // Create dotted line effect with multiple small segments
    List<LatLng> routePoints = _createDottedLinePoints(
      userLocation,
      _closestZonePoint!,
    );

    polylines = {
      Polyline(
        polylineId: const PolylineId('route_to_zone'),
        points: routePoints,
        color: const Color.fromARGB(136, 29, 29, 29),
        width: 4,
        patterns: [PatternItem.dash(20), PatternItem.gap(10)],
        geodesic: true,
        startCap: Cap.roundCap,
        endCap: Cap.customCapFromBitmap(BitmapDescriptor.defaultMarker),
      ),
    };

    print("✅ Route line created from user to ZONE CENTER");
    print("   From: (${userLocation.latitude}, ${userLocation.longitude})");
    print(
      "   To: (${_closestZonePoint!.latitude}, ${_closestZonePoint!.longitude})",
    );
  }

  // ✅ Create points for dotted line
  List<LatLng> _createDottedLinePoints(LatLng start, LatLng end) {
    List<LatLng> points = [];
    int numPoints = 50; // Number of intermediate points

    for (int i = 0; i <= numPoints; i++) {
      double fraction = i / numPoints;
      double lat = start.latitude + (end.latitude - start.latitude) * fraction;
      double lng =
          start.longitude + (end.longitude - start.longitude) * fraction;
      points.add(LatLng(lat, lng));
    }

    return points;
  }

  // ✅ Start arrow animation
  void _startArrowAnimation() {
    if (!hasZoneData || isInsideZone) return;

    _arrowAnimationTimer?.cancel();
    _arrowAnimationTimer = Timer.periodic(const Duration(milliseconds: 100), (
      timer,
    ) {
      if (mounted) {
        setState(() {
          _arrowAnimationValue += 0.02;
          if (_arrowAnimationValue > 1.0) {
            _arrowAnimationValue = 0.0;
          }
        });
      }
    });
  }

  void _setupMapElements() {
    print("\n🗺️  SETTING UP MAP ELEMENTS:");

    if (hasPolygon && polygonPoints.isNotEmpty) {
      polygons = {
        Polygon(
          polygonId: const PolygonId('service_zone'),
          points: polygonPoints,
          fillColor: isInsideZone
              ? Colors.green.withOpacity(0.3)
              : Colors.orange.withOpacity(0.3),
          strokeColor: isInsideZone ? Colors.green : Colors.orange,
          strokeWidth: 3,
          geodesic: true,
        ),
      };
      print("   ✅ Polygon created with ${polygonPoints.length} points");
      print("   🎨 Color: ${isInsideZone ? 'Green' : 'Orange'}");
    } else {
      print("   ⚠️  No polygon to display");
    }

    // Create route line if outside zone
    _createRouteLine();

    markers = {
      Marker(
        markerId: const MarkerId('user_location'),
        position: LatLng(controller.latitude.value, controller.longitude.value),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          isInsideZone ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueBlue,
        ),
        infoWindow: InfoWindow(
          title: 'Your Location',
          snippet: isInsideZone ? 'Inside Zone' : 'Outside Zone',
        ),
      ),
    };

    if (hasZoneData && hasPolygon) {
      // Add zone center marker - This is the TARGET
      markers.add(
        Marker(
          markerId: const MarkerId('zone_center'),
          position: zoneCenter,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(
            title: '🎯 Zone Center',
            snippet: 'Navigate here',
          ),
        ),
      );
    }

    print("   ✅ ${markers.length} markers created");
    print(
      "   📍 User Location: (${controller.latitude.value}, ${controller.longitude.value})",
    );
    if (hasZoneData) {
      print("   📍 Zone Center (Target): $zoneCenter");
    }
    print("");
  }

  void _calculateDistance() {
    print("\n📏 CALCULATING DISTANCE:");

    final zoneObject =
        widget.zoneData?['zone'] ?? widget.zoneData?['nearestZone'];
    if (zoneObject != null && zoneObject['distanceInKm'] != null) {
      setState(() {
        distanceInKm = (zoneObject['distanceInKm'] as num).toDouble();
      });
      print(
        "   ✅ Using distance from API: ${distanceInKm.toStringAsFixed(2)} km",
      );
      return;
    }

    if (hasPolygon && polygonPoints.isNotEmpty) {
      double minDistance = double.infinity;

      for (var point in polygonPoints) {
        double distance = Geolocator.distanceBetween(
          controller.latitude.value,
          controller.longitude.value,
          point.latitude,
          point.longitude,
        );

        if (distance < minDistance) {
          minDistance = distance;
        }
      }

      setState(() {
        distanceInKm = minDistance / 1000;
      });
      print(
        "   ✅ Distance to nearest polygon edge: ${distanceInKm.toStringAsFixed(2)} km",
      );
    } else {
      double distanceInMeters = Geolocator.distanceBetween(
        controller.latitude.value,
        controller.longitude.value,
        zoneCenter.latitude,
        zoneCenter.longitude,
      );
      setState(() {
        distanceInKm = distanceInMeters / 1000;
      });
      print(
        "   ✅ Distance to default center: ${distanceInKm.toStringAsFixed(2)} km",
      );
    }
    print("────────────────────────────────────────────────────────────\n");
  }

  Future<void> _launchGoogleMaps() async {
    // Navigate to zone center
    final targetLat = zoneCenter.latitude;
    final targetLng = zoneCenter.longitude;

    final String googleUrl =
        "https://www.google.com/maps/dir/?api=1&origin=${controller.latitude.value},${controller.longitude.value}&destination=$targetLat,$targetLng&travelmode=driving";

    print("\n🚗 LAUNCHING GOOGLE MAPS:");
    print(
      "   From: (${controller.latitude.value}, ${controller.longitude.value})",
    );
    print("   To: Zone Center ($targetLat, $targetLng)");
    print("   URL: $googleUrl");

    try {
      bool launched = await launchUrl(
        Uri.parse(googleUrl),
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        print("   ❌ Failed to launch Google Maps");
        if (mounted) {
          Get.snackbar(
            "Navigation Error",
            "Could not launch maps",
            backgroundColor: Colors.redAccent,
            colorText: Colors.white,
          );
        }
      } else {
        print("   ✅ Google Maps launched successfully");
      }
    } catch (e) {
      print("   ❌ Map Launch Error: $e");
      if (mounted) {
        Get.snackbar(
          "Navigation Error",
          "Error details: ${e.toString()}",
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
        );
      }
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    print("\n🗺️  MAP CREATED SUCCESSFULLY");

    if (hasPolygon && polygonPoints.isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          print("   📐 Fitting bounds to polygon...");
          _fitBoundsToPolygon();
        }
      });
    }
  }

  void _fitBoundsToPolygon() {
    if (polygonPoints.isEmpty || mapController == null) {
      print("   ⚠️  Cannot fit bounds: No polygon points or map controller");
      return;
    }

    double minLat = polygonPoints[0].latitude;
    double maxLat = polygonPoints[0].latitude;
    double minLng = polygonPoints[0].longitude;
    double maxLng = polygonPoints[0].longitude;

    for (var point in polygonPoints) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    final userLat = controller.latitude.value;
    final userLng = controller.longitude.value;
    if (userLat < minLat) minLat = userLat;
    if (userLat > maxLat) maxLat = userLat;
    if (userLng < minLng) minLng = userLng;
    if (userLng > maxLng) maxLng = userLng;

    double latPadding = (maxLat - minLat) * 0.1;
    double lngPadding = (maxLng - minLng) * 0.1;

    final bounds = LatLngBounds(
      southwest: LatLng(minLat - latPadding, minLng - lngPadding),
      northeast: LatLng(maxLat + latPadding, maxLng + lngPadding),
    );

    print("   ✅ Bounds calculated:");
    print(
      "      SW: (${bounds.southwest.latitude}, ${bounds.southwest.longitude})",
    );
    print(
      "      NE: (${bounds.northeast.latitude}, ${bounds.northeast.longitude})",
    );

    mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80));
  }

  @override
  void dispose() {
    print("\n🗑️  ZoneMapPage disposed");
    _arrowAnimationTimer?.cancel();
    mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final zoneName = hasZoneData
        ? (widget.zoneData?['zone']?['name'] ?? "Service Zone")
        : "No Service Zone Nearby";

    print("\n🏗️  BUILDING ZoneMapPage UI");
    print("   Zone Name: $zoneName");

    return Scaffold(
      appBar: AppBar(
        title: Text(zoneName),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: LatLng(
                controller.latitude.value,
                controller.longitude.value,
              ),
              zoom: hasZoneData ? 13 : 12,
            ),
            polygons: polygons,
            polylines: polylines, // ✅ Add polylines
            markers: markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            mapType: MapType.normal,
            zoomControlsEnabled: true,
            compassEnabled: true,
            mapToolbarEnabled: true,
          ),
          Positioned(
            bottom: 60,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!hasZoneData) ...[
                    const Icon(Icons.location_off, color: Colors.red, size: 40),
                    const SizedBox(height: 12),
                    const Text(
                      "No Service Zone Available",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "You are currently outside all service zones. Please contact support for assistance.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: const Color.fromARGB(255, 224, 11, 11),
                      ),
                    ),
                  ] else ...[
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: isInsideZone ? Colors.blue : Colors.orange,
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          "Distance to Zone",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          "${distanceInKm.toStringAsFixed(2)} KM",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: isInsideZone ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Text(
                      isInsideZone
                          ? "✅ You are inside the service zone. You can start your shift."
                          : "⚠️ Follow the dotted line to reach the zone center.",
                      style: TextStyle(
                        color: isInsideZone
                            ? Colors.green
                            : Colors.grey.shade700,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      if (hasZoneData) ...[
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _launchGoogleMaps,
                            icon: const Icon(Icons.navigation, size: 20),
                            label: const Text("Navigate"),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.black,
                              minimumSize: const Size(0, 48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              side: const BorderSide(color: Colors.black),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            print("\n👈 Got It button pressed - Going back");
                            Get.back();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            minimumSize: const Size(0, 48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            hasZoneData ? "Got It" : "Close",
                            style: const TextStyle(color: Colors.white),
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
      ),
    );
  }
}
