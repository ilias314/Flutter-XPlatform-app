import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:recipes/models/recipe.dart';
import 'package:recipes/widgets/ui_utils.dart'; // To access showNotImplementedSnackbar

// ------------------------------------------------------
// 1. The Real Recipe Card (Used in Home Screen)
// ------------------------------------------------------
class RecipeCard extends StatelessWidget {
  final Recipe recipe;

  const RecipeCard({
    super.key,
    required this.recipe,
  });

  @override
  Widget build(BuildContext context) {
    // Helper to get the first category or a default text
    final String categoryText = recipe.categories.isNotEmpty 
        ? recipe.categories.first 
        : 'Allgemein';

    return GestureDetector(
      onTap: () {
        context.push('/recipes/${recipe.id}');
      },
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 4, // Slightly higher elevation for better look
        surfaceTintColor: Colors.white, // Ensures card stays white-ish
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- TOP AREA: IMAGE + FAVORITE BUTTON ---
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // 1. Image
                  recipe.imageUrl != null && recipe.imageUrl!.isNotEmpty
                      ? Image.network(
                          recipe.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, _, __) => _buildPlaceholderImage(),
                        )
                      : _buildPlaceholderImage(),

                  // 2. Gradient Overlay (Optional, makes text/icons pop if needed, keeping it subtle here)
                  
                  // 3. Favorite Button (Top Right)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Material(
                      color: Colors.white.withOpacity(0.85), // Semi-transparent white
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () {
                          // Placeholder for favorite logic
                          showNotImplementedSnackbar(context); 
                        },
                        child: const Padding(
                          padding: EdgeInsets.all(6.0),
                          child: Icon(
                            Icons.favorite_border, // Use Icons.favorite for filled state
                            size: 20,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 4. Rating Badge (Bottom Left of Image) - "Looking Good" touch
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            recipe.avgRating > 0 ? recipe.avgRating.toStringAsFixed(1) : "Neu",
                            style: const TextStyle(
                              color: Colors.white, 
                              fontSize: 12, 
                              fontWeight: FontWeight.bold
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // --- BOTTOM AREA: DETAILS ---
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Title
                  Text(
                    recipe.name, 
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),

                  // 2. Info Row: Time & Difficulty
                  Row(
                    children: [
                      // Time
                      _buildIconText(Icons.access_time, '${recipe.preparationTime} Min'),
                      const SizedBox(width: 12),
                      // Difficulty
                      _buildIconText(Icons.bar_chart, recipe.difficulty),
                    ],
                  ),
                  
                  const SizedBox(height: 6),

                  // 3. Info Row: Category (Gerichttyp)
                  Row(
                    children: [
                      _buildIconText(Icons.eco_outlined, categoryText, color: Colors.green),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper Widget for small icon+text rows
  Widget _buildIconText(IconData icon, String text, {Color color = Colors.grey}) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(fontSize: 12, color: Colors.grey[700]),
        ),
      ],
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: Icon(Icons.restaurant, size: 40, color: Colors.grey),
      ),
    );
  }
}

// ------------------------------------------------------
// 2. The Placeholder (Unchanged)
// ------------------------------------------------------
class RecipeCardPlaceholder extends StatelessWidget {
  const RecipeCardPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Icon(Icons.restaurant_menu, color: Colors.grey, size: 40),
      ),
    );
  }
}