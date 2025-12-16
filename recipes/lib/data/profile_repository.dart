import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart'; //  Wichtig für Laptop-Upload
import 'dart:typed_data'; // für die Bild-Daten

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(Supabase.instance.client);
});

class ProfileRepository {
  final SupabaseClient _supabase;

  ProfileRepository(this._supabase);

  // 1. Profil laden
  Future<Map<String, dynamic>?> getProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;
    try {
      return await _supabase.from('profiles').select().eq('id', user.id).single();
    } catch (e) {
      return null;
    }
  }

  // 2. Ernährungsweise ändern
  Future<void> updateDietaryPreference(String preference) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('No user');
    await _supabase.from('profiles').update({'dietary_preferences': {'preference': preference}}).eq('id', user.id);
  }

  // 3. Username ändern
  Future<void> updateUsername(String newName) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('No user');
    await _supabase.from('profiles').update({'display_name': newName}).eq('id', user.id);
  }

  // ---------------------------------------------------------
  // 4. BILD UPLOAD (UNIVERSAL: HANDY & LAPTOP)
  // ---------------------------------------------------------
  // Wir nutzen hier 'XFile' statt 'File', weil das auf allen Geräten funktioniert.
  Future<String> uploadProfilePicture(XFile image) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Nicht eingeloggt');

    try {
      // A) Bild-Daten als "Bytes" lesen (funktioniert auf Windows/Mac/Web/Mobile)
      final Uint8List bytes = await image.readAsBytes();

      // B) Dateiendung holen
      final fileExt = image.name.split('.').last.toLowerCase();
      final fileName = '${user.id}/${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      
      // C) Content-Type bestimmen (gegen Namespace-Fehler)
      final contentType = fileExt == 'png' ? 'image/png' : 'image/jpeg';

      // D) Binär-Upload (uploadBinary statt upload)
      await _supabase.storage
          .from('avatars') 
          .uploadBinary(
            fileName, 
            bytes, 
            fileOptions: FileOptions(
              upsert: true,
              contentType: contentType, 
            ),
          );

      // E) URL holen
      final imageUrl = _supabase.storage.from('avatars').getPublicUrl(fileName);

      // F) URL in Datenbank speichern
      await _supabase
          .from('profiles')
          .update({ 'avatar_url': imageUrl })
          .eq('id', user.id);

      return imageUrl; 
    } catch (e) {
      print("Upload Error: $e");
      throw Exception('Upload fehlgeschlagen: $e');
    }
  }
  // ---------------------------------------------------------
  // 5. Profilbild löschen
  // ---------------------------------------------------------
  Future<void> deleteProfileImage() async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Nicht eingeloggt');

    try {
      // Wir setzen die URL in der Datenbank einfach auf null
      await _supabase
          .from('profiles')
          .update({ 'avatar_url': null })
          .eq('id', user.id);
          
      // Optional: Du könntest hier auch das File aus dem Storage löschen,
      // aber das Link-Entfernen reicht für die Optik völlig aus.
    } catch (e) {
      throw Exception('Löschen fehlgeschlagen: $e');
    }
  }
}