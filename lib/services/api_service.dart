import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/news_article.dart';
import '../models/sport_league.dart';
import '../models/sport_match.dart';
import '../models/team.dart';

class ApiService {
  ApiService({String? customBaseUrl, http.Client? client})
      : _client = client ?? http.Client(),
        baseUrl = customBaseUrl ?? defaultBaseUrl;

  final http.Client _client;
  final String baseUrl;

  static String get defaultBaseUrl {
    if (kIsWeb) return 'http://localhost:3000/api/v1';
    try {
      if (Platform.isAndroid) return 'http://10.0.2.2:3000/api/v1';
    } catch (_) {}
    return 'http://localhost:3000/api/v1';
  }

  Future<Map<String, dynamic>> _get(String path,
      {Map<String, String>? queryParams, String? token}) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: queryParams);
    final headers = <String, String>{'Accept': 'application/json'};
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    final response = await _client.get(uri, headers: headers).timeout(
          const Duration(seconds: 8),
        );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw HttpException(
        'Server returned ${response.statusCode}: ${response.body}');
  }

  /// Fetches scoreboard from Express backend.
  Future<List<SportMatch>> matches(SportLeague? league, {DateTime? date}) async {
    final query = <String, String>{'league': league?.key ?? 'all'};
    if (date != null) {
      final y = date.year.toString().padLeft(4, '0');
      final m = date.month.toString().padLeft(2, '0');
      final d = date.day.toString().padLeft(2, '0');
      query['date'] = '$y$m$d';
    }
    final result = await _get('/scores', queryParams: query);
    final rawData = result['data'];
    final List events;
    if (rawData is List) {
      events = rawData;
    } else if (rawData is Map && rawData['events'] is List) {
      events = rawData['events'] as List;
    } else {
      events = [];
    }
    return events
        .map((x) => SportMatch.fromEspn((x as Map).cast<String, dynamic>(),
            league: league?.key))
        .toList();
  }

  /// Fetches news articles from Express backend.
  Future<List<NewsArticle>> news(SportLeague? league, {String? category}) async {
    final query = <String, String>{'league': league?.key ?? 'all'};
    if (category != null && category != 'All') {
      query['category'] = category;
    }
    final result = await _get('/news', queryParams: query);
    final articles = (result['articles'] ??
            result['data']?['articles'] ??
            (result['data'] is List ? result['data'] : null)) as List? ??
        [];
    return articles
      .map((x) => NewsArticle.fromEspn((x as Map).cast<String, dynamic>(),
        category: league?.label ?? 'Sports'))
        .toList();
  }

  /// Fetches match summary and timeline events from Express backend.
  Future<Map<String, dynamic>> summary(SportLeague league, String eventId) async {
    final cleanLeague = league.key.replaceAll('/', '-');
    final result = await _get('/matches/$cleanLeague/$eventId/summary');
    return (result['summary'] as Map?)?.cast<String, dynamic>() ?? {};
  }

  /// Fetches popular teams catalog from Express backend.
  Future<List<Team>> popularTeams() async {
    final result = await _get('/teams/popular');
    final teams = (result['teams'] ??
            result['data']?['teams'] ??
            (result['data'] is List ? result['data'] : null)) as List? ??
        [];
    return teams
        .map((x) => Team.fromJson((x as Map).cast<String, dynamic>()))
        .toList();
  }

  /// Fetches matches for a specific team from Express backend.
  Future<List<SportMatch>> teamMatches(Team team) async {
    final result = await _get('/teams/${team.id}/matches',
        queryParams: {'teamName': team.name});
    final matches = (result['matches'] ??
            result['data']?['matches'] ??
            (result['data'] is List ? result['data'] : null)) as List? ??
        [];
    return matches
        .map((x) => SportMatch.fromEspn((x as Map).cast<String, dynamic>()))
        .toList();
  }

  /// Fetches user favorites from Express backend with Firebase Bearer token.
  Future<List<Team>> getFavorites(String token) async {
    final result = await _get('/favorites', token: token);
    final favorites = (result['favorites'] ??
            result['data']?['favorites'] ??
            (result['data'] is List ? result['data'] : null)) as List? ??
        [];
    return favorites
        .map((x) => Team.fromJson((x as Map).cast<String, dynamic>()))
        .toList();
  }
}
