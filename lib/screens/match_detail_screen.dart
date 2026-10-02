import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';
import '../models/sport_league.dart';
import '../models/sport_match.dart';
import '../repositories/sports_repository.dart';
import '../state/favorites_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';

class Match extends StatefulWidget {
  const Match({super.key, required this.repository, required this.favorites});
  final SportsRepository repository;
  final FavoritesController favorites;

  @override
  State<Match> createState() => _MatchState();
}

class _MatchState extends State<Match> {
  Future<Map<String, dynamic>>? _summary;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final match = ModalRoute.of(context)?.settings.arguments as SportMatch?;
    if (match != null && _summary == null) _summary = _loadSummary(match);
  }

  Future<Map<String, dynamic>> _loadSummary(SportMatch match) {
    final league = supportedLeagues
            .where((item) => match.league.contains(item.league))
            .firstOrNull ??
        supportedLeagues.first;
    return widget.repository.matchSummary(league, match.id);
  }

  @override
  Widget build(BuildContext context) {
    final match = ModalRoute.of(context)?.settings.arguments as SportMatch?;
    if (match == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Match Detail')),
        body: const AppEmptyState(
          title: 'No match selected',
          message: 'Open a match from schedule or live scores.',
        ),
      );
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppTheme.bg,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _hero(match),
              const Material(
                color: Colors.white,
                child: TabBar(
                  tabs: [
                    Tab(text: 'Overview'),
                    Tab(text: 'Stats'),
                    Tab(text: 'Timeline'),
                  ],
                ),
              ),
              Expanded(
                child: FutureBuilder<Map<String, dynamic>>(
                  future: _summary,
                  builder: (context, snapshot) {
                    final summary = snapshot.data ?? const {};
                    return TabBarView(
                      children: [
                        _overview(match, summary, snapshot.connectionState),
                        _stats(summary),
                        _timeline(summary),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: const BottomNav(index: 3),
      ),
    );
  }

  Widget _hero(SportMatch match) {
    final title = _leagueLabel(match.league);
    final status = match.isCompleted
        ? 'FT'
        : match.isLive
            ? match.status
            : DateFormat('EEE, d MMM').format(match.startTime.toLocal());
    final score = match.homeScore.isEmpty && match.awayScore.isEmpty
        ? '-'
        : '${match.homeScore.isEmpty ? '-' : match.homeScore} - '
            '${match.awayScore.isEmpty ? '-' : match.awayScore}';

    return Container(
      color: AppTheme.primary,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 16),
      child: Column(
        children: [
          Row(
            children: [
              _heroIcon(Iconsax.arrow_left, 'Back',
                  () => Navigator.maybePop(context)),
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ),
              _heroIcon(Iconsax.export_1, 'Share', () {}),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _heroTeam(match.home),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      score,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 38,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.13),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.22)),
                      ),
                      child: Text(
                        status,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _heroTeam(match.away),
            ],
          ),
          if (match.venue.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              match.venue,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8), fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }

  Widget _heroTeam(dynamic team) => Expanded(
        child: Column(
          children: [
            TeamBadge(name: team.name, logoUrl: team.logoUrl, size: 54),
            const SizedBox(height: 7),
            Text(
              team.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      );

  Widget _heroIcon(IconData icon, String tooltip, VoidCallback onPressed) =>
      IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.tightFor(width: 30, height: 30),
        icon: Icon(icon, color: Colors.white, size: 21),
      );

  Widget _overview(
      SportMatch match, Map<String, dynamic> summary, ConnectionState state) {
    final events = _events(summary);
    final nextFixture = _nextFixture(summary);
    return RefreshIndicator(
      onRefresh: () async => setState(() => _summary = _loadSummary(match)),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
        children: [
          _sectionTitle('Key events'),
          const SizedBox(height: 8),
          if (state == ConnectionState.waiting)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (events.isEmpty)
            _emptyPanel('No key events have been posted yet.')
          else
            _eventPanel(events),
          if (nextFixture != null) ...[
            const SizedBox(height: 18),
            _sectionTitle('Next Fixture Info'),
            const SizedBox(height: 8),
            _fixturePanel(nextFixture),
          ],
        ],
      ),
    );
  }

  Widget _timeline(Map<String, dynamic> summary) {
    final events = _events(summary);
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
      children: [
        _sectionTitle('Timeline'),
        const SizedBox(height: 8),
        events.isEmpty
            ? _emptyPanel('No timeline updates yet.')
            : _eventPanel(events),
      ],
    );
  }

  Widget _stats(Map<String, dynamic> summary) {
    final teamStats = _teamStats(summary);
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
      children: [
        _sectionTitle('Match Stats'),
        const SizedBox(height: 8),
        if (teamStats.isEmpty)
          _emptyPanel('Match stats are not available yet.')
        else
          Card(
            child: Column(
              children: teamStats.map((item) {
                final stat = item;
                if (stat['team'] != null) {
                  return ListTile(
                    dense: true,
                    title: Text('${stat['team']}'),
                    titleTextStyle: const TextStyle(
                        fontWeight: FontWeight.w800, color: AppTheme.primary),
                  );
                }
                return ListTile(
                  dense: true,
                  title: Text('${stat['label'] ?? 'Stat'}'),
                  trailing: Text('${stat['value'] ?? ''}'),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _sectionTitle(String title) => Text(
        title,
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
      );

  Widget _eventPanel(List<Map<String, dynamic>> events) => Card(
        child: Column(
          children: events.take(12).map((event) {
            final clock = (event['clock'] as Map?)?['displayValue'] ??
                event['clock'] ??
                '';
            final text = event['text'] ?? event['shortText'] ?? 'Match update';
            return ListTile(
              dense: true,
              visualDensity: const VisualDensity(vertical: -1),
              leading: SizedBox(
                width: 34,
                child: Text(
                  '$clock',
                  style: const TextStyle(
                      color: AppTheme.muted, fontWeight: FontWeight.w700),
                ),
              ),
              title: Text('$text'),
              trailing: Icon(_eventIcon('$text'), size: 18),
            );
          }).toList(),
        ),
      );

  Widget _emptyPanel(String message) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(message),
        ),
      );

  Widget _fixturePanel(Map<String, dynamic> fixture) => Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${fixture['dateLabel'] ?? fixture['date'] ?? ''}'
                    .toUpperCase(),
                style: const TextStyle(
                    color: AppTheme.secondary, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              Text(
                '${fixture['name'] ?? '${fixture['home'] ?? ''} vs ${fixture['away'] ?? ''}'}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              if ('${fixture['league'] ?? ''}'.isNotEmpty ||
                  '${fixture['time'] ?? ''}'.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  '${fixture['league'] ?? ''}${fixture['league'] != null && fixture['time'] != null ? ' · ' : ''}${fixture['time'] ?? ''}',
                  style: const TextStyle(color: AppTheme.muted, fontSize: 12),
                ),
              ],
            ],
          ),
        ),
      );

  List<Map<String, dynamic>> _events(Map<String, dynamic> summary) {
    final header = summary['header'] as Map?;
    final competitions = header?['competitions'] as List?;
    final competition = competitions?.firstOrNull as Map?;
    final details = (competition?['details'] as List? ?? const [])
        .whereType<Map>()
        .map((event) => event.cast<String, dynamic>())
        .toList();
    final scoring = (summary['scoringPlays'] as List? ?? const [])
        .whereType<Map>()
        .map((event) {
      final item = event.cast<String, dynamic>();
      return {
        ...item,
        'text': item['text'] ?? item['shortText'] ?? item['type'],
        'clock': item['clock'] ?? item['period'],
      };
    }).toList();
    return [...details, ...scoring];
  }

  List<Map<String, dynamic>> _teamStats(Map<String, dynamic> summary) {
    final teams = (summary['boxscore'] as Map?)?['teams'] as List? ?? const [];
    final stats = <Map<String, dynamic>>[];
    for (final item in teams.whereType<Map>()) {
      final team = (item['team'] as Map?)?['displayName'] ??
          (item['team'] as Map?)?['name'];
      if (team != null) stats.add({'team': team});
      for (final stat in (item['statistics'] as List? ?? const [])) {
        if (stat is Map) {
          final value = stat['displayValue'] ?? stat['value'];
          stats.add({
            'label': stat['label'] ?? stat['name'] ?? 'Stat',
            'value': value ?? '',
          });
        }
      }
    }
    if (stats.isEmpty) {
      for (final stat in (summary['stats'] as List? ?? const [])) {
        if (stat is Map) stats.add(stat.cast<String, dynamic>());
      }
    }
    return stats;
  }

  Map<String, dynamic>? _nextFixture(Map<String, dynamic> summary) {
    final fixture = summary['nextFixture'] ?? summary['next_fixture'];
    return fixture is Map ? fixture.cast<String, dynamic>() : null;
  }

  IconData _eventIcon(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('card')) return Iconsax.square;
    if (lower.contains('goal')) return Iconsax.close_circle;
    return Iconsax.info_circle;
  }

  String _leagueLabel(String league) {
    return supportedLeagues
            .where((item) => league.contains(item.league))
            .map((item) => item.label)
            .firstOrNull ??
        league.replaceAll(RegExp(r'[-_/]+'), ' ');
  }
}
