class Recipe {
  final String? id;
  final String userId;
  final String name;
  final String? imageUrl;
  final int preparationTime;
  final String difficulty;
  final int portions;
  final String description;
  
  // Nutrition Data
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double sugar;
  final double fiber;

  final double avgRating;
  final DateTime? createdAt;

  Recipe({
    this.id,
    required this.userId,
    required this.name,
    this.imageUrl,
    required this.preparationTime,
    required this.difficulty,
    required this.portions,
    required this.description,
    this.calories = 0.0,
    this.protein = 0.0,
    this.carbs = 0.0,
    this.fat = 0.0,
    this.sugar = 0.0,
    this.fiber = 0.0,
    this.avgRating = 0.0,
    this.createdAt,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['id'],
      userId: json['user_id'],
      name: json['name'],
      imageUrl: json['image_url'],
      preparationTime: json['preparation_time'] ?? 0,
      difficulty: json['difficulty'] ?? 'mittel',
      portions: json['portions'] ?? 1,
      description: json['description'] ?? '',
      
      // Map Database Columns to Dart Variables
      calories: (json['calories_per_portion'] ?? 0).toDouble(),
      protein: (json['protein_per_portion'] ?? 0).toDouble(),
      carbs: (json['carbs_per_portion'] ?? 0).toDouble(),
      fat: (json['fat_per_portion'] ?? 0).toDouble(),
      sugar: (json['sugar_per_portion'] ?? 0).toDouble(),
      fiber: (json['fiber_per_portion'] ?? 0).toDouble(),
      
      avgRating: (json['avg_rating'] ?? 0).toDouble(),
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'name': name,
      'image_url': imageUrl,
      'preparation_time': preparationTime,
      'difficulty': difficulty,
      'portions': portions,
      'description': description,
      'calories_per_portion': calories,
      'protein_per_portion': protein,
      'carbs_per_portion': carbs,
      'fat_per_portion': fat,
      'sugar_per_portion': sugar,
      'fiber_per_portion': fiber,
    };
  }
}