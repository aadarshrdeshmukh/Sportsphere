import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/news_article.dart';
import '../models/sport_league.dart';
import '../models/sport_match.dart';

class EspnService {
  EspnService({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;
  static const _base = 'https://site.api.espn.com/apis/site/v2/sports';
  Future<Map<String, dynamic>> _get(String path) async {
    final response = await _client
        .get(Uri.parse('$_base/$path'))
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      throw Exception('ESPN returned ${response.statusCode}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<List<SportMatch>> scoreboard(SportLeague league,
      {DateTime? date}) async {
    final suffix = date == null
        ? ''
        : '?dates=${date.year.toString().padLeft(4, '0')}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
    final data = await _get('${league.key}/scoreboard$suffix');
    return (data['events'] as List? ?? [])
        .map((e) => SportMatch.fromEspn((e as Map).cast<String, dynamic>(),
            league: league.key))
        .toList();
  }

  Future<List<NewsArticle>> news(SportLeague league) async {
    final data = await _get('${league.key}/news');
    return (data['articles'] as List? ?? [])
        .map((e) => NewsArticle.fromEspn(
              (e as Map).cast<String, dynamic>(),
              category: league.label,
            ))
        .toList();
  }

  Future<Map<String, dynamic>> summary(SportLeague league, String eventId) =>
      _get('${league.key}/summary?event=$eventId');

  /// The public BBC feed is a useful, no-key fallback when a league news
  /// endpoint is temporarily unavailable.
  Future<List<NewsArticle>> bbcNews() async {
    final response = await _client
        .get(Uri.parse('https://feeds.bbci.co.uk/sport/rss.xml'))
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      throw Exception('BBC returned ${response.statusCode}');
    }
    final items =
        RegExp(r'<item>([\\s\\S]*?)</item>').allMatches(response.body);
    String value(String body, String tag) =>
        RegExp('<$tag[^>]*>([\\s\\S]*?)</$tag>')
            .firstMatch(body)
            ?.group(1)
            ?.replaceAll('<![CDATA[', '')
            .replaceAll(']]>', '')
            .trim() ??
        '';
    return items
        .map((item) {
          final body = item.group(1)!;
          final image = RegExp(r'<media:thumbnail[^>]+url="([^"]+)"')
              .firstMatch(body)
              ?.group(1);
          return NewsArticle(
            id: value(body, 'guid').isEmpty
                ? value(body, 'link')
                : value(body, 'guid'),
            title: value(body, 'title'),
            description:
                value(body, 'description').replaceAll(RegExp('<[^>]+>'), ''),
            publishedAt:
                DateTime.tryParse(value(body, 'pubDate')) ?? DateTime.now(),
            imageUrl: image,
            category: 'Sports',
            source: 'BBC Sport',
          );
        })
        .where((article) => article.title.isNotEmpty)
        .toList();
  }

  Future<String?> teamLogo(String name) async {
    final response = await _client.get(Uri.parse(
        'https://www.thesportsdb.com/api/v1/json/3/searchteams.php?t=${Uri.encodeComponent(name)}'));
    if (response.statusCode != 200) return null;
    final teams =
        (jsonDecode(response.body) as Map<String, dynamic>)['teams'] as List?;
    return teams?.isNotEmpty == true
        ? teams!.first['strBadge'] as String?
        : null;
  }

  /// Fetches teams from all supported league scoreboards and league team rosters.
  Future<List<Map<String, dynamic>>> teamsFromScoreboards() async {
    final teams = <String, Map<String, dynamic>>{};
    for (final league in [
      'soccer/eng.1',
      'soccer/uefa.champions',
      'basketball/nba',
      'football/nfl'
    ]) {
      try {
        final data = await _get('$league/scoreboard');
        for (final event in (data['events'] as List? ?? [])) {
          for (final comp in (event['competitions'] as List? ?? [])) {
            for (final c in (comp['competitors'] as List? ?? [])) {
              final team = c['team'] as Map<String, dynamic>? ?? {};
              final id = '${team['id'] ?? ''}';
              if (id.isNotEmpty && !teams.containsKey(id)) {
                teams[id] = {
                  ...team,
                  'league': league,
                };
              }
            }
          }
        }
      } catch (_) {}

      try {
        final teamData = await _get('$league/teams');
        final sports = teamData['sports'] as List? ?? [];
        for (final s in sports) {
          for (final l in (s['leagues'] as List? ?? [])) {
            for (final t in (l['teams'] as List? ?? [])) {
              final team = t['team'] as Map<String, dynamic>? ?? {};
              final id = '${team['id'] ?? ''}';
              if (id.isNotEmpty && !teams.containsKey(id)) {
                final logos = team['logos'] as List?;
                teams[id] = {
                  ...team,
                  'logo': logos?.isNotEmpty == true ? logos![0]['href'] : null,
                  'league': league,
                };
              }
            }
          }
        }
      } catch (_) {}
    }
    return teams.values.toList();
  }

  /// Searches TheSportsDB for any global team by name.
  Future<List<Map<String, dynamic>>> searchGlobalTeams(String query) async {
    if (query.trim().isEmpty) return [];
    try {
      final response = await _client
          .get(Uri.parse(
              'https://www.thesportsdb.com/api/v1/json/3/searchteams.php?t=${Uri.encodeComponent(query.trim())}'))
          .timeout(const Duration(seconds: 4));
      if (response.statusCode != 200) return [];
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final teams = json['teams'] as List?;
      if (teams == null) return [];
      return teams.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }
}
