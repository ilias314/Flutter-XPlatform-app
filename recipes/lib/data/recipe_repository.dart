import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/recipe.dart';

class RecipeRepository {
  final SupabaseClient _client;

  RecipeRepository(this._client);

  /// Main function to save a new recipe and its ingredients
  Future<void> createRecipe({
    required String userId,
    required String name,
    required String description,
    required int prepTime,
    required int portions,
    required String difficulty,
    String? imageUrl,
    // We expect a list of maps: [{'name': 'Flour', 'quantity': 500, 'unit': 'g'}, ...]
    required List<Map<String, dynamic>> ingredients,
    double calories = 0.0,
    double protein = 0.0,
    double carbs = 0.0,
    double fat = 0.0,
    double sugar = 0.0,
    double fiber = 0.0,
  }) async {
    
    // --- STEP 1: Insert the Recipe ---
    // We insert the main details and ask Supabase to return the new ID immediately.
    final recipeResponse = await _client.from('recipes').insert({
      'user_id': userId,
      'name': name,
      'description': description,
      'preparation_time': prepTime,
      'portions': portions,
      'difficulty': difficulty,
      'image_url': imageUrl,
      'calories_per_portion': 0, // Default to 0 if UI doesn't have this field yet

      'protein_per_portion': protein,
      'carbs_per_portion': carbs,
      'fat_per_portion': fat,
      'sugar_per_portion': sugar,
      'fiber_per_portion': fiber,
      
      // Initialize ratings to 0
      'avg_rating': 0.0,
      'rating_count': 0,
    }).select('id').single(); 

    final String newRecipeId = recipeResponse['id'];

    // --- STEP 2: Process Ingredients ---
    // This is tricky: Ingredients might already exist in the DB, or they might be new.
    for (var item in ingredients) {
      final String ingName = item['name'];
      final double quantity = (item['quantity'] as num).toDouble();
      final String unit = item['unit'];

      if (ingName.isEmpty) continue; // Skip empty rows

      // A. Get the Ingredient ID (Find existing OR Create new)
      String ingredientId = await _getOrCreateIngredientId(ingName, unit);

      // B. Link Ingredient to Recipe (Insert into 'recipe_ingredients')
      await _client.from('recipe_ingredients').insert({
        'recipe_id': newRecipeId,
        'ingredient_id': ingredientId,
        'quantity': quantity,
        'unit': unit,
      });
    }
  }

  /// Helper: Checks if ingredient exists. If yes, returns ID. If no, creates it and returns new ID.
  Future<String> _getOrCreateIngredientId(String name, String defaultUnit) async {
    // 1. Try to find it
    final existing = await _client
        .from('ingredients')
        .select('id')
        .ilike('name', name) // Case-insensitive search (e.g. "Milk" == "milk")
        .maybeSingle();

    if (existing != null) {
      return existing['id'];
    }

    // 2. If not found, create it
    final newIngredient = await _client
        .from('ingredients')
        .insert({
          'name': name,
          'default_unit': defaultUnit
        })
        .select('id')
        .single();
        
    return newIngredient['id'];
  }
  
  /// Helper: Fetch all recipes for the Home Screen
  Future<List<Recipe>> getRecipes() async {
    final data = await _client.from('recipes').select().order('created_at', ascending: false);
    return data.map((json) => Recipe.fromJson(json)).toList();
  }
}