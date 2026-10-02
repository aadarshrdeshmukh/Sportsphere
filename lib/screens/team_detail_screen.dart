import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';
import '../models/team.dart' as model;
import '../models/sport_match.dart';
import '../repositories/sports_repository.dart';
import '../state/favorites_controller.dart';
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
  String? _fallbackLogo;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final team = ModalRoute.of(context)?.settings.arguments as model.Team?;
    if (team != null && _matches == null) {
      _matches = widget.repository.teamMatches(team);
      if (team.logoUrl?.isEmpty != false) {
        widget.repository.logoFallback(team.name).then((url) {
          if (mounted) setState(() => _fallbackLogo = url);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final team = ModalRoute.of(context)?.settings.arguments as model.Team?;
    if (team == null) {
      return Scaffold(
          appBar: AppBar(title: const Text('Team Detail')),
          body: const AppEmptyState(
              title: 'No team selected',
              message: 'Open a team from a match or your favorites.'));
    }
    return AnimatedBuilder(
        animation: widget.favorites,
        builder: (_, __) => Scaffold(
            appBar: AppBar(title: const Text('Team Detail')),
            body: RefreshIndicator(
                onRefresh: () async {
                  setState(() {
                    _matches = widget.repository.teamMatches(team);
                  });
                },
                child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    children: [
                  Center(
                      child: TeamBadge(
                          name: team.name,
                          logoUrl: team.logoUrl ?? _fallbackLogo,
                          size: 88)),
                  const SizedBox(height: 10),
                  Center(
                      child: Text(team.name,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w800))),
                  if (team.abbreviation.isNotEmpty)
                    Center(child: Text(team.abbreviation)),
                  const SizedBox(height: 14),
                  Center(
                      child: FilledButton.icon(
                          onPressed: () => widget.favorites.toggle(team),
                          icon: Icon(widget.favorites.contains(team.id)
                              ? Iconsax.heart_copy
                              : Iconsax.heart),
                          label: Text(widget.favorites.contains(team.id)
                              ? 'Following'
                              : 'Follow team'))),
                  const SizedBox(height: 24),
                  FutureBuilder<List<SportMatch>>(
                      future: _matches,
                      builder: (_, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Padding(
                              padding: EdgeInsets.all(32),
                              child: Center(
                                  child: CircularProgressIndicator()));
                        }
                        final allMatches = snapshot.data ?? [];
                        if (allMatches.isEmpty) {
                          return const AppEmptyState(
                              title: 'No fixtures found',
                              message: 'Try refreshing scores later.');
                        }
                        final upcoming = allMatches
                            .where((m) => !m.isCompleted && !m.isLive)
                            .toList();
                        final results = allMatches
                            .where((m) => m.isCompleted || m.isLive)
                            .toList()
                          ..sort(
                              (a, b) => b.startTime.compareTo(a.startTime));
                        return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Upcoming fixtures',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                          fontWeight: FontWeight.w800)),
                              const SizedBox(height: 8),
                              if (upcoming.isEmpty)
                                const Card(
                                    child: Padding(
                                        padding: EdgeInsets.all(14),
                                        child: Text(
                                            'No upcoming fixtures found.')))
                              else
                                ...upcoming
                                    .take(5)
                                    .map((m) => _matchTile(m)),
                              const SizedBox(height: 20),
                              Text('Recent results',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                          fontWeight: FontWeight.w800)),
                              const SizedBox(height: 8),
                              if (results.isEmpty)
                                const Card(
                                    child: Padding(
                                        padding: EdgeInsets.all(14),
                                        child: Text(
                                            'No recent results found.')))
                              else
                                ...results
                                    .take(5)
                                    .map((m) => _matchTile(m)),
                            ]);
                      })
                ]))));
  }

  Widget _matchTile(SportMatch match) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
          onTap: () =>
              Navigator.pushNamed(context, '/match', arguments: match),
          child: MatchCard(
              league: match.league,
              home: match.home.name,
              away: match.away.name,
              hs: match.homeScore,
              as: match.awayScore,
              time: match.isCompleted
                  ? 'Final'
                  : match.isLive
                      ? match.status
                      : DateFormat('d MMM, jm')
                          .format(match.startTime.toLocal()),
              live: match.isLive)));
}
