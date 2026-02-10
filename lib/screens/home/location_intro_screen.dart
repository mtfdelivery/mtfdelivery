import 'package:flutter/material.dart';

class LocationIntroScreen extends StatelessWidget {
  const LocationIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Select Location")),
      body: const Center(child: Text("Location Selection Screen")),
    );
  }
}
