import 'dart:async';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../models/team.dart';
import '../repositories/sports_repository.dart';
import '../state/favorites_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';

class Onboarding extends StatefulWidget {
  const Onboarding({super.key, required this.favorites, this.repository});
  final FavoritesController favorites;
  final SportsRepository? repository;
  @override
  State<Onboarding> createState() => _OnboardingState();
}

class _OnboardingState extends State<Onboarding> {
  final Map<String, Team> _allDiscoveredTeams = {};
  List<Team> _popularTeams = [];
  List<Team> _displayedTeams = [];
  bool _loading = true;
  bool _searchingOnline = false;
  final _selected = <String>{};
  final _searchController = TextEditingController();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _selected.addAll(widget.favorites.ids);
    _fetchTeams();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchTeams() async {
    List<Team> fetched = [];
    if (widget.repository != null) {
      try {
        fetched = await widget.repository!.popularTeams();
      } catch (_) {}
    }
    if (mounted) {
      setState(() {
        _popularTeams = fetched;
        for (final t in fetched) {
          _allDiscoveredTeams[t.id] = t;
        }
        _displayedTeams = List.from(fetched);
        _loading = false;
      });
    }
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    final trimmed = query.trim().toLowerCase();

    if (trimmed.isEmpty) {
      setState(() {
        _searchingOnline = false;
        _displayedTeams = List.from(_popularTeams);
      });
      return;
    }

    // Instant local filtering
    final localMatches = _allDiscoveredTeams.values.where((t) {
      final nameMatches = t.name.toLowerCase().contains(trimmed);
      final abbrMatches = t.abbreviation.toLowerCase().contains(trimmed);
      return nameMatches || abbrMatches;
    }).toList();

    setState(() {
      _displayedTeams = localMatches;
      _searchingOnline = trimmed.length >= 2;
    });

    // Debounced online search for teams outside the initial list
    if (trimmed.length >= 2 && widget.repository != null) {
      _debounceTimer = Timer(const Duration(milliseconds: 350), () async {
        try {
          final results = await widget.repository!.searchTeams(trimmed);
          if (!mounted ||
              _searchController.text.trim().toLowerCase() != trimmed) {
            return;
          }

          setState(() {
            _searchingOnline = false;
            for (final t in results) {
              _allDiscoveredTeams[t.id] = t;
            }
            final combinedMap = <String, Team>{};
            for (final t in [...localMatches, ...results]) {
              combinedMap[t.id] = t;
            }
            _displayedTeams = combinedMap.values.toList();
          });
        } catch (_) {
          if (mounted) {
            setState(() {
              _searchingOnline = false;
            });
          }
        }
      });
    } else {
      setState(() {
        _searchingOnline = false;
      });
    }
  }

  void _clearSearch() {
    _searchController.clear();
    _onSearchChanged('');
  }

  Future<void> _continue() async {
    for (final team in _allDiscoveredTeams.values) {
      final shouldFollow = _selected.contains(team.id);
      final isFollowed = widget.favorites.contains(team.id);
      if (shouldFollow && !isFollowed) {
        await widget.favorites.toggle(team);
      } else if (!shouldFollow && isFollowed) {
        await widget.favorites.remove(team.id);
      }
    }
    if (mounted) Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  Widget build(BuildContext c) => Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          actions: [
            TextButton(
              onPressed: () => Navigator.pushReplacementNamed(c, '/home'),
              child: const Text('Skip',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header title and description
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pick Your Favorites',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.text,
                        letterSpacing: -0.5,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Select your favorite teams to receive real-time scores, highlights, and breaking news updates.',
                      style: TextStyle(
                          color: AppTheme.muted, fontSize: 13, height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Search any team, club, or franchise...',
                    hintStyle: const TextStyle(
                      color: AppTheme.muted,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                    prefixIcon: const Icon(
                      Iconsax.search_normal_1,
                      color: AppTheme.muted,
                      size: 20,
                    ),
                    suffixIcon: _searchingOnline
                        ? const UnconstrainedBox(
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.primary,
                              ),
                            ),
                          )
                        : _searchController.text.isNotEmpty
                            ? IconButton(
                                icon:
                                    const Icon(Iconsax.close_circle, size: 18),
                                onPressed: _clearSearch,
                                color: AppTheme.muted,
                              )
                            : null,
                    filled: true,
                    fillColor: AppTheme.bg,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppTheme.outline),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: AppTheme.outline.withValues(alpha: 0.8),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: AppTheme.primary,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Teams Grid or Empty State
              Expanded(
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: AppTheme.primary,
                        ),
                      )
                    : _displayedTeams.isEmpty
                        ? Center(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 32),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: AppTheme.bg,
                                      shape: BoxShape.circle,
                                      border:
                                          Border.all(color: AppTheme.outline),
                                    ),
                                    child: const Icon(
                                      Iconsax.search_status,
                                      size: 32,
                                      color: AppTheme.muted,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  const Text(
                                    'No teams found',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.text,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Try searching for another team name or check your spelling.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color:
                                          AppTheme.muted.withValues(alpha: 0.9),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : GridView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: _displayedTeams.length,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 0.88,
                            ),
                            itemBuilder: (_, i) {
                              final team = _displayedTeams[i];
                              final on = _selected.contains(team.id);
                              return InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: () => setState(() {
                                  if (on) {
                                    _selected.remove(team.id);
                                  } else {
                                    _selected.add(team.id);
                                  }
                                }),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  decoration: BoxDecoration(
                                    color: on ? AppTheme.primary : Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: on
                                          ? AppTheme.primary
                                          : AppTheme.outline,
                                      width: on ? 1.5 : 1.0,
                                    ),
                                    boxShadow: on
                                        ? [
                                            BoxShadow(
                                              color: AppTheme.primary
                                                  .withValues(alpha: 0.25),
                                              blurRadius: 8,
                                              offset: const Offset(0, 3),
                                            )
                                          ]
                                        : null,
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      TeamBadge(
                                        name: team.name,
                                        logoUrl: team.logoUrl,
                                        size: 40,
                                      ),
                                      const SizedBox(height: 8),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                        ),
                                        child: Text(
                                          '${team.name} ${on ? '✓' : '+'}',
                                          textAlign: TextAlign.center,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: on
                                                ? FontWeight.w700
                                                : FontWeight.w600,
                                            color: on
                                                ? Colors.white
                                                : AppTheme.text,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
              ),

              // Bottom Continue Button
              Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    onPressed: _continue,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      _selected.isNotEmpty
                          ? 'Continue (${_selected.length}) →'
                          : 'Continue →',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}
