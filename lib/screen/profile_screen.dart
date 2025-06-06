import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_skeleton/screen/edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _userName = "Loading...";
  String _userEmail = "Loading...";
  String _userGender = "Loading...";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final User? currentUser = Supabase.instance.client.auth.currentUser;

      if (currentUser != null) {
        final response = await Supabase.instance.client
            .from('users')
            .select('email, role, name, gender')
            .eq('id', currentUser.id)
            .limit(1)
            .single();

        if (response != null) {
          setState(() {
            _userEmail = response['email'] as String? ?? "N/A";
            _userName = response['name'] as String? ?? (_userEmail.split('@')[0]);
            _userGender = response['gender'] as String? ?? "Not specified";
          });
        } else {
          setState(() {
            _userEmail = currentUser.email ?? "N/A (Auth)";
            _userName = currentUser.email?.split('@')[0] ?? "N/A";
            _userGender = "Not specified";
          });
        }
      } else {
        setState(() {
          _userName = "Not Logged In";
          _userEmail = "N/A";
          _userGender = "N/A";
        });
      }
    } on PostgrestException catch (e) {
      debugPrint('Error fetching user profile (Postgrest): ${e.message}');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading profile: ${e.message}")),
      );
      setState(() {
        _userName = "Error";
        _userEmail = "Error";
        _userGender = "Error";
      });
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading profile: $e")),
      );
      setState(() {
        _userName = "Error";
        _userEmail = "Error";
        _userGender = "Error";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    try {
      await Supabase.instance.client.auth.signOut();
      if (!mounted) return;
      // Navigate to login screen after logout
      Navigator.pushReplacementNamed(context, '/login');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Logged out successfully!")),
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Logout failed: ${e.message}")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("An unexpected error occurred during logout: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal[50],
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        // Removed the logout button from AppBar here, as it's now at the bottom
        // actions: [
        //   IconButton(
        //     icon: const Icon(Icons.logout),
        //     onPressed: _logout,
        //   ),
        // ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 60,
              backgroundColor: Colors.teal,
              child: Icon(Icons.person, size: 80, color: Colors.white),
            ),
            const SizedBox(height: 24),
            Text(
              "User: $_userName",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.teal[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _userEmail,
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 32),
            _buildProfileInfoCard(
              context,
              icon: Icons.email,
              label: 'Email',
              value: _userEmail,
            ),
            const SizedBox(height: 16),
            _buildProfileInfoCard(
              context,
              icon: Icons.people,
              label: 'Gender',
              value: _userGender,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () async {
                final bool? didUpdate = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const EditProfileScreen()),
                );
                if (didUpdate == true) {
                  _fetchUserProfile();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Edit Profile'),
            ),
            const SizedBox(height: 16), // Added space between buttons
            ElevatedButton(
              onPressed: _logout, // Call the logout function
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, // Distinct color for logout
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Logout'),
            ),
            const SizedBox(height: 24), // Keep extra padding at the bottom
          ],
        ),
      ),
    );
  }

  Widget _buildProfileInfoCard(BuildContext context, {required IconData icon, required String label, required String value}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        child: Row(
          children: [
            Icon(icon, color: Colors.teal, size: 28),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
