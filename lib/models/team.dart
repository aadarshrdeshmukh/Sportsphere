class Team {
  const Team(
      {required this.id,
      required this.name,
      required this.abbreviation,
      this.logoUrl,
      this.league = ''});
  final String id, name, abbreviation, league;
  final String? logoUrl;
  factory Team.fromEspn(Map<String, dynamic> json, {String league = ''}) => Team(
      id: '${json['id'] ?? ''}',
      name:
          '${json['displayName'] ?? json['shortDisplayName'] ?? json['name'] ?? 'Unknown team'}',
      abbreviation: '${json['abbreviation'] ?? json['shortName'] ?? ''}',
      logoUrl: (json['logo'] ?? json['logoUrl']) as String?,
      league: league.isEmpty ? '${json['league'] ?? ''}' : league);
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'abbreviation': abbreviation,
        'logoUrl': logoUrl,
        'league': league
      };
  factory Team.fromJson(Map<String, dynamic> json) => Team(
      id: '${json['id']}',
      name: '${json['name']}',
      abbreviation: '${json['abbreviation'] ?? ''}',
      logoUrl: json['logoUrl'] as String?,
      league: '${json['league'] ?? ''}');
}
