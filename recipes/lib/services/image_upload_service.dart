import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class ImageUploadService {
  final SupabaseClient _client;

  ImageUploadService(this._client);

  Future<String?> uploadRecipeImage(File imageFile, String userId) async {
    try {
      final bytes = await imageFile.readAsBytes();
      // 1. Generate a unique filename
      final fileExt = imageFile.path.split('.').last;
      final fileName = '${DateTime.now().toIso8601String()}_$userId.$fileExt';
      final filePath = '/$userId/$fileName'; // Folder structure: user_id/filename

      // 2. Upload to Supabase Bucket 'recipe_images'
      await _client.storage.from('recipe_images').uploadBinary(
        filePath,
        bytes,
        fileOptions: const FileOptions(
          contentType: 'image/jpeg', // Optional: Helps browser display it correctly
          upsert: false
        ),
      );

      // 3. Get the Public Link
      final imageUrl = _client.storage.from('recipe_images').getPublicUrl(filePath);
      return imageUrl;
    } catch (e) {
      print('Upload Error: $e');
      return null;
    }
  }
}