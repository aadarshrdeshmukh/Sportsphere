import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sportsphere/models/news_article.dart';
import 'package:sportsphere/models/sport_league.dart';
import 'package:sportsphere/models/sport_match.dart';
import 'package:sportsphere/models/team.dart';
import 'package:sportsphere/repositories/sports_repository.dart';
import 'package:sportsphere/screens/auth_screen.dart';
import 'package:sportsphere/screens/league_filter_sheet.dart';
import 'package:sportsphere/screens/match_detail_screen.dart';
import 'package:sportsphere/screens/team_detail_screen.dart' as screen;
import 'package:sportsphere/services/firestore_service.dart';
import 'package:sportsphere/services/api_service.dart';
import 'package:sportsphere/state/auth_controller.dart';
import 'package:sportsphere/state/favorites_controller.dart';
import 'package:sportsphere/state/live_scores_controller.dart';
import 'package:sportsphere/state/news_controller.dart';
import 'package:sportsphere/state/sports_controller.dart';
import 'package:sportsphere/widgets/account_sheet.dart';

class _MockRepository extends SportsRepository {
  final List<NewsArticle> stories;
  final List<SportMatch> sampleMatches;
  final List<Team> teams;
  final bool returnFromCache;
  final String? mockError;

  _MockRepository({
    this.stories = const [],
    this.sampleMatches = const [],
    this.teams = const [],
    this.returnFromCache = false,
    this.mockError,
  });

  @override
  Future<DataResult<List<NewsArticle>>> news(SportLeague? league) async =>
      DataResult(stories, fromCache: returnFromCache, error: mockError);

  @override
  Future<DataResult<List<SportMatch>>> matches(SportLeague? league,
          {DateTime? date}) async =>
      DataResult(sampleMatches, fromCache: returnFromCache, error: mockError);

  @override
  Future<List<SportMatch>> teamMatches(Team team) async => sampleMatches
      .where((m) =>
          m.home.id == team.id ||
          m.away.id == team.id ||
          m.home.name.toLowerCase() == team.name.toLowerCase() ||
          m.away.name.toLowerCase() == team.name.toLowerCase())
      .toList();

  @override
  Future<List<Team>> popularTeams() async => teams;

  @override
  Future<Map<String, dynamic>> matchSummary(
          SportLeague league, String eventId) async =>
      {
        'header': {
          'competitions': [
            {
              'details': [
                {
                  'text': 'Goal scored by Saka',
                  'clock': {'displayValue': '23\''}
                }
              ]
            }
          ]
        }
      };
}

class _MockFirestoreService extends FirestoreService {
  final Map<String, Map<String, Team>> _db = {};

  @override
  Future<List<Team>> fetchFavorites(String userId) async =>
      _db[userId]?.values.toList() ?? [];

  @override
  Future<void> saveFavorite(String userId, Team team) async {
    _db.putIfAbsent(userId, () => {})[team.id] = team;
  }

  @override
  Future<void> removeFavorite(String userId, String teamId) async {
    _db[userId]?.remove(teamId);
  }

  @override
  Future<void> syncLocalToRemote(String userId, List<Team> localTeams) async {
    final userMap = _db.putIfAbsent(userId, () => {});
    for (final team in localTeams) {
      userMap[team.id] = team;
    }
  }
}

class _UnavailableClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    throw http.ClientException('backend unavailable');
  }
}

