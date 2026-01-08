import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/recipe.dart';

final favoritesProvider = StateNotifierProvider<FavoritesNotifier, Set<String>>(
  (ref) {
    return FavoritesNotifier();
  },
);

class FavoritesNotifier extends StateNotifier<Set<String>> {
  FavoritesNotifier() : super({}) {
    _loadFavorites();
  }

  final _supabase = Supabase.instance.client;

  Future<void> _loadFavorites() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final data = await _supabase
        .from('favourites')
        .select('recipe_id')
        .eq('user_id', user.id);

    state = {for (final row in data) row['recipe_id'] as String};
  }

  Future<void> toggleFavorite(String recipeId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final isFav = state.contains(recipeId);

    if (isFav) {
      await _supabase
          .from('favourites')
          .delete()
          .eq('user_id', user.id)
          .eq('recipe_id', recipeId);

      state = {...state}..remove(recipeId);
    } else {
      await _supabase.from('favourites').insert({
        'user_id': user.id,
        'recipe_id': recipeId,
      });

      state = {...state, recipeId};
    }
  }
}
