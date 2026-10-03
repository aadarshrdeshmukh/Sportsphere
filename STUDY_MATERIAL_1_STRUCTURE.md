# SportSphere Study Material 1: Project Structure and Symbol Guide

This guide explains the purpose of each tracked application folder and file. It focuses on symbols written by this project (classes, methods, functions, and reusable Flutter widgets), not generated files inside `build/`, `.dart_tool/`, or package dependencies.

## 1. System overview

```text
Flutter UI (screens + widgets)
        |
ChangeNotifier state controllers
        |
SportsRepository (fallback/orchestration)
   |        |             |
Express   ESPN        SharedPreferences/mock assets
API       direct
        |
Firebase Auth + Firestore for identity/favorites
```

The backend is an Express API gateway. It normalizes data from ESPN, optional API-Sports, BBC RSS, and TheSportsDB, then adds authentication and caching before the Flutter repository consumes it.

## 2. Top-level folders and files

| Path | Main responsibility | Why it exists |
|---|---|---|
| `lib/` | Flutter/Dart application source | Keeps app code separate from platform shells and tests. |
| `lib/models/` | Immutable domain objects | Gives screens and services typed match, team, league, and article data. |
| `lib/repositories/` | Data orchestration and fallback | Prevents UI/controllers from knowing where data came from. |
| `lib/screens/` | Full pages and modal filter screens | Contains user-facing feature flows. |
| `lib/services/` | Network, cache, and Firebase integrations | Isolates external systems behind small APIs. |
| `lib/state/` | `ChangeNotifier` controllers | Stores UI state and notifies listening widgets. |
| `lib/theme/` | Colors, typography, themes, and design tokens | Makes visual behavior consistent and supports light/dark/system modes. |
| `lib/widgets/` | Shared presentation components | Avoids duplicating match cards, badges, navigation, and empty states. |
| `assets/` | Mock JSON, images, and SVG illustrations | Supplies offline demo data and branding. |
| `server/src/` | Node/Express backend | Provides a secure, cached aggregation API. |
| `server/test/` | API integration tests | Verifies routes through a real ephemeral HTTP server. |
| `test/` | Flutter unit/widget tests | Verifies models, controllers, services, and startup UI. |
| `.github/workflows/` | CI build automation | Reproducibly builds Android and iOS artifacts. |
| `pubspec.yaml` | Flutter dependencies/assets/SDK constraints | Defines the Dart package and build inputs. |
| `server/package.json` | Node dependencies and scripts | Defines the backend runtime and test commands. |

## 3. Flutter entrypoint and configuration

### `lib/main.dart`

- `main()` initializes Flutter bindings, Firebase, shared preferences, and controllers before calling `runApp`; this guarantees dependencies are ready before the first frame.
- `App` (`StatefulWidget`) is the root widget and owns application-wide authentication/theme wiring.
- `_AppState` listens for auth changes, disposes listeners, and builds the correct authenticated/unauthenticated branch.
- `_HomeShell` and `_HomeShellState` manage the tabbed home experience.
- `_switchTab(int)` changes the selected tab using `setState`.
- `TabSwitcher` (`InheritedWidget`) exposes tab-selection context without passing callbacks through every child.
- `updateShouldNotify` returns `false` because the inherited object is not used as a change-notification channel.
- Main Flutter widgets used: `MaterialApp`, `AnimatedBuilder`, `Theme`, `IndexedStack`, navigation widgets, and the feature screens.

### `lib/firebase_options.dart`

- `DefaultFirebaseOptions` stores platform-specific `FirebaseOptions`.
- `currentPlatform` selects Android, iOS, macOS, or web settings.
- `android`, `ios`, `macos`, and `web` provide Firebase configuration objects.
- The class centralizes generated Firebase setup so `main()` does not contain platform conditionals.

### `lib/theme/app_theme.dart`

