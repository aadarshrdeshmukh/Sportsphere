import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthController extends ChangeNotifier {
  AuthController({FirebaseAuth? auth}) : _customAuth = auth {
    _init();
  }

  final FirebaseAuth? _customAuth;
  StreamSubscription<User?>? _sub;

  FirebaseAuth? get _auth {
    if (_customAuth != null) return _customAuth;
    try {
      return FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }

  User? _user;
  User? get user => _user;
  bool get isSignedIn => _user != null;
  bool get isAnonymous => _user?.isAnonymous ?? false;
  String? get email => _user?.email;
  String? get displayName => _user?.displayName ?? (_user?.email?.split('@').first);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  void _init() {
    final auth = _auth;
    if (auth != null) {
      _user = auth.currentUser;
      _sub = auth.authStateChanges().listen((user) {
        _user = user;
        notifyListeners();
      });
    }
  }

  Future<bool> signInWithEmail(String email, String password) async {
    final auth = _auth;
    if (auth == null) {
      _error = 'Firebase is not initialized.';
      notifyListeners();
      return false;
    }
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final credential = await auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      _user = credential.user;
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _formatAuthError(e);
      return false;
    } catch (e) {
      _error = 'An unexpected error occurred: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signUpWithEmail(String email, String password) async {
    final auth = _auth;
    if (auth == null) {
      _error = 'Firebase is not initialized.';
      notifyListeners();
      return false;
    }
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final credential = await auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      _user = credential.user;
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _formatAuthError(e);
      return false;
    } catch (e) {
      _error = 'An unexpected error occurred: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signInWithGoogle() async {
    final auth = _auth;
    if (auth == null) {
      _error = 'Firebase is not initialized.';
      notifyListeners();
      return false;
    }
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final googleProvider = GoogleAuthProvider();
      final credential = kIsWeb
          ? await auth.signInWithPopup(googleProvider)
          : await auth.signInWithProvider(googleProvider);
      _user = credential.user;
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _formatAuthError(e);
      return false;
    } catch (e) {
      _error = 'Google Sign In failed: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signInAnonymously() async {
    final auth = _auth;
    if (auth == null) {
      _error = 'Firebase is not initialized.';
      notifyListeners();
      return false;
    }
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final credential = await auth.signInAnonymously();
      _user = credential.user;
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _formatAuthError(e);
      return false;
    } catch (e) {
      _error = 'Guest login failed: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    final auth = _auth;
    if (auth == null) return;
    _isLoading = true;
    notifyListeners();
    try {
      await auth.signOut();
      _user = null;
    } catch (e) {
      _error = 'Sign out failed: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _formatAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled in the Firebase Console.';
      default:
        return e.message ?? 'Authentication failed (${e.code}).';
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
