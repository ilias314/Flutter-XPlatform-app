class Recipe {
  final String? id; // Nullable because a new recipe doesn't have an ID yet
  final String userId;
  final String name;
  final String? imageUrl;
  final int preparationTime; // in minutes
  final String difficulty;   // 'einfach', 'mittel', 'schwer'
  final int portions;
  final String description;
  final double calories;     // Matches 'calories_per_portion' in DB
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
    this.createdAt,
  });

  // --- 1. From Database (JSON) to Flutter (Object) ---
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
      calories: (json['calories_per_portion'] ?? 0).toDouble(),
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
    );
  }

  // --- 2. From Flutter (Object) to Database (JSON) ---
  // We use this when sending data to Supabase
  Map<String, dynamic> toJson() {
    return {
      // Note: We usually DON'T send 'id' or 'created_at' for new items 
      // (Supabase generates them automatically)
      'user_id': userId,
      'name': name,
      'image_url': imageUrl,
      'preparation_time': preparationTime,
      'difficulty': difficulty,
      'portions': portions,
      'description': description,
      'calories_per_portion': calories,
    };
  }
}