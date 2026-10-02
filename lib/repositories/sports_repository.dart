import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/news_article.dart';
import '../models/sport_league.dart';
import '../models/sport_match.dart';
import '../models/team.dart';
import '../services/api_service.dart';
import '../services/cache_service.dart';
import '../services/espn_service.dart';

class DataResult<T> {
  const DataResult(this.data, {this.fromCache = false, this.error});
  final T data;
  final bool fromCache;
  final String? error;
}

class SportsRepository {
  SportsRepository({ApiService? api, CacheService? cache, EspnService? espn})
      : _api = api ?? ApiService(),
        _cache = cache ?? CacheService(),
        _espn = espn ?? EspnService();

  final ApiService _api;
  final CacheService _cache;
  final EspnService _espn;

  Future<DataResult<List<SportMatch>>> matches(SportLeague? league,
      {DateTime? date}) async {
    if (league == null) {
      return allMatches(date: date);
    }
    final key = _scoreboardKey(league, date);
    // 1. Try Express backend
    try {
      final data = _filterForDate(await _api.matches(league, date: date), date);
      if (data.isNotEmpty) {
        await _cache.writeJson(key, {'events': data.map(_matchJson).toList()});
      }
      return DataResult(data);
    } catch (_) {
      // 2. Direct live fallback
      try {
        final directData =
            _filterForDate(await _espn.scoreboard(league, date: date), date);
        if (directData.isNotEmpty) {
          await _cache
              .writeJson(key, {'events': directData.map(_matchJson).toList()});
        }
        return DataResult(directData);
      } catch (_) {}
    }

    return DataResult(
      await _readMatches(key, league: league),
      fromCache: true,
      error: 'Sports server unavailable; showing saved/mock data.',
    );
  }

  /// Fetches matches across all supported leagues.
  Future<DataResult<List<SportMatch>>> allMatches({DateTime? date}) async {
    // 1. Try Express backend for all leagues
    try {
      final data = _filterForDate(await _api.matches(null, date: date), date);
      return DataResult(data);
    } catch (_) {
      // 2. Direct live fallback across leagues
      try {
        final results = await Future.wait(
            supportedLeagues.map((l) => _espn.scoreboard(l, date: date)));
        final all =
            _filterForDate(results.expand((list) => list).toList(), date)
              ..sort((a, b) => a.startTime.compareTo(b.startTime));
        if (all.isNotEmpty) {
          return DataResult(all);
        }
      } catch (_) {}
    }

    return DataResult(
      await _readMatches('scoreboard_all'),
      fromCache: true,
      error: 'Sports server unavailable; showing saved/mock data.',
    );
  }

  String _scoreboardKey(SportLeague league, DateTime? date) {
    final base = 'scoreboard_${league.key.replaceAll('/', '_')}';
    if (date == null) return base;
    final day = '${date.year.toString().padLeft(4, '0')}'
        '${date.month.toString().padLeft(2, '0')}'
        '${date.day.toString().padLeft(2, '0')}';
    return '${base}_$day';
  }

  List<SportMatch> _filterForDate(
      List<SportMatch> matches, DateTime? selectedDate) {
    if (selectedDate == null) return matches;
    return matches.where((match) {
      final local = match.startTime.toLocal();
      return local.year == selectedDate.year &&
          local.month == selectedDate.month &&
          local.day == selectedDate.day;
    }).toList();
  }

  Future<DataResult<List<NewsArticle>>> news(SportLeague? league) async {
    if (league == null) {
      return allNews();
    }
    final key = 'news_${league.key.replaceAll('/', '_')}';
    // 1. Try Express backend
    try {
      final data = await _api.news(league);
      if (data.isNotEmpty) {
        await _cacheNews(key, data);
      }
      return DataResult(data);
    } catch (_) {
      // 2. Direct live fallback
      try {
        final direct = await _espn.news(league);
        if (direct.isNotEmpty) {
          await _cacheNews(key, direct);
          return DataResult(direct);
        }
      } catch (_) {}
    }

    return DataResult(
      await _readNews(key),
      fromCache: true,
      error: 'Sports server unavailable; showing saved/mock data.',
    );
  }

  /// Fetches news across all supported leagues.
  Future<DataResult<List<NewsArticle>>> allNews() async {
    // 1. Try Express backend
    try {
      final data = await _api.news(null);
      if (data.isNotEmpty) {
        await _cacheNews('news_all', data);
      }
      return DataResult(data);
    } catch (_) {
      // 2. Direct live fallback
      try {
        final direct = await _espn.bbcNews();
        if (direct.isNotEmpty) {
          await _cacheNews('news_all', direct);
          return DataResult(direct);
        }
      } catch (_) {}
    }

    return DataResult(
      await _readNews('news_all'),
      fromCache: true,
      error: 'Sports server unavailable; showing saved/mock data.',
    );
  }

