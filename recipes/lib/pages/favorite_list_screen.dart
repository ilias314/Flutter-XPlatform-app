import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recipes/widgets/recipe_card.dart'; 
import '../providers/favorites_provider.dart';

class FavoriteListScreen extends ConsumerWidget {
  const FavoriteListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoriteRecipes = ref.watch(favoritesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meine Favoriten'),
        centerTitle: true,
      ),
      body: favoriteRecipes.isEmpty
          ? const Center(
              child: Text('Noch keine Favoriten gespeichert.'),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: favoriteRecipes.length,
              // Grid Layout: 2 Columns, similar to Home Screen
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75, // Adjusts the height/width ratio
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemBuilder: (context, index) {
                final recipe = favoriteRecipes[index];
                return RecipeCard(recipe: recipe);
              },
            ),
    );
  }
}