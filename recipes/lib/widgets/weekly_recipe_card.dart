import 'package:flutter/material.dart';
import 'package:recipes/pages/recipe_detail_screen.dart';
import 'package:recipes/widgets/ui_utils.dart';
import '../models/recipe.dart'; // <--- 1. WICHTIG: Importiere das Model

class WochenplanRecipeCard extends StatelessWidget {
  // -------------------------------------------------------
  // 2. HIER IST DIE DEFINITION, DIE DIR GEFEHLT HAT:
  // -------------------------------------------------------
  final Recipe? recipe;

  const WochenplanRecipeCard({
    super.key,
    this.recipe, // <--- Das macht den Parameter 'recipe' verfügbar
  });
  // -------------------------------------------------------

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
              // --- Linke Seite: Bild ---
              Container(
                width: 140,
                height: 100,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(4.0),
                  color: Colors.grey.shade100,
                  // Bild laden, falls vorhanden
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
                // Platzhalter-Icon, falls kein Bild
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

              // --- Rechte Seite: Text ---
              Expanded(
                child: SizedBox(
                  height: 100,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      // A. Name & Herz
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              // ACHTUNG: Hier nutzen wir 'name' passend zu deinem Model
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

                      // B. Bewertung (Dummy)
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 15),
                          Text(
                            recipe != null &&
                                    recipe!.avgRating != null &&
                                    recipe!.avgRating! > 0
                                ? '${recipe!.avgRating!.toStringAsFixed(1)} ' 
                                : 'Neu',
                            style: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(width: 15),
                          const Text('Einfach', style: TextStyle(fontSize: 12)),
                        ],
                      ),

                      // C. Zeit (Echte Daten aus Model)
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
                            recipe != null
                                ? '${recipe!.categories}'
                                : 'Allgemein',
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
