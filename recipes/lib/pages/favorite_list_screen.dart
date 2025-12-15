import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/recipe.dart'; 
import '../widgets/weekly_recipe_card.dart'; 

class FavoriteListScreen extends StatefulWidget {
  const FavoriteListScreen({super.key});

  @override
  State<FavoriteListScreen> createState() => _FavoriteListScreenState();
}

class _FavoriteListScreenState extends State<FavoriteListScreen> {
 
  final List<Recipe> _favoriteRecipes = []; 
  // -----------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meine Favoriten'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
      ),
      // Hier prüft er: Ist die Liste leer? -> Ja -> Zeige den Text.
      body: _favoriteRecipes.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 60, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Noch keine Favoriten gespeichert.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16.0),
              itemCount: _favoriteRecipes.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final recipe = _favoriteRecipes[index];
                
                return SizedBox(
                  height: 130, 
                  child: WochenplanRecipeCard(
                    recipe: recipe, 
                  ),
                );
              },
            ),
    );
  }
}