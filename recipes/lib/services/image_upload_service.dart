import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';

class ImageUploadService {
  final SupabaseClient _client;

  ImageUploadService(this._client);

  // ----------------------------------------------------------------
  // METHODE 1: Profilbild hochladen (Bucket: 'avatars')
  // ----------------------------------------------------------------
  Future<String?> uploadProfileImage(File imageFile, String userId) async {
    try {
      // 1. Bytes und Endung lesen
      Uint8List bytes = await imageFile.readAsBytes();
      String fileExt = imageFile.path.split('.').last.toLowerCase();

      // 2. Dateiname (Wir überschreiben immer das gleiche Bild für den User, um Speicher zu sparen)
      // Oder: Timestamp nutzen, um Caching-Probleme zu vermeiden.
      final fileName = '$userId/profile_${DateTime.now().millisecondsSinceEpoch}.$fileExt';

      // 3. WICHTIG: Content-Type dynamisch bestimmen
      // Das verhindert den "Namespace" / XML Fehler!
      final mimeType = fileExt == 'png' ? 'image/png' : 'image/jpeg';

      // 4. Upload in 'avatars' Bucket
      await _client.storage.from('avatars').uploadBinary(
        fileName,
        bytes,
        fileOptions: FileOptions(
          contentType: mimeType, // <--- DAS IST DER FIX
          upsert: true, // Überschreiben erlauben
        ),
      );

      // 5. Public URL holen
      final imageUrl = _client.storage.from('avatars').getPublicUrl(fileName);
      return imageUrl;
      
    } catch (e) {
      print('❌ Profile Upload Error: $e');
      throw Exception('Upload fehlgeschlagen: $e');
    }
  }

  // ----------------------------------------------------------------
  // METHODE 2: Rezeptbild hochladen (Bucket: 'recipe_images')
  // ----------------------------------------------------------------
  Future<String?> uploadRecipeImage(dynamic imageFile, String userId) async {
    try {
      Uint8List bytes;
      String fileExt;
      
      // Handle both web and mobile
      if (kIsWeb) {
        // Web: imageFile is XFile, read as bytes directly
        bytes = await imageFile.readAsBytes();
        fileExt = imageFile.name.split('.').last;
      } else {
        // Mobile: imageFile is File
        bytes = await (imageFile as File).readAsBytes();
        fileExt = (imageFile as File).path.split('.').last;
      }
      
      // Generate a unique filename
      final fileName = '${DateTime.now().toIso8601String()}_$userId.$fileExt';
      final filePath = '/$userId/$fileName';

      // Upload to Supabase Bucket 'recipe_images'
      await _client.storage.from('recipe_images').uploadBinary(
        filePath,
        bytes,
        fileOptions: const FileOptions(
          contentType: 'image/jpeg',
          upsert: false
        ),
      );

      // Get the Public Link
      final imageUrl = _client.storage.from('recipe_images').getPublicUrl(filePath);
      return imageUrl;
    } catch (e) {
      print('Upload Error: $e');
      return null;
    }
  }
}