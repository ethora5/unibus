import 'package:flutter/material.dart';

class DriverScheduleScreen extends StatelessWidget {
  const DriverScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('UNITEN Internal Shuttle Bus')),
      body: InteractiveViewer(
        minScale: 1,
        maxScale: 4,
        child: Center(
          child: Image.asset(
            'assets/images/bus_schedule.png',
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
