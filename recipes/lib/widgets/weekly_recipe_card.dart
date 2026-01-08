import 'package:flutter/material.dart';
import 'package:recipes/pages/recipe_detail_screen.dart';
import 'package:recipes/widgets/ui_utils.dart';
import '../models/recipe.dart';

class WochenplanRecipeCard extends StatelessWidget {
  final Recipe? recipe;

  const WochenplanRecipeCard({super.key, this.recipe});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2.0,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: () {
          if (recipe != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RecipeDetailScreen(recipeId: recipe!.id!),
              ),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 140,
                height: 100,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(4.0),
                  color: Colors.grey.shade100,
                  image:
                      (recipe != null &&
                          recipe!.imageUrl != null &&
                          recipe!.imageUrl!.isNotEmpty)
                      ? DecorationImage(
                          image: NetworkImage(recipe!.imageUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child:
                    (recipe == null ||
                        recipe!.imageUrl == null ||
                        recipe!.imageUrl!.isEmpty)
                    ? const Center(
                        child: Icon(
                          Icons.photo_size_select_actual_outlined,
                          size: 40,
                          color: Colors.grey,
                        ),
                      )
                    : null,
              ),

              const SizedBox(width: 10.0),

              Expanded(
                child: SizedBox(
                  height: 100,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              recipe?.name ?? 'Name des Rezepts',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                            ),
                          ),
                          Icon(
                            recipe != null
                                ? Icons.favorite
                                : Icons.favorite_border,
                            size: 20,
                            color: recipe != null ? Colors.red : null,
                          ),
                        ],
                      ),

                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 15),
                          Text(
                            recipe!.avgRating > 0
                                ? '${recipe!.avgRating.toStringAsFixed(1)} '
                                : 'Neu',
                            style: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(width: 15),
                          const Text('Einfach', style: TextStyle(fontSize: 12)),
                        ],
                      ),

                      Row(
                        children: [
                          const Icon(Icons.timer, size: 13),
                          const SizedBox(width: 4),
                          Text(
                            recipe != null
                                ? '${recipe!.preparationTime} min'
                                : '30 min',
                            style: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(width: 15),
                          const Icon(Icons.restaurant_menu, size: 13),
                          const SizedBox(width: 4),
                          Text(
                            recipe?.displayCategory ?? 'Allgemein',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
