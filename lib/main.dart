import 'package:flutter/material.dart';
import 'auth/login.dart';
import 'auth/register.dart';
import 'screens/home.dart';
import 'screens/kyc.dart';
import 'screens/splash_screen.dart'; // ✅ correct path here

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Zamboree Delivery',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),

      // ✅ Start the app with splash screen
      initialRoute: '/splash',

      routes: {
        '/splash': (context) => const SplashScreen(),
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/kyc': (context) =>  KycPage(),
        '/dashboard': (context) => const Dashboard(title: 'Dashboard'),
      },
    );
  }
}