void main() {
  const event = {
    'id': 'event-1',
    'date': '2026-09-28T16:30:00Z',
    'season': {'slug': 'eng.1'},
    'competitions': [
      {
        'status': {
          'type': {'shortDetail': '45\'', 'state': 'in', 'completed': false}
        },
        'venue': {'fullName': 'Emirates Stadium'},
        'competitors': [
          {
            'homeAway': 'home',
            'score': '1',
            'team': {
              'id': 'ars',
              'displayName': 'Arsenal',
              'abbreviation': 'ARS'
            }
          },
          {
            'homeAway': 'away',
            'score': '0',
            'team': {
              'id': 'che',
              'displayName': 'Chelsea',
              'abbreviation': 'CHE'
            }
          }
        ]
      }
    ]
  };

  group('Model parsing & serialization', () {
    test('parses ESPN match fields and live status', () {
      final match = SportMatch.fromEspn(event);
      expect(match.id, 'event-1');
      expect(match.home.name, 'Arsenal');
      expect(match.away.name, 'Chelsea');
      expect(match.venue, 'Emirates Stadium');
      expect(match.isLive, isTrue);
      expect(match.isCompleted, isFalse);
    });

    test('Team JSON serialization and deserialization', () {
      const team = Team(
        id: '359',
        name: 'Arsenal',
        abbreviation: 'ARS',
        logoUrl: 'https://example.com/ars.png',
        league: 'soccer/eng.1',
      );
      final json = team.toJson();
      final fromJson = Team.fromJson(json);
      expect(fromJson.id, '359');
      expect(fromJson.name, 'Arsenal');
      expect(fromJson.abbreviation, 'ARS');
      expect(fromJson.logoUrl, 'https://example.com/ars.png');
      expect(fromJson.league, 'soccer/eng.1');
    });

    test('NewsArticle parsing and toJson', () {
      final article = NewsArticle.fromEspn({
        'id': 'art-1',
        'headline': 'Big Match Ahead',
        'description': 'Preview of the weekend.',
        'published': '2026-09-28T10:00:00Z',
        'images': [
          {'url': 'https://example.com/img.jpg'}
        ],
        'links': {
          'web': {'href': 'https://espn.com/story/1'}
        },
        'categories': [
          {'description': 'Premier League'}
        ],
        'source': {'name': 'ESPN'}
      });

      expect(article.id, 'art-1');
      expect(article.title, 'Big Match Ahead');
      expect(article.category, 'Premier League');
      expect(article.url, 'https://espn.com/story/1');
      expect(article.imageUrl, 'https://example.com/img.jpg');

      final json = article.toJson();
      expect(json['headline'], 'Big Match Ahead');

      final categorized = NewsArticle.fromEspn(
        {'headline': 'NFL headline'},
        category: 'NFL',
      );
      expect(categorized.category, 'NFL');
    });
  });

  group('Controllers & State', () {
    test('NewsController filters by category', () async {
      final controller = NewsController(_MockRepository(stories: [
        NewsArticle(
            id: '1',
            title: 'Football news',
            description: '',
            publishedAt: DateTime(2026),
            category: 'Football'),
        NewsArticle(
            id: '2',
            title: 'Basketball news',
            description: '',
            publishedAt: DateTime(2026),
            category: 'Basketball'),
      ]));
      await controller.refresh();
      expect(controller.categories,
          containsAll(['All', 'Football', 'Basketball']));
      controller.selectCategory('Football');
      expect(controller.filteredArticles.single.title, 'Football news');
    });

    test('FavoritesController persists, loads and syncs with Firestore',
        () async {
      SharedPreferences.setMockInitialValues({});
      final firestore = _MockFirestoreService();
      final first = FavoritesController(firestoreService: firestore);
      const team = Team(id: 'ars', name: 'Arsenal', abbreviation: 'ARS');

      await first.load(userId: 'user_123');
      await first.toggle(team);
      expect(first.contains('ars'), isTrue);

      final cloudFavorites = await firestore.fetchFavorites('user_123');
      expect(cloudFavorites.length, 1);
      expect(cloudFavorites.first.name, 'Arsenal');

      final restored = FavoritesController(firestoreService: firestore);
      await restored.load(userId: 'user_123');
      expect(restored.contains('ars'), isTrue);
      expect(restored.teams.length, 1);

      await restored.remove('ars');
      expect(restored.contains('ars'), isFalse);
      expect(restored.teams, isEmpty);
    });

    test('LiveScoresController filters live, upcoming, and finished', () async {
      final match1 = SportMatch.fromEspn(event); // live
      final match2 = SportMatch(
        id: 'event-2',
        league: 'eng.1',
        home: const Team(id: '1', name: 'MCI', abbreviation: 'MCI'),
        away: const Team(id: '2', name: 'LIV', abbreviation: 'LIV'),
        startTime: DateTime.now().add(const Duration(hours: 2)),
        status: 'Scheduled',
        homeScore: '',
        awayScore: '',
        venue: 'Etihad',
        isCompleted: false,
        state: 'pre',
      );
      final match3 = SportMatch(
        id: 'event-3',
        league: 'eng.1',
        home: const Team(id: '3', name: 'MUN', abbreviation: 'MUN'),
        away: const Team(id: '4', name: 'TOT', abbreviation: 'TOT'),
        startTime: DateTime.now().subtract(const Duration(hours: 3)),
        status: 'Final',
        homeScore: '2',
        awayScore: '1',
        venue: 'Old Trafford',
        isCompleted: true,
        state: 'post',
      );

      final controller = LiveScoresController(
          _MockRepository(sampleMatches: [match1, match2, match3]));
      await controller.refresh();

      expect(controller.live.length, 1);
      expect(controller.upcoming.length, 1);
      expect(controller.finished.length, 1);
      controller.dispose();
    });

    test('SportsController handles caching and error flags', () async {
      final controller = SportsController(_MockRepository(
        sampleMatches: [SportMatch.fromEspn(event)],
        returnFromCache: true,
        mockError: 'Network timeout',
      ));
      await controller.refresh();
      expect(controller.showingCachedData, isTrue);
      expect(controller.error, 'Network timeout');
      expect(controller.matches.length, 1);
      controller.dispose();
    });

    test('SportsRepository fetches popular teams', () async {
      const mockTeam = Team(id: '359', name: 'Arsenal', abbreviation: 'ARS');
      final repo = _MockRepository(teams: [mockTeam]);
      final teams = await repo.popularTeams();
      expect(teams.single.name, 'Arsenal');
    });

    test(
        'SportsRepository uses exact bundled mock data when API is unavailable',
        () async {
      SharedPreferences.setMockInitialValues({});
      final repo = SportsRepository(
        api: ApiService(client: _UnavailableClient()),
      );

      final scores = await repo.allMatches();
      final news = await repo.allNews();

      expect(scores.fromCache, isTrue);
      expect(scores.error, contains('saved/mock data'));
      expect(scores.data.first.id, 'match-live-1');
      expect(scores.data.first.home.name, 'Arsenal');
      expect(news.data.first.id, 'espn-news-1');
      expect(news.data.first.title,
          'Arsenal secure crucial derby victory as title race intensifies');
    });
  });

  group('UI Widgets & Screen tests', () {
    testWidgets('Match detail displays teams, score, and key events',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final match = SportMatch.fromEspn(event);
      await tester.pumpWidget(MaterialApp(
        onGenerateRoute: (settings) {
          if (settings.name == '/match') {
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => Match(
                repository: _MockRepository(),
                favorites: FavoritesController(
                    firestoreService: _MockFirestoreService()),
              ),
            );
          }
          return null;
        },
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () =>
                Navigator.pushNamed(context, '/match', arguments: match),
            child: const Text('Open Match'),
          ),
        ),
      ));

      await tester.tap(find.text('Open Match'));
      await tester.pumpAndSettle();

      expect(find.text('Arsenal'), findsOneWidget);
      expect(find.text('Chelsea'), findsOneWidget);
      expect(find.text('Key events'), findsOneWidget);
      expect(find.text('Goal scored by Saka'), findsOneWidget);
    });

    testWidgets('Team detail shows team info, follow toggle, and fixtures',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      const team = Team(id: 'ars', name: 'Arsenal', abbreviation: 'ARS');
      final favorites =
          FavoritesController(firestoreService: _MockFirestoreService());
      final repo = _MockRepository(sampleMatches: [SportMatch.fromEspn(event)]);

      await tester.pumpWidget(MaterialApp(
        onGenerateRoute: (settings) {
          if (settings.name == '/team') {
            return MaterialPageRoute(
              settings: settings,
              builder: (_) =>
                  screen.Team(repository: repo, favorites: favorites),
            );
          }
          return null;
        },
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () =>
                Navigator.pushNamed(context, '/team', arguments: team),
            child: const Text('Open Team'),
          ),
        ),
      ));

      await tester.tap(find.text('Open Team'));
      await tester.pumpAndSettle();

      expect(find.text('Arsenal'), findsWidgets);
      expect(find.text('Follow team'), findsOneWidget);

      await tester.tap(find.text('Follow team'));
      await tester.pump();
      expect(find.text('Following'), findsOneWidget);
    });

    testWidgets('LeagueFilterSheet displays supported leagues', (tester) async {
      SportLeague? selected;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                selected = await LeagueFilterSheet.show(
                    context, supportedLeagues.first);
              },
              child: const Text('Open Sheet'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('Filter by league'), findsOneWidget);
      expect(find.text('Premier League'), findsOneWidget);
      expect(find.text('NBA'), findsOneWidget);

      await tester.tap(find.text('NBA'));
      await tester.pump();
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();

      expect(selected?.label, 'NBA');
    });

    testWidgets('AuthScreen and AccountSheet render properly', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final auth = AuthController();
      final favorites =
          FavoritesController(firestoreService: _MockFirestoreService());

      await tester.pumpWidget(MaterialApp(
        home: AuthScreen(auth: auth),
      ));

      expect(find.text('Welcome Back to SportSphere'), findsOneWidget);
      expect(find.text('Sign In'), findsWidgets);
      expect(find.text('Continue as Guest'), findsOneWidget);

      await tester.tap(find.text('Create Account'));
      await tester.pump();
      expect(find.text('Join SportSphere'), findsOneWidget);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AccountSheet(auth: auth, favorites: favorites),
        ),
      ));

      expect(find.text('Followed Teams'), findsOneWidget);
      expect(find.text('Cloud Sync (Firestore)'), findsOneWidget);
    });
  });
}
