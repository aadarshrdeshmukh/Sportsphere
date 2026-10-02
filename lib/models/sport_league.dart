class SportLeague {
  const SportLeague(this.label, this.sport, this.league);
  final String label, sport, league;
  String get key => '$sport/$league';
}

const supportedLeagues = [
  SportLeague('Premier League', 'soccer', 'eng.1'),
  SportLeague('Champions League', 'soccer', 'uefa.champions'),
  SportLeague('NBA', 'basketball', 'nba'),
  SportLeague('NFL', 'football', 'nfl')
];
