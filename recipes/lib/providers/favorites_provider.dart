import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/recipe.dart';

final favoritesProvider = StateNotifierProvider<FavoritesNotifier, List<Recipe>>((ref) {
  return FavoritesNotifier();
});

class FavoritesNotifier extends StateNotifier<List<Recipe>> {
  FavoritesNotifier() : super([]) {
    _loadFavorites(); 
  }

  final _supabase = Supabase.instance.client;

  Future<void> _loadFavorites() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      final data = await _supabase
          .from('favourites')
          .select('recipes (*)') 
          .eq('user_id', user.id);

      // verwandeln der Daten in eine Liste von Recipe-Objekten
      final List<Recipe> loadedRecipes = (data as List).map((fav) {
        return Recipe.fromJson(fav['recipes']);
      }).toList();

      state = loadedRecipes;
    } catch (e) {
      print('Fehler beim Laden der Favoriten: $e');
    }
  }

  Future<void> toggleFavorite(Recipe recipe) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final isExist = state.any((r) => r.id == recipe.id);

    try {
      if (isExist) {
        await _supabase
            .from('favourites')
            .delete()
            .eq('user_id', user.id)
            .eq('recipe_id', recipe.id as Object);
        
        state = state.where((r) => r.id != recipe.id).toList();
      } else {
        await _supabase.from('favourites').insert({
          'user_id': user.id,
          'recipe_id': recipe.id,
        });

        state = [...state, recipe];
      }
    } catch (e) {
      print('Fehler beim Ändern des Favoriten: $e');
    }
  }
}