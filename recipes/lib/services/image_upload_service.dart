import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';

class ImageUploadService {
  final SupabaseClient _client;

  ImageUploadService(this._client);

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