import 'package:flutter/material.dart';

class ShopsScreen extends StatelessWidget {
  const ShopsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shops'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.store, size: 80, color: Colors.teal),
              SizedBox(height: 20),
              Text(
                'Discover unique items at our Shops!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                'Explore our retail outlets and specialty stores. (Functionality to be added)',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              SizedBox(height: 30),
              // ElevatedButton(
              //   onPressed: () { /* TODO: Implement shop details */ },
              //   child: const Text('Browse Shops'),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