  Future<void> _cacheNews(String key, List<NewsArticle> data) =>
      _cache.writeJson(key, {
        'articles': data
            .map((a) => {
                  'id': a.id,
                  'headline': a.title,
                  'description': a.description,
                  'published': a.publishedAt.toIso8601String(),
                  'categories': [
                    {'description': a.category}
                  ],
                  'source': {'name': a.source},
                  'images': a.imageUrl == null
                      ? []
                      : [
                          {'url': a.imageUrl}
                        ]
                })
            .toList()
      });

  Future<Map<String, dynamic>> matchSummary(
      SportLeague league, String eventId) async {
    try {
      final data = await _api.summary(league, eventId);
      if (data.isNotEmpty) return data;
    } catch (_) {}
    return {};
  }

  Future<List<SportMatch>> teamMatches(Team team) async {
    // 1. Try Express backend
    try {
      final data = await _api.teamMatches(team);
      if (data.isNotEmpty) return data;
    } catch (_) {}

    // 2. Query matches across leagues
    final results =
        await Future.wait(supportedLeagues.map((league) => matches(league)));
    final teamNameLower = team.name.toLowerCase();
    return results
        .expand((result) => result.data)
        .where((match) =>
            match.home.id == team.id ||
            match.away.id == team.id ||
            match.home.name.toLowerCase() == teamNameLower ||
            match.away.name.toLowerCase() == teamNameLower)
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  Future<String?> logoFallback(String teamName) async {
    try {
      return await _espn.teamLogo(teamName);
    } catch (_) {
      return null;
    }
  }

  /// Returns distinct teams visible in current scoreboards across all leagues.
  Future<List<Team>> popularTeams() async {
    // 1. Try Express backend
    try {
      final teams = await _api.popularTeams();
      if (teams.isNotEmpty) return teams;
    } catch (_) {}

    // 2. Try direct ESPN
    try {
      final espnTeams = await _espn.teamsFromScoreboards();
      if (espnTeams.isNotEmpty) {
        return espnTeams
            .map((t) => Team.fromEspn(t, league: '${t['league'] ?? ''}'))
            .toList();
      }
    } catch (_) {}

    // 3. Cached / mock fallback
    final matches = await _readMatches('popular_teams');
    final teams = <String, Team>{};
    for (final match in matches) {
      teams[match.home.id] = match.home;
      teams[match.away.id] = match.away;
    }
    return teams.values.toList();
  }

  /// Searches for any team across cached rosters and online sports databases.
  Future<List<Team>> searchTeams(String query) async {
    if (query.trim().isEmpty) return [];
    final results = <Team>[];
    final seen = <String>{};

    final teams = await popularTeams();
    for (final team in teams) {
      if (team.name.toLowerCase().contains(query.trim().toLowerCase()) &&
          seen.add(team.id)) {
        results.add(team);
      }
    }

    return results;
  }

  Future<List<NewsArticle>> _readNews(String key) async {
    final raw = await _readJson(key, 'assets/mock/news.json');
    return (raw['articles'] as List? ?? [])
        .map((x) => NewsArticle.fromEspn((x as Map).cast<String, dynamic>()))
        .toList();
  }

  Future<List<SportMatch>> _readMatches(String key,
      {SportLeague? league}) async {
    final raw = await _readJson(key, 'assets/mock/scoreboard.json');
    final events = (raw['events'] as List? ?? []);
    final now = DateTime.now();
    return events
        .map((x) {
          final json = Map<String, dynamic>.from(x as Map);
          final id = '${json['id'] ?? ''}';
          if (id.contains('live')) {
            json['date'] = now.toIso8601String();
          } else if (id.contains('today')) {
            json['date'] = now.add(const Duration(hours: 3)).toIso8601String();
          }
          return SportMatch.fromEspn(json);
        })
        .where((match) => league == null || match.league == league.key)
        .toList();
  }

  Future<Map<String, dynamic>> _readJson(String key, String asset) async {
    final cached = await _cache.read(key);
    final text = cached ?? await rootBundle.loadString(asset);
    return jsonDecode(text) as Map<String, dynamic>;
  }

  Map<String, dynamic> _matchJson(SportMatch m) => {
        'id': m.id,
        'date': m.startTime.toIso8601String(),
        'season': {'slug': m.league},
        'competitions': [
          {
            'status': {
              'type': {
                'shortDetail': m.status,
                'completed': m.isCompleted,
                'state': m.state,
              }
            },
            'venue': {'fullName': m.venue},
            'competitors': [
              {
                'homeAway': 'home',
                'score': m.homeScore,
                'team': m.home.toJson()
              },
              {
                'homeAway': 'away',
                'score': m.awayScore,
                'team': m.away.toJson()
              }
            ]
          }
        ]
      };
}