- `AppTheme` groups the visual design system.
- `light`, `dark`, and `system` theme builders return Material 3 `ThemeData`.
- Private color/text/shape helpers create consistent `ColorScheme`, `TextTheme`, button, input, card, dialog, and navigation styling.
- Flutter types used include `ThemeData`, `ColorScheme`, `TextTheme`, `TextStyle`, `ButtonStyle`, and `InputDecorationTheme`.
- The reason is single-source styling: changing a token updates every screen and supports accessibility/theme switching.

## 4. Domain models: `lib/models/`

### `news_article.dart`

- `NewsArticle` is an immutable article model.
- Constructor initializes title, description, image/link, publication time, and category fields.
- `NewsArticle.fromEspn` maps an ESPN article payload to the app model.
- `toJson`/`fromJson`-style serialization supports cache/mock persistence where present.
- Purpose: normalize an external article shape before it reaches widgets.

### `sport_league.dart`

- `SportLeague` is a small immutable value object containing `label`, `sport`, and league key.
- `supportedLeagues` is the canonical list for Premier League, Champions League, NBA, and NFL.
- Purpose: one typed league definition can drive filters, API URLs, labels, and grouping.

### `sport_match.dart`

- `SportMatch` is the immutable match/score model.
- Constructor captures event identity, teams, score, date, status, league, venue, and optional metadata.
- `SportMatch.fromEspn` normalizes ESPN scoreboard events.
- Serialization helpers support cached/mock data.
- Purpose: screens render a stable model regardless of upstream API format.

### `team.dart`

- `Team` is the immutable team model.
- Constructor stores ID, name, logo, abbreviation, color, and league data.
- `Team.fromEspn` maps an ESPN team.
- `Team.fromJson` restores a team from local/server JSON.
- Serialization helpers support favorites persistence and API responses.

## 5. Data layer: repository and services

### `lib/repositories/sports_repository.dart`

- `DataResult<T>` wraps returned data with source/fallback metadata, allowing the UI to explain cached/mock results.
- `SportsRepository` coordinates all sources.
- `allMatches({DateTime? date})` loads all supported league matches.
- `_scoreboardKey` creates a stable cache key from league/date.
- `news` loads one league's news with fallback handling.
- `allNews` aggregates news across leagues.
- `_cacheNews` writes normalized news to local storage.
- `teamMatches` loads fixtures/results for one team.
- `logoFallback` resolves a missing team logo.
- `popularTeams` loads the starter team catalog.
- `searchTeams` filters/searches available teams.
- Important reason: this is the boundary between presentation/state and unreliable network providers. It tries the local API, direct ESPN, cache, and bundled mocks in a controlled order.

### `lib/services/api_service.dart`

- `ApiService` is the typed HTTP client for the Express gateway.
- Internal request/decoding helpers build URLs, inspect status codes, and decode JSON.
- `matches` retrieves scoreboards/schedules.
- `news` retrieves a filtered news feed.
- `popularTeams` retrieves the team catalog.
- `teamMatches` retrieves team fixtures.
- `getFavorites` retrieves cloud favorites for an authenticated user.
- Reason: centralizes base URL selection, HTTP errors, and response parsing.

### `lib/services/espn_service.dart`

- `EspnService` is the direct-provider fallback.
- `scoreboard` requests and maps ESPN scoreboard events.
- `news` requests ESPN news.
- `bbcNews` parses BBC RSS as a news fallback.
- Local `value` extracts RSS XML tags.
- `teamLogo` obtains a logo fallback.
- Reason: the app can still provide useful sports data when the local backend is unavailable.

### `lib/services/cache_service.dart`

- `CacheService.read` reads a string from `SharedPreferences`.
- `write` stores a string.
- `writeJson` encodes and stores JSON.
- Reason: preserves last-known content and supports offline-friendly behavior.

### `lib/services/firestore_service.dart`

- `FirestoreService.fetchFavorites` reads a user's Firestore favorite-team collection.
- `saveFavorite` creates/updates a favorite document.
- `removeFavorite` deletes one favorite.
- `syncLocalToRemote` uploads locally selected teams after sign-in.
- Reason: separates cloud persistence from `FavoritesController` and keeps Firebase details out of UI code.

