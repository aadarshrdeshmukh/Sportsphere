import 'dart:async';

import 'package:flutter/widgets.dart';

import '../models/sport_league.dart';
import '../models/sport_match.dart';
import '../repositories/sports_repository.dart';

class LiveScoresController extends ChangeNotifier with WidgetsBindingObserver {
  LiveScoresController(this._repository);

  final SportsRepository _repository;
  SportLeague? selectedLeague;
  List<SportMatch> matches = [];
  bool isLoading = false;
  bool showingCachedData = false;
  String? error;
  Timer? _poller;

  List<SportMatch> get live => matches.where((match) => match.isLive).toList();
  List<SportMatch> get upcoming =>
      matches.where((match) => !match.isLive && !match.isCompleted).toList();
  List<SportMatch> get finished =>
      matches.where((match) => match.isCompleted).toList();

  Future<void> refresh() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final result = await _repository.matches(selectedLeague);
      matches = result.data;
      showingCachedData = result.fromCache;
      error = result.error;
    } catch (exception) {
      matches = [];
      showingCachedData = false;
      error = '$exception';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> selectLeague(SportLeague? league) async {
    selectedLeague = league;
    await refresh();
  }

  void startPolling() {
    _poller?.cancel();
    _poller = Timer.periodic(const Duration(seconds: 45), (_) => refresh());
    WidgetsBinding.instance.addObserver(this);
  }

  void stopPolling() {
    _poller?.cancel();
    _poller = null;
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _poller?.cancel();
      _poller = null;
    } else if (state == AppLifecycleState.resumed) {
      refresh();
      startPolling();
    }
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}
