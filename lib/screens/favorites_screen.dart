import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';
import '../models/sport_match.dart';
import '../models/team.dart';
import '../repositories/sports_repository.dart';
import '../state/auth_controller.dart';
import '../state/favorites_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';

class Favorites extends StatefulWidget {
  const Favorites({
    super.key,
    required this.repository,
    required this.favorites,
    this.auth,
  });

  final SportsRepository repository;
  final FavoritesController favorites;
  final AuthController? auth;

  @override
  State<Favorites> createState() => _FavoritesState();
}

class _FavoritesState extends State<Favorites> {
  Future<List<SportMatch>>? _matches;

  @override
  void initState() {
    super.initState();
    widget.favorites.addListener(_onFavoritesChanged);
    _matches = _loadMatches();
  }

  @override
  void dispose() {
    widget.favorites.removeListener(_onFavoritesChanged);
    super.dispose();
  }

  void _onFavoritesChanged() {
    if (mounted) setState(() => _matches = _loadMatches());
  }

  Future<List<SportMatch>> _loadMatches() async {
    final matches = <SportMatch>[];
    for (final team in widget.favorites.teams) {
      matches.addAll(await widget.repository.teamMatches(team));
    }
    final ids = <String>{};
    return matches.where((match) => !match.isCompleted && ids.add(match.id)).toList()
      ..sort((first, second) => first.startTime.compareTo(second.startTime));
  }

  List<Team> get _orderedTeams {
    const order = ['359', '363', '13', '2'];
    final teams = [...widget.favorites.teams];
    teams.sort((first, second) =>
        order.indexOf(first.id).compareTo(order.indexOf(second.id)));
    return teams;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.favorites,
      builder: (_, __) => Scaffold(
        backgroundColor: const Color(0xFFF5F7F6),
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text('Favorites',
              style: TextStyle(
                  color: AppTheme.primary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800)),
          actions: [
            IconButton(
              tooltip: 'Add team',
              onPressed: () => Navigator.pushNamed(context, '/onboarding'),
              icon: const Icon(Iconsax.user_add, color: Color(0xFF202522)),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: () async => setState(() => _matches = _loadMatches()),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(14, 18, 14, 28),
            children: [
              const Text('My Teams',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              if (_orderedTeams.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 28),
                  child: Center(child: Text('No favorite teams added.')),
                )
              else
                SizedBox(
                  height: 82,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: _orderedTeams.map(_teamBubble).toList(),
                  ),
                ),
              const SizedBox(height: 16),
              const Text('Upcoming Matches',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              FutureBuilder<List<SportMatch>>(
                future: _matches,
                builder: (_, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      _orderedTeams.isNotEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final matches = snapshot.data ?? [];
                  if (matches.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(28),
                      child: Center(child: Text('No upcoming matches.')),
                    );
                  }
                  return Column(children: matches.take(3).map(_matchCard).toList());
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _teamBubble(Team team) {
    final name = team.name == 'Los Angeles Lakers' ? 'Lakers' :
        team.name == 'Boston Celtics' ? 'Celtics' : team.name;
    return InkWell(
      borderRadius: BorderRadius.circular(36),
      onTap: () => Navigator.pushNamed(context, '/team', arguments: team),
      child: SizedBox(
        width: 68,
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(color: _teamColor(team.id), width: 2),
              ),
              child: TeamBadge(name: team.name, logoUrl: team.logoUrl, size: 28),
            ),
            const SizedBox(height: 6),
            Text(name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Color _teamColor(String id) {
    switch (id) {
      case '359':
        return const Color(0xFFFF3D42);
      case '363':
        return const Color(0xFF356DFF);
      case '13':
        return const Color(0xFFFFA300);
      default:
        return const Color(0xFF6555E8);
    }
  }

  Widget _matchCard(SportMatch match) {
    final home = match.home.name;
    final away = match.away.name;
    final homeIsFavorite = widget.favorites.contains(match.home.id);
    final favorite = homeIsFavorite ? match.home : match.away;
    final opponent = homeIsFavorite ? away : home;
    final shortName = favorite.name == 'Los Angeles Lakers'
        ? 'Lakers'
        : favorite.name == 'Boston Celtics'
            ? 'Celtics'
            : favorite.name;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.pushNamed(context, '/match', arguments: match),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFD2D8D4)),
          ),
          child: Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                    shape: BoxShape.circle, color: _teamColor(favorite.id)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(shortName,
                            style: const TextStyle(
                                color: AppTheme.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.w800)),
                        const Spacer(),
                        Text(_leagueName(match.league),
                            style: const TextStyle(
                                color: AppTheme.muted, fontSize: 10)),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        Expanded(
                            child: Text('vs $opponent',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800, fontSize: 14))),
                        Text(DateFormat('HH:mm').format(match.startTime.toLocal()),
                            style: const TextStyle(
                                color: AppTheme.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.w800)),
                        const SizedBox(width: 10),
                        Text(DateFormat('EEE, d MMM').format(match.startTime.toLocal()),
                            style: const TextStyle(
                                color: AppTheme.muted, fontSize: 10)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _leagueName(String value) {
    if (value == 'soccer/eng.1') return 'Premier League';
    if (value == 'soccer/uefa.champions') return 'Champions League';
    if (value == 'basketball/nba') return 'NBA Regular Season';
    return value;
  }
}
