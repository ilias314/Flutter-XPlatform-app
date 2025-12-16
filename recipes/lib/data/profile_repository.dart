import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// The Provider
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(Supabase.instance.client);
});

class ProfileRepository {
  final SupabaseClient _supabase;

  ProfileRepository(this._supabase);

  // 1. Get Profile
  Future<Map<String, dynamic>?> getProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    try {
      final data = await _supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();
      return data;
    } catch (e) {
      // Falls noch kein Profil existiert, ist das kein kritischer Fehler
      print('Info fetching profile: $e'); 
      return null;
    }
  }

  // 2. Update Dietary Preference
  Future<void> updateDietaryPreference(String preference) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('No user logged in');

    try {
      // Upsert: Erstellt oder aktualisiert das Profil
      await _supabase.from('profiles').upsert({
        'id': user.id,
        'email': user.email, // E-Mail mitspeichern zur Sicherheit
        'dietary_preferences': {'preference': preference},
      });
      
      print('✅ Dietary preference updated');
    } catch (e) {
      print('❌ Error updating preference: $e');
      rethrow;
    }
  }

  // =========================================================
  // NEUE METHODE: USERNAME
  // =========================================================
  
  // 3. Update Username
  Future<void> updateUsername(String newName) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('No user logged in');

    try {
      print('🔄 Updating display_name to: $newName');

      // Wir nutzen 'upsert' (Update oder Insert), damit es auch klappt,
      // wenn der User vorher noch gar keinen Eintrag in der Tabelle hatte.
      await _supabase.from('profiles').upsert({
        'id': user.id,
        'display_name': newName,
        // Wir aktualisieren nur diese Spalte, aber bei upsert müssen wir aufpassen,
        // dass wir keine anderen Daten überschreiben, falls es ein Insert ist.
        // Supabase 'update' ist sicherer, wenn das Profil sicher existiert.
        // Da wir oben im Code aber schon 'updateDietaryPreference' nutzen, 
        // gehen wir davon aus, dass ein Profil existiert oder angelegt wird.
      }, onConflict: 'id'); // onConflict sorgt dafür, dass bei gleicher ID geupdatet wird.

      // Alternativ, wenn du sicher bist, dass das Profil existiert:
      /*
      await _supabase
          .from('profiles')
          .update({'username': newName})
          .eq('id', user.id);
      */
      
      print('✅ Username updated successfully');
    } catch (e) {
      print('❌ Error updating username: $e');
      throw Exception('Konnte Benutzernamen nicht speichern: $e');
    }
  }
}