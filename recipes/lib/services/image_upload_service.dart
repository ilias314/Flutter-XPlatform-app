import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';

class ImageUploadService {
  final SupabaseClient _client;

  ImageUploadService(this._client);

  Future<String?> uploadProfileImage(File imageFile, String userId) async {
    try {
      Uint8List bytes = await imageFile.readAsBytes();
      String fileExt = imageFile.path.split('.').last.toLowerCase();

      final fileName = '$userId/profile_${DateTime.now().millisecondsSinceEpoch}.$fileExt';

      final mimeType = fileExt == 'png' ? 'image/png' : 'image/jpeg';

      await _client.storage.from('avatars').uploadBinary(
        fileName,
        bytes,
        fileOptions: FileOptions(
          contentType: mimeType, 
          upsert: true, 
        ),
      );

      final imageUrl = _client.storage.from('avatars').getPublicUrl(fileName);
      return imageUrl;
      
    } catch (e) {
      print('Profile Upload Error: $e');
      throw Exception('Upload fehlgeschlagen: $e');
    }
  }

  Future<String?> uploadRecipeImage(dynamic imageFile, String userId) async {
    try {
      Uint8List bytes;
      String fileExt;
      
      if (kIsWeb) {
        bytes = await imageFile.readAsBytes();
        fileExt = imageFile.name.split('.').last;
      } else {
        bytes = await (imageFile as File).readAsBytes();
        fileExt = (imageFile as File).path.split('.').last;
      }
      
      final fileName = '${DateTime.now().toIso8601String()}_$userId.$fileExt';
      final filePath = '/$userId/$fileName';

      await _client.storage.from('recipe_images').uploadBinary(
        filePath,
        bytes,
        fileOptions: const FileOptions(
          contentType: 'image/jpeg',
          upsert: false
        ),
      );

      final imageUrl = _client.storage.from('recipe_images').getPublicUrl(filePath);
      return imageUrl;
    } catch (e) {
      print('Upload Error: $e');
      return null;
    }
  }
}