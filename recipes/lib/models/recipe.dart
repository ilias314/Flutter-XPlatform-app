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
  final int portions;
  final String description;
  final double avgRating; 
  final DateTime createdAt; 
  final String category;  

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
    required this.portions,
    required this.description,
    this.avgRating = 0.0,
    required this.createdAt, 
    required this.category, 
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['id'],
      name: json['name'] ?? 'Unbenannt', 
      imageUrl: json['image_url'],
      preparationTime: json['preparation_time'] ?? 0,
      difficulty: json['difficulty'] ?? 'Mittel',
      calories: (json['calories'] ?? 0).toDouble(),
      protein: (json['protein'] ?? 0).toDouble(),
      carbs: (json['carbs'] ?? 0).toDouble(),
      fat: (json['fat'] ?? 0).toDouble(),
      portions: json['portions'] ?? 1,
      description: json['description'] ?? '',
      avgRating: (json['avg_rating'] ?? 0).toDouble(),
      // Parse Supabase Date string to DateTime
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      // Default to 'Alles' if missing
      category: json['category'] ?? 'Alles', 
    );
  }
}