import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:recipes/models/recipe.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/recipe_repository.dart';
import '../widgets/weekly_recipe_card.dart'; 

class MyRecipesListScreen extends StatefulWidget {
  const MyRecipesListScreen({super.key});

  @override
  State<MyRecipesListScreen> createState() => _MyRecipesListScreenState();
}

class _MyRecipesListScreenState extends State<MyRecipesListScreen> {
  late Future<List<Recipe>> _userRecipesFuture;
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _refreshRecipes();
  }

  void _refreshRecipes() {
    final userId = supabase.auth.currentUser?.id;
    if (userId != null) {
      final repo = RecipeRepository(supabase);
      setState(() {
        _userRecipesFuture = repo.getUserRecipes(userId);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meine Rezepte'),
        centerTitle: true,
      ),
      body: FutureBuilder<List<Recipe>>(
        future: _userRecipesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Fehler: ${snapshot.error}'));
          }

          final recipes = snapshot.data ?? [];

          if (recipes.isEmpty) {
            return const Center(
              child: Text('Du hast noch keine Rezepte erstellt.'),
            );
          }

          // man zeigt die Liste der Rezepte an
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: recipes.length,
            itemBuilder: (context, index) {
              final recipe = recipes[index];

              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0), 
                child: WochenplanRecipeCard(
                  recipe: recipe,
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await context.push('/create-recipe');
          _refreshRecipes();
        },
        backgroundColor: Colors.orange,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}