import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:recipes/data/recipe_repository.dart'; 
import 'package:recipes/models/recipe.dart'; 
import 'package:recipes/pages/recipe_detail_screen.dart'; 
import 'package:recipes/widgets/recipe_card.dart'; 

class StartseitePages extends StatefulWidget {
  const StartseitePages({super.key});

  @override
  State<StartseitePages> createState() => _StartseitePagesState();
}

class _StartseitePagesState extends State<StartseitePages> {
  // We store the "Future" here so we can load data when the screen opens
  late Future<List<Recipe>> _recipesFuture;

  @override
  void initState() {
    super.initState();
    // 1. Fetch the data immediately
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
      // 2. The Body is now a FutureBuilder
      body: FutureBuilder<List<Recipe>>(
        future: _recipesFuture,
        builder: (context, snapshot) {
          // A. Loading State
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // B. Error State
          if (snapshot.hasError) {
            return Center(child: Text('Fehler: ${snapshot.error}'));
          }

          // C. Data Ready
          final allRecipes = snapshot.data ?? [];

          if (allRecipes.isEmpty) {
            return const Center(
              child: Text(
                'Noch keine Rezepte.\nErstelle das erste!',
                textAlign: TextAlign.center,
              ),
            );
          }

          // D. Sort/Filter Logic (Optional: Organize your lists)
          // For now, we just reverse the list for "Newest" and shuffle/sort for "Top"
          final newestRecipes = List<Recipe>.from(allRecipes); // Already sorted by date in Repo
          
          // Example: Filter mostly high rated (dummy logic if rating is 0)
          final topRecipes = allRecipes.where((r) => r.preparationTime < 60).toList();

          return SingleChildScrollView(
            child: Column(
              children: <Widget>[
                const SizedBox(height: 20),
                
                // 1. Neueste Rezepte (The main list)
                _buildRealRecipeSection(context, 'Neueste Rezepte', newestRecipes),
                
                const SizedBox(height: 20),
                
                // 2. Schnelle Rezepte (Simulated "Top" category)
                _buildRealRecipeSection(context, 'Schnelle Küche (< 60 Min)', topRecipes),
                
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- HELPER WIDGET: Displays a horizontal list of RecipeCards ---
  Widget _buildRealRecipeSection(BuildContext context, String title, List<Recipe> recipes) {
    // 1. Safety Check: If no recipes, hide the entire section
    if (recipes.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 2. Section Title & "See All" Button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              TextButton(
                onPressed: () {
                  // TODO: Implement a "See All" page later
                  // context.push('/all-recipes');
                },
                child: const Text('Alle ansehen'),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 10),

        // 3. The Horizontal List
        SizedBox(
          height: 260, // Fixed height to fit the Card
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: recipes.length,
            itemBuilder: (context, index) {
              final recipe = recipes[index]; // <--- Get the specific recipe object
              
              return Container(
                width: 200, // Fixed width for each card
                margin: const EdgeInsets.symmetric(horizontal: 6),
                
                // 4. Use the RecipeCard Widget
                child: RecipeCard(recipe: recipe), 
              );
            },
          ),
        ),
      ],
    );
  }
}