import 'package:flutter/foundation.dart';

import '../models/news_article.dart';
import '../models/sport_league.dart';
import '../repositories/sports_repository.dart';

class NewsController extends ChangeNotifier {
  NewsController(this._repository);

  final SportsRepository _repository;
  SportLeague? selectedLeague;
  String selectedCategory = 'All';
  List<NewsArticle> articles = [];
  bool isLoading = false;
  bool showingCachedData = false;
  String? error;

  List<String> get categories => [
        'All',
        ...{
          for (final article in articles)
            if (article.category.trim().isNotEmpty) article.category,
        },
      ];

  List<NewsArticle> get filteredArticles => selectedCategory == 'All'
      ? articles
      : articles
          .where((article) => article.category == selectedCategory)
          .toList();

  Future<void> refresh() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final result = await _repository.news(selectedLeague);
      articles = result.data;
      showingCachedData = result.fromCache;
      error = result.error;
    } catch (exception) {
      articles = [];
      showingCachedData = false;
      error = '$exception';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> selectLeague(SportLeague? league) async {
    selectedLeague = league;
    selectedCategory = 'All';
    await refresh();
  }

  void selectCategory(String category) {
    selectedCategory = category;
    notifyListeners();
  }
}
