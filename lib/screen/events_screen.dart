import 'package:flutter/material.dart';

class EventsScreen extends StatelessWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shows & Events'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.event, size: 80, color: Colors.teal),
              SizedBox(height: 20),
              Text(
                'Check out our exciting Shows & Events!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                'Details about upcoming performances and special events will appear here. (Functionality to be added)',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              SizedBox(height: 30),
              // ElevatedButton(
              //   onPressed: () { /* TODO: Implement event details */ },
              //   child: const Text('View Events'),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
