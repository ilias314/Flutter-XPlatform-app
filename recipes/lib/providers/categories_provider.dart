import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/category.dart';
import '../data/recipe_repository.dart';

final categoriesProvider = FutureProvider<List<RecipeCategory>>((ref) async {
  final supabase = Supabase.instance.client;
  final repo = RecipeRepository(supabase);
  return repo.getCategories();
});
