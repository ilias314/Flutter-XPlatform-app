import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:recipes/data/recipe_repository.dart'; 
import 'package:recipes/models/recipe.dart'; 
import 'package:recipes/widgets/recipe_card.dart'; 

class StartseitePages extends StatefulWidget {
  const StartseitePages({super.key});

  @override
  State<StartseitePages> createState() => _StartseitePagesState();
}

class _StartseitePagesState extends State<StartseitePages> {
  late Future<List<Recipe>> _recipesFuture;

  @override
  void initState() {
    super.initState();
    final repo = RecipeRepository(Supabase.instance.client);
    _recipesFuture = repo.getRecipes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RecipeS'),
        centerTitle: true,
        actions: <Widget>[
          Hero(
            tag: 'search-bar',
            child: Material(
              color: Colors.transparent,
              child: IconButton(
                icon: const Icon(Icons.search),
                onPressed: () => context.go('/search'),
              ),
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<Recipe>>(
        future: _recipesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Fehler: ${snapshot.error}'));
          }

          final allRecipes = snapshot.data ?? [];

          if (allRecipes.isEmpty) {
            return const Center(child: Text('Noch keine Rezepte vorhanden.'));
          }

          // -----------------------------------------------------------
          // DATA PREPARATION (Sorting & Filtering)
          // -----------------------------------------------------------

          // 1. Neueste Rezepte (Assuming the API returns them, or we sort by ID/Date)
          final newestRecipes = List<Recipe>.from(allRecipes); 
          // newestRecipes.sort((a, b) => b.createdAt.compareTo(a.createdAt)); // Uncomment if you have a date field

          // 2. Top Rezepte je nach Ernährungsweise (Placeholder Logic)
          // TODO: Connect this to the user's actual profile preference (e.g., from Riverpod)
          // For now, we simulate a "Vegetarian" preference or just show a mix.
          final dietRecipes = allRecipes.where((r) {
             // Example: return r.isVegetarian == true;
             return true; // Returns all for now until you define the filter
          }).take(5).toList();

          // 3. Top der Woche (High rating + Created recently)
          // Since we might not have 'rating' or 'date' yet, we take the first 3 as a dummy.
          final topWeekRecipes = allRecipes.take(3).toList(); 

          // 4. Top des Monats
          // We take a different slice or sort differently
          final topMonthRecipes = allRecipes.skip(3).take(3).toList();

          return SingleChildScrollView(
            child: Column(
              children: <Widget>[
                const SizedBox(height: 20),
                
                // SECTION 1: Top Rezepte je nach Ernährungsweise
                _buildRealRecipeSection(context, 'Für dich ausgewählt', dietRecipes),
                
                const SizedBox(height: 10),

                // SECTION 2: Neueste Rezepte
                _buildRealRecipeSection(context, 'Neueste Rezepte', newestRecipes),
                
                const SizedBox(height: 10),

                // SECTION 3: Top Rezepte der Woche
                _buildRealRecipeSection(context, 'Top der Woche', topWeekRecipes),

                const SizedBox(height: 10),

                // SECTION 4: Top Rezepte des Monats
                _buildRealRecipeSection(context, 'Top des Monats', topMonthRecipes),
                
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- HELPER WIDGET ---
  Widget _buildRealRecipeSection(BuildContext context, String title, List<Recipe> recipes) {
    if (recipes.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title Row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
              ),
              TextButton(
                onPressed: () {
                  // TODO: Navigate to a "See All" list
                },
                child: const Text('Alle'),
              ),
            ],
          ),
        ),
        
        // Horizontal List
        SizedBox(
          height: 260, 
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: recipes.length,
            itemBuilder: (context, index) {
              final recipe = recipes[index];
              return Container(
                width: 200, 
                margin: const EdgeInsets.symmetric(horizontal: 6),
                child: RecipeCard(recipe: recipe), 
              );
            },
          ),
        ),
      ],
    );
  }
}