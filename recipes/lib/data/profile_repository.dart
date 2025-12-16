import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider to access this repository
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(Supabase.instance.client);
});

class ProfileRepository {
  final SupabaseClient _supabase;

  ProfileRepository(this._supabase);

  // 1. Get the current user's profile
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
      print('Error fetching profile: $e');
      return null;
    }
  }

  // 2. Update the Dietary Preference
  Future<void> updateDietaryPreference(String preference) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('No user logged in');
    }

    try {
      print('🔄 Updating dietary preference to: $preference');
      
      // Check if profile exists first
      final existing = await _supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (existing == null) {
        // Profile doesn't exist, create it
        print('📝 Creating new profile');
        await _supabase.from('profiles').insert({
          'id': user.id,
          'email': user.email,
          'dietary_preferences': {'preference': preference},
        });
      } else {
        // Profile exists, update it
        print('📝 Updating existing profile');
        await _supabase
            .from('profiles')
            .update({
              'dietary_preferences': {'preference': preference},
            })
            .eq('id', user.id);
      }
      
      print('✅ Dietary preference updated successfully');
    } catch (e) {
      print('❌ Error updating dietary preference: $e');
      rethrow;
    }
  }
}