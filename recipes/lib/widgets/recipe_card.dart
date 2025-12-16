import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:recipes/models/recipe.dart'; 

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
    return GestureDetector(
      onTap: () {
        context.push('/recipes/${recipe.id}');
      },
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // IMAGE AREA
            Expanded(
              child: recipe.imageUrl != null && recipe.imageUrl!.isNotEmpty
                  ? Image.network(
                      recipe.imageUrl!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (ctx, _, __) => _buildPlaceholderImage(),
                    )
                  : _buildPlaceholderImage(),
            ),
            
            // TEXT AREA
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    // --- FIX: Changed 'title' to 'name' ---
                    // If this is still red, check lib/models/recipe.dart to see the correct variable name.
                    recipe.name, 
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        '${recipe.preparationTime} Min.',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
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

  Widget _buildPlaceholderImage() {
    return Container(
      color: Colors.grey[300],
      child: const Center(
        child: Icon(Icons.fastfood, size: 40, color: Colors.grey),
      ),
    );
  }
}

// ------------------------------------------------------
// 2. The Placeholder (Used in Profile/RecipeSection)
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