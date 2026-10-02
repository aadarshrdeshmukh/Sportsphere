import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';
import '../models/sport_league.dart';
import '../models/sport_match.dart';
import '../repositories/sports_repository.dart';
import '../state/live_scores_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';
import '../widgets/app_navigation.dart';

class Live extends StatefulWidget {
  const Live({super.key, required this.repository});
  final SportsRepository repository;

  @override
  State<Live> createState() => _LiveState();
}

class _LiveState extends State<Live> {
  late final LiveScoresController _scores;

  @override
  void initState() {
    super.initState();
    _scores = LiveScoresController(widget.repository)
      ..refresh()
      ..startPolling();
  }

  @override
  void dispose() {
    _scores.dispose();
    super.dispose();
  }

  Future<void> _showFilterSheet() async {
    final result = await showModalBottomSheet<SportLeague?>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _LiveFilterSheet(
        selectedLeague: _scores.selectedLeague,
      ),
    );

    if (result != _scores.selectedLeague) {
      _scores.selectLeague(result);
    }
  }

  Widget _buildFilterBar(ColorScheme colorScheme) {
    final leagueLabel = _scores.selectedLeague?.label ?? 'All Sports';
    final hasActiveFilter = _scores.selectedLeague != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _showFilterSheet,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: hasActiveFilter
                  ? (isDark ? Colors.white54 : colorScheme.primary.withValues(alpha: 0.4))
                  : colorScheme.outline,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Iconsax.setting_4,
                size: 18,
                color: hasActiveFilter
                    ? (isDark ? Colors.white : colorScheme.primary)
                    : (isDark ? Colors.white70 : colorScheme.onSurface.withValues(alpha: 0.5)),
              ),
              const SizedBox(width: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _scores.selectedLeague != null
                      ? (isDark ? Colors.white.withValues(alpha: 0.15) : colorScheme.primaryContainer)
                      : colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  leagueLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _scores.selectedLeague != null
                        ? (isDark ? Colors.white : colorScheme.primary)
                        : (isDark ? Colors.white70 : colorScheme.onSurface.withValues(alpha: 0.7)),
                  ),
                ),
              ),
              const Spacer(),
              Icon(
                Iconsax.arrow_down_1,
                size: 20,
                color: isDark ? Colors.white60 : colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: _scores,
      builder: (context, _) => DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: const Text('Live & Scores'),
            actions: [
              IconButton(
                tooltip: 'Filter by league',
                onPressed: _showFilterSheet,
                icon: Badge(
                  isLabelVisible: _scores.selectedLeague != null,
                  smallSize: 8,
                  child: const Icon(Iconsax.setting_4),
                ),
              ),
              IconButton(
                tooltip: 'Refresh scores',
                onPressed: _scores.isLoading ? null : _scores.refresh,
                icon: const Icon(Iconsax.refresh_2),
              ),
            ],
            bottom: TabBar(
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Live'),
                      if (_scores.live.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppTheme.live,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${_scores.live.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Tab(text: 'Upcoming'),
                const Tab(text: 'Finished'),
              ],
            ),
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
                child: _buildFilterBar(colorScheme),
              ),
                if (_scores.showingCachedData || _scores.error != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
                    child: _ScoreNotice(
                      cached: _scores.showingCachedData,
                      error: _scores.error,
                    ),
                  ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _scoreList('live', _scores.live),
                      _scoreList('upcoming', _scores.upcoming),
                      _scoreList('finished', _scores.finished),
                    ],
                  ),
                ),
              ],
            ),
            bottomNavigationBar: const AppNavigation(index: 3),
          ),
        ),
      );
  }

  Widget _scoreList(String group, List<SportMatch> matches) => RefreshIndicator(
        onRefresh: _scores.refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          children: [
            if (_scores.isLoading && _scores.matches.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 72),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (matches.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 48),
                child: AppEmptyState(
                  title: _emptyTitle(group),
                  message: 'Choose another competition or pull down to refresh.',
                  icon: _emptyIcon(group),
                ),
              )
            else
              ...matches.map(_matchCard),
            const SizedBox(height: 16),
          ],
        ),
      );

  Widget _matchCard(SportMatch match) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.pushNamed(context, '/match', arguments: match),
          child: MatchCard(
            league: _scores.selectedLeague?.label ?? match.league,
            home: match.home.name,
            away: match.away.name,
            hs: match.homeScore,
            as: match.awayScore,
            time: match.isCompleted
                ? 'Final'
                : match.isLive
                    ? match.status
                    : DateFormat.jm().format(match.startTime.toLocal()),
            live: match.isLive,
          ),
        ),
      );

  IconData _emptyIcon(String group) => switch (group) {
        'live' => Iconsax.activity,
        'upcoming' => Iconsax.calendar_tick,
        _ => Iconsax.cup,
      };

  String _emptyTitle(String group) => switch (group) {
        'live' => 'No live games in progress',
        'upcoming' => 'No upcoming matches found',
        _ => 'No finished matches found',
      };
}

class _LiveFilterSheet extends StatefulWidget {
  const _LiveFilterSheet({
    required this.selectedLeague,
  });

  final SportLeague? selectedLeague;

  @override
  State<_LiveFilterSheet> createState() => _LiveFilterSheetState();
}

class _LiveFilterSheetState extends State<_LiveFilterSheet> {
  late SportLeague? _selectedLeague;

  @override
  void initState() {
    super.initState();
    _selectedLeague = widget.selectedLeague;
  }

  bool get _hasChanges =>
      _selectedLeague?.key != widget.selectedLeague?.key;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Drag Handle ──
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: colorScheme.onSurface.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // ── Title Row ──
            Row(
              children: [
                Icon(Iconsax.setting_4, size: 20, color: colorScheme.primary),
                const SizedBox(width: 8),
                const Text(
                  'Filter Scores by League',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => setState(() => _selectedLeague = null),
                  child: const Text(
                    'Reset',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Competition Section ──
            Text(
              'COMPETITION',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: colorScheme.onSurface.withValues(alpha: 0.45),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildFilterChip(
                  label: 'All Sports',
                  icon: Iconsax.cup,
                  isSelected: _selectedLeague == null,
                  onTap: () => setState(() => _selectedLeague = null),
                  colorScheme: colorScheme,
                ),
                ...supportedLeagues.map((league) => _buildFilterChip(
                      label: league.label,
                      isSelected: _selectedLeague?.key == league.key,
                      onTap: () => setState(() => _selectedLeague = league),
                      colorScheme: colorScheme,
                    )),
              ],
            ),
            const SizedBox(height: 28),

            // ── Apply Button ──
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context, _selectedLeague),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  _hasChanges ? 'Apply Filter' : 'Done',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
    IconData? icon,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(100),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: isSelected ? colorScheme.primary : colorScheme.surface,
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: isSelected ? colorScheme.primary : colorScheme.outline,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon,
                    size: 15,
                    color: isSelected ? Colors.white : colorScheme.onSurface),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected ? Colors.white : colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScoreNotice extends StatelessWidget {
  const _ScoreNotice({required this.cached, this.error});
  final bool cached;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainerHigh : colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
        border: isDark ? Border.all(color: Colors.white24, width: 1) : null,
      ),
      child: Row(
        children: [
          Icon(
            cached ? Iconsax.cloud_cross : Iconsax.info_circle,
            size: 18,
            color: isDark ? Colors.white : colorScheme.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              cached
                  ? 'Showing saved scores — pull down to retry.'
                  : error ?? 'Unable to refresh scores.',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
