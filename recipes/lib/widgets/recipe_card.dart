import 'package:flutter/material.dart';
import 'package:recipes/widgets/ui_utils.dart';

class RecipeCardPlaceholder extends StatelessWidget {
  const RecipeCardPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2.0,
      child: InkWell(
        onTap: () => showNotImplementedSnackbar(context), 
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Center(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                    child: const Center(
                      child: Icon(Icons.photo_size_select_actual_outlined, size: 40, color: Colors.grey),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Name des Rezepts',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Icon(Icons.favorite_border, size: 20),
                ],
              ),
              const SizedBox(height: 10.0),
              const Row(
                children: [
                  Icon(Icons.star, color: Colors.amber, size: 15),
                  Text('4.5', style: TextStyle(fontSize: 12)),
                  SizedBox(width: 15),
                  Text('Einfach', style: TextStyle(fontSize: 12)),
                ],
              ),
              const SizedBox(height: 5.0),
              const Row(
                children: [
                  Icon(Icons.timer, size: 13),
                  Text('Zeit', style: TextStyle(fontSize: 12)),
                  SizedBox(width: 15),
                  Icon(Icons.restaurant, size: 13),
                  Text('Gerichttyp', style: TextStyle(fontSize: 12)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}