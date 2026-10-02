import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/news_article.dart';
import '../models/sport_league.dart';
import '../models/sport_match.dart';
import '../repositories/sports_repository.dart';

class SportsController extends ChangeNotifier {
  SportsController(this._repository);
  final SportsRepository _repository;
  SportLeague? selectedLeague;
  DateTime selectedDate = DateTime.now();
  List<SportMatch> matches = [], liveMatches = [];
  List<NewsArticle> articles = [];
  bool isLoading = false;
  String? error;
  bool showingCachedData = false;
  Timer? _poller;
  Future<void> refresh({DateTime? date}) async {
    if (date != null) selectedDate = _dateOnly(date);
    isLoading = true;
    error = null;
    notifyListeners();
    final results = await Future.wait([
      _repository.matches(selectedLeague, date: selectedDate),
      _repository.news(selectedLeague)
    ]);
    final score = results[0] as DataResult<List<SportMatch>>,
        news = results[1] as DataResult<List<NewsArticle>>;
    matches = score.data;
    liveMatches = matches.where((m) => m.isLive).toList();
    articles = news.data;
    showingCachedData = score.fromCache || news.fromCache;
    error = score.error ?? news.error;
    isLoading = false;
    notifyListeners();
  }

  Future<void> selectLeague(SportLeague? league) async {
    selectedLeague = league;
    await refresh();
  }

  Future<void> selectDate(DateTime date) => refresh(date: date);

  DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  void startLivePolling() {
    _poller?.cancel();
    _poller = Timer.periodic(const Duration(seconds: 45), (_) => refresh());
  }

  void stopLivePolling() => _poller?.cancel();
  @override
  void dispose() {
    _poller?.cancel();
    super.dispose();
  }
}
