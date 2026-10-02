import 'package:flutter/material.dart';

/// Placeholder kept for backward compatibility.
/// Navigation is now managed by the top-level [_HomeShell] in main.dart.
class AppNavigation extends StatelessWidget {
  const AppNavigation({super.key, required this.index});
  final int index;
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
