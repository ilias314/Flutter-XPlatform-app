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
              
              // ✅ FIX: Use 'MaxCrossAxisExtent' instead of 'FixedCrossAxisCount'
              // This automatically adds more columns on Desktop!
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 250, // Maximum width of a card (Mobile size)
                childAspectRatio: 0.75,
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