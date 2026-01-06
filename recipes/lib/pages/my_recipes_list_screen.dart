import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:recipes/models/recipe.dart';
import 'package:recipes/providers/home_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/recipe_repository.dart';
import 'package:recipes/widgets/recipe_card.dart'; 

class MyRecipesListScreen extends ConsumerStatefulWidget  {
  const MyRecipesListScreen({super.key});

  @override
  ConsumerState<MyRecipesListScreen> createState() => _MyRecipesListScreenState();
}

class _MyRecipesListScreenState extends ConsumerState<MyRecipesListScreen> {
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
      appBar: AppBar(title: const Text('Meine Rezepte'), centerTitle: true),
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

          // Grid View for "Home-like" cards
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: recipes.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75, // Keeps cards vertical and standard size
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemBuilder: (context, index) {
              final recipe = recipes[index];

              return GestureDetector(
                // Keep edit/delete functionality on long press
                onLongPress: () => _showActions(recipe),
                // The Card itself handles the tap to navigate
                child: RecipeCard(recipe: recipe),
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

  void _showActions(Recipe recipe) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Aktion auswählen', textAlign: TextAlign.center),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Rezept bearbeiten'),
                onTap: () {
                  Navigator.of(context).pop();
                  context.push('/edit-recipe', extra: recipe); 
                },
              ),

              const Divider(),

              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text(
                  'Rezept löschen',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  _confirmDelete(recipe);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(Recipe recipe) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Rezept löschen?'),
        content: const Text(
          'Diese Aktion kann nicht rückgängig gemacht werden.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteRecipe(recipe.id!);
    }
  }

  Future<void> _deleteRecipe(String recipeId) async {
    final userId = supabase.auth.currentUser!.id;
    final repo = RecipeRepository(supabase);

    await repo.deleteRecipe(recipeId, userId);
    _refreshRecipes();
    ref.invalidate(allRecipesProvider);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rezept gelöscht')),
      );
    }
  }
}