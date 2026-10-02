import 'package:flutter/material.dart';
import '../widgets/app_navigation.dart';

class Loading extends StatelessWidget {
  const Loading({super.key});
  @override
  Widget build(BuildContext c) => Scaffold(
      appBar: AppBar(title: const Text('SportSphere')),
      body: const Center(child: CircularProgressIndicator()),
      bottomNavigationBar: const AppNavigation(index: 0));
}
