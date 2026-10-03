# SportSphere Study Material 2: Symbol, Widget, and Technology Reference

This is a compact revision table. Symbol names are grouped per file when a file contains many private UI helpers; this keeps the table readable while still covering the complete project inventory.

## Flutter application table

| File | Function/class/method names used | Widgets/packages used | Brief reason |
|---|---|---|---|
| `lib/main.dart` | `main`, `App`, `_AppState`, `initState`, `_onAuthChanged`, `dispose`, `build`, `_HomeShell`, `_HomeShellState`, `_switchTab`, `TabSwitcher`, `updateShouldNotify` | `MaterialApp`, `AnimatedBuilder`, `IndexedStack`, `InheritedWidget` | Bootstraps Firebase/controllers, chooses auth branch, and preserves tab state. |
| `lib/firebase_options.dart` | `DefaultFirebaseOptions`, `currentPlatform`, `android`, `ios`, `macos`, `web` | `FirebaseOptions`, `TargetPlatform` | Supplies platform-specific Firebase setup. |
| `lib/models/news_article.dart` | `NewsArticle`, constructor, `fromEspn`, JSON conversion | Plain Dart immutable model | Normalizes news data and supports persistence. |
| `lib/models/sport_league.dart` | `SportLeague`, constructor, `supportedLeagues` | Plain Dart value object | Canonical league metadata drives filters and APIs. |
| `lib/models/sport_match.dart` | `SportMatch`, constructor, `fromEspn`, JSON conversion | Plain Dart immutable model | Provides a stable match shape to every layer. |
| `lib/models/team.dart` | `Team`, constructor, `fromEspn`, `fromJson`, JSON conversion | Plain Dart immutable model | Represents teams consistently across API, favorites, and UI. |
| `lib/repositories/sports_repository.dart` | `DataResult`, `SportsRepository`, `allMatches`, `_scoreboardKey`, `news`, `allNews`, `_cacheNews`, `teamMatches`, `logoFallback`, `popularTeams`, `searchTeams` | `rootBundle`, JSON, async `Future` | Orchestrates API/direct/cache/mock fallback paths. |
| `lib/services/api_service.dart` | `ApiService`, request/decode helpers, `matches`, `news`, `popularTeams`, `teamMatches`, `getFavorites` | `http`, `Uri`, JSON | Encapsulates calls to the Express API. |
| `lib/services/espn_service.dart` | `EspnService`, `scoreboard`, `news`, `bbcNews`, RSS `value`, `teamLogo` | `http`, JSON, RSS parsing | Keeps sports data available when backend is unavailable. |
| `lib/services/cache_service.dart` | `CacheService`, `read`, `write`, `writeJson` | `SharedPreferences`, `jsonEncode` | Stores last-known data for offline use. |
| `lib/services/firestore_service.dart` | `FirestoreService`, `fetchFavorites`, `saveFavorite`, `removeFavorite`, `syncLocalToRemote` | Firebase Auth/Firestore | Persists authenticated user favorites in the cloud. |
| `lib/state/auth_controller.dart` | `AuthController`, `_init`, `signInWithEmail`, `signUpWithEmail`, `signInWithGoogle`, `signInAnonymously`, `signOut`, `_formatAuthError`, `dispose` | `ChangeNotifier`, Firebase Auth | Central observable authentication state and error translation. |
| `lib/state/favorites_controller.dart` | `FavoritesController`, `contains`, `load`, `syncWithUser`, `_syncWithFirestore`, `toggle`, `remove`, `_saveLocal` | `ChangeNotifier`, `SharedPreferences` | Manages local/cloud favorite synchronization. |
| `lib/state/sports_controller.dart` | `SportsController`, `refresh`, `selectLeague`, `selectDate`, `_dateOnly`, `startLivePolling`, `stopLivePolling`, `dispose` | `ChangeNotifier`, `Timer` | Owns schedule selection and periodic refresh. |
| `lib/state/live_scores_controller.dart` | `LiveScoresController`, `refresh`, `selectLeague`, `startPolling`, `stopPolling`, `didChangeAppLifecycleState`, `dispose` | `ChangeNotifier`, `WidgetsBindingObserver`, `Timer` | Updates live scores while saving battery in background. |
| `lib/state/news_controller.dart` | `NewsController`, `refresh`, `selectLeague`, `selectCategory` | `ChangeNotifier` | Owns feed loading and filters. |
| `lib/state/theme_controller.dart` | `ThemeController`, `_load`, `setMode` | `ChangeNotifier`, `ThemeMode`, `SharedPreferences` | Persists system/light/dark preference. |
| `lib/theme/app_theme.dart` | `AppTheme`, `light`, `dark`, `system`, private token/style builders | `ThemeData`, `ColorScheme`, `TextTheme`, Material 3 | Centralizes design tokens and accessibility-friendly themes. |
| `lib/screens/splash_screen.dart` | `Splash`, `_SplashState`, `initState`, `_checkReturningUser`, `_onGetStarted`, `_onSignIn`, `_onExploreAsGuest`, `_buildMinimalTag`, `build` | `Scaffold`, SVG/image widgets, buttons | Handles first-run and returning-user navigation. |
| `lib/screens/onboarding_screen.dart` | `Onboarding`, `_fetchTeams`, `_onSearchChanged`, `_clearSearch`, `_continue`, `build` | `TextField`, `ListView`, selection controls | Collects favorite teams during onboarding. |
| `lib/screens/auth_screen.dart` | `AuthScreen`, `_handleBack`, `_submit`, `_continueWithGoogle`, `dispose`, `build` | `Form`, `TextFormField`, buttons, progress UI | Validates and submits authentication. |
| `lib/screens/home_dashboard_screen.dart` | `Home`, lifecycle methods, `_content`, `_greetingCard`, `_liveNowSection`, `_buildLiveMatchCard`, `_teamSmallBadge`, `_initialBadge`, `_myTeamsSection`, `_todaysMatchesSection`, `_topNewsSection`, `_formatLeagueName`, `_age`, `_greetingTime` | `RefreshIndicator`, `ListView`, `Card`, `CachedNetworkImage` | Composes the primary dashboard from controller state. |
| `lib/screens/schedule_screen.dart` | `Schedule`, `_pickCustomDate`, `_jumpToNextWeekend`, `_filteredMatches`, `_showFilterSheet`, `_buildFilterBar`, `_matchTile`, `_age`, `_sameDay`, `_ScheduleFilterSheet`, `_buildFilterChip`, `_buildStatusChip` | date picker, filter chips, list tiles, modal sheet | Provides date/status/league schedule browsing. |
| `lib/screens/live_scores_screen.dart` | `Live`, `_showFilterSheet`, `_buildFilterBar`, `_scoreList`, `_matchCard`, `_emptyIcon`, `_emptyTitle`, `_LiveFilterSheet`, `_buildFilterChip`, `_ScoreNotice` | `RefreshIndicator`, grouped lists, bottom sheet | Shows live groups with filtering and explicit empty states. |
| `lib/screens/news_feed_screen.dart` | `News`, `_showFilterSheet`, `_buildCategoryFilters`, `_articleCard`, `_relativeTime`, `_NewsFilterSheet`, `_buildFilterChip`, `_NewsNotice` | article cards, chips, modal sheet | Displays and filters current sports news. |
| `lib/screens/news_article_detail_screen.dart` | `Article`, `_ArticleImage`, `_CategoryBadge`, `_CircleAction`, `_ArticleFooter` | scroll view, image, badges, action buttons | Presents full article content and link actions. |
| `lib/screens/match_detail_screen.dart` | `Match`, `_hero`, `_heroTeam`, `_heroIcon`, `_overview`, `_timeline`, `_stats`, `_sectionTitle`, `_eventPanel`, `_emptyPanel`, `_fixturePanel`, `_eventIcon`, `_leagueLabel` | `Card`, rows/columns, timeline/stat panels | Gives detailed context for one match. |
| `lib/screens/team_detail_screen.dart` | `Team`, `_teamHeader`, `_tabs`, `_fixtureList`, `_fixtureCard`, `_opponent`, `_leagueName` | tabs, logo, fixture cards | Displays a team's identity, fixtures, and favorite state. |
| `lib/screens/favorites_screen.dart` | `Favorites`, `_loadMatches`, `_onFavoritesChanged`, `_teamBubble`, `_teamColor`, `_matchCard`, `_leagueName` | `GridView`, lists, cards, refresh UI | Combines favorite teams and their match data. |
| `lib/screens/league_filter_sheet.dart` | `LeagueFilterSheet`, state creation/init/build | `SafeArea`, modal sheet, radio/list controls | Reusable league-selection UI. |
| `lib/screens/settings_screen.dart` | `SettingsScreen`, `_SectionTitle`, `_SettingsTile`, `_ThemeOptionTile`, `build` | `ListTile`, switches, theme controls | Exposes account and appearance preferences. |
| `lib/screens/loading_state_screen.dart` | `Loading`, `build` | `Scaffold`, `CircularProgressIndicator` | Consistent loading feedback. |
| `lib/screens/error_state_screen.dart` | `ErrorState`, `build` | error icon/message/retry widgets | Makes failures visible and actionable. |
| `lib/screens/empty_state_screen.dart` | `EmptyState`, `build` | empty-state layout and navigation | Explains a valid zero-result response. |
| `lib/widgets/widgets.dart` | `TeamBadge`, `_initial`, `StatusBadge`, `MatchCard`, `_teamRow`, `BroadcastHeroCard`, `NewsCard`, `FeaturedNewsCard`, `SportFilterChip`, `SectionHeader`, `AppEmptyState`, `BottomNav`; each `build` | `Card`, `Row`, `Column`, `Expanded`, `Image`, `Icon`, chips, buttons | Reusable visual language and less duplicated screen code. |
| `lib/widgets/account_sheet.dart` | `AccountSheet`, `build` | modal sheet, `ListTile`, icons | Account actions without leaving the current page. |
| `lib/widgets/company_logo.dart` | `CompanyLogo`, `build`, `_loading`, `_fallback` | `CachedNetworkImage`, placeholder containers, `url_launcher` | Resilient remote logo loading and provider links. |
| `lib/widgets/app_navigation.dart` | `AppNavigation`, `build` | `SizedBox.shrink` | Navigation abstraction point; currently a safe placeholder. |

