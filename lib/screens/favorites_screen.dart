import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';
import '../models/sport_match.dart';
import '../repositories/sports_repository.dart';
import '../state/auth_controller.dart';
import '../state/favorites_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/account_sheet.dart';
import '../widgets/app_navigation.dart';
import '../widgets/widgets.dart';

class Favorites extends StatefulWidget {
  const Favorites({
    super.key,
    required this.repository,
    required this.favorites,
    this.auth,
  });

  final SportsRepository repository;
  final FavoritesController favorites;
  final AuthController? auth;

  @override
  State<Favorites> createState() => _FavoritesState();
}

class _FavoritesState extends State<Favorites> {
  Future<List<SportMatch>>? _matches;

  @override
  void initState() {
    super.initState();
    _matches = _loadMatches();
  }

  Future<List<SportMatch>> _loadMatches() async {
    final matches = <SportMatch>[];
    for (final team in widget.favorites.teams) {
      matches.addAll(await widget.repository.teamMatches(team));
    }
    final ids = <String>{};
    return matches.where((m) => !m.isCompleted && ids.add(m.id)).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: widget.favorites,
      builder: (_, __) => Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('My Favorites'),
          actions: [
            IconButton(
              tooltip: 'Add Teams',
              icon: const Icon(Iconsax.add_circle),
              onPressed: () => Navigator.pushNamed(context, '/onboarding'),
            ),
            if (widget.auth != null)
              IconButton(
                tooltip: 'Account & Sync',
                icon: const Icon(Iconsax.user),
                onPressed: () => AccountSheet.show(
                  context,
                  auth: widget.auth!,
                  favorites: widget.favorites,
                ),
              ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: () async => setState(() => _matches = _loadMatches()),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            children: [
              // ── 1. Header: Followed Teams ──
              Row(
                children: [
                  const Text(
                    'Followed Teams',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const Spacer(),
                  if (widget.favorites.teams.isNotEmpty)
                    TextButton.icon(
                      onPressed: () =>
                          Navigator.pushNamed(context, '/onboarding'),
                      icon: const Icon(Iconsax.add, size: 16),
                      label: const Text('Add Team'),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        textStyle: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),

              if (widget.favorites.teams.isEmpty)
                AppEmptyState(
                  title: 'No favorite teams added',
                  message:
                      'Pick your clubs and teams to receive customized score alerts and match schedules.',
                  icon: Iconsax.star_1,
                  actionLabel: '+ Choose Teams',
                  onAction: () => Navigator.pushNamed(context, '/onboarding'),
                )
              else
                ...widget.favorites.teams.map((team) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Material(
                        color: colorScheme.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(
                            color: colorScheme.outline,
                            width: 1,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 2),
                          leading: TeamBadge(
                            name: team.name,
                            logoUrl: team.logoUrl,
                            size: 34,
                          ),
                          title: Text(
                            team.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          subtitle: Text(
                            team.abbreviation,
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                          onTap: () => Navigator.pushNamed(
                            context,
                            '/team',
                            arguments: team,
                          ),
                          trailing: IconButton(
                            tooltip: 'Unfollow ${team.name}',
                            icon: const Icon(
                              Iconsax.heart_copy,
                              color: AppTheme.live,
                              size: 22,
                            ),
                            onPressed: () async {
                              await widget.favorites.remove(team.id);
                              setState(() => _matches = _loadMatches());
                            },
                          ),
                        ),
                      ),
                    )),

              const SizedBox(height: 24),

              // ── 2. Header: Upcoming Matches ──
              const Text(
                'Upcoming Matches',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 10),

              FutureBuilder<List<SportMatch>>(
                future: _matches,
                builder: (_, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      widget.favorites.teams.isNotEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 48),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final matches = snapshot.data ?? [];
                  if (matches.isEmpty) {
                    return AppEmptyState(
                      title: 'No upcoming matches',
                      message: widget.favorites.teams.isEmpty
                          ? 'Follow teams above to track their fixtures here.'
                          : 'Your followed clubs have no games in the active calendar.',
                      icon: Iconsax.calendar,
                    );
                  }
                  return Column(
                    children: matches
                        .map((match) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () => Navigator.pushNamed(
                                  context,
                                  '/match',
                                  arguments: match,
                                ),
                                child: MatchCard(
                                  league: match.league.replaceAll('-', ' '),
                                  home: match.home.name,
                                  away: match.away.name,
                                  hs: match.homeScore,
                                  as: match.awayScore,
                                  time: DateFormat('EEE, d MMM • ')
                                      .add_jm()
                                      .format(match.startTime.toLocal()),
                                  live: match.isLive,
                                ),
                              ),
                            ))
                        .toList(),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
        bottomNavigationBar: const AppNavigation(index: 4),
      ),
    );
  }
}
