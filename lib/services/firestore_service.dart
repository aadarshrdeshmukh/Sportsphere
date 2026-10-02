import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/team.dart';

class FirestoreService {
  FirestoreService({FirebaseFirestore? firestore}) : _customFirestore = firestore;

  final FirebaseFirestore? _customFirestore;

  FirebaseFirestore? get _firestore {
    if (_customFirestore != null) return _customFirestore;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  CollectionReference<Map<String, dynamic>>? _userFavorites(String userId) =>
      _firestore?.collection('users').doc(userId).collection('favorites');

  /// Fetches all favorite teams stored in Firestore for a given user.
  Future<List<Team>> fetchFavorites(String userId) async {
    final collection = _userFavorites(userId);
    if (collection == null) return const [];
    try {
      final snapshot = await collection.get();
      return snapshot.docs
          .map((doc) => Team.fromJson(doc.data()))
          .where((team) => team.id.isNotEmpty)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  /// Saves a favorite team to Firestore.
  Future<void> saveFavorite(String userId, Team team) async {
    final collection = _userFavorites(userId);
    if (collection == null) return;
    try {
      await collection.doc(team.id).set(team.toJson());
    } catch (_) {}
  }

  /// Removes a favorite team from Firestore.
  Future<void> removeFavorite(String userId, String teamId) async {
    final collection = _userFavorites(userId);
    if (collection == null) return;
    try {
      await collection.doc(teamId).delete();
    } catch (_) {}
  }

  /// Syncs an entire batch of local favorite teams up to Firestore.
  Future<void> syncLocalToRemote(String userId, List<Team> localTeams) async {
    final firestore = _firestore;
    final collection = _userFavorites(userId);
    if (firestore == null || collection == null) return;
    try {
      final batch = firestore.batch();
      for (final team in localTeams) {
        final doc = collection.doc(team.id);
        batch.set(doc, team.toJson());
      }
      await batch.commit();
    } catch (_) {}
  }
}