## Backend table

| File | Function/class/method names used | Widgets/packages used | Brief reason |
|---|---|---|---|
| `server/src/config/env.js` | `config` | `dotenv`, `process.env` | Centralizes environment configuration. |
| `server/src/config/firebase.js` | Firebase Admin initialization, exported `auth`, `db` | `firebase-admin` | Enables server-side token verification and Firestore access. |
| `server/src/app.js` | Express app setup, health handler, route registration | `express`, `cors`, security middleware | Composes the HTTP application and API prefix. |
| `server/src/server.js` | server startup/listen handler | Node `http`/Express | Runs the backend process. |
| `server/src/routes/index.js` | router mounting | Express `Router` | Keeps route modules versioned and composable. |
| `server/src/routes/favorites.routes.js` | GET/POST/DELETE route mappings | `Router`, `requireAuth` | Protects cloud favorite endpoints. |
| `server/src/routes/match.routes.js` | match-summary route mapping | `Router` | Maps URL to match controller. |
| `server/src/routes/news.routes.js` | news route mapping | `Router` | Maps URL to news controller. |
| `server/src/routes/scores.routes.js` | scores/live route mappings | `Router` | Maps scoreboard endpoints. |
| `server/src/routes/team.routes.js` | popular/team-match route mappings | `Router` | Maps team endpoints. |
| `server/src/controllers/scores.controller.js` | `ScoresController.getScoreboard`, `getScores`, `getLiveScores` | Express `req/res/next`, `Set`, async | Aggregates, filters, caches, and returns score data. |
| `server/src/controllers/news.controller.js` | `NewsController.getNews` | Express, array filtering | Returns news and applies category filters. |
| `server/src/controllers/match.controller.js` | `MatchController.getMatchSummary` | Express, async | Returns a normalized match summary. |
| `server/src/controllers/team.controller.js` | `TeamController.getPopularTeams`, `getTeamMatches` | Express, async, event iteration | Returns teams and fixtures. |
| `server/src/controllers/favorites.controller.js` | `FavoritesController.getFavorites`, `saveFavorite`, `removeFavorite` | Firestore, Express validation | Performs authenticated favorite CRUD. |
| `server/src/middleware/auth.middleware.js` | `requireAuth`, `optionalAuth` | Firebase Admin Auth, Bearer headers | Enforces or optionally attaches identity. |
| `server/src/middleware/error.middleware.js` | `errorHandler` | Express error middleware | Provides one consistent error response path. |
| `server/src/services/cache.service.js` | `CacheService` constructor, `get`, `set`, `has`, `del`, `flush`, `getOrSet` | `Map`, TTL timestamps, promises | Reduces upstream latency and request volume. |
| `server/src/services/espn.service.js` | `sportLabel`, `categorize`, `normalizeLeague`, `EspnService.getScoreboard`, `getNews`, `getAllNews`, `getMatchSummary`, `getPopularTeams` | `axios`, `Set`, `Map` | Primary sports aggregation and normalization. |
| `server/src/services/api-sports.service.js` | `seasonFor`, `dateValue`, `statusValue`, `scoreValue`, `normalizeEvent`, API-Sports service methods | `axios`, mapping tables | Optional richer provider with normalized output. |
| `server/src/services/bbc.service.js` | `BbcService` RSS fetch and `_extractTag` | `axios`, regex, `Date` | News fallback when ESPN has no usable result. |
| `server/src/services/thesportsdb.service.js` | `TheSportsDbService` team search method | `axios` | Logo/badge fallback. |
| `server/test/api.test.js` | setup/teardown, health/scores/live/news/shorthand/auth tests | Node test runner, `fetch`, ephemeral HTTP server | Verifies the real API contract without a fixed port. |

