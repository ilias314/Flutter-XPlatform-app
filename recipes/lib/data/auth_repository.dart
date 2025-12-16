import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 1. Der Provider: Macht das Repository für die UI verfügbar
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(Supabase.instance.client);
});

// 2. Die Klasse: Beinhaltet alle Auth-Funktionen
class AuthRepository {
  final SupabaseClient _supabase;

  AuthRepository(this._supabase);

  // Getter für aktuellen User und Auth-Status
  User? get currentUser => _supabase.auth.currentUser;
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  // --- Sign Up (Registrieren) ---
  // HIER WICHTIG: username Parameter für Profil-Erstellung
  Future<void> signUp({
    required String email, 
    required String password,
    required String username, 
  }) async {
    try {
      // 1. User erstellen
      final AuthResponse res = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      // 2. Profil Eintrag in Datenbank erstellen (Upsert)
      final user = res.user;
      if (user != null) {
        await _supabase.from('profiles').upsert({
          'id': user.id,
          'email': email,
          'display_name': username, // Speichert den Namen in 'display_name'
        });
      }
    } catch (e) {
      throw Exception('Registrierung fehlgeschlagen: $e');
    }
  }

  // --- Sign In (Einloggen) ---
  Future<void> signIn({required String email, required String password}) async {
    try {
      await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw Exception('Login fehlgeschlagen: $e');
    }
  }

  // --- Sign Out (Ausloggen) ---
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }


  // 1. E-Mail ändern
  Future<void> updateEmail(String newEmail) async {
    try {
      await _supabase.auth.updateUser(
        UserAttributes(email: newEmail),
      );
    } catch (e) {
      throw Exception('Konnte E-Mail nicht ändern: ${e.toString()}');
    }
  }

  // 2. Passwort ändern
  Future<void> updatePassword(String newPassword) async {
    try {
      await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );
    } catch (e) {
      throw Exception('Konnte Passwort nicht ändern: ${e.toString()}');
    }
  }

  // 3. Re-Authentifizierung (Altes Passwort prüfen)
  Future<void> reauthenticate(String oldPassword) async {
    final user = _supabase.auth.currentUser;
    if (user == null || user.email == null) {
      throw Exception('Benutzer nicht geladen.');
    }

    try {
      // Wir versuchen einen Login im Hintergrund, um das Passwort zu prüfen
      await _supabase.auth.signInWithPassword(
        email: user.email!, 
        password: oldPassword
      );
    } catch (e) {
      throw Exception('Das alte Passwort ist falsch.');
    }
  }

  // 4. Account löschen (via SQL Funktion)
  Future<void> deleteAccount() async {
    try {
      // Ruft die SQL-Funktion 'delete_user' auf (muss in Supabase angelegt sein)
      await _supabase.rpc('delete_user');
      // Lokal ausloggen
      await _supabase.auth.signOut();
    } catch (e) {
      throw Exception('Profil konnte nicht gelöscht werden: $e');
    }
  }
}