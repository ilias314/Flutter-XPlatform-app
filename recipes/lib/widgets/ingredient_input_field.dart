import 'package:flutter/material.dart';
import 'package:recipes/models/ingredient.dart';

class IngredientInputField extends StatelessWidget {
  final IngredientInput ingredient;
  final VoidCallback onDelete;
  final ValueChanged<String> onQuantityChanged;
  final ValueChanged<String> onUnitChanged;
  final ValueChanged<String> onNameChanged;

  const IngredientInputField({
    required this.ingredient,
    required this.onDelete,
    required this.onQuantityChanged,
    required this.onUnitChanged,
    required this.onNameChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: TextFormField(
              initialValue: ingredient.quantity > 0
                  ? ingredient.quantity.toString()
                  : '',
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Menge',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: onQuantityChanged,
            ),
          ),
          const SizedBox(width: 8),

          Expanded(
            flex: 2,
            child: TextFormField(
              initialValue: ingredient.unit,
              decoration: const InputDecoration(
                labelText: 'Einheit',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: onUnitChanged,
            ),
          ),
          const SizedBox(width: 8),

          Expanded(
            flex: 5,
            child: TextFormField(
              initialValue: ingredient.name,
              decoration: const InputDecoration(
                labelText: 'Zutat',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: onNameChanged,
            ),
          ),

          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
