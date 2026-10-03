import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../main.dart';
import '../models/sport_match.dart';
import '../models/team.dart';
import '../repositories/sports_repository.dart';
import '../state/auth_controller.dart';
import '../state/favorites_controller.dart';
import '../state/sports_controller.dart';
import '../widgets/account_sheet.dart';
import '../widgets/app_navigation.dart';

class Home extends StatefulWidget {
  const Home({
    super.key,
    required this.repository,
    required this.favorites,
    this.auth,
  });

  final SportsRepository repository;
  final FavoritesController favorites;
  final AuthController? auth;

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with WidgetsBindingObserver {
  late final SportsController _sports;

  @override
  void initState() {
    super.initState();
    _sports = SportsController(widget.repository)
      ..refresh()
      ..startLivePolling();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sports.stopLivePolling();
    _sports.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _sports.stopLivePolling();
    } else if (state == AppLifecycleState.resumed) {
      _sports
        ..refresh()
        ..startLivePolling();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? colorScheme.surface : const Color(0xFFF9FAFB),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: isDark ? colorScheme.surface : Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 18,
        title: Text(
          'SportSphere',
          style: TextStyle(
            color: isDark ? colorScheme.primary : const Color(0xFF0D5E46),
            fontWeight: FontWeight.w800,
            fontSize: 22,
            letterSpacing: -0.4,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Notifications',
            icon: Icon(
              Icons.notifications_none_rounded,
              size: 24,
              color: isDark ? Colors.white : const Color(0xFF1F2937),
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('No new notifications'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 18, left: 4),
            child: GestureDetector(
              onTap: () {
                if (widget.auth != null) {
                  AccountSheet.show(
                    context,
                    auth: widget.auth!,
                    favorites: widget.favorites,
                  );
                } else {
                  Navigator.pushNamed(context, '/settings');
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFE5E7EB),
                    width: 1.5,
                  ),
                ),
                child: const CircleAvatar(
                  radius: 17,
                  backgroundImage: NetworkImage(
                    'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100&auto=format&fit=crop&q=80',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: Listenable.merge([_sports, widget.favorites]),
        builder: (_, __) => RefreshIndicator(
          color: const Color(0xFF0D5E46),
          onRefresh: _sports.refresh,
          child: _content(colorScheme, isDark),
        ),
      ),
      bottomNavigationBar: const AppNavigation(index: 0),
    );
  }

  Widget _content(ColorScheme colorScheme, bool isDark) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      children: [
        // ── 1. Greeting Card ──
        _greetingCard(colorScheme, isDark),
        const SizedBox(height: 22),

        // ── 2. Live Now Section ──
        _liveNowSection(colorScheme, isDark),
        const SizedBox(height: 24),

        // ── 3. My Teams Section ──
        _myTeamsSection(colorScheme, isDark),
        const SizedBox(height: 24),

        // Show upcoming matches only when there is nothing live to show.
        if (_sports.liveMatches.isEmpty) ...[
          // ── 4. Upcoming Matches Section ──
          _todaysMatchesSection(colorScheme, isDark),
          const SizedBox(height: 24),
        ],

        // ── 5. Top News Section ──
        _topNewsSection(colorScheme, isDark),
        const SizedBox(height: 20),
      ],
    );
  }

  // ── 1. Greeting Card ──
  Widget _greetingCard(ColorScheme colorScheme, bool isDark) {
    final userName = widget.auth?.user?.displayName?.trim();
    final displayName = userName?.isNotEmpty == true
        ? userName!.split(RegExp(r'\s+')).first
        : null;
    final initialLetter = displayName?.substring(0, 1).toUpperCase();
    final greeting = displayName == null
        ? _greetingTime()
        : '${_greetingTime()}, $displayName';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? colorScheme.outline : const Color(0xFFE5E7EB),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF111827),
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Here is your live sports overview for today.',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? const Color(0xFF9CA3AF)
                        : const Color(0xFF6B7280),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isDark ? colorScheme.primary : const Color(0xFF0D5E46),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: initialLetter == null
                ? null
                : Text(
                    initialLetter,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ── 2. Live Now Section ──
  Widget _liveNowSection(ColorScheme colorScheme, bool isDark) {
    final liveMatches = _sports.liveMatches;

    final displayMatches = liveMatches;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Live Now',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF111827),
                letterSpacing: -0.2,
              ),
            ),
            InkWell(
              onTap: () => TabSwitcher.of(context)?.switchTab(3),
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Text(
                  'See All',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color:
                        isDark ? colorScheme.primary : const Color(0xFF0D5E46),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 155,
          child: displayMatches.isEmpty
              ? const Center(child: Text('No live matches right now.'))
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  itemCount: displayMatches.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final match = displayMatches[index];
                    return _buildLiveMatchCard(match, isDark, colorScheme);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildLiveMatchCard(
      SportMatch match, bool isDark, ColorScheme colorScheme) {
    final leagueText = _formatLeagueName(match.league);

    final homeScore = match.homeScore.isNotEmpty ? match.homeScore : '–';
    final awayScore = match.awayScore.isNotEmpty ? match.awayScore : '–';
    final liveStatus = match.status.isNotEmpty ? match.status : 'LIVE';

    return InkWell(
      onTap: () => Navigator.pushNamed(context, '/match', arguments: match),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 275,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: isDark ? colorScheme.surface : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? colorScheme.outline : const Color(0xFFE5E7EB),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top League & Live indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    leagueText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? const Color(0xFF9CA3AF)
                          : const Color(0xFF4B5563),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDC2626),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 5.5,
                        height: 5.5,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'LIVE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Home Team Row
            Row(
              children: [
                _teamSmallBadge(match.home.name, match.home.logoUrl),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    match.home.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF111827),
                    ),
                  ),
                ),
                Text(
                  homeScore,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF111827),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Away Team Row
            Row(
              children: [
                _teamSmallBadge(match.away.name, match.away.logoUrl),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    match.away.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF111827),
                    ),
                  ),
                ),
                Text(
                  awayScore,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF111827),
                  ),
                ),
              ],
            ),
            const Spacer(),

            // Match Time Row
            Row(
              children: [
                const Icon(
                  Icons.access_time_filled_rounded,
                  size: 14,
                  color: Color(0xFFDC2626),
                ),
                const SizedBox(width: 4),
                Text(
                  liveStatus,
                  style: const TextStyle(
                    color: Color(0xFFDC2626),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _teamSmallBadge(String name, String? logoUrl) {
    final lower = name.toLowerCase();
    Color borderColor = const Color(0xFFD1D5DB);
    String? resolvedLogo = logoUrl;

    if (lower.contains('arsenal')) {
      borderColor = const Color(0xFFEF4444);
      resolvedLogo ??= 'https://a.espncdn.com/i/teamlogos/soccer/500/359.png';
    } else if (lower.contains('chelsea')) {
      borderColor = const Color(0xFF2563EB);
      resolvedLogo ??= 'https://a.espncdn.com/i/teamlogos/soccer/500/363.png';
    } else if (lower.contains('real madrid')) {
      borderColor = const Color(0xFF6B7280);
      resolvedLogo ??= 'https://a.espncdn.com/i/teamlogos/soccer/500/86.png';
    } else if (lower.contains('bayern')) {
      borderColor = const Color(0xFFDC2626);
      resolvedLogo ??= 'https://a.espncdn.com/i/teamlogos/soccer/500/132.png';
    } else if (lower.contains('barcelona')) {
      borderColor = const Color(0xFFDC2626);
      resolvedLogo ??= 'https://a.espncdn.com/i/teamlogos/soccer/500/83.png';
    } else if (lower.contains('manchester city') ||
        lower.contains('man city')) {
      borderColor = const Color(0xFF0284C7);
      resolvedLogo ??= 'https://a.espncdn.com/i/teamlogos/soccer/500/382.png';
    } else if (lower.contains('liverpool')) {
      borderColor = const Color(0xFFDC2626);
      resolvedLogo ??= 'https://a.espncdn.com/i/teamlogos/soccer/500/375.png';
    } else if (lower.contains('lakers')) {
      borderColor = const Color(0xFFF59E0B);
      resolvedLogo ??= 'https://a.espncdn.com/i/teamlogos/nba/500/lal.png';
    } else if (lower.contains('celtics')) {
      borderColor = const Color(0xFF10B981);
      resolvedLogo ??= 'https://a.espncdn.com/i/teamlogos/nba/500/bos.png';
    }

    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: ClipOval(
        child: resolvedLogo?.isNotEmpty == true
            ? Image.network(
                resolvedLogo!,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => _initialBadge(name, borderColor),
              )
            : _initialBadge(name, borderColor),
      ),
    );
  }

  Widget _initialBadge(String name, Color color) {
    return Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }

  // ── 3. My Teams Section ──
  Widget _myTeamsSection(ColorScheme colorScheme, bool isDark) {
    final userFavorites = widget.favorites.teams;
    final displayTeams = <(String, Color, String, String, String)>[];
    final seen = <String>{};

    for (final t in userFavorites) {
      final lower = t.name.toLowerCase();
      Color border = const Color(0xFF10B981);
      if (lower.contains('arsenal')) {
        border = const Color(0xFFEF4444);
      } else if (lower.contains('chelsea')) {
        border = const Color(0xFF2563EB);
      } else if (lower.contains('lakers')) {
        border = const Color(0xFFF59E0B);
      } else if (lower.contains('madrid') ||
          lower.contains('barcelona') ||
          lower.contains('liverpool')) {
        border = const Color(0xFFE11D48);
      } else if (lower.contains('manchester') || lower.contains('city')) {
        border = const Color(0xFF0284C7);
      }
      if (seen.add(t.name)) {
        displayTeams.add((t.name, border, t.logoUrl ?? '', t.id, t.league));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'My Teams',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF111827),
                letterSpacing: -0.2,
              ),
            ),
            InkWell(
              onTap: () => Navigator.pushNamed(context, '/onboarding'),
              child: Text(
                'Edit',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark ? colorScheme.primary : const Color(0xFF0D5E46),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (displayTeams.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 18),
            child: Text('No favorite teams yet.'),
          )
        else
          Row(
            children: displayTeams.take(4).map((data) {
              final name = data.$1;
              final borderColor = data.$2;
              final logoUrl = data.$3;
              final teamId = data.$4;
              final league = data.$5;

              return Expanded(
                child: InkWell(
                  onTap: () {
                    final team = Team(
                      id: teamId,
                      name: name,
                      abbreviation: name.length > 3
                          ? name.substring(0, 3).toUpperCase()
                          : name.toUpperCase(),
                      logoUrl: logoUrl,
                      league: league,
                    );
                    Navigator.pushNamed(context, '/team', arguments: team);
                  },
                  borderRadius: BorderRadius.circular(35),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 62,
                        height: 62,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: name == 'Lakers'
                              ? const Color(0xFF3B0764)
                              : (isDark ? colorScheme.surface : Colors.white),
                          border: Border.all(
                            color: borderColor,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: borderColor.withValues(alpha: 0.12),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(8),
                        child: ClipOval(
                          child: logoUrl.isNotEmpty
                              ? Image.network(
                                  logoUrl,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => Center(
                                    child: Icon(
                                      name == 'Lakers'
                                          ? Icons.sports_basketball
                                          : Icons.sports_soccer,
                                      size: 26,
                                      color: name == 'Lakers'
                                          ? const Color(0xFFF59E0B)
                                          : borderColor,
                                    ),
                                  ),
                                )
                              : Center(
                                  child: Text(
                                    name.isNotEmpty ? name[0] : '?',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: borderColor,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        name,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color:
                              isDark ? Colors.white : const Color(0xFF111827),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  // ── 4. Today's Matches Section ──
  Widget _todaysMatchesSection(ColorScheme colorScheme, bool isDark) {
    final upcoming = _sports.upcomingMatches;

    if (upcoming.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Today's Matches",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF111827),
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 12),
          const Text('No upcoming matches.'),
        ],
      );
    }

    final match = upcoming.first;

    final leagueText = _formatLeagueName(match.league);

    String timeFormatted;
    if (match.status.toLowerCase().contains('today') ||
        match.status.contains('PM') ||
        match.status.contains('AM') ||
        match.status.contains(':')) {
      final clean = match.status.replaceAll('Today,', '').trim();
      timeFormatted = 'Today, $clean';
    } else {
      timeFormatted =
          'Today, ${DateFormat.Hm().format(match.startTime.toLocal())}';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Today's Matches",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF111827),
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: () => Navigator.pushNamed(context, '/match', arguments: match),
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? colorScheme.surface : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark ? colorScheme.outline : const Color(0xFFE5E7EB),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      leagueText,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? const Color(0xFF9CA3AF)
                            : const Color(0xFF6B7280),
                      ),
                    ),
                    Text(
                      timeFormatted,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFEA580C),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Team 1 Row
                Row(
                  children: [
                    _teamSmallBadge(match.home.name, match.home.logoUrl),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        match.home.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color:
                              isDark ? Colors.white : const Color(0xFF111827),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Team 2 Row
                Row(
                  children: [
                    _teamSmallBadge(match.away.name, match.away.logoUrl),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        match.away.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color:
                              isDark ? Colors.white : const Color(0xFF111827),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Action: Set Reminder
                InkWell(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'Reminder set for ${match.home.name} vs ${match.away.name}!'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.notifications_none_rounded,
                          size: 16,
                          color: isDark
                              ? colorScheme.primary
                              : const Color(0xFF0D5E46),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Set Reminder',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? colorScheme.primary
                                : const Color(0xFF0D5E46),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── 5. Top News Section ──
  Widget _newsImagePlaceholder(ColorScheme colorScheme) => Container(
        color: colorScheme.surfaceContainerHighest,
        alignment: Alignment.center,
        child: Icon(Icons.image_outlined, color: colorScheme.onSurfaceVariant),
      );

  Widget _topNewsSection(ColorScheme colorScheme, bool isDark) {
    final articles = _sports.articles;
    if (articles.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top News',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF111827),
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 12),
          const Text('No news stories available.'),
        ],
      );
    }

    final article = articles.firstWhere(
      (a) =>
          a.category.toLowerCase().contains('football') ||
          a.category.toLowerCase().contains('premier') ||
          a.category.toLowerCase().contains('soccer'),
      orElse: () => articles.first,
    );

    final rawCat = article.category;
    final displayCategory = rawCat.toLowerCase().contains('eng') ||
            rawCat.toLowerCase().contains('premier')
        ? 'FOOTBALL'
        : (rawCat.isNotEmpty ? rawCat.toUpperCase() : 'FOOTBALL');

    final imageUrl = article.imageUrl;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Top News',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF111827),
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: () =>
              Navigator.pushNamed(context, '/article', arguments: article),
          borderRadius: BorderRadius.circular(18),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? colorScheme.surface : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark ? colorScheme.outline : const Color(0xFFE5E7EB),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Image
                SizedBox(
                  height: 190,
                  width: double.infinity,
                  child: imageUrl?.isNotEmpty == true
                      ? Image.network(
                          imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _newsImagePlaceholder(colorScheme),
                        )
                      : _newsImagePlaceholder(colorScheme),
                ),

                // Bottom Meta Row
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 3.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5EE),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          displayCategory,
                          style: const TextStyle(
                            color: Color(0xFF0D5E46),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _age(article.publishedAt),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? const Color(0xFF9CA3AF)
                              : const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatLeagueName(String rawLeague) {
    final lower = rawLeague.toLowerCase();
    if (lower.contains('eng.1') || lower.contains('premier')) {
      return 'Premier League';
    }
    if (lower.contains('esp.1') ||
        lower.contains('la liga') ||
        lower.contains('laliga')) {
      return 'La Liga';
    }
    if (lower.contains('uefa') || lower.contains('champions')) {
      return 'Champions League';
    }
    if (lower.contains('ita.1') || lower.contains('serie')) {
      return 'Serie A';
    }
    if (lower.contains('ger.1') || lower.contains('bundesliga')) {
      return 'Bundesliga';
    }
    if (lower.contains('nba') || lower.contains('basketball')) {
      return 'NBA';
    }
    if (lower.contains('nfl') || lower.contains('football')) {
      return 'NFL';
    }
    if (rawLeague.contains('/')) {
      final last = rawLeague.split('/').last.replaceAll('.', ' ').trim();
      if (last.isNotEmpty) {
        return last[0].toUpperCase() + last.substring(1);
      }
    }
    return rawLeague.isNotEmpty ? rawLeague : 'Sports';
  }

  String _age(DateTime value) {
    final diff = DateTime.now().difference(value);
    if (diff.inMinutes < 60) {
      return diff.inMinutes <= 1 ? 'Just now' : '${diff.inMinutes}m ago';
    }
    if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    }
    return '${diff.inDays}d ago';
  }

  String _greetingTime() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }
}
