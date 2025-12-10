import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 1. The Provider: This makes the repository accessible to the UI
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(Supabase.instance.client);
});

// 2. The Class: Handles all Auth Logic
class AuthRepository {
  final SupabaseClient _supabase;

  AuthRepository(this._supabase);

  // Check if a user is already logged in
  User? get currentUser => _supabase.auth.currentUser;

  // Stream to listen for auth changes (Login -> Logout -> Login)
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  // Sign Up (Register)
  Future<void> signUp({required String email, required String password}) async {
    try {
      await _supabase.auth.signUp(
        email: email,
        password: password,
      );
      // Note: If you enabled "Confirm Email" in Supabase, the user won't be 
      // logged in until they click the link in their email.
    } catch (e) {
      throw Exception('Registration failed: $e');
    }
  }

  // Sign In (Login)
  Future<void> signIn({required String email, required String password}) async {
    try {
      await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}