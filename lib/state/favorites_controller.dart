import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/team.dart';
import '../services/firestore_service.dart';

class FavoritesController extends ChangeNotifier {
  FavoritesController({FirestoreService? firestoreService})
      : _firestoreService = firestoreService ?? FirestoreService();

  static const _key = 'favorite_teams';
  final FirestoreService _firestoreService;
  final Map<String, Team> _teams = {};
  String? _userId;

  List<Team> get teams => _teams.values.toList()
    ..sort((first, second) => first.name.compareTo(second.name));
  Set<String> get ids => Set.unmodifiable(_teams.keys.toSet());
  bool contains(String id) => _teams.containsKey(id);

  Future<void> load({String? userId, bool seedMock = false}) async {
    _userId = userId;
    final saved =
        (await SharedPreferences.getInstance()).getStringList(_key) ?? const [];
    _teams.clear();
    if (saved.isEmpty && seedMock) {
      try {
        final text = await rootBundle.loadString('assets/mock/favorites.json');
        final raw = jsonDecode(text) as Map<String, dynamic>;
        saved.addAll((raw['teams'] as List? ?? []).map(
            (value) => jsonEncode((value as Map).cast<String, dynamic>())));
      } catch (_) {}
    }
    for (final value in saved) {
      try {
        final json = jsonDecode(value) as Map<String, dynamic>;
        final team = Team.fromJson(json);
        if (team.id.isNotEmpty) _teams[team.id] = team;
      } catch (_) {
        // Ignores legacy format
      }
    }

    // If a user is logged in, sync with Firestore
    if (_userId != null && _userId!.isNotEmpty) {
      await _syncWithFirestore();
    }

    notifyListeners();
  }

  Future<void> syncWithUser(String? userId) async {
    _userId = userId;
    if (_userId != null && _userId!.isNotEmpty) {
      await _syncWithFirestore();
      notifyListeners();
    }
  }

  Future<void> _syncWithFirestore() async {
    if (_userId == null || _userId!.isEmpty) return;
    try {
      final remoteTeams = await _firestoreService.fetchFavorites(_userId!);
      // Merge remote teams into local
      for (final team in remoteTeams) {
        _teams[team.id] = team;
      }
      // Push any local favorites to remote
      await _firestoreService.syncLocalToRemote(_userId!, _teams.values.toList());
      // Save merged locally
      await _saveLocal();
    } catch (_) {}
  }

  Future<void> toggle(Team team) async {
    if (team.id.isEmpty) return;
    final isRemoving = _teams.containsKey(team.id);
    if (isRemoving) {
      _teams.remove(team.id);
      if (_userId != null && _userId!.isNotEmpty) {
        _firestoreService.removeFavorite(_userId!, team.id);
      }
    } else {
      _teams[team.id] = team;
      if (_userId != null && _userId!.isNotEmpty) {
        _firestoreService.saveFavorite(_userId!, team);
      }
    }
    await _saveLocal();
    notifyListeners();
  }

  Future<void> remove(String id) async {
    _teams.remove(id);
    if (_userId != null && _userId!.isNotEmpty) {
      _firestoreService.removeFavorite(_userId!, id);
    }
    await _saveLocal();
    notifyListeners();
  }

  Future<void> _saveLocal() => (SharedPreferences.getInstance())
      .then((preferences) => preferences.setStringList(
            _key,
            _teams.values.map((team) => jsonEncode(team.toJson())).toList(),
          ));
}
