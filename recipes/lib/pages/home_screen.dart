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
      // ---------------------------------------------------------
      // 1. APP BAR (Ohne manuelles leading Icon!)
      // Flutter fügt das Burger-Icon automatisch hinzu, weil wir unten einen 'drawer' haben.
      // ---------------------------------------------------------
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

      // ---------------------------------------------------------
      // 2. DRAWER (Das Menü, das von der Seite kommt)
      // ---------------------------------------------------------
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero, // Wichtig, damit es auch hinter die Statusleiste geht
          children: [
            // Der Kopfbereich des Menüs
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.orange, // Deine App-Farbe
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
            
            // Eintrag 1: Favoriten
            ListTile(
              title: const Text('Favoriten'),
              onTap: () {
                // Erst den Drawer schließen, dann navigieren
                Navigator.pop(context); 
                context.push('/favorites');
                print("Navigiere zu Favoriten");
              },
            ),

            // Eintrag 2: Meine Rezepte
            ListTile(
              title: const Text('Meine Rezepte'),
              onTap: () {
                Navigator.pop(context);
                // context.go('/my-recipes'); // TODO: Route einfügen
                print("Navigiere zu Meine Rezepte");
              },
            ),
          ],
        ),
      ),

      // ---------------------------------------------------------
      // 3. BODY (Der Inhalt der Seite)
      // ---------------------------------------------------------
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

          // Data Preparation...
          final newestRecipes = List<Recipe>.from(allRecipes); 
          final dietRecipes = allRecipes.take(5).toList();
          final topWeekRecipes = allRecipes.take(3).toList(); 
          final topMonthRecipes = allRecipes.skip(3).take(3).toList();

          return SingleChildScrollView(
            child: Column(
              children: <Widget>[
                const SizedBox(height: 20),
                _buildRealRecipeSection(context, 'Für dich ausgewählt', dietRecipes),
                const SizedBox(height: 10),
                _buildRealRecipeSection(context, 'Neueste Rezepte', newestRecipes),
                const SizedBox(height: 10),
                _buildRealRecipeSection(context, 'Top der Woche', topWeekRecipes),
                const SizedBox(height: 10),
                _buildRealRecipeSection(context, 'Top des Monats', topMonthRecipes),
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
                onPressed: () {},
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