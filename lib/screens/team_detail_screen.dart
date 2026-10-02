import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';
import '../models/team.dart' as model;
import '../models/sport_match.dart';
import '../repositories/sports_repository.dart';
import '../state/favorites_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';

class Team extends StatefulWidget {
  const Team({super.key, required this.repository, required this.favorites});
  final SportsRepository repository;
  final FavoritesController favorites;

  @override
  State<Team> createState() => _TeamState();
}

class _TeamState extends State<Team> {
  Future<List<SportMatch>>? _matches;
  int _tab = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final team = ModalRoute.of(context)?.settings.arguments as model.Team?;
    if (team != null && _matches == null) {
      _matches = widget.repository.teamMatches(team);
    }
  }

  @override
  Widget build(BuildContext context) {
    final team = ModalRoute.of(context)?.settings.arguments as model.Team?;
    if (team == null) {
      return const Scaffold(body: Center(child: Text('No team selected')));
    }

    return AnimatedBuilder(
      animation: widget.favorites,
      builder: (_, __) => Scaffold(
        backgroundColor: const Color(0xFFF5F7F6),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            tooltip: 'Back',
            onPressed: () => Navigator.maybePop(context),
            icon: const Icon(Iconsax.arrow_left_2, color: Color(0xFF202522)),
          ),
          actions: [
            IconButton(
              tooltip: 'Settings',
              onPressed: () => Navigator.pushNamed(context, '/settings'),
              icon: const Icon(Iconsax.setting_2, color: Color(0xFF202522)),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: () async => setState(() {
            _matches = widget.repository.teamMatches(team);
          }),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            children: [
              _teamHeader(team),
              _tabs(),
              FutureBuilder<List<SportMatch>>(
                future: _matches,
                builder: (_, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final matches = snapshot.data ?? [];
                  final upcoming = matches
                      .where((match) => !match.isCompleted && !match.isLive)
                      .toList();
                  final results = matches
                      .where((match) => match.isCompleted)
                      .toList();
                  final content = _tab == 0
                      ? _fixtureList(upcoming)
                      : _tab == 1
                          ? _fixtureList(results)
                          : const Padding(
                              padding: EdgeInsets.all(28),
                              child: Center(
                                child: Text('Team news will appear here.')));
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
                    child: content,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _teamHeader(model.Team team) => Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
        child: Row(
          children: [
            TeamBadge(name: team.name, logoUrl: team.logoUrl, size: 58),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(team.name,
                      style: const TextStyle(
                          fontSize: 25, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(
                    '${team.league == 'soccer/eng.1' ? 'Premier League' : team.league} · England',
                    style: const TextStyle(color: AppTheme.muted, fontSize: 12),
                  ),
                ],
              ),
            ),
            FilledButton(
              onPressed: () => widget.favorites.toggle(team),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 15),
                minimumSize: const Size(0, 36),
              ),
              child: Text(widget.favorites.contains(team.id)
                  ? 'Following'
                  : 'Follow team'),
            ),
          ],
        ),
      );

  Widget _tabs() => Container(
        height: 43,
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFD9DEDB))),
        ),
        child: Row(
          children: ['Fixtures', 'Results', 'News']
              .asMap()
              .entries
              .map((entry) => Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _tab = entry.key),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(entry.value,
                              style: TextStyle(
                                  color: _tab == entry.key
                                      ? AppTheme.primary
                                      : AppTheme.muted,
                                  fontWeight: _tab == entry.key
                                      ? FontWeight.w800
                                      : FontWeight.w500)),
                          const SizedBox(height: 7),
                          Container(
                            height: 2,
                            width: 52,
                            color: _tab == entry.key
                                ? AppTheme.primary
                                : Colors.transparent,
                          ),
                        ],
                      ),
                    ),
                  ))
              .toList(),
        ),
      );

  Widget _fixtureList(List<SportMatch> matches) {
    if (matches.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(28),
        child: Center(child: Text('No fixtures found.')),
      );
    }
    return Column(children: matches.take(5).map(_fixtureCard).toList());
  }

  Widget _fixtureCard(SportMatch match) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => Navigator.pushNamed(context, '/match', arguments: match),
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 11),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFD2D8D4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(_leagueName(match.league),
                          style: const TextStyle(
                              color: AppTheme.muted,
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                    ),
                    Text(DateFormat('HH:mm').format(match.startTime.toLocal()),
                        style: const TextStyle(
                            color: AppTheme.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w800)),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Expanded(
                        child: Text('vs ${_opponent(match)}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 14))),
                    Text(DateFormat('EEE, d MMM').format(match.startTime.toLocal()),
                        style: const TextStyle(
                            color: AppTheme.muted, fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

  String _opponent(SportMatch match) => match.home.name == 'Arsenal'
      ? match.away.name
      : match.home.name;

  String _leagueName(String value) {
    if (value == 'soccer/eng.1') return 'Premier League';
    if (value == 'soccer/uefa.champions') return 'Champions League';
    if (value == 'basketball/nba') return 'NBA Regular Season';
    return value;
  }
}
