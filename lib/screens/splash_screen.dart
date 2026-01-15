// // import 'dart:async';
// // import 'package:flutter/material.dart';

// // class SplashScreen extends StatefulWidget {
// //   const SplashScreen({super.key});

// //   @override
// //   State<SplashScreen> createState() => _SplashScreenState();
// // }

// // class _SplashScreenState extends State<SplashScreen> {
// //   @override
// //   void initState() {
// //     super.initState();

// //     // Navigate to Login after 3 seconds
// //     Timer(const Duration(seconds: 3), () {
// //       Navigator.pushReplacementNamed(context, '/login');
// //     });
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       backgroundColor: Colors.white,
// //       body: Stack(
// //         children: [
// //           // 🌕 Top Yellow Curved Background
// //           CustomPaint(
// //             size: Size(MediaQuery.of(context).size.width, 170),
// //             painter: _SplashCurvePainter(),
// //           ),

// //           // 🌿 Decorative Leaf (Top Left Corner)
// //           Positioned(
// //             // top: 400,
// //             bottom: 390,
// //             right: -22,
// //             child: Transform.rotate(
// //               angle: -0.10, // Slight tilt
// //               child: Image.asset(
// //                 'assets/images/leaf (1).png',
// //                 width: 150,
// //                 height: 150,
// //                 fit: BoxFit.contain,
// //               ),
// //             ),
// //           ),

// //           // 🏷️ Centered Logo, Brand Name, Tagline & Subheading
// //           Center(
// //             child: Column(
// //               mainAxisAlignment: MainAxisAlignment.center,
// //               children: [
// //                 Image.asset(
// //                   'assets/images/illustration.png',
// //                   height: 350,
// //                   width: 350,
// //                   fit: BoxFit.contain,
// //                 ),
// //                 const SizedBox(height: 20),
// //                 const Text(
// //                   "Zamboree",
// //                   style: TextStyle(
// //                     fontSize: 34,
// //                     fontWeight: FontWeight.bold,
// //                     color: Colors.redAccent,
// //                     letterSpacing: 1.5,
// //                   ),
// //                 ),
// //                 const SizedBox(height: 6),
// //                 const Text(
// //                   "Fast • Reliable • Delivered with Care",
// //                   style: TextStyle(
// //                     fontSize: 14,
// //                     fontWeight: FontWeight.w600,
// //                     color: Colors.black87,
// //                     letterSpacing: 0.7,
// //                   ),
// //                 ),
// //                 const SizedBox(height: 12),
// //                 const Padding(
// //                   padding: EdgeInsets.symmetric(horizontal: 40.0),
// //                   child: Text(
// //                     "Empowering delivery partners with speed and trust — "
// //                     "because every package deserves to arrive with a smile.",
// //                     textAlign: TextAlign.center,
// //                     style: TextStyle(
// //                       fontSize: 13,
// //                       color: Colors.black54,
// //                       height: 1.5,
// //                     ),
// //                   ),
// //                 ),
// //               ],
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// // }

// // // 🎨 Simple Top Yellow Curve Painter
// // class _SplashCurvePainter extends CustomPainter {
// //   @override
// //   void paint(Canvas canvas, Size size) {
// //     final paint = Paint()
// //       ..shader = const LinearGradient(
// //         colors: [
// //           Color(0xFF19676E), // Blue-green start
// //           Color(0xFF4A2FBD), // Violet mid
// //           Color(0xFF40A798), // Teal-green end
// //         ],
// //         begin: Alignment.topLeft,
// //         end: Alignment.bottomRight,
// //       ).createShader(const Rect.fromLTWH(0.0, 0.0, 400.0, 400.0));
// //     final path = Path();

// //     path.lineTo(0, size.height * 0.75);
// //     path.quadraticBezierTo(
// //       size.width * 0.25,
// //       size.height * 0.9,
// //       size.width * 0.5,
// //       size.height * 0.75,
// //     );
// //     path.quadraticBezierTo(
// //       size.width * 0.75,
// //       size.height * 0.6,
// //       size.width,
// //       size.height * 0.75,
// //     );
// //     path.lineTo(size.width, 0);
// //     path.close();

// //     canvas.drawPath(path, paint);
// //   }

// //   @override
// //   bool shouldRepaint(CustomPainter oldDelegate) => false;
// // }

// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:get/get.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:zamboree/Controller/LocationController.dart';

// class SplashScreen extends StatefulWidget {
//   const SplashScreen({super.key});

//   @override
//   State<SplashScreen> createState() => _SplashScreenState();
// }

// class _SplashScreenState extends State<SplashScreen> {
//   @override
//   void initState() {
//     super.initState();
//     _initApp();
//   }

//   Future<void> _initApp() async {
//     await _handleLocationPermission();
//     _goNextScreen();
//   }

//   Future<void> _goNextScreen() async {
//     Timer(const Duration(seconds: 3), () {
//       Navigator.pushReplacementNamed(context, '/login');
//     });
//   }

//   Future<void> _handleLocationPermission() async {
//     bool serviceEnabled;
//     LocationPermission permission;

//     // Check GPS enabled
//     serviceEnabled = await Geolocator.isLocationServiceEnabled();
//     if (!serviceEnabled) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Please enable GPS / Location")),
//       );
//       return;
//     }

//     // Check Permission
//     permission = await Geolocator.checkPermission();

//     if (permission == LocationPermission.denied) {
//       permission = await Geolocator.requestPermission();
//     }

//     if (permission == LocationPermission.deniedForever) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text("Enable location permission from settings"),
//         ),
//       );
//       return;
//     }

