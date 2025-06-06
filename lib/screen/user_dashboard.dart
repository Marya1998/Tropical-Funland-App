import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_skeleton/screen/resorts_screen.dart';
import 'package:flutter_skeleton/screen/events_screen.dart';
import 'package:flutter_skeleton/screen/dining_screen.dart';
import 'package:flutter_skeleton/screen/shops_screen.dart';
import 'package:flutter_skeleton/screen/orders_screen.dart';
import 'package:flutter_skeleton/screen/rewards_screen.dart';
import 'package:flutter_skeleton/screen/profile_screen.dart';
import 'package:flutter_skeleton/screen/admin_dashboard.dart';

class UserDashboard extends StatefulWidget {
  const UserDashboard({super.key});

  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  final TextEditingController _searchController = TextEditingController();
  int _selectedIndex = 0;
  String _currentUserName = 'Guest';
  String _currentUserId = '';
  String _currentUserRole = 'user'; // Default role

  final List<Widget> _widgetOptions = [];

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
    _initializeWidgetOptions();
  }

  void _initializeWidgetOptions() {
    _widgetOptions.clear();
    _widgetOptions.addAll([
      _buildHomeScreen(),
      const OrdersScreen(),
      const RewardsScreen(),
      const ProfileScreen(),
    ]);

    if (_currentUserRole == 'admin') {
      _widgetOptions.add(const AdminDashboard());
    }
  }

  Future<void> _fetchUserProfile() async {
    final User? user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      _currentUserId = user.id;
      try {
        final response = await Supabase.instance.client
            .from('users')
            .select('name, role')
            .eq('id', user.id)
            .single();

        if (response != null) {
          if (!mounted) return;
          setState(() {
            _currentUserName = response['name'] as String? ?? user.email?.split('@')[0] ?? 'User';
            _currentUserRole = response['role'] as String? ?? 'user';
            _initializeWidgetOptions();
          });
        }
      } catch (e) {
        debugPrint('Error fetching user profile: $e');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading user data: ${e.toString()}')),
        );
      }
    } else {
      if (!mounted) return;
      setState(() {
        _currentUserName = 'Guest';
        _currentUserRole = 'user';
        _initializeWidgetOptions();
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tropical Funland'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notifications tapped!')),
              );
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _widgetOptions,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          const BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag),
            label: 'Orders',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.card_giftcard),
            label: 'Rewards',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
          if (_currentUserRole == 'admin')
            const BottomNavigationBarItem(
              icon: Icon(Icons.admin_panel_settings),
              label: 'Admin',
            ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.teal,
        unselectedItemColor: Colors.grey,
        backgroundColor: const Color(0xFFD4F0EC),
        type: BottomNavigationBarType.fixed,
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _buildHomeScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              'Hello $_currentUserName,',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.teal[800]),
            ),
          ),
          const SizedBox(height: 16),
          // Search Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(10),
            ),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search products',
                border: InputBorder.none,
                icon: Icon(Icons.search, color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Categories',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal[800]),
          ),
          const SizedBox(height: 16),
          _buildCategoryGrid(context),
          const SizedBox(height: 24),
          Text(
            'Popular Products',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal[800]),
          ),
          const SizedBox(height: 16),
          _buildPopularProducts(), // This will now be text-only
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildCategoryGrid(BuildContext context) {
    final List<Map<String, dynamic>> categories = [
      {'name': 'Resorts', 'icon': Icons.hotel, 'route': '/resorts'},
      {'name': 'Shows & Events', 'icon': Icons.event, 'route': '/events'},
      {'name': 'Dining', 'icon': Icons.restaurant, 'route': '/dining'},
      {'name': 'Shops', 'icon': Icons.store, 'route': '/shops'},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
        childAspectRatio: 1.8,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return GestureDetector(
          onTap: () {
            if (!mounted) return;
            switch (category['route']) {
              case '/resorts':
                Navigator.push(context, MaterialPageRoute(builder: (context) => const ResortsScreen()));
                break;
              case '/events':
                Navigator.push(context, MaterialPageRoute(builder: (context) => const EventsScreen()));
                break;
              case '/dining':
                Navigator.push(context, MaterialPageRoute(builder: (context) => const DiningScreen()));
                break;
              case '/shops':
                Navigator.push(context, MaterialPageRoute(builder: (context) => const ShopsScreen()));
                break;
              default:
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Navigation for ${category['name']} not implemented yet.')),
                );
            }
          },
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(category['icon'] as IconData, size: 35, color: Colors.teal),
                  const SizedBox(height: 6),
                  Text(
                    category['name'] as String,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPopularProducts() {
    String searchQuery = _searchController.text.trim().toLowerCase();

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: Supabase.instance.client
          .from('products')
          .stream(primaryKey: ['id'])
          .eq('status_active', true),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        List<Map<String, dynamic>> products = snapshot.data ?? [];

        if (searchQuery.isNotEmpty) {
          products = products.where((product) {
            final String name = (product['name'] as String? ?? '').toLowerCase();
            final String category = (product['category'] as String? ?? '').toLowerCase();
            final String description = (product['description'] as String? ?? '').toLowerCase();
            return name.contains(searchQuery) ||
                category.contains(searchQuery) ||
                description.contains(searchQuery);
          }).toList();
        }

        if (products.isEmpty) {
          return const Center(child: Text('No popular products available.'));
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16.0,
            mainAxisSpacing: 16.0,
            // CHANGED THIS LINE TO GIVE MORE VERTICAL SPACE FOR CONTENT
            childAspectRatio: 1.0, // Was 2.5, which was too short. 1.0 makes it a square.
            // Adjust as needed (e.g., 1.1, 1.2 if 1.0 is too tall).
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            String name = product['name'] ?? 'Product Name';
            double price = (product['price'] as num?)?.toDouble() ?? 0.0;
            // Removed imageUrl and isValidImageUrl since we are not displaying images

            return Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: InkWell(
                onTap: () {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Tapped on ${product['name']}! (Details coming soon)')),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'RM ${price.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}