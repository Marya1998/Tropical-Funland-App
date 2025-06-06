import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_skeleton/supabase_config.dart';

import 'package:flutter_skeleton/screen/login_screen.dart';
import 'package:flutter_skeleton/screen/admin_dashboard.dart';
import 'package:flutter_skeleton/screen/user_dashboard.dart';
import 'package:flutter_skeleton/screen/forgot_password_screen.dart';
import 'package:flutter_skeleton/screen/register_screen.dart';
import 'package:flutter_skeleton/screen/profile_screen.dart';
import 'package:flutter_skeleton/screen/rewards_screen.dart';
import 'package:flutter_skeleton/screen/orders_screen.dart';
import 'package:flutter_skeleton/screen/contact_us_screen.dart';

// Import new screens
import 'package:flutter_skeleton/screen/resorts_screen.dart';
import 'package:flutter_skeleton/screen/events_screen.dart';
import 'package:flutter_skeleton/screen/dining_screen.dart';
import 'package:flutter_skeleton/screen/shops_screen.dart';
import 'package:flutter_skeleton/screen/order_details_screen.dart';
import 'package:flutter_skeleton/screen/rate_and_review_screen.dart';
import 'package:flutter_skeleton/screen/edit_profile_screen.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.SUPABASE_URL,
    anonKey: SupabaseConfig.SUPABASE_ANON_KEY,
  );

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  User? _user;
  String? _userRole;

  @override
  void initState() {
    super.initState();
    Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;

      setState(() {
        _user = session?.user;
      });

      if (session != null && session.user != null && (event == AuthChangeEvent.signedIn || event == AuthChangeEvent.initialSession)) {
        try {
          final response = await Supabase.instance.client
              .from('users')
              .select('role')
              .eq('id', session.user!.id)
              .limit(1)
              .single(); // Use single() for a single record

          if (response != null) {
            setState(() {
              _userRole = response['role'] as String?;
            });
          } else {
            setState(() {
              _userRole = null;
            });
          }
        } on PostgrestException catch (e) {
          debugPrint('Error fetching user role (Postgrest): ${e.message}');
          setState(() {
            _userRole = null;
          });
        } catch (e) {
          debugPrint('Error fetching user role: $e');
          setState(() {
            _userRole = null;
          });
        }
      } else if (event == AuthChangeEvent.signedOut) {
        setState(() {
          _user = null;
          _userRole = null;
        });
      }
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tropical Funland',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) {
          if (_user == null) {
            return const LoginScreen();
          } else {
            if (_userRole == null) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            } else if (_userRole == 'admin') {
              return const AdminDashboard();
            } else if (_userRole == 'user') {
              return const UserDashboard();
            } else {
              return const Scaffold(
                body: Center(
                  child: Text('Unauthorized role or invalid user data.'),
                ),
              );
            }
          }
        },
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/forgot_password': (context) => const ForgotPasswordScreen(),
        '/adminDashboard': (context) => const AdminDashboard(),
        '/userDashboard': (context) => const UserDashboard(),
        '/profile': (context) => const ProfileScreen(),
        '/rewards': (context) => const RewardsScreen(),
        '/orders': (context) => const OrdersScreen(),
        '/contact_us': (context) => const ContactUsScreen(),
        // New Routes:
        '/resorts': (context) => const ResortsScreen(),
        '/events': (context) => const EventsScreen(),
        '/dining': (context) => const DiningScreen(),
        '/shops': (context) => const ShopsScreen(),
        '/orderDetails': (context) => const Text('Error: Should use push with arguments.'), // Should not be directly accessed
        '/rateAndReview': (context) => const Text('Error: Should use push with arguments.'), // Should not be directly accessed
        '/editProfile': (context) => const EditProfileScreen(),
      },
      // OnGenerateRoute for screens that require arguments like OrderDetailsScreen
      onGenerateRoute: (settings) {
        if (settings.name == '/orderDetails') {
          final args = settings.arguments;
          if (args is Map<String, dynamic>) {
            return MaterialPageRoute(builder: (context) => OrderDetailsScreen(order: args));
          }
        }
        if (settings.name == '/rateAndReview') {
          final args = settings.arguments;
          if (args is String) { // Assuming productId is passed as a string
            return MaterialPageRoute(builder: (context) => RateAndReviewScreen(productId: args));
          }
        }
        return null; // Let other routes handle
      },
    );
  }
}
