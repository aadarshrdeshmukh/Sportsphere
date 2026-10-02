import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';
import '../models/news_article.dart';
import '../models/sport_league.dart';
import '../repositories/sports_repository.dart';
import '../state/news_controller.dart';
import '../widgets/widgets.dart';
import '../widgets/app_navigation.dart';

class News extends StatefulWidget {
  const News({super.key, required this.repository});
  final SportsRepository repository;

  @override
  State<News> createState() => _NewsState();
}

class _NewsState extends State<News> {
  late final NewsController _news;

  @override
  void initState() {
    super.initState();
    _news = NewsController(widget.repository)..refresh();
  }

  @override
  void dispose() {
    _news.dispose();
    super.dispose();
  }

  Future<void> _showFilterSheet() async {
    final result = await showModalBottomSheet<_NewsFilterResult>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _NewsFilterSheet(
        selectedLeague: _news.selectedLeague,
        selectedCategory: _news.selectedCategory,
        categories: _news.categories,
        totalArticles: _news.articles.length,
      ),
    );

    if (result != null) {
      _news.selectLeague(result.league);
      _news.selectCategory(result.category);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: _news,
      builder: (context, _) {
        final hasActiveFilter =
            _news.selectedLeague != null || _news.selectedCategory != 'All';

        return Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: const Text('News'),
            actions: [
              IconButton(
                tooltip: 'Filter news',
                onPressed: _showFilterSheet,
                icon: Badge(
                  isLabelVisible: hasActiveFilter,
                  smallSize: 8,
                  child: const Icon(Iconsax.search_normal_1),
                ),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: _news.refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
              children: [
                _buildCategoryFilters(colorScheme),
                const SizedBox(height: 14),

                // ── 2. Notice / Error Banner ──
                if (_news.showingCachedData || _news.error != null) ...[
                  _NewsNotice(
                    cached: _news.showingCachedData,
                    error: _news.error,
                  ),
                  const SizedBox(height: 14),
                ],

              if (_news.isLoading && _news.articles.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 72),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_news.filteredArticles.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: AppEmptyState(
                    title: _news.articles.isEmpty
                        ? 'No news stories available'
                        : 'No stories in "${_news.selectedCategory}"',
                    message: 'Try switching to "All" or pulling down to refresh.',
                    icon: Iconsax.document_text_1,
                    actionLabel: 'Show All Stories',
                    onAction: () {
                      _news.selectCategory('All');
                      _news.selectLeague(null);
                    },
                  ),
                )
              else ...[
                if (_news.filteredArticles.isNotEmpty) ...[
                  FeaturedNewsCard(
                    title: _news.filteredArticles.first.title,
                    cat: _news.filteredArticles.first.category,
                    age: _relativeTime(_news.filteredArticles.first.publishedAt),
                    imageUrl: _news.filteredArticles.first.imageUrl,
                    onTap: () => Navigator.pushNamed(
                      context,
                      '/article',
                      arguments: _news.filteredArticles.first,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ..._news.filteredArticles.skip(1).map(_articleCard),
                ],
              ],
              const SizedBox(height: 16),
            ],
          ),
        ),
        bottomNavigationBar: const AppNavigation(index: 2),
        );
      },
    );
  }

  Widget _buildCategoryFilters(ColorScheme colorScheme) {
    final categories = _news.categories;
    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final category in categories.take(4)) ...[
                  SportFilterChip(
                    label: category,
                    isSelected: _news.selectedCategory == category,
                    onTap: () => _news.selectCategory(category),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
        ),
        IconButton(
          tooltip: 'Refresh news',
          onPressed: _news.isLoading ? null : _news.refresh,
          icon: const Icon(Iconsax.refresh_2),
          style: IconButton.styleFrom(
            foregroundColor: colorScheme.primary,
            backgroundColor: colorScheme.primaryContainer,
          ),
        ),
      ],
    );
  }

  Widget _articleCard(NewsArticle article) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () =>
              Navigator.pushNamed(context, '/article', arguments: article),
          child: NewsCard(
            cat: article.category,
            title: article.title,
            age: _relativeTime(article.publishedAt),
            imageUrl: article.imageUrl,
          ),
        ),
      );

  String _relativeTime(DateTime date) {
    final difference = DateTime.now().difference(date.toLocal());
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) return '${difference.inMinutes}m ago';
    if (difference.inDays < 1) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return DateFormat('d MMM').format(date.toLocal());
  }
}

