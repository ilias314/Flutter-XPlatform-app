import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/recipe.dart';
import '../models/category.dart';

class RecipeRepository {
  final SupabaseClient _client;

  RecipeRepository(this._client);

  /// Fetch all available categories
  Future<List<RecipeCategory>> getCategories() async {
    final data = await _client
        .from('categories')
        .select()
        .order('name', ascending: true);

    return data.map((json) => RecipeCategory.fromJson(json)).toList();
  }

  Future<List<Recipe>> getUserRecipes(String userId) async {
    try {
      final response = await _client
          .from('recipes')
          .select('''
          *,
          recipe_categories (
            categories (
              name
            )
          )
        ''') 
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      
      return (response as List).map((json) => Recipe.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération de vos recettes : $e');
    }
  }

  /// Main function to save a new recipe and its ingredients
  Future<void> createRecipe({
    required String userId,
    required String name,
    required String description,
    required int prepTime,
    required int portions,
    required String difficulty,
    String? imageUrl,
    required List<Map<String, dynamic>> ingredients,
    List<String> categoryIds = const [], // NEW: Category IDs
    double calories = 0.0,
    double protein = 0.0,
    double carbs = 0.0,
    double fat = 0.0,
    double sugar = 0.0,
    double fiber = 0.0,
  }) async {
    // --- STEP 1: Insert the Recipe ---
    final recipeResponse = await _client
        .from('recipes')
        .insert({
          'user_id': userId,
          'name': name,
          'description': description,
          'preparation_time': prepTime,
          'portions': portions,
          'difficulty': difficulty,
          'image_url': imageUrl,
          'calories_per_portion': calories,
          'protein_per_portion': protein,
          'carbs_per_portion': carbs,
          'fat_per_portion': fat,
          'sugar_per_portion': sugar,
          'fiber_per_portion': fiber,
          'avg_rating': 0.0,
          'rating_count': 0,
        })
        .select('id')
        .single();

    final String newRecipeId = recipeResponse['id'];

    // --- STEP 2: Process Ingredients ---
    for (var item in ingredients) {
      final String ingName = item['name'];
      final double quantity = (item['quantity'] as num).toDouble();
      final String unit = item['unit'];

      if (ingName.isEmpty) continue;

      String ingredientId = await _getOrCreateIngredientId(ingName, unit);

      await _client.from('recipe_ingredients').insert({
        'recipe_id': newRecipeId,
        'ingredient_id': ingredientId,
        'quantity': quantity,
        'unit': unit,
      });
    }

    // --- STEP 3: Link Categories to Recipe ---
    if (categoryIds.isNotEmpty) {
      final categoryLinks = categoryIds
          .map(
            (categoryId) => {
              'recipe_id': newRecipeId,
              'category_id': categoryId,
            },
          )
          .toList();

      await _client.from('recipe_categories').insert(categoryLinks);
    }
  }

  /// Helper: Checks if ingredient exists. If yes, returns ID. If no, creates it and returns new ID.
  Future<String> _getOrCreateIngredientId(
    String name,
    String defaultUnit,
  ) async {
    final existing = await _client
        .from('ingredients')
        .select('id')
        .ilike('name', name)
        .maybeSingle();

    if (existing != null) {
      return existing['id'];
    }

    final newIngredient = await _client
        .from('ingredients')
        .insert({'name': name, 'default_unit': defaultUnit})
        .select('id')
        .single();

    return newIngredient['id'];
  }

  /// Helper: Fetch all recipes for the Home Screen with categories
  Future<List<Recipe>> getRecipes() async {
    final data = await _client
        .from('recipes')
        .select('''
          *,
          recipe_categories (
            categories (
              name
            )
          )
        ''')
        .order('created_at', ascending: false);

    return data.map((json) => Recipe.fromJson(json)).toList();
  }

  /// Fetch recipes filtered by category names
  Future<List<Recipe>> getRecipesByCategories(
    List<String> categoryNames,
  ) async {
    if (categoryNames.isEmpty) {
      return getRecipes();
    }

    // First get category IDs from names
    final categoryData = await _client
        .from('categories')
        .select('id')
        .inFilter('name', categoryNames);

    final categoryIds = categoryData.map((c) => c['id'] as String).toList();

    if (categoryIds.isEmpty) {
      return [];
    }

    // Then get recipes that have these categories
    final recipeLinks = await _client
        .from('recipe_categories')
        .select('recipe_id')
        .inFilter('category_id', categoryIds);

    final recipeIds = recipeLinks
        .map((r) => r['recipe_id'] as String)
        .toSet()
        .toList();

    if (recipeIds.isEmpty) {
      return [];
    }

    // Finally fetch the full recipe data
    final data = await _client
        .from('recipes')
        .select('''
          *,
          recipe_categories (
            categories (
              name
            )
          )
        ''')
        .inFilter('id', recipeIds)
        .order('avg_rating', ascending: false);

    return data.map((json) => Recipe.fromJson(json)).toList();
  }

  /// Fetch ingredients for a specific recipe
  /// Returns a list like: [{'name': 'Tomato', 'quantity': 2.0, 'unit': 'pcs'}
  Future<List<Map<String, dynamic>>> getRecipeIngredients(
    String recipeId,
  ) async {
    try {
      final response = await _client
          .from('recipe_ingredients')
          .select('''
          quantity,
          unit,
          ingredient_id,
          ingredients (
            id,
            name
          )
        ''')
          .eq('recipe_id', recipeId);

      return List<Map<String, dynamic>>.from(
        response.map(
          (item) => {
           
            'ingredient_id': item['ingredient_id'],
            'name': item['ingredients']['name'],
            'quantity': (item['quantity'] ?? 0).toDouble(),
            'unit': item['unit'] ?? '',
          },
        ),
      );
    } catch (e) {
      print('Error loading ingredients: $e');
      return [];
    }
  }
}