## Tests, CI, and technology choice

| Area | Technology used | Why it is the best fit here | Why not the main alternatives |
|---|---|---|---|
| Mobile UI | Flutter + Dart | One declarative codebase, fast hot reload, strong widget library, native Android/iOS/web/desktop builds | Native Kotlin/Swift would duplicate UI; React Native adds a JavaScript bridge/runtime and a second ecosystem. |
| UI design | Material 3 | Accessible components, theming, responsive layout, and first-party Flutter support | Building every component from scratch increases inconsistency and maintenance. |
| State | `ChangeNotifier` | Lightweight, built into Flutter, sufficient for this controller-oriented app | Redux/BLoC/Riverpod can be excellent, but add ceremony/dependencies for this scope; `setState` alone would not share state cleanly. |
| Local persistence | `SharedPreferences` | Simple key/value cache works well for theme, favorites, and last-known JSON | SQLite is heavier for small preferences; secure storage is for secrets, not general cached sports data. |
| Backend | Node.js + Express | Fast I/O for many external HTTP requests, small REST middleware surface, easy deployment | A larger Java/Spring or .NET stack would add ceremony; a serverless-only design makes multi-provider caching/aggregation less direct. |
| HTTP | Dart `http` + Node `axios` | Simple, mature clients with async support and predictable error handling | Full GraphQL is unnecessary because the app consumes focused REST resources. |
| Auth/data | Firebase Auth + Firestore | Managed authentication and synchronized favorites without operating a custom identity/database stack | A custom PostgreSQL/auth service offers more control but requires migrations, servers, token handling, and operations. |
| Sports providers | ESPN + BBC + optional API-Sports/TheSportsDB | Multiple fallback providers improve availability and normalize provider-specific gaps | Depending on one provider creates a single outage/rate-limit failure point. |
| CI | GitHub Actions + Flutter stable | Native repository integration, reproducible Android/iOS artifact builds, cache support | Manual builds are not repeatable; a larger CI platform is unnecessary for this repository. |
| Testing | Flutter test + Node test runner | Tests native widget/controller behavior and actual HTTP routes | End-to-end device testing alone is slower and less diagnostic; a full browser automation stack is excessive for current API coverage. |

