import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiHelper {
  static const String _baseUrl = "https://api.gamsgroup.in";

  static Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    print("fgdfgrgrs $data");
    try {
      final response = await http.post(
        Uri.parse("$_baseUrl$endpoint"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(data),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {"success": false, "message": "Network error: $e"};
    }
  }

  static Future<Map<String, dynamic>> get(String endpoint) async {
    try {
      final response = await http.get(Uri.parse("$_baseUrl$endpoint"));
      return jsonDecode(response.body);
    } catch (e) {
      return {"success": false, "message": "Network error: $e"};
    }
  }

  static Future<Map<String, dynamic>> put(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await http.put(
        Uri.parse("$_baseUrl$endpoint"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(data),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {"success": false, "message": "Network error: $e"};
    }
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
//         body: data, // 👈 NO jsonEncode
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
