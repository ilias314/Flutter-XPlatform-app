import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(Supabase.instance.client);
});

class AuthRepository {
  final SupabaseClient _supabase;

  AuthRepository(this._supabase);

  User? get currentUser => _supabase.auth.currentUser;
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  Future<void> signUp({
    required String email,
    required String password,
    required String username,
    required String dietaryPreference,
  }) async {
    try {
      final AuthResponse res = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      final user = res.user;
      if (user != null) {
        await _supabase.from('profiles').upsert({
          'id': user.id,
          'email': email,
          'display_name': username,
          'dietary_preferences': {'preference': dietaryPreference},
        });
      }
    } catch (e) {
      throw Exception('Registrierung fehlgeschlagen: $e');
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    try {
      await _supabase.auth.signInWithPassword(email: email, password: password);
    } catch (e) {
      throw Exception('Login fehlgeschlagen: $e');
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  Future<void> updateEmail(String newEmail) async {
    try {
      await _supabase.auth.updateUser(UserAttributes(email: newEmail));
    } catch (e) {
      throw Exception('Konnte E-Mail nicht ändern: ${e.toString()}');
    }
  }

  Future<void> updatePassword(String newPassword) async {
    try {
      await _supabase.auth.updateUser(UserAttributes(password: newPassword));
    } catch (e) {
      throw Exception('Konnte Passwort nicht ändern: ${e.toString()}');
    }
  }

  Future<void> reauthenticate(String oldPassword) async {
    final user = _supabase.auth.currentUser;
    if (user == null || user.email == null) {
      throw Exception('Benutzer nicht geladen.');
    }

    try {
      await _supabase.auth.signInWithPassword(
        email: user.email!,
        password: oldPassword,
      );
    } catch (e) {
      throw Exception('Das alte Passwort ist falsch.');
    }
  }

  Future<void> deleteAccount() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      await _supabase
          .from('profiles')
          .update({'deletion_scheduled_at': DateTime.now().toIso8601String()})
          .eq('id', user.id);

      await _supabase.auth.signOut();
    } catch (e) {
      throw Exception('Fehler beim Löschen des Accounts: $e');
    }
  }
}
