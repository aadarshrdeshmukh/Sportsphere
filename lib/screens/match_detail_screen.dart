import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';
import '../models/sport_league.dart';
import '../models/sport_match.dart';
import '../repositories/sports_repository.dart';
import '../state/favorites_controller.dart';
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
    if (match != null && _summary == null) {
      final league = supportedLeagues
              .where((item) => match.league.contains(item.league))
              .firstOrNull ??
          supportedLeagues.first;
      _summary = widget.repository.matchSummary(league, match.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final match = ModalRoute.of(context)?.settings.arguments as SportMatch?;
    if (match == null) {
      return Scaffold(
          appBar: AppBar(title: const Text('Match Detail')),
          body: const AppEmptyState(
              title: 'No match selected',
              message: 'Open a match from schedule or live scores.'));
    }
    final status = match.isCompleted
        ? 'Final'
        : match.isLive
            ? match.status
            : DateFormat('EEE, d MMM • ')
                .add_jm()
                .format(match.startTime.toLocal());
    return Scaffold(
        appBar: AppBar(title: const Text('Match Detail')),
        body: RefreshIndicator(
            onRefresh: () async {
              final league = supportedLeagues
                      .where((item) => match.league.contains(item.league))
                      .firstOrNull ??
                  supportedLeagues.first;
              setState(() {
                _summary = widget.repository.matchSummary(league, match.id);
              });
            },
            child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  Center(
                      child: Text(
                          match.league.replaceAll('-', ' ').toUpperCase(),
                          style: Theme.of(context).textTheme.labelLarge)),
                  const SizedBox(height: 12),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _team(match.home, match.homeScore),
                        Text(match.isLive ? '•' : '–',
                            style: const TextStyle(
                                fontSize: 32, fontWeight: FontWeight.w800)),
                        _team(match.away, match.awayScore)
                      ]),
                  const SizedBox(height: 20),
                  Card(
                      child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(children: [
                            StatusBadge(label: status, live: match.isLive),
                            if (match.venue.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Iconsax.location, size: 18),
                                    const SizedBox(width: 6),
                                    Flexible(child: Text(match.venue))
                                  ])
                            ]
                          ]))),
                  const SizedBox(height: 20),
                  Text('Key events',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  FutureBuilder<Map<String, dynamic>>(
                      future: _summary,
                      builder: (_, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Padding(
                              padding: EdgeInsets.all(22),
                              child:
                                  Center(child: CircularProgressIndicator()));
                        }
                        final header = snapshot.data?['header'] as Map?;
                        final competition = (header?['competitions'] as List?)
                            ?.firstOrNull as Map?;
                        final events =
                            competition?['details'] as List? ?? const [];
                        if (events.isEmpty) {
                          return const Card(
                              child: Padding(
                                  padding: EdgeInsets.all(14),
                                  child: Text(
                                      'No key events have been posted yet.')));
                        }
                        return Card(
                            child: Column(
                                children: events
                                    .take(12)
                                    .map((event) => ListTile(
                                        leading: const Icon(Iconsax.cup),
                                        title: Text(
                                            '${event['text'] ?? event['shortText'] ?? 'Match update'}'),
                                        subtitle: Text(
                                            '${(event['clock'] as Map?)?['displayValue'] ?? ''}')))
                                    .toList()));
                      })
                ])));
  }

  Widget _team(dynamic team, String score) => Expanded(
      child: InkWell(
          onTap: () => Navigator.pushNamed(context, '/team', arguments: team),
          child: Column(children: [
            TeamBadge(name: team.name, logoUrl: team.logoUrl, size: 64),
            const SizedBox(height: 8),
            Text(team.name, textAlign: TextAlign.center),
            Text(score.isEmpty ? '–' : score,
                style:
                    const TextStyle(fontSize: 32, fontWeight: FontWeight.w800))
          ])));
}