## 6. State controllers: `lib/state/`

All controllers extend `ChangeNotifier`; mutations update fields and call `notifyListeners()` so listening widgets rebuild.

### `auth_controller.dart`

- `AuthController` owns Firebase authentication state.
- `_init` subscribes to auth-state changes.
- `signInWithEmail`, `signUpWithEmail`, `signInWithGoogle`, and `signInAnonymously` implement the supported login paths.
- `signOut` terminates the session.
- `_formatAuthError` converts Firebase exceptions into user-readable messages.
- `dispose` closes subscriptions.
- Reason: one observable source of truth for account state and authentication errors.

### `favorites_controller.dart`

- `FavoritesController` stores favorite teams locally and remotely.
- `contains` checks a team ID.
- `load` restores local/mock favorites.
- `syncWithUser` selects local or cloud synchronization.
- `_syncWithFirestore` downloads cloud favorites.
- `toggle` adds/removes a team.
- `remove` deletes a team.
- `_saveLocal` persists the local collection.
- Reason: favorite behavior is reused by home, team detail, account, and favorites screens.

### `sports_controller.dart`

- `SportsController` owns schedule/general scoreboard state.
- `refresh` loads matches for a date.
- `selectLeague` changes the active league and refreshes.
- `selectDate` delegates date changes to `refresh`.
- `_dateOnly` normalizes date comparisons.
- `startLivePolling` and `stopLivePolling` manage periodic refresh.
- `dispose` cancels timers.

### `live_scores_controller.dart`

- `LiveScoresController` owns live-only match state.
- `refresh` retrieves live matches.
- `selectLeague` filters a league.
- `startPolling`/`stopPolling` manage the 45-second timer.
- `didChangeAppLifecycleState` pauses/resumes polling when the app backgrounds/returns.
- `dispose` unregisters lifecycle observation and cancels timers.

### `news_controller.dart`

- `NewsController.refresh` loads the current news feed.
- `selectLeague` changes the news league.
- `selectCategory` applies a category filter.
- Reason: keeps filtering/loading state outside article widgets.

### `theme_controller.dart`

- `ThemeController._load` restores the saved theme mode.
- `setMode` persists and broadcasts light/dark/system selection.
- Reason: theme choice survives restarts and is available throughout the app.

## 7. Screens: `lib/screens/`

Every screen's public widget is a `StatefulWidget` when it owns mutable/loading state and a `StatelessWidget` for static state pages. `build` composes Material/Cupertino widgets; `initState`, `dispose`, and `didChangeDependencies` manage lifecycle.

