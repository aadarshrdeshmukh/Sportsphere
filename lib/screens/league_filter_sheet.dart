import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../models/sport_league.dart';
import '../theme/app_theme.dart';

/// A modal bottom sheet allowing users to select a league filter.
class LeagueFilterSheet extends StatefulWidget {
  const LeagueFilterSheet({super.key, required this.selected});
  final SportLeague selected;

  /// Shows the filter sheet and returns the selected league, or null if dismissed.
  static Future<SportLeague?> show(
          BuildContext context, SportLeague current) =>
      showModalBottomSheet<SportLeague>(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) => LeagueFilterSheet(selected: current),
      );

  @override
  State<LeagueFilterSheet> createState() => _LeagueFilterSheetState();
}

class _LeagueFilterSheetState extends State<LeagueFilterSheet> {
  late SportLeague _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.selected;
  }

  @override
  Widget build(BuildContext context) => SafeArea(
      child: SingleChildScrollView(
        child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('Filter by league',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ...supportedLeagues.map((league) {
                final isSelected = _selected.key == league.key;
                return ListTile(
                  title: Text(league.label),
                  subtitle: Text(league.sport),
                  leading: Icon(
                    isSelected
                        ? Iconsax.tick_circle
                        : Iconsax.record,
                    color: isSelected ? AppTheme.primary : AppTheme.outline,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  onTap: () => setState(() => _selected = league),
                );
              }),
              const SizedBox(height: 12),
              SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                      onPressed: () => Navigator.pop(context, _selected),
                      child: const Text('Apply')))
            ])),
      ));
}
