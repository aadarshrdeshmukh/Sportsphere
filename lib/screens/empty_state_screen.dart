import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../theme/app_theme.dart';
import '../widgets/app_navigation.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({super.key});
  @override
  Widget build(BuildContext c) => Scaffold(
      appBar: AppBar(title: const Text('Favorites')),
      body: const Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Iconsax.heart, color: AppTheme.primary, size: 56),
        SizedBox(height: 16),
        Text('No favorites yet', style: TextStyle(fontWeight: FontWeight.bold))
      ])),
      bottomNavigationBar: const AppNavigation(index: 4));
}
