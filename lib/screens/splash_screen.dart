import 'dart:async';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    // Navigate to Login after 3 seconds
    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacementNamed(context, '/login');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 🌕 Top Yellow Curved Background
          CustomPaint(
            size: Size(MediaQuery.of(context).size.width, 220),
            painter: _SplashCurvePainter(),
          ),

          // 🌿 Decorative Leaf (Top Left Corner)
          Positioned(
            // top: 400,
            bottom: 390,
            right: -22,
            child: Transform.rotate(
              angle: -0.10, // Slight tilt
              child: Image.asset(
                'assets/images/leaf (1).png',
                width: 150,
                height: 150,
                fit: BoxFit.contain,
              ),
            ),
          ),

          // 🏷️ Centered Logo, Brand Name, Tagline & Subheading
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/illustration.png',
                  height: 350,
                  width: 350,
                  fit: BoxFit.contain,
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
                    letterSpacing: 0.7,
                  ),
                ),
                const SizedBox(height: 12),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 40.0),
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

// 🎨 Simple Top Yellow Curve Painter
class _SplashCurvePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFF19676E), // Blue-green start
          Color(0xFF4A2FBD), // Violet mid
          Color(0xFF40A798), // Teal-green end
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(const Rect.fromLTWH(0.0, 0.0, 400.0, 400.0));
    final path = Path();

    path.lineTo(0, size.height * 0.75);
    path.quadraticBezierTo(size.width * 0.25, size.height * 0.9,
        size.width * 0.5, size.height * 0.75);
    path.quadraticBezierTo(size.width * 0.75, size.height * 0.6,
        size.width, size.height * 0.75);
    path.lineTo(size.width, 0);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
