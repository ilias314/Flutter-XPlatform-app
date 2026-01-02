class EinkaufslisteItem {
  final String id;
  final String? ingredientId; 
  final String? customName;   
  final double quantity;
  final String unit;
  final bool checked;

  EinkaufslisteItem({
    required this.id,
    this.ingredientId,
    this.customName,
    required this.quantity,
    required this.unit,
    this.checked = false,
  });

  factory EinkaufslisteItem.fromJson(Map<String, dynamic> json) {
    return EinkaufslisteItem(
      id: json['id'],
      ingredientId: json['ingredient_id'], 
      customName: json['custom_name'],     
      quantity: (json['quantity'] ?? 0).toDouble(),
      unit: json['unit'] ?? '',
      checked: json['checked'] ?? false,
    );
  }
}