class Recipe {
  final String? id;
  final String name;
  final String? imageUrl;
  final int preparationTime;
  final String difficulty; // 'Einfach', 'Mittel', 'Schwer'
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  final double sugar;
  final int portions;
  final String description;
   double avgRating; 
  final DateTime createdAt;
  
  // Changed from single category to list of categories
  final List<String> categories;

  Recipe({
    this.id,
    required this.name,
    this.imageUrl,
    required this.preparationTime,
    required this.difficulty,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
    required this.sugar,
    required this.portions,
    required this.description,
    this.avgRating = 0.0,
    required this.createdAt,
    this.categories = const [],
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    // Parse categories from the JOIN result
    List<String> categoryList = [];
    if (json['recipe_categories'] != null) {
      final catData = json['recipe_categories'];
      if (catData is List) {
        categoryList = catData
            .map((item) {
              // Handle nested structure from Supabase JOIN
              if (item['categories'] != null && item['categories']['name'] != null) {
                return item['categories']['name'] as String;
              }
              return null;
            })
            .where((name) => name != null)
            .cast<String>()
            .toList();
      }
    }

    return Recipe(
      id: json['id'],
      name: json['name'] ?? 'Unbenannt', 
      imageUrl: json['image_url'],
      preparationTime: json['preparation_time'] ?? 0,
      difficulty: json['difficulty'] ?? 'Mittel',
      calories: (json['calories_per_portion'] ?? 0).toDouble(),
      protein: (json['protein_per_portion'] ?? 0).toDouble(),
      carbs: (json['carbs_per_portion'] ?? 0).toDouble(),
      fat: (json['fat_per_portion'] ?? 0).toDouble(),
      fiber: (json['fiber_per_portion'] ?? 0).toDouble(),
      sugar: (json['sugar_per_portion'] ?? 0).toDouble(),
      portions: json['portions'] ?? 1,
      description: json['description'] ?? '',
      avgRating: (json['avg_rating'] ?? 0).toDouble(),
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      categories: categoryList,
    );
  }
}