// recipe_repository.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recipes/data/recipe_repository.dart';
import 'package:recipes/models/recipe.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final recipeRepositoryProvider = Provider((ref) => RecipeRepository(Supabase.instance.client));

final allRecipesProvider = FutureProvider<List<Recipe>>((ref) async {
  final repo = ref.watch(recipeRepositoryProvider);
  return repo.getRecipes();
});