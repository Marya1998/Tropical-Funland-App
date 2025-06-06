import 'package:flutter/material.dart';

class DiningScreen extends StatelessWidget {
  const DiningScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dining'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.restaurant, size: 80, color: Colors.teal),
              SizedBox(height: 20),
              Text(
                'Indulge in our exquisite Dining options!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                'Browse menus and make reservations at our restaurants. (Functionality to be added)',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              SizedBox(height: 30),
              // ElevatedButton(
              //   onPressed: () { /* TODO: Implement dining options */ },
              //   child: const Text('Explore Restaurants'),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
