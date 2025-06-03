import 'package:flutter/material.dart';
import 'package:flutter_skeleton/Screen/contact_screen.dart';
import 'package:flutter_skeleton/Screen/rewards_screen.dart';
import 'screen/profile_screen.dart';
import 'screen/login_screen.dart';
import 'screen/admin_dashboard.dart';
import 'screen/user_dashboard.dart';
import 'screen/rewards_screen.dart';
import 'screen/contact_screen.dart';


// TODO: Import your admin and user dashboard screens

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Tropical Funland',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        useMaterial3: true,
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/profile': (context) => const ProfileScreen(),
        // Add these after you create them:
        '/adminDashboard': (context) => const AdminDashboard(),
        '/userDashboard': (context) => const UserDashboard(),
        '/rewards': (context) => const RewardsScreen(),
        '/contact': (context) => const ContactUsScreen(),
      },
    );
  }
}