| File and public class | Important private methods/classes | Main widgets/concepts | Why used |
|---|---|---|---|
| `splash_screen.dart` / `Splash` | `_checkReturningUser`, `_onGetStarted`, `_onSignIn`, `_onExploreAsGuest`, `_buildMinimalTag` | `Scaffold`, `SvgPicture`, buttons | First-run routing and branding. |
| `onboarding_screen.dart` / `Onboarding` | `_fetchTeams`, `_onSearchChanged`, `_clearSearch`, `_continue` | `TextField`, `ListView`, `Checkbox`/selection controls | Lets users choose favorite teams before entering the app. |
| `auth_screen.dart` / `AuthScreen` | `_handleBack`, `_submit`, `_continueWithGoogle` | `Form`, `TextFormField`, `ElevatedButton`, progress/error UI | Validates and submits account credentials. |
| `home_dashboard_screen.dart` / `Home` | `_content`, `_greetingCard`, `_liveNowSection`, `_buildLiveMatchCard`, `_myTeamsSection`, `_todaysMatchesSection`, `_topNewsSection`, formatting helpers | `RefreshIndicator`, `ListView`, `Card`, `CachedNetworkImage` | Presents the high-value dashboard and live updates. |
| `schedule_screen.dart` / `Schedule` | `_pickCustomDate`, `_jumpToNextWeekend`, `_filteredMatches`, `_showFilterSheet`, `_matchTile`, `_age`, `_sameDay`; `_ScheduleFilterSheet` | date picker, filter chips, list tiles, bottom sheet | Browses fixtures by date/status/league. |
| `live_scores_screen.dart` / `Live` | `_showFilterSheet`, `_buildFilterBar`, `_scoreList`, `_matchCard`, `_emptyIcon`, `_emptyTitle`; `_LiveFilterSheet`, `_ScoreNotice` | `RefreshIndicator`, grouped lists, bottom sheet | Shows current matches and clear empty/error states. |
| `news_feed_screen.dart` / `News` | `_showFilterSheet`, `_buildCategoryFilters`, `_articleCard`, `_relativeTime`; `_NewsFilterSheet`, `_NewsNotice` | article cards, filter chips, bottom sheet | Provides filtered news with readable timestamps. |
| `news_article_detail_screen.dart` / `Article` | `_ArticleImage`, `_CategoryBadge`, `_CircleAction`, `_ArticleFooter` | image, badges, share/open actions, scroll view | Displays a complete article and external link actions. |
| `match_detail_screen.dart` / `Match` | `_hero`, `_heroTeam`, `_heroIcon`, `_overview`, `_timeline`, `_stats`, `_eventPanel`, `_emptyPanel`, `_fixturePanel`, `_eventIcon`, `_leagueLabel` | hero layout, cards, timeline, stats | Explains one match beyond its score. |
| `team_detail_screen.dart` / `Team` | `_teamHeader`, `_tabs`, `_fixtureList`, `_fixtureCard`, `_opponent`, `_leagueName` | tabs, team logo, fixture cards | Shows team identity, fixtures, and favorite action. |
| `favorites_screen.dart` / `Favorites` | `_loadMatches`, `_onFavoritesChanged`, `_teamBubble`, `_teamColor`, `_matchCard`, `_leagueName` | `GridView`/lists, cards, refresh UI | Combines selected teams with their upcoming matches. |
| `league_filter_sheet.dart` / `LeagueFilterSheet` | state initialization and selection | `showModalBottomSheet`, radio/list controls | Reusable league selection surface. |
| `settings_screen.dart` / `SettingsScreen` | `_SectionTitle`, `_SettingsTile`, `_ThemeOptionTile` | list tiles, switches, theme selectors | Centralizes preferences/account actions. |
| `loading_state_screen.dart` / `Loading` | `build` | `CircularProgressIndicator`, `Scaffold` | Standard loading state. |
| `error_state_screen.dart` / `ErrorState` | `build` | error icon/message/retry UI | Explicit failure state instead of silent fallback. |
| `empty_state_screen.dart` / `EmptyState` | `build` | empty icon/message and navigation | Explains valid zero-result states. |

## 8. Reusable widgets: `lib/widgets/`

### `widgets.dart`

- `TeamBadge`: logo with initials fallback; avoids broken-image UI.
- `StatusBadge`: compact live/upcoming/final status indicator.
- `MatchCard`: reusable match summary card; `_teamRow` renders one team row.
- `BroadcastHeroCard`: prominent featured/live broadcast card.
- `NewsCard`: standard article preview.
- `FeaturedNewsCard`: larger article presentation for dashboard use.
- `SportFilterChip`: consistent filter control.
- `SectionHeader`: title plus optional action.
- `AppEmptyState`: shared empty-result message.
- `BottomNav`: reusable bottom navigation presentation.
- Every widget implements `build`; the widgets choose `Row`, `Column`, `Card`, `Expanded`, `Image`, `Icon`, and interaction widgets to keep screens declarative and consistent.

### `account_sheet.dart`

- `AccountSheet` displays sign-in/account state, favorites, and sign-out actions.
- Uses `showModalBottomSheet`-style composition, `ListTile`, icons, and controller callbacks.
- Reason: account actions are available without replacing the current screen.

### `company_logo.dart`

- `CompanyLogo` loads a remote logo using `CachedNetworkImage`.
- `_loading` renders a placeholder; `_fallback` renders a safe local/initial fallback.
- `url_launcher` integration opens a company/provider URL where appropriate.