//     // Get current location
//     Position position = await Geolocator.getCurrentPosition(
//       desiredAccuracy: LocationAccuracy.high,
//     );

//     // Update Controller immediately so Dashboard has it
//     Get.find<LocationController>().updateLocation(
//       position.latitude,
//       position.longitude,
//     );

//     // Save in SharedPreferences
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     await prefs.setDouble("latitude", position.latitude);
//     await prefs.setDouble("longitude", position.longitude);

//     print("Latitude: ${position.latitude}");
//     print("Longitude: ${position.longitude}");
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: Stack(
//         children: [
//           CustomPaint(
//             size: Size(MediaQuery.of(context).size.width, 170),
//             painter: _SplashCurvePainter(),
//           ),

//           Positioned(
//             bottom: 390,
//             right: -22,
//             child: Transform.rotate(
//               angle: -0.10,
//               child: Image.asset(
//                 'assets/images/leaf (1).png',
//                 width: 150,
//                 height: 150,
//               ),
//             ),
//           ),

//           Center(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center, 
//               children: [
//                 Image.asset(
//                   'assets/images/illustration.png',
//                   height: 350, 
//                   width: 350,
//                 ),
//                 const SizedBox(height: 20),
//                 const Text(
//                   "Zamboree",
//                   style: TextStyle(
//                     fontSize: 34,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.redAccent,
//                     letterSpacing: 1.5,
//                   ),
//                 ),
//                 const SizedBox(height: 6),
//                 const Text(
//                   "Fast • Reliable • Delivered with Care",
//                   style: TextStyle(
//                     fontSize: 14,
//                     fontWeight: FontWeight.w600,
//                     color: Colors.black87,
//                   ),
//                 ),
//                 const SizedBox(height: 12),
//                 const Padding(
//                   padding: EdgeInsets.symmetric(horizontal: 40.0),
//                   child: Text(
//                     "Empowering delivery partners with speed and trust — "
//                     "because every package deserves to arrive with a smile.",
//                     textAlign: TextAlign.center,
//                     style: TextStyle(
//                       fontSize: 13,
//                       color: Colors.black54,
//                       height: 1.5,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _SplashCurvePainter extends CustomPainter {
//   @override
//   void paint(Canvas canvas, Size size) {
//     final paint = Paint()
//       ..shader = const LinearGradient(
//         colors: [Color(0xFF19676E), Color(0xFF4A2FBD), Color(0xFF40A798)],
//         begin: Alignment.topLeft,
//         end: Alignment.bottomRight,
//       ).createShader(const Rect.fromLTWH(0.0, 0.0, 400.0, 400.0));

//     final path = Path();

//     path.lineTo(0, size.height * 0.75);
//     path.quadraticBezierTo(
//       size.width * 0.25,
//       size.height * 0.9,
//       size.width * 0.5,
//       size.height * 0.75,
//     );
//     path.quadraticBezierTo(
//       size.width * 0.75,
//       size.height * 0.6,
//       size.width,
//       size.height * 0.75,
//     );
//     path.lineTo(size.width, 0);
//     path.close();

//     canvas.drawPath(path, paint);
//   }

//   @override
//   bool shouldRepaint(CustomPainter oldDelegate) => false;
// }

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zamboree/Controller/LocationController.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initApp();
  }

  /// App init: Location + Token check
  Future<void> _initApp() async {
    await _handleLocationPermission();
    await Future.delayed(const Duration(seconds: 3));
    await _goNextScreen();
  }

  /// Decide next screen based on token
  Future<void> _goNextScreen() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    debugPrint("🔐 Splash Token: $token");

    if (token != null && token.isNotEmpty) {
      // Token present → Dashboard
      Navigator.pushReplacementNamed(context, '/dashboard');
    } else {
      // Token missing → Login
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  /// 🔹 Location handling (same as your logic)
  Future<void> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showSnack("Please enable GPS / Location");
      return;
    }

    permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      _showSnack("Enable location permission from settings");
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    /// Update GetX controller
    Get.find<LocationController>().updateLocation(
      position.latitude,
      position.longitude,
    );

    /// Save locally
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setDouble("latitude", position.latitude);
    await prefs.setDouble("longitude", position.longitude);

    debugPrint("📍 Lat: ${position.latitude}, Lng: ${position.longitude}");
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          /// Top Curve
          CustomPaint(
            size: Size(MediaQuery.of(context).size.width, 170),
            painter: _SplashCurvePainter(),
          ),

          /// 🍃 Leaf
          Positioned(
            bottom: 390,
            right: -22,
            child: Transform.rotate(
              angle: -0.10,
              child: Image.asset(
                'assets/images/leaf (1).png',
                width: 150,
                height: 150,
              ),
            ),
          ),

          /// 🎯 Center Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/illustration.png',
                  height: 350,
                  width: 350,
                ),
                const SizedBox(height: 20),
                const Text(
                  "Zamboree",
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: Colors.redAccent,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  "Fast • Reliable • Delivered with Care",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    "Empowering delivery partners with speed and trust — "
                    "because every package deserves to arrive with a smile.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.black54,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 🎨 Curve Painter (unchanged)
class _SplashCurvePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF19676E), Color(0xFF4A2FBD), Color(0xFF40A798)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(const Rect.fromLTWH(0, 0, 400, 400));

    final path = Path();
    path.lineTo(0, size.height * 0.75);
    path.quadraticBezierTo(
      size.width * 0.25,
      size.height * 0.9,
      size.width * 0.5,
      size.height * 0.75,
    );
    path.quadraticBezierTo(
      size.width * 0.75,
      size.height * 0.6,
      size.width,
      size.height * 0.75,
    );
    path.lineTo(size.width, 0);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
