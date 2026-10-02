import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';
import '../models/news_article.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';

class Article extends StatelessWidget {
  const Article({super.key});
  @override
  Widget build(BuildContext context) {
    final article = ModalRoute.of(context)?.settings.arguments as NewsArticle?;
    if (article == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('News')),
        body: const Center(child: Text('Select a story to read it.')),
      );
    }
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 310,
            pinned: true,
            automaticallyImplyLeading: false,
            backgroundColor: Colors.black,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  _ArticleImage(article.imageUrl),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.transparent, Color(0xAA000000)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    bottom: 16,
                    child: _CategoryBadge(article.category),
                  ),
                ],
              ),
            ),
            leading: _CircleAction(
              icon: Iconsax.arrow_left_2,
              onPressed: () => Navigator.maybePop(context),
            ),
            actions: [
              _CircleAction(
                icon: Iconsax.share,
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Article link ready to share')),
                ),
              ),
              _CircleAction(icon: Iconsax.bookmark, onPressed: () {}),
              const SizedBox(width: 8),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(article.title,
                      style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          height: 1.15)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: AppTheme.primaryContainer,
                        child: Text(
                          article.source.isEmpty
                              ? '?'
                              : article.source[0].toUpperCase(),
                          style: const TextStyle(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w800),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${article.author == null ? article.source : 'by ${article.author}'}\nPublished ${DateFormat('d MMM, y, h:mm a').format(article.publishedAt.toLocal())}${article.readTime == null ? '' : ' • ${article.readTime} min read'}',
                          style: const TextStyle(
                              fontSize: 12, height: 1.45, color: AppTheme.muted),
                        ),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Divider(),
                  ),
                  if (article.description.isEmpty)
                    Text(article.title,
                        style: const TextStyle(fontSize: 16, height: 1.65))
                  else
                    ...article.description.split('\n\n').map(
                          (paragraph) => Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: Text(paragraph,
                                style: const TextStyle(
                                    fontSize: 16, height: 1.65)),
                          ),
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _ArticleFooter(article: article),
    );
  }
}

class _ArticleImage extends StatelessWidget {
  const _ArticleImage(this.url);
  final String? url;

  @override
  Widget build(BuildContext context) => Container(
        color: AppTheme.paleGreen,
        alignment: Alignment.center,
        child: url?.isNotEmpty == true
            ? Image.network(url!, fit: BoxFit.cover, width: double.infinity,
                errorBuilder: (_, __, ___) => const Icon(Iconsax.image,
                    size: 48, color: AppTheme.primary))
            : const Icon(Iconsax.image, size: 48, color: AppTheme.primary),
      );
}

class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
            color: AppTheme.secondary, borderRadius: BorderRadius.circular(6)),
        child: Text(label.toUpperCase(),
            style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w800)),
      );
}

class _CircleAction extends StatelessWidget {
  const _CircleAction({
    required this.icon,
    required this.onPressed,
    this.onLightSurface = false,
  });
  final IconData icon;
  final VoidCallback onPressed;
  final bool onLightSurface;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 8),
        child: IconButton(
          onPressed: onPressed,
          icon: Icon(
            icon,
            color: onLightSurface ? AppTheme.text : Colors.white,
            size: 20,
          ),
          style: IconButton.styleFrom(
            backgroundColor: onLightSurface
                ? Theme.of(context).colorScheme.surface
                : Colors.black.withValues(alpha: 0.55),
            side: BorderSide(
              color: onLightSurface ? AppTheme.outlineVariant : Colors.white24,
            ),
          ),
        ),
      );
}

class _ArticleFooter extends StatelessWidget {
  const _ArticleFooter({required this.article});
  final NewsArticle article;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Theme.of(context).colorScheme.surface,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                children: [
                  _CircleAction(
                    icon: Iconsax.share,
                    onLightSurface: true,
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Article link ready to share')),
                    ),
                  ),
                  _CircleAction(
                    icon: Iconsax.bookmark,
                    onLightSurface: true,
                    onPressed: () {},
                  ),
                  const Spacer(),
                  if (article.url?.isNotEmpty == true)
                    TextButton(
                      onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Link: ${article.url}')),
                      ),
                      child: const Text('Read later'),
                    ),
                ],
              ),
            ),
          ),
        ),
        BottomNav(
          index: 2,
          onDestinationSelected: (_) {
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}