class _NewsFilterResult {
  final SportLeague? league;
  final String category;
  const _NewsFilterResult({this.league, required this.category});
}

class _NewsFilterSheet extends StatefulWidget {
  const _NewsFilterSheet({
    required this.selectedLeague,
    required this.selectedCategory,
    required this.categories,
    required this.totalArticles,
  });

  final SportLeague? selectedLeague;
  final String selectedCategory;
  final List<String> categories;
  final int totalArticles;

  @override
  State<_NewsFilterSheet> createState() => _NewsFilterSheetState();
}

class _NewsFilterSheetState extends State<_NewsFilterSheet> {
  late SportLeague? _selectedLeague;
  late String _selectedCategory;

  @override
  void initState() {
    super.initState();
    _selectedLeague = widget.selectedLeague;
    _selectedCategory = widget.selectedCategory;
  }

  bool get _hasChanges =>
      _selectedLeague?.key != widget.selectedLeague?.key ||
      _selectedCategory != widget.selectedCategory;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Drag Handle ──
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: colorScheme.onSurface.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // ── Title Row ──
            Row(
              children: [
                Icon(Iconsax.setting_4, size: 20, color: colorScheme.primary),
                const SizedBox(width: 8),
                const Text(
                  'Filter News & Stories',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => setState(() {
                    _selectedLeague = null;
                    _selectedCategory = 'All';
                  }),
                  child: const Text(
                    'Reset',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Competition Section ──
            Text(
              'COMPETITION',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: colorScheme.onSurface.withValues(alpha: 0.45),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildFilterChip(
                  label: 'All Sports',
                  icon: Iconsax.cup,
                  isSelected: _selectedLeague == null,
                  onTap: () => setState(() => _selectedLeague = null),
                  colorScheme: colorScheme,
                ),
                ...supportedLeagues.map((league) => _buildFilterChip(
                      label: league.label,
                      isSelected: _selectedLeague?.key == league.key,
                      onTap: () => setState(() => _selectedLeague = league),
                      colorScheme: colorScheme,
                    )),
              ],
            ),
            const SizedBox(height: 22),

            // ── Category / Topic Section ──
            if (widget.categories.isNotEmpty) ...[
              Text(
                'TOPIC / CATEGORY',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: colorScheme.onSurface.withValues(alpha: 0.45),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.categories.map((category) {
                  final isSelected = _selectedCategory == category;
                  return _buildFilterChip(
                    label: category,
                    isSelected: isSelected,
                    onTap: () =>
                        setState(() => _selectedCategory = category),
                    colorScheme: colorScheme,
                  );
                }).toList(),
              ),
              const SizedBox(height: 28),
            ],

            // ── Apply Button ──
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(
                  context,
                  _NewsFilterResult(
                    league: _selectedLeague,
                    category: _selectedCategory,
                  ),
                ),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  _hasChanges ? 'Apply Filters' : 'Done',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
    IconData? icon,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(100),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
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
                Icon(icon,
                    size: 15,
                    color: isSelected ? Colors.white : colorScheme.onSurface),
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

class _NewsNotice extends StatelessWidget {
  const _NewsNotice({required this.cached, this.error});
  final bool cached;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            cached ? Iconsax.cloud_cross : Iconsax.info_circle,
            size: 18,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              cached
                  ? 'Showing saved stories — pull down to retry.'
                  : error ?? 'Unable to refresh news.',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
