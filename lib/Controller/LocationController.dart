import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geocoding/geocoding.dart';

class LocationController extends GetxController {
  RxDouble latitude = 0.0.obs;
  RxDouble longitude = 0.0.obs;
  RxString locationText = "Fetching location...".obs;

  @override
  void onInit() {
    loadLocation();
    super.onInit();
  }

  Future<void> loadLocation() async {
    final prefs = await SharedPreferences.getInstance();
    latitude.value = prefs.getDouble("latitude") ?? 26.8467;
    longitude.value = prefs.getDouble("longitude") ?? 80.9462;
    await _updateLocationText(latitude.value, longitude.value);
  }

  Future<void> updateLocation(double lat, double lng) async {
    latitude.value = lat;
    longitude.value = lng;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble("latitude", lat);
    await prefs.setDouble("longitude", lng);

    await _updateLocationText(lat, lng);
  }

  Future<void> _updateLocationText(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        // Try to get the most specific name available
        String specificArea =
            place.subLocality ??
            place.name ??
            place.thoroughfare ??
            place.locality ??
            "Unknown";
        String city = place.locality ?? "";

        String address;
        if (specificArea.isNotEmpty &&
            city.isNotEmpty &&
            specificArea != city) {
          address = "$specificArea, $city";
        } else {
          address = specificArea.isNotEmpty ? specificArea : city;
        }

        locationText.value = address;
      } else {
        locationText.value =
            "Lat: ${lat.toStringAsFixed(3)}, Lng: ${lng.toStringAsFixed(3)}";
      }
    } catch (e) {
      locationText.value =
          "Lat: ${lat.toStringAsFixed(3)}, Lng: ${lng.toStringAsFixed(3)}";
    }
  }
}