### `app_navigation.dart`

- `AppNavigation` is a navigation abstraction/widget placeholder with `build`.
- It currently returns a compact placeholder (`SizedBox.shrink`) so navigation can be replaced without changing callers.

## 9. Backend: `server/src/`

### Configuration and entrypoints

- `config/env.js`: `config` reads port, environment, CORS, Firebase, and optional API-Sports settings from environment variables.
- `config/firebase.js`: initializes Firebase Admin once, then exports `auth` and `db`.
- `app.js`: creates the Express app, installs CORS/JSON/security/error middleware, registers `/api/v1` routes, and exposes `/health`.
- `server.js`: starts the HTTP server and handles startup errors.

### Routes

- `routes/index.js` mounts versioned routers.
- `favorites.routes.js`, `match.routes.js`, `news.routes.js`, `scores.routes.js`, and `team.routes.js` create Express `Router` instances and map HTTP verbs/paths to controllers.
- Route modules keep URL design separate from handler logic.

### Controllers

- `ScoresController.getScoreboard`, `getScores`, `getLiveScores`: return normalized schedules/live scores, including all-league aggregation and cache metadata.
- `NewsController.getNews`: returns ESPN/BBC-backed news and category filtering.
- `MatchController.getMatchSummary`: returns one event summary/timeline.
- `TeamController.getPopularTeams`, `getTeamMatches`: returns team catalogs and matching fixtures.
- `FavoritesController.getFavorites`, `saveFavorite`, `removeFavorite`: CRUD cloud favorites.
- Controller methods use `(req, res, next)` and forward errors to centralized middleware.

### Middleware

- `requireAuth` rejects missing/invalid Bearer tokens for protected favorites routes.
- `optionalAuth` accepts public requests while attaching a verified user when a token is present.
- `errorHandler` converts thrown/rejected errors into consistent HTTP responses.

### Backend services

- `CacheService.constructor`, `get`, `set`, `has`, `del`, `flush`, `getOrSet`: in-memory TTL cache to reduce provider calls and improve latency.
- `EspnService`: `normalizeLeague`, `getScoreboard`, `getNews`, `getAllNews`, `getMatchSummary`, `getPopularTeams`; `sportLabel` and `categorize` normalize provider data.
- `ApiSportsService`: `seasonFor`, `dateValue`, `statusValue`, `scoreValue`, `normalizeEvent`, and API methods provide optional normalized API-Sports data.
- `BbcService`: fetches RSS and `_extractTag` parses XML fields for news fallback.
- `TheSportsDbService`: searches a team and returns badge/logo fallback.

## 10. Tests, assets, and CI

### Tests

- `test/sports_logic_test.dart`: model parsing, repository/controller behavior, persistence, auth/firestore fakes, and screen construction.
- `test/widget_test.dart`: launches the app and checks startup widget behavior.
- `server/test/api.test.js`: starts the Express app on an ephemeral port and tests health, scores, live scores, news, shorthand leagues, and unauthorized favorites.

### Assets

- `assets/mock/*.json`: offline favorites/news/scoreboard fixtures.
- `assets/svg/*.svg`: logos, navigation icons, and hero illustrations.
- `assets/images/*`: application and provider branding.

### `.github/workflows/build-mobile.yml`

- Workflow triggers on pushes to `main`/`master`, pull requests, and manual dispatch.
- `actions/checkout@v4` obtains source.
- `subosito/flutter-action@v2` installs/caches stable Flutter.
- `flutter pub get` resolves Dart packages.
- `flutter create --platforms=android|ios --org com.example .` regenerates platform scaffolding in CI.
- `flutter build apk --release` creates Android output.
- `flutter build ios --release --no-codesign` creates an unsigned iOS app.
- `ditto` packages the iOS `.app`.
- `actions/upload-artifact@v4` publishes APK/ZIP artifacts.
- Reason: every pull request gets reproducible mobile build evidence without requiring local signing credentials.

