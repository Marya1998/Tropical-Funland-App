import 'package:flutter/material.dart';

class RewardsScreen extends StatelessWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          automaticallyImplyLeading: false,
          title: const Row(
            children: [
              Icon(Icons.close, color: Colors.black),
              SizedBox(width: 8),
              Text('Rewards', style: TextStyle(color: Colors.black)),
            ],
          ),
          bottom: const TabBar(
            labelColor: Colors.pink,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.pink,
            tabs: [
              Tab(text: 'Available'),
              Tab(text: 'History'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            AvailableRewards(),
            Center(child: Text("No past rewards")),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: 2,
          selectedItemColor: Colors.black,
          unselectedItemColor: Colors.grey,
          backgroundColor: Color(0xFFD4F0EC),
          onTap: (index) {
            // Example navigation
            if (index == 0) Navigator.pushReplacementNamed(context, '/');
            if (index == 1) Navigator.pushReplacementNamed(context, '/cart');
            if (index == 3) Navigator.pushReplacementNamed(context, '/profile');
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
            BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: ''),
            BottomNavigationBarItem(icon: Icon(Icons.emoji_events), label: ''),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: ''),
          ],
        ),
      ),
    );
  }
}

class AvailableRewards extends StatelessWidget {
  const AvailableRewards({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text("You received", style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        _rewardCard(
          image: 'assets/images/slush.jpg',
          title: 'Free 1 drink (slush) redemption at The Juice Bar',
          expiry: 'Valid until 1 June 2025',
        ),
        _rewardCard(
          image: 'assets/images/resort.jpg',
          title: '15% Discount off resort booking (limited availability)',
          expiry: 'Valid until 25 July 2025',
        ),
        const SizedBox(height: 20),
        const Text("Rewards Promotion", style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        _rewardCard(
          image: 'assets/images/suite.jpg',
          title: 'Grand Suite for 50% off',
          expiry: 'Valid until 1 August 2025',
        ),
      ],
    );
  }

  Widget _rewardCard({required String image, required String title, required String expiry}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Image.asset(image, width: 100, height: 100, fit: BoxFit.cover),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  Text(expiry, style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
