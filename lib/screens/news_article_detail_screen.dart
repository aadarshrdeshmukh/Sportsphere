import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';
import '../models/news_article.dart';
import '../theme/app_theme.dart';

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
      appBar: AppBar(title: const Text('News')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 210,
            width: double.infinity,
            color: AppTheme.paleGreen,
            alignment: Alignment.center,
            child: article.imageUrl == null || article.imageUrl!.isEmpty
                ? const Icon(Iconsax.image,
                    size: 48, color: AppTheme.primary)
                : Image.network(
                    article.imageUrl!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: 210,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    },
                    errorBuilder: (_, __, ___) => const Icon(
                        Iconsax.image,
                        size: 48,
                        color: AppTheme.primary)),
          ),
        ),
        const SizedBox(height: 16),
        Text(article.category,
            style: const TextStyle(
                color: AppTheme.primary, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text(article.title,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        Text(
            '${article.source} • ${DateFormat('d MMM, y').format(article.publishedAt.toLocal())}',
            style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 16),
        Text(
            article.description.isEmpty
                ? 'No description was provided for this story.'
                : article.description,
            style: const TextStyle(height: 1.6)),
        if (article.url != null && article.url!.isNotEmpty) ...[
          const SizedBox(height: 20),
          SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Link: ${article.url}')),
                    );
                  },
                  icon: const Icon(Iconsax.export_3, size: 18),
                  label: const Text('Read full article'))),
        ],
      ]),
    );
  }
}
