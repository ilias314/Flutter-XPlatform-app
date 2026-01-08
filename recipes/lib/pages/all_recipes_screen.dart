import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recipes/providers/home_provider.dart';
import 'package:recipes/models/recipe.dart';
import 'package:recipes/widgets/recipe_card.dart';
import '../models/allRecipes.dart';

class AllRecipesScreen extends ConsumerWidget {
  final AllRecipesArgs args;

  const AllRecipesScreen({super.key, required this.args});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipesAsync = ref.watch(allRecipesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(_titleFromMode(args))),
      body: recipesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Fehler: $e')),
        data: (allRecipes) {
          final filtered = _applyFilter(allRecipes, args);

          return LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;

              if (width < 600) {
                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: SizedBox(
                        height: 260,
                        child: RecipeCard(recipe: filtered[index]),
                      ),
                    );
                  },
                );
              }
              int crossAxisCount;
              if (width < 900) {
                crossAxisCount = 2;
              } else if (width < 1200) {
                crossAxisCount = 3;
              } else {
                crossAxisCount = 4;
              }

              return GridView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filtered.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 3 / 4,
                ),
                itemBuilder: (context, index) {
                  return RecipeCard(recipe: filtered[index]);
                },
              );
            },
          );
        },
      ),
    );
  }
}

List<Recipe> _applyFilter(List<Recipe> recipes, AllRecipesArgs args) {
  final now = DateTime.now();

  switch (args.mode) {
    case AllRecipesMode.newest:
      return List.of(recipes)
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    case AllRecipesMode.topWeek:
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      return recipes.where((r) => r.createdAt.isAfter(startOfWeek)).toList()
        ..sort((a, b) => b.avgRating.compareTo(a.avgRating));

    case AllRecipesMode.topMonth:
      final startOfMonth = DateTime(now.year, now.month, 1);
      return recipes.where((r) => r.createdAt.isAfter(startOfMonth)).toList()
        ..sort((a, b) => b.avgRating.compareTo(a.avgRating));

    case AllRecipesMode.diet:
      if (args.dietPreference == 'Alles') {
        return List.of(recipes)
          ..sort((a, b) => b.avgRating.compareTo(a.avgRating));
      }
      return recipes
          .where(
            (r) => r.categories.any(
              (c) => c.toLowerCase() == args.dietPreference.toLowerCase(),
            ),
          )
          .toList()
        ..sort((a, b) => b.avgRating.compareTo(a.avgRating));
  }
}

String _titleFromMode(AllRecipesArgs args) {
  switch (args.mode) {
    case AllRecipesMode.newest:
      return 'Alle neuen Rezepte';
    case AllRecipesMode.topWeek:
      return 'Top der Woche';
    case AllRecipesMode.topMonth:
      return 'Top des Monats';
    case AllRecipesMode.diet:
      return 'Für dich (${args.dietPreference})';
  }
}
