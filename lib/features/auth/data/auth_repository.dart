import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class AuthRepository {
  bool get isAuthenticated;
  String? get currentAdminEmail;
  Future<void> signInWithEmailPassword(String email, String password);
  Future<void> signOut();
  Stream<AuthState?> get authStateChanges;
}

class SupabaseAuthRepository implements AuthRepository {
  SupabaseClient? get _client {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  @override
  bool get isAuthenticated {
    final client = _client;
    if (client == null) return false;
    return client.auth.currentSession != null;
  }

  @override
  String? get currentAdminEmail {
    final client = _client;
    return client?.auth.currentUser?.email;
  }

  @override
  Future<void> signInWithEmailPassword(String email, String password) async {
    final client = _client;
    if (client == null) {
      throw Exception('Supabase is not initialized. Please verify your connection.');
    }

    try {
      await client.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      debugPrint('Supabase sign-in error: $e');
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    final client = _client;
    if (client != null) {
      try {
        await client.auth.signOut();
      } catch (e) {
        debugPrint('Supabase sign-out error: $e');
      }
    }
  }

  @override
  Stream<AuthState?> get authStateChanges {
    final client = _client;
    if (client == null) {
      return const Stream.empty();
    }
    return client.auth.onAuthStateChange;
  }
}

