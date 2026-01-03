import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:recipes/providers/home_provider.dart';
import 'package:recipes/widgets/ui_utils.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:recipes/data/recipe_repository.dart'; 
import 'package:recipes/models/recipe.dart'; 
import 'package:recipes/widgets/recipe_card.dart'; 
import 'package:recipes/data/profile_repository.dart'; 

class StartseitePages extends ConsumerStatefulWidget {
  const StartseitePages({super.key});

  @override
  ConsumerState<StartseitePages> createState() => _StartseitePagesState();
}

class _StartseitePagesState extends ConsumerState<StartseitePages> {
  
  // Default preference until loaded from DB
  String _userDietaryPreference = "Alles"; 

  @override
  void initState() {
    super.initState();
    _loadUserPreference();
  }

  // Load the saved preference from Supabase
  Future<void> _loadUserPreference() async {
    final profile = await ref.read(profileRepositoryProvider).getProfile();
    if (profile != null && profile['dietary_preferences'] != null) {
      final json = profile['dietary_preferences'];
      if (json['preference'] != null) {
        if (mounted) {
          setState(() {
            _userDietaryPreference = json['preference'];
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final recipesAsync = ref.watch(allRecipesProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('RecipeS'),
        titleTextStyle: const TextStyle(
          color: Colors.orange, 
          fontSize: 24, 
          fontWeight: FontWeight.bold,
        ),
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

      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.orange,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(Icons.restaurant_menu, color: Colors.white, size: 48),
                  SizedBox(height: 10),
                  Text(
                    'RecipeS Menü',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            
            ListTile(
              title: const Text('Favoriten'),
              onTap: () {
                Navigator.pop(context); 
                context.push('/favorites');
                print("Navigiere zu Favoriten");
              },
            ),

            ListTile(
              title: const Text('Meine Rezepte'),
              onTap: () {
                Navigator.pop(context);
                context.push('/my-recipes');
                print("Navigiere zu Meine Rezepte");
              },
            ),
          ],
        ),
      ),

      body: recipesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Fehler: $error')),
        data: (allRecipes) {
          if (allRecipes.isEmpty) {
            return const Center(child: Text('Noch keine Rezepte vorhanden.'));
          }

          // ============================================================
          // 1. NEUESTE REZEPTE (Top 10 Newest)
          // ============================================================
          final newestRecipes = List<Recipe>.from(allRecipes);
          newestRecipes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          final newestSection = newestRecipes.take(10).toList();

          // ============================================================
          // 2. FÜR DICH AUSGEWÄHLT (Based on User Dietary Preference)
          // ============================================================
          List<Recipe> dietRecipes;

          if (_userDietaryPreference == "Alles") {
            // Show all recipes sorted by rating
            dietRecipes = List.from(allRecipes);
            dietRecipes.sort((a, b) => b.avgRating.compareTo(a.avgRating));
          } else {
            // Filter by category - check if recipe has the matching category
            dietRecipes = allRecipes.where((recipe) {
              // Check if any of the recipe's categories match the user preference
              bool hasMatch = recipe.categories.any((cat) => 
                cat.toLowerCase() == _userDietaryPreference.toLowerCase()
              );
              
              if (hasMatch) {
                print('✅ Recipe "${recipe.name}" matches $_userDietaryPreference (categories: ${recipe.categories})');
              }
              
              return hasMatch;
            }).toList();
            
            // Sort by rating
            dietRecipes.sort((a, b) => b.avgRating.compareTo(a.avgRating));
          }

          print('🍽️ User preference: $_userDietaryPreference');
          print('📊 Total recipes: ${allRecipes.length}');
          print('📊 Matching recipes: ${dietRecipes.length}');
          final dietSection = dietRecipes.take(10).toList();

          // ============================================================
          // 3. TOP DER WOCHE (Created this week, sorted by Rating)
          // ============================================================
          final now = DateTime.now();
          final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
          final endOfWeek = startOfWeek.add(const Duration(days: 7));

          final weekRecipes = allRecipes.where((r) {
            return r.createdAt.isAfter(startOfWeek) && r.createdAt.isBefore(endOfWeek);
          }).toList();
          
          weekRecipes.sort((a, b) => b.avgRating.compareTo(a.avgRating));
          final topWeekSection = weekRecipes.take(10).toList();

          // ============================================================
          // 4. TOP DES MONATS (Created this month, sorted by Rating)
          // ============================================================
          final startOfMonth = DateTime(now.year, now.month, 1);
          final endOfMonth = DateTime(now.year, now.month + 1, 0);

          final monthRecipes = allRecipes.where((r) {
            return r.createdAt.isAfter(startOfMonth) && r.createdAt.isBefore(endOfMonth);
          }).toList();

          monthRecipes.sort((a, b) => b.avgRating.compareTo(a.avgRating));
          final topMonthSection = monthRecipes.take(10).toList();

          return SingleChildScrollView(
            child: Column(
              children: <Widget>[
                const SizedBox(height: 20),
                
                // 1. NEUESTE
                _buildRealRecipeSection(context, 'Neueste Rezepte', newestSection),
                
                const SizedBox(height: 10),

                // 2. FÜR DICH (DIET) - Show message if no matches
                if (dietSection.isNotEmpty)
                  _buildRealRecipeSection(
                    context, 
                    'Für dich ausgewählt${_userDietaryPreference != "Alles" ? " ($_userDietaryPreference)" : ""}', 
                    dietSection
                  )
                else if (_userDietaryPreference != "Alles")
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Icon(Icons.info_outline, size: 48, color: Colors.grey[600]),
                            const SizedBox(height: 8),
                            Text(
                              'Keine $_userDietaryPreference Rezepte gefunden',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Erstelle Rezepte mit der Kategorie "$_userDietaryPreference" oder ändere deine Präferenz!',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                
                const SizedBox(height: 10),

                // 3. TOP WOCHE
                if (topWeekSection.isNotEmpty)
                  _buildRealRecipeSection(context, 'Top der Woche', topWeekSection),

                const SizedBox(height: 10),

                // 4. TOP MONAT
                if (topMonthSection.isNotEmpty)
                  _buildRealRecipeSection(context, 'Top des Monats', topMonthSection),
                
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRealRecipeSection(BuildContext context, String title, List<Recipe> recipes) {
    if (recipes.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                onPressed: () => showNotImplementedSnackbar(context),
                child: const Text('Alle'),
              ),
            ],
          ),
        ),
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