import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';
import '../models/sport_league.dart';
import '../models/sport_match.dart';
import '../repositories/sports_repository.dart';
import '../state/sports_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';

class Schedule extends StatefulWidget {
  const Schedule({super.key, required this.repository});
  final SportsRepository repository;

  @override
  State<Schedule> createState() => _ScheduleState();
}

class _ScheduleState extends State<Schedule> {
  late final SportsController _sports;
  int _statusFilterIndex = 0; // 0: All, 1: Live, 2: Upcoming, 3: Finished

  @override
  void initState() {
    super.initState();
    _sports = SportsController(widget.repository)..refresh();
  }

  @override
  void dispose() {
    _sports.dispose();
    super.dispose();
  }

  Future<void> _pickCustomDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _sports.selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      _sports.selectDate(picked);
    }
  }

  void _jumpToNextWeekend() {
    final now = DateTime.now();
    int daysUntilSaturday = (DateTime.saturday - now.weekday) % 7;
    if (daysUntilSaturday == 0) daysUntilSaturday = 7;
    final nextSat = now.add(Duration(days: daysUntilSaturday));
    _sports.selectDate(nextSat);
  }

  List<SportMatch> _filteredMatches() {
    if (_statusFilterIndex == 1) {
      return _sports.matches.where((m) => m.isLive).toList();
    } else if (_statusFilterIndex == 2) {
      return _sports.matches.where((m) => !m.isLive && !m.isCompleted).toList();
    } else if (_statusFilterIndex == 3) {
      return _sports.matches.where((m) => m.isCompleted).toList();
    }
    return _sports.matches;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: _sports,
      builder: (context, _) {
        final matches = _filteredMatches();

        return Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: const Text('Schedule'),
            actions: [
              IconButton(
                tooltip: 'Filter competitions & status',
                onPressed: _showFilterSheet,
                icon: Badge(
                  isLabelVisible:
                      _sports.selectedLeague != null || _statusFilterIndex != 0,
                  smallSize: 8,
                  child: const Icon(Iconsax.setting_4),
                ),
              ),
              IconButton(
                tooltip: 'Pick custom date',
                onPressed: _pickCustomDate,
                icon: const Icon(Iconsax.calendar_2),
              ),
              IconButton(
                tooltip: 'Refresh schedule',
                onPressed: _sports.isLoading ? null : _sports.refresh,
                icon: const Icon(Iconsax.refresh_2),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: _sports.refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              children: [
                // ── 1. Date Selector Strip ──
                _DateSelector(
                  selected: _sports.selectedDate,
                  onSelected: _sports.selectDate,
                ),
                const SizedBox(height: 16),

                // ── 2. Filter Bar (opens bottom sheet) ──
                _buildFilterBar(colorScheme),
                const SizedBox(height: 18),

                // ── 3. Cache / Error Notice ──
                if (_sports.showingCachedData || _sports.error != null) ...[
                  _DataNotice(
                    showingCache: _sports.showingCachedData,
                    message: _sports.error,
                  ),
                  const SizedBox(height: 14),
                ],

                // ── 4. Section Heading with Date & Status Filter ──
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat('EEEE, d MMMM')
                                .format(_sports.selectedDate),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _sports.selectedLeague?.label ?? 'All Sports',
                            style: TextStyle(
                              fontSize: 13,
                              color: colorScheme.onSurface
                                  .withValues(alpha: 0.55),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_sports.matches.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_sports.matches.length} matches',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),

                // ── 5. Match List or Enhanced Empty State ──
                if (_sports.isLoading && _sports.matches.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 72),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (matches.isEmpty) ...[
                  // Enhanced Empty State Container
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: colorScheme.outline, width: 1),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colorScheme.primaryContainer,
                          ),
                          child: Icon(
                            Iconsax.calendar,
                            size: 26,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          _statusFilterIndex != 0
                              ? 'No ${_statusFilterIndex == 1 ? "live" : _statusFilterIndex == 2 ? "upcoming" : "finished"} matches'
                              : 'No matches scheduled',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'No fixtures found for ${DateFormat('d MMMM').format(_sports.selectedDate)} in ${_sports.selectedLeague?.label ?? 'All Competitions'}.',
                          style: TextStyle(
                            fontSize: 13,
                            color: colorScheme.onSurface.withValues(alpha: 0.55),
                            height: 1.35,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 18),

                        // Action Shortcuts
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: [
                            FilledButton.tonal(
                              onPressed: () => _sports.selectDate(DateTime.now()),
                              style: FilledButton.styleFrom(
                                minimumSize: const Size(0, 38),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text(
                                'Check Today',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            OutlinedButton(
                              onPressed: _jumpToNextWeekend,
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(0, 38),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text(
                                'Weekend Games',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: _pickCustomDate,
                              icon: const Icon(Iconsax.calendar_1, size: 16),
                              label: const Text(
                                'Calendar',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(0, 38),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // ── 7. Matchday Previews & Trending Stories (Keeps screen rich & alive) ──
                  if (_sports.articles.isNotEmpty) ...[
                    const SizedBox(height: 26),
                    SectionHeader(
                      title: 'Matchday Previews & News',
                      action: 'See all',
                      onAction: () => Navigator.pushNamed(context, '/news'),
                    ),
                    const SizedBox(height: 12),
                    ..._sports.articles.take(3).map(
                          (article) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: NewsCard(
                              cat: article.category,
                              age: _age(article.publishedAt),
                              title: article.title,
                              imageUrl: article.imageUrl,
                              onTap: () => Navigator.pushNamed(
                                context,
                                '/article',
                                arguments: article,
                              ),
                            ),
                          ),
                        ),
                  ],
                ] else
                  ...matches.map(_matchTile),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showFilterSheet() async {
    final liveCount = _sports.matches.where((m) => m.isLive).length;
    final upcomingCount =
        _sports.matches.where((m) => !m.isLive && !m.isCompleted).length;
    final finishedCount = _sports.matches.where((m) => m.isCompleted).length;

    final result = await showModalBottomSheet<_FilterResult>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ScheduleFilterSheet(
        selectedLeague: _sports.selectedLeague,
        statusFilterIndex: _statusFilterIndex,
        totalCount: _sports.matches.length,
        liveCount: liveCount,
        upcomingCount: upcomingCount,
        finishedCount: finishedCount,
      ),
    );

    if (result != null) {
      _sports.selectLeague(result.league);
      setState(() => _statusFilterIndex = result.statusIndex);
    }
  }

  Widget _buildFilterBar(ColorScheme colorScheme) {
    final leagueLabel = _sports.selectedLeague?.label ?? 'All Sports';
    final statusLabels = ['All', 'Live', 'Upcoming', 'Finished'];
    final statusLabel = statusLabels[_statusFilterIndex];
    final hasActiveFilter =
        _sports.selectedLeague != null || _statusFilterIndex != 0;

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
                  ? colorScheme.primary.withValues(alpha: 0.4)
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
                    : (isDark ? Colors.white70 : colorScheme.onSurface.withValues(alpha: 0.7)),
              ),
              const SizedBox(width: 10),
              // League chip
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _sports.selectedLeague != null
                      ? (isDark ? colorScheme.primary : colorScheme.primaryContainer)
                      : colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  leagueLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _sports.selectedLeague != null
                        ? (isDark ? Colors.white : colorScheme.primary)
                        : (isDark ? Colors.white70 : colorScheme.onSurface.withValues(alpha: 0.8)),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              // Status chip
              if (_statusFilterIndex != 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusFilterIndex == 1
                        ? AppTheme.liveContainer
                        : (isDark ? colorScheme.primary : colorScheme.primaryContainer),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _statusFilterIndex == 1
                          ? AppTheme.live
                          : (isDark ? Colors.white : colorScheme.primary),
                    ),
                  ),
                ),
              const Spacer(),
              Icon(
                Iconsax.arrow_down_1,
                size: 20,
                color: isDark ? Colors.white60 : colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _matchTile(SportMatch match) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: MatchCard(
          league: _sports.selectedLeague?.label ?? match.league,
          home: match.home.name,
          away: match.away.name,
          homeLogo: match.home.logoUrl,
          awayLogo: match.away.logoUrl,
          time: match.isCompleted
              ? 'Final'
              : match.isLive
                  ? match.status
                  : DateFormat.jm().format(match.startTime.toLocal()),
          hs: match.homeScore,
          as: match.awayScore,
          live: match.isLive,
          isFinal: match.isCompleted,
          onTap: () => Navigator.pushNamed(context, '/match', arguments: match),
        ),
      );

  String _age(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class _DateSelector extends StatelessWidget {
  const _DateSelector({required this.selected, required this.onSelected});
  final DateTime selected;
  final ValueChanged<DateTime> onSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final today = DateTime.now();
    // Center the 7 days window around selected date or today
    final start = DateTime(today.year, today.month, today.day)
        .subtract(const Duration(days: 2));

    final days = List.generate(7, (i) => start.add(Duration(days: i)));

    return Row(
      children: [
        for (final (i, day) in days.indexed) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(
            child: Semantics(
              button: true,
              selected: _sameDay(day, selected),
              label: DateFormat('EEE d MMM').format(day),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => onSelected(day),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    height: 74,
                    decoration: BoxDecoration(
                      color: _sameDay(day, selected)
                          ? colorScheme.primary
                          : colorScheme.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _sameDay(day, selected)
                            ? colorScheme.primary
                            : colorScheme.outline,
                        width: 1,
                      ),
                      boxShadow: _sameDay(day, selected)
                          ? [
                              BoxShadow(
                                color: colorScheme.primary.withValues(alpha: 0.25),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          DateFormat('EEE').format(day).toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                            color: _sameDay(day, selected)
                                ? Colors.white
                                : colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${day.day}',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: _sameDay(day, selected)
                                ? Colors.white
                                : colorScheme.onSurface,
                          ),
                        ),
                        if (_sameDay(day, today)) ...[
                          const SizedBox(height: 3),
                          Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _sameDay(day, selected)
                                  ? Colors.white
                                  : colorScheme.primary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  bool _sameDay(DateTime first, DateTime second) =>
      first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;
}

class _FilterResult {
  final SportLeague? league;
  final int statusIndex;
  const _FilterResult({this.league, required this.statusIndex});
}

class _ScheduleFilterSheet extends StatefulWidget {
  const _ScheduleFilterSheet({
    required this.selectedLeague,
    required this.statusFilterIndex,
    required this.totalCount,
    required this.liveCount,
    required this.upcomingCount,
    required this.finishedCount,
  });
  final SportLeague? selectedLeague;
  final int statusFilterIndex;
  final int totalCount;
  final int liveCount;
  final int upcomingCount;
  final int finishedCount;

  @override
  State<_ScheduleFilterSheet> createState() => _ScheduleFilterSheetState();
}

class _ScheduleFilterSheetState extends State<_ScheduleFilterSheet> {
  late SportLeague? _selectedLeague;
  late int _statusIndex;

  @override
  void initState() {
    super.initState();
    _selectedLeague = widget.selectedLeague;
    _statusIndex = widget.statusFilterIndex;
  }

  bool get _hasChanges =>
      _selectedLeague?.key != widget.selectedLeague?.key ||
      _statusIndex != widget.statusFilterIndex;

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
                  'Filters',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => setState(() {
                    _selectedLeague = null;
                    _statusIndex = 0;
                  }),
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
                      onTap: () =>
                          setState(() => _selectedLeague = league),
                      colorScheme: colorScheme,
                    )),
              ],
            ),
            const SizedBox(height: 22),

            // ── Match Status Section ──
            Text(
              'MATCH STATUS',
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
                _buildStatusChip(
                  label: 'All',
                  count: widget.totalCount,
                  index: 0,
                  colorScheme: colorScheme,
                ),
                if (widget.liveCount > 0)
                  _buildStatusChip(
                    label: 'Live',
                    count: widget.liveCount,
                    index: 1,
                    colorScheme: colorScheme,
                    isLive: true,
                  ),
                if (widget.upcomingCount > 0)
                  _buildStatusChip(
                    label: 'Upcoming',
                    count: widget.upcomingCount,
                    index: 2,
                    colorScheme: colorScheme,
                  ),
                if (widget.finishedCount > 0)
                  _buildStatusChip(
                    label: 'Finished',
                    count: widget.finishedCount,
                    index: 3,
                    colorScheme: colorScheme,
                  ),
              ],
            ),
            const SizedBox(height: 28),

            // ── Apply Button ──
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(
                  context,
                  _FilterResult(
                    league: _selectedLeague,
                    statusIndex: _statusIndex,
                  ),
                ),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  _hasChanges ? 'Apply Filters' : 'Done',
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
                Icon(icon, size: 15,
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

  Widget _buildStatusChip({
    required String label,
    required int count,
    required int index,
    required ColorScheme colorScheme,
    bool isLive = false,
  }) {
    final isSelected = _statusIndex == index;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(100),
        onTap: () => setState(() => _statusIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: isSelected
                ? (isLive ? AppTheme.live : colorScheme.primary)
                : colorScheme.surface,
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: isSelected
                  ? (isLive ? AppTheme.live : colorScheme.primary)
                  : colorScheme.outline,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isLive && !isSelected) ...[
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.live,
                  ),
                ),
              ],
              Text(
                '$label ($count)',
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

class _DataNotice extends StatelessWidget {
  const _DataNotice({required this.showingCache, this.message});
  final bool showingCache;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            showingCache ? Iconsax.cloud_cross : Iconsax.info_circle,
            size: 18,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              showingCache
                  ? 'Showing saved schedule — pull down to retry.'
                  : message ?? 'Unable to reach live schedule.',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
