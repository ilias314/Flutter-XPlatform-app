import 'package:flutter/material.dart';
import 'package:recipes/widgets/ui_utils.dart';
import 'package:recipes/widgets/recipe_card.dart'; // Ensure this matches your file name exactly

class RecipeSection extends StatelessWidget {
  final String title;
  const RecipeSection({required this.title, super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              InkWell(
                onTap: () => showNotImplementedSnackbar(context), 
                child: const Row(
                  children: [
                    Text('Mehr', style: TextStyle(color: Colors.blue)),
                    Icon(Icons.arrow_forward_ios, size: 16, color: Colors.blue),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 200,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: GridView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 6,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 1,
                childAspectRatio: 0.8,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemBuilder: (context, index) {
                // This now works because RecipeCardPlaceholder is defined in recipe_card.dart
                return const RecipeCardPlaceholder();
              },
            ),
          ),
        ),
      ],
    );
  }
}