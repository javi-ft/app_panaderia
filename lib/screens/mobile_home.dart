import 'package:flutter/material.dart';

class MobileHome extends StatelessWidget {
  const MobileHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi App Móvil'),
      ),
      body: const Center(
        child: Text('Versión Móvil de la App'),
      ),
    );
  }
}