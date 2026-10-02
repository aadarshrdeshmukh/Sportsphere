import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'screens/auth_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/home_dashboard_screen.dart';
import 'screens/live_scores_screen.dart';
import 'screens/match_detail_screen.dart';
import 'screens/news_article_detail_screen.dart';
import 'screens/news_feed_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/schedule_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/team_detail_screen.dart';
import 'theme/app_theme.dart';
import 'repositories/sports_repository.dart';
import 'state/auth_controller.dart';
import 'state/favorites_controller.dart';
import 'state/theme_controller.dart';
import 'widgets/widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {
    // If Firebase is already initialized or running in an environment without native plugins.
  }
  runApp(const App());
}

class App extends StatefulWidget {
  const App({super.key, this.auth, this.favorites, this.repository});
  final AuthController? auth;
  final FavoritesController? favorites;
  final SportsRepository? repository;

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final SportsRepository _repository;
  late final FavoritesController _favorites;
  late final AuthController _auth;
  late final ThemeController _theme;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? SportsRepository();
    _favorites = widget.favorites ?? FavoritesController();
    _auth = widget.auth ?? AuthController();
    _theme = ThemeController();

    _favorites.load(userId: _auth.user?.uid);
    _auth.addListener(_onAuthChanged);
  }

  void _onAuthChanged() {
    _favorites.syncWithUser(_auth.user?.uid);
  }

  @override
  void dispose() {
    _auth.removeListener(_onAuthChanged);
    _auth.dispose();
    _favorites.dispose();
    _theme.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _theme,
        builder: (_, __) => MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: _theme.mode,
          initialRoute: '/',
          routes: {
            '/': (_) => const Splash(),
            '/home': (_) => _HomeShell(
                  repository: _repository,
                  favorites: _favorites,
                  auth: _auth,
                  theme: _theme,
                ),
            '/onboarding': (_) =>
                Onboarding(favorites: _favorites, repository: _repository),
            '/auth': (_) => AuthScreen(auth: _auth),
            '/settings': (_) => SettingsScreen(
                  themeController: _theme,
                  auth: _auth,
                  favorites: _favorites,
                ),
          },
          onGenerateRoute: (settings) {
            switch (settings.name) {
              case '/article':
                return MaterialPageRoute(
                    settings: settings, builder: (_) => const Article());
              case '/match':
                return MaterialPageRoute(
                    settings: settings,
                    builder: (_) =>
                        Match(repository: _repository, favorites: _favorites));
              case '/team':
                return MaterialPageRoute(
                    settings: settings,
                    builder: (_) =>
                        Team(repository: _repository, favorites: _favorites));
            }
            return null;
          },
        ),
      );
}

class _HomeShell extends StatefulWidget {
  final SportsRepository repository;
  final FavoritesController favorites;
  final AuthController auth;
  final ThemeController theme;

  const _HomeShell({
    required this.repository,
    required this.favorites,
    required this.auth,
    required this.theme,
  });

  @override
  State<_HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<_HomeShell> {
  int _tabIndex = 0;

  void _switchTab(int index) => setState(() => _tabIndex = index);

  @override
  Widget build(BuildContext context) {
    return TabSwitcher(
      switchTab: _switchTab,
      child: Scaffold(
        body: IndexedStack(
          index: _tabIndex,
          children: [
            Home(
              repository: widget.repository,
              favorites: widget.favorites,
              auth: widget.auth,
            ),
            Schedule(repository: widget.repository),
            News(repository: widget.repository),
            Live(repository: widget.repository),
            Favorites(
              repository: widget.repository,
              favorites: widget.favorites,
              auth: widget.auth,
            ),
          ],
        ),
        bottomNavigationBar: BottomNav(
          index: _tabIndex,
          onDestinationSelected: _switchTab,
        ),
      ),
    );
  }
}

/// Inherited widget that lets child screens switch the shell's active tab.
class TabSwitcher extends InheritedWidget {
  const TabSwitcher({super.key, required this.switchTab, required super.child});
  final void Function(int index) switchTab;

  static TabSwitcher? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<TabSwitcher>();

  @override
  bool updateShouldNotify(TabSwitcher oldWidget) => false;
}
