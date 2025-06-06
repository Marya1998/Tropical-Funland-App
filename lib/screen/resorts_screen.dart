import 'package:flutter/material.dart';

class ResortsScreen extends StatelessWidget {
  const ResortsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resorts'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.hotel, size: 80, color: Colors.teal),
              SizedBox(height: 20),
              Text(
                'Welcome to our Resorts section!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                'Here you will find a list of rooms and booking options. (Functionality to be added)',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              SizedBox(height: 30),
              // Placeholder for a "Book Now" button or a list of rooms
              // ElevatedButton(
              //   onPressed: () { /* TODO: Implement booking flow */ },
              //   child: const Text('Book a Room'),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
