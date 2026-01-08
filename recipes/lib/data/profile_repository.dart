import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(Supabase.instance.client);
});

class ProfileRepository {
  final SupabaseClient _supabase;

  ProfileRepository(this._supabase);

  Future<Map<String, dynamic>?> getProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;
    try {
      return await _supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();
    } catch (e) {
      return null;
    }
  }

  Future<void> updateDietaryPreference(String preference) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('No user');
    await _supabase
        .from('profiles')
        .update({
          'dietary_preferences': {'preference': preference},
        })
        .eq('id', user.id);
  }

  Future<void> updateUsername(String newName) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('No user');
    await _supabase
        .from('profiles')
        .update({'display_name': newName})
        .eq('id', user.id);
  }

  Future<String> uploadProfilePicture(XFile image) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Nicht eingeloggt');

    try {
      final Uint8List bytes = await image.readAsBytes();

      final fileExt = image.name.split('.').last.toLowerCase();
      final fileName =
          '${user.id}/${DateTime.now().millisecondsSinceEpoch}.$fileExt';

      final contentType = fileExt == 'png' ? 'image/png' : 'image/jpeg';

      await _supabase.storage
          .from('avatars')
          .uploadBinary(
            fileName,
            bytes,
            fileOptions: FileOptions(upsert: true, contentType: contentType),
          );

      final imageUrl = _supabase.storage.from('avatars').getPublicUrl(fileName);

      await _supabase
          .from('profiles')
          .update({'avatar_url': imageUrl})
          .eq('id', user.id);

      return imageUrl;
    } catch (e) {
      print("Upload Error: $e");
      throw Exception('Upload fehlgeschlagen: $e');
    }
  }

  Future<void> deleteProfileImage() async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Nicht eingeloggt');

    try {
      await _supabase
          .from('profiles')
          .update({'avatar_url': null})
          .eq('id', user.id);
    } catch (e) {
      throw Exception('Löschen fehlgeschlagen: $e');
    }
  }
}
