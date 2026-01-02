import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recipes/widgets/weekly_recipe_card.dart';
import '../providers/favorites_provider.dart';

class FavoriteListScreen extends ConsumerWidget {
  const FavoriteListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Hol dir die Liste der Favoriten-Rezepte aus dem Provider
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
          : ListView.separated(
              padding: const EdgeInsets.all(16.0),
              itemCount: favoriteRecipes.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final recipe = favoriteRecipes[index];
                return SizedBox(
                  height: 130, 
                  child: WochenplanRecipeCard(recipe: recipe),
                );
              },
            ),
    );
  }
}