import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../theme/app_theme.dart';
export 'company_logo.dart';

/// 1. TeamBadge — Circular team crest with network cache, fallback initials & border.
class TeamBadge extends StatelessWidget {
  const TeamBadge({
    super.key,
    required this.name,
    this.size = 36,
    this.logoUrl,
  });

  final String name;
  final double size;
  final String? logoUrl;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colorScheme.surface,
        border: Border.all(
          color: colorScheme.outlineVariant,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(
        child: Padding(
          padding: EdgeInsets.all(size * 0.12),
          child: logoUrl?.isNotEmpty == true
              ? Image.network(
                  logoUrl!,
                  width: size * 0.76,
                  height: size * 0.76,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => _initial(colorScheme),
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return _initial(colorScheme);
                  },
                )
              : _initial(colorScheme),
        ),
      ),
    );
  }

  Widget _initial(ColorScheme colorScheme) => Center(
        child: Text(
          name.isEmpty ? '?' : name[0].toUpperCase(),
          style: TextStyle(
            color: colorScheme.primary,
            fontWeight: FontWeight.w800,
            fontSize: size * 0.42,
          ),
        ),
      );
}

/// 2. StatusBadge — Broadcast status indicator for Live, Final, or Scheduled matches.
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    this.live = false,
    this.isFinal = false,
  });

  final String label;
  final bool live;
  final bool isFinal;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (live) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
        decoration: BoxDecoration(
          color: AppTheme.liveContainer,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: AppTheme.live.withValues(alpha: 0.4),
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.only(right: 5),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.live,
              ),
            ),
            Text(
              label.isNotEmpty ? label.toUpperCase() : 'LIVE',
              style: const TextStyle(
                color: AppTheme.live,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      );
    }

    if (isFinal) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label.isNotEmpty ? label.toUpperCase() : 'FT',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: colorScheme.onSurface.withValues(alpha: 0.7),
            letterSpacing: 0.3,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: colorScheme.primary,
        ),
      ),
    );
  }
}

/// 3. MatchCard — Broadcast Material 3 Match Card with team crests, score pills & live states.
class MatchCard extends StatelessWidget {
  const MatchCard({
    super.key,
    required this.league,
    required this.home,
    required this.away,
    this.time = '',
    this.hs = '',
    this.as = '',
    this.live = false,
    this.homeLogo,
    this.awayLogo,
    this.isFinal = false,
    this.onTap,
  });

  final String league;
  final String home;
  final String away;
  final String time;
  final String hs;
  final String as;
  final bool live;
  final String? homeLogo;
  final String? awayLogo;
  final bool isFinal;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final int? homeScoreNum = int.tryParse(hs);
    final int? awayScoreNum = int.tryParse(as);
    final bool homeWon = isFinal &&
        homeScoreNum != null &&
        awayScoreNum != null &&
        homeScoreNum > awayScoreNum;
    final bool awayWon = isFinal &&
        homeScoreNum != null &&
        awayScoreNum != null &&
        awayScoreNum > homeScoreNum;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: live
                  ? AppTheme.live.withValues(alpha: 0.4)
                  : colorScheme.outline,
              width: live ? 1.2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: live
                    ? AppTheme.live.withValues(alpha: 0.04)
                    : Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                // Top League & Status Row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        league.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: colorScheme.onSurface.withValues(alpha: 0.65),
                        ),
                      ),
                    ),
                    const Spacer(),
                    StatusBadge(
                      label: time.isNotEmpty ? time : (live ? 'LIVE' : ''),
                      live: live,
                      isFinal:
                          isFinal || (!live && hs.isNotEmpty && as.isNotEmpty),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Home Team Row
                _teamRow(
                  name: home,
                  score: hs,
                  logoUrl: homeLogo,
                  isWinner: homeWon,
                  colorScheme: colorScheme,
                ),
                const SizedBox(height: 8),

                // Away Team Row
                _teamRow(
                  name: away,
                  score: as,
                  logoUrl: awayLogo,
                  isWinner: awayWon,
                  colorScheme: colorScheme,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _teamRow({
    required String name,
    required String score,
    required bool isWinner,
    String? logoUrl,
    required ColorScheme colorScheme,
  }) {
    return Row(
      children: [
        TeamBadge(name: name, size: 28, logoUrl: logoUrl),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isWinner ? FontWeight.w800 : FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
        ),
        if (score.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: isWinner
                  ? AppTheme.primaryContainer
                  : (live
                      ? AppTheme.liveContainer.withValues(alpha: 0.5)
                      : Colors.transparent),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              score,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: isWinner
                    ? AppTheme.win
                    : (live ? AppTheme.live : colorScheme.onSurface),
              ),
            ),
          ),
      ],
    );
  }
}

/// 4. BroadcastHeroCard — Elevated banner for marquee live matches.
class BroadcastHeroCard extends StatelessWidget {
  const BroadcastHeroCard({
    super.key,
    required this.league,
    required this.homeTeam,
    required this.awayTeam,
    required this.homeScore,
    required this.awayScore,
    this.status = 'LIVE',
    this.homeLogo,
    this.awayLogo,
    this.venue,
    this.onTap,
  });

  final String league;
  final String homeTeam;
  final String awayTeam;
  final String homeScore;
  final String awayScore;
  final String status;
  final String? homeLogo;
  final String? awayLogo;
  final String? venue;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF074D37), Color(0xFF0B6E4F), Color(0xFF063A29)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0B6E4F).withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                // Top Header: League + LIVE Indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      league.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: AppTheme.live,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            margin: const EdgeInsets.only(right: 5),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            status,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Match Scoreboard Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Home Team
                    Expanded(
                      child: Column(
                        children: [
                          TeamBadge(
                              name: homeTeam, size: 48, logoUrl: homeLogo),
                          const SizedBox(height: 8),
                          Text(
                            homeTeam,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Center Scores
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            homeScore.isNotEmpty ? homeScore : '0',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              '-',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Text(
                            awayScore.isNotEmpty ? awayScore : '0',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Away Team
                    Expanded(
                      child: Column(
                        children: [
                          TeamBadge(
                              name: awayTeam, size: 48, logoUrl: awayLogo),
                          const SizedBox(height: 8),
                          Text(
                            awayTeam,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                if (venue != null && venue!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    venue!,
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 5. NewsCard — Rich list news card with enlarged media thumbnail & category chip.
class NewsCard extends StatelessWidget {
  const NewsCard({
    super.key,
    required this.title,
    required this.cat,
    required this.age,
    this.imageUrl,
    this.onTap,
  });

  final String title;
  final String cat;
  final String age;
  final String? imageUrl;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colorScheme.outline, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Enlarged Thumbnail (112x96)
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: 112,
                    height: 96,
                    color: colorScheme.surfaceContainerHighest,
                    child: imageUrl?.isNotEmpty == true
                        ? Image.network(
                            imageUrl!,
                            width: 112,
                            height: 96,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Center(
                              child: Icon(
                                Iconsax.cup,
                                size: 32,
                                color: colorScheme.primary,
                              ),
                            ),
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: colorScheme.primary,
                                  ),
                                ),
                              );
                            },
                          )
                        : Center(
                            child: Icon(
                              Iconsax.document_text_1,
                              size: 32,
                              color: colorScheme.primary,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 14),

                // Text Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      // Meta Tag & Age Row
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.secondaryContainer,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              cat.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 10.5,
                                color: AppTheme.secondary,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            age,
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  colorScheme.onSurface.withValues(alpha: 0.5),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Enlarged High-Legibility Title
                      Text(
                        title,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                          height: 1.28,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 6. FeaturedNewsCard — 16:9 Full media hero news card.
class FeaturedNewsCard extends StatelessWidget {
  const FeaturedNewsCard({
    super.key,
    required this.title,
    required this.cat,
    required this.age,
    this.imageUrl,
    this.onTap,
  });

  final String title;
  final String cat;
  final String age;
  final String? imageUrl;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(
              children: [
                // Background image (16:9)
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: imageUrl?.isNotEmpty == true
                      ? Image.network(
                          imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: const Color(0xFF0B6E4F),
                          ),
                        )
                      : Container(color: const Color(0xFF0B6E4F)),
                ),

                // Dark Gradient Overlay for high legibility
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.85),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),

                // Content
                Positioned(
                  bottom: 14,
                  left: 14,
                  right: 14,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.secondary,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              cat.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            age,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 7. SportFilterChip — Pill button for league and sport filtering.
class SportFilterChip extends StatelessWidget {
  const SportFilterChip({
    super.key,
    required this.label,
    required this.isSelected,
    this.icon,
    this.onTap,
  });

  final String label;
  final bool isSelected;
  final IconData? icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(100),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: isSelected ? colorScheme.primary : colorScheme.surface,
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: isSelected ? colorScheme.primary : colorScheme.outline,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 16,
                  color: isSelected ? Colors.white : colorScheme.onSurface,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected ? Colors.white : colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 8. SectionHeader — Standard section title with action CTA.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.action,
    this.onAction,
  });

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
        const Spacer(),
        if (action != null)
          InkWell(
            onTap: onAction,
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Text(
                action!,
                style: TextStyle(
                  color: colorScheme.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// 9. AppEmptyState — Reusable empty state view.
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.title,
    required this.message,
    this.icon = Iconsax.box,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colorScheme.primaryContainer,
            ),
            child: Icon(icon, size: 26, color: colorScheme.primary),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: TextStyle(
              fontSize: 13,
              color: colorScheme.onSurface.withValues(alpha: 0.55),
              height: 1.3,
            ),
            textAlign: TextAlign.center,
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: onAction,
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 38),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                actionLabel!,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 10. BottomNav — Material 3 navigation bar matching exact SportSphere design.
class BottomNav extends StatelessWidget {
  const BottomNav({
    super.key,
    required this.index,
    this.onDestinationSelected,
  });

  final int index;
  final ValueChanged<int>? onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final destinations = [
      (Iconsax.home_2, Iconsax.home_2_copy, 'Home'),
      (Iconsax.calendar, Iconsax.calendar_copy, 'Schedule'),
      (Iconsax.document_text_1, Iconsax.document_text_1_copy, 'News'),
      (Iconsax.video_play, Iconsax.video_play_copy, 'Live'),
      (Iconsax.heart, Iconsax.heart_copy, 'Favorites'),
    ];

    final unselectedColor = isDark ? const Color(0xFFD1D5DB) : const Color(0xFF9CA3AF);
    final selectedColor = isDark ? Colors.white : AppTheme.primary;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surface : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? colorScheme.outline : const Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
      ),
      child: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: isDark ? colorScheme.surface : Colors.white,
          indicatorColor: isDark
              ? AppTheme.primary
              : const Color(0xFFE8F5EE),
          height: 66,
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            final isSelected = states.contains(WidgetState.selected);
            return TextStyle(
              fontSize: 11.5,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected
                  ? selectedColor
                  : unselectedColor,
            );
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            final isSelected = states.contains(WidgetState.selected);
            return IconThemeData(
              size: 22,
              color: isSelected
                  ? (isDark ? Colors.white : AppTheme.primary)
                  : unselectedColor,
            );
          }),
        ),
        child: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: (i) => onDestinationSelected?.call(i),
          elevation: 0,
          destinations: [
            for (final d in destinations)
              NavigationDestination(
                icon: Icon(d.$1),
                selectedIcon: Icon(d.$2),
                label: d.$3,
              ),
          ],
        ),
      ),
    );
  }
}

