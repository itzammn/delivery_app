import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiHelper {
  static const String _baseUrl = "https://dev-api.gamsgroup.in";
  // static const String _baseUrl = "http://192.168.29.58:8000";

  // Get token from SharedPreferences
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token'); // ✅ Match with login page key
    print(
      "🔐 Retrieved Token: ${token != null ? 'Found (${token.substring(0, 20)}...)' : 'NULL'}",
    );
    return token;
  }

  // Get headers with authentication
  static Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();

    final headers = {
      "Content-Type": "application/json",
      if (token != null && token.isNotEmpty) "Authorization": "Bearer $token",
    };

    print(
      "📋 Headers prepared: ${token != null ? 'With Authorization' : 'Without Authorization'}",
    );
    return headers;
  }

  static Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    print("📤 POST Request: $endpoint");
    print("📦 Request Data: $data");

    try {
      final headers = await _getHeaders();
      print("🔑 Headers: $headers");

      final response = await http.post(
        Uri.parse("$_baseUrl$endpoint"),
        headers: headers,
        body: jsonEncode(data),
      );

      print("📥 Response Status: ${response.statusCode}");
      print("📥 Response Body: ${response.body}");

      return jsonDecode(response.body);
    } catch (e) {
      print("❌ Network Error: $e");
      return {"success": false, "message": "Network error: $e"};
    }
  }

  static Future<Map<String, dynamic>> get(String endpoint) async {
    print("📤 GET Request: $endpoint");

    try {
      final headers = await _getHeaders();
      print("🔑 Headers: $headers");

      final response = await http.get(
        Uri.parse("$_baseUrl$endpoint"),
        headers: headers,
      );

      print("📥 Response Status: ${response.statusCode}");
      print("📥 Response Body: ${response.body}");

      return jsonDecode(response.body);
    } catch (e) {
      print("❌ Network Error: $e");
      return {"success": false, "message": "Network error: $e"};
    }
  }

  static Future<Map<String, dynamic>> put(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    print("📤 PUT Request: $endpoint");
    print("📦 Request Data: $data");

    try {
      final headers = await _getHeaders();

      final response = await http.put(
        Uri.parse("$_baseUrl$endpoint"),
        headers: headers,
        body: jsonEncode(data),
      );

      print("📥 Response Status: ${response.statusCode}");
      print("📥 Response Body: ${response.body}");

      return jsonDecode(response.body);
    } catch (e) {
      print("❌ Network Error: $e");
      return {"success": false, "message": "Network error: $e"};
    }
  }

  static Future<Map<String, dynamic>> uploadImage(String filePath) async {
    try {
      final token = await _getToken();

      final request = http.MultipartRequest(
        "POST",
        Uri.parse("$_baseUrl/upload/delivery-uploader?folder=Delivery"),
      );

      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      request.files.add(
        await http.MultipartFile.fromPath(
          "image",
          filePath,
          filename: "upload_${DateTime.now().millisecondsSinceEpoch}.jpg",
          contentType: MediaType("image", "jpeg"),
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print("📥 Image Upload Response: ${response.body}");
      return jsonDecode(response.body);
    } catch (e) {
      print("❌ Upload Error: $e");
      return {"success": false, "message": "Upload error: $e"};
    }
  }

  static Future<Map<String, dynamic>> checkZone(double lat, double lng) async {
    return post("/food-delivery/check-zone", {
      "latitude": lat,
      "longitude": lng,
    });
  }

  /// ACCEPT ORDER API
  static Future<Map<String, dynamic>> acceptOrder(String orderId) async {
    return post("/food-delivery/order-accept", {"orderId": orderId});
  }

  /// CANCEL ORDER API
  static Future<Map<String, dynamic>> orderCancel({
    required String orderId,
    required String reason,
  }) async {
    return post("/food-delivery/order-cancel", {
      "orderId": orderId,
      "reason": reason,
    });
  }

  /// ORDER REACHED API
  static Future<Map<String, dynamic>> orderReached({
    required String orderId,
    required double lat,
    required double lng,
  }) async {
    return post("/food-delivery/order-reached", {
      "orderId": orderId,
      "lat": lat,
      "lng": lng,
    });
  }

  static Future<Map<String, dynamic>> orderPickup({
    required String orderId,
    required String otp,
  }) async {
    return post("/food-delivery/order-pickup", {
      "orderId": orderId,
      "otp": otp,
    });
  }

  /// ORDER ARRIVED AT DROP LOCATION
  static Future<Map<String, dynamic>> orderArrived({
    required String orderId,
    required double lat,
    required double lng,
  }) async {
    return post("/food-delivery/order-arrived", {
      "orderId": orderId,
      "lat": lat.toString(),
      "lng": lng.toString(),
    });
  }

  /// SEND OTP TO USER
  static Future<Map<String, dynamic>> sendOrderOtp(String orderId) async {
    return post("/food-delivery/order-otp", {"orderId": orderId});
  }

  /// ORDER DELIVERED
  static Future<Map<String, dynamic>> orderDelivered({
    required String orderId,
    required String otp,
  }) async {
    return post("/food-delivery/order-delivered", {
      "orderId": orderId,
      "otp": otp,
    });
  }

  /// GET PROFILE DATA
  static Future<Map<String, dynamic>> getProfile() async {
    return get(
      "/delivery/profile/my-profile",
    ); // This is a common pattern, adjusting if needed
  }
}
// import 'dart:convert';
// import 'package:http/http.dart' as http;

// class ApiHelper {
//   static const String _baseUrl = "https://api.gamsgroup.in";

//   static Future<Map<String, dynamic>> post(
//     String endpoint,
//     Map<String, dynamic> data,
//   ) async {
//     try {
//       final response = await http.post(
//         Uri.parse("$_baseUrl$endpoint"),
//         headers: {"Accept": "application/json"},
//         body: data, // NO jsonEncode
//       );

//       print("📤 POST => $_baseUrl$endpoint");
//       print("📦 DATA => $data");
//       print("📥 RESPONSE => ${response.body}");

//       return jsonDecode(response.body);
//     } catch (e) {
//       return {"success": false, "message": "Network error: $e"};
//     }
//   }

//   static Future<Map<String, dynamic>> get(String endpoint) async {
//     try {
//       final response = await http.get(Uri.parse("$_baseUrl$endpoint"));
//       return jsonDecode(response.body);
//     } catch (e) {
//       return {"success": false, "message": "Network error: $e"};
//     }
//   }

//   static Future<Map<String, dynamic>> put(
//     String endpoint,
//     Map<String, dynamic> data,
//   ) async {
//     try {
//       final response = await http.put(
//         Uri.parse("$_baseUrl$endpoint"),
//         headers: {"Accept": "application/json"},
//         body: data,
//       );
//       return jsonDecode(response.body);
//     } catch (e) {
//       return {"success": false, "message": "Network error: $e"};
//     }
//   }
// }
