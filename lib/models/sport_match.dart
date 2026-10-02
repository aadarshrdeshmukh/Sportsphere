import 'team.dart';

class SportMatch {
  const SportMatch(
      {required this.id,
      required this.league,
      required this.home,
      required this.away,
      required this.startTime,
      required this.status,
      this.homeScore = '',
      this.awayScore = '',
      this.venue = '',
      this.isCompleted = false,
      this.state = ''});
  final String id, league, status, homeScore, awayScore, venue, state;
  final Team home, away;
  final DateTime startTime;
  final bool isCompleted;
  bool get isLive => !isCompleted && state.toLowerCase() == 'in';
  factory SportMatch.fromEspn(Map<String, dynamic> event, {String? league}) {
    final competitions = event['competitions'] as List? ?? [];
    final competition = competitions.isEmpty
        ? <String, dynamic>{}
        : (competitions.first as Map).cast<String, dynamic>();
    final competitors = (competition['competitors'] as List? ?? [])
        .cast<Map<String, dynamic>>();
    Map<String, dynamic> find(String side) => competitors
        .cast<Map<String, dynamic>>()
        .firstWhere((c) => c['homeAway'] == side, orElse: () => {});
    final home = find('home'), away = find('away');
    final status = (competition['status'] as Map<String, dynamic>?)?['type']
            as Map<String, dynamic>? ??
        {};
    return SportMatch(
        id: '${event['id']}',
        league: league ??
            '${(event['season'] as Map?)?['slug'] ?? event['shortName'] ?? ''}',
        home: Team.fromEspn(
            (home['team'] as Map?)?.cast<String, dynamic>() ?? {}),
        away: Team.fromEspn(
            (away['team'] as Map?)?.cast<String, dynamic>() ?? {}),
        homeScore: '${home['score'] ?? ''}',
        awayScore: '${away['score'] ?? ''}',
        startTime: DateTime.tryParse('${event['date']}') ?? DateTime.now(),
        status:
            '${status['shortDetail'] ?? status['description'] ?? 'Scheduled'}',
        venue: '${(competition['venue'] as Map?)?['fullName'] ?? ''}',
        isCompleted: status['completed'] == true,
        state: '${status['state'] ?? ''}');
  }
}
