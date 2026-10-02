import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../theme/app_theme.dart';
import '../widgets/app_navigation.dart';

class ErrorState extends StatelessWidget {
  const ErrorState({super.key});
  @override
  Widget build(BuildContext c) => Scaffold(
      appBar: AppBar(title: const Text('SportSphere')),
      body: const Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Iconsax.warning_2, color: AppTheme.secondary, size: 48),
        SizedBox(height: 16),
        Text('Something went wrong',
            style: TextStyle(fontWeight: FontWeight.bold))
      ])),
      bottomNavigationBar: const AppNavigation(index: 0));
}
