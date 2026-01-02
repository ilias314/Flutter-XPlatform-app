class RecipeComment {
  final String id;
  final String userId;
  final String content;
  final DateTime createdAt;

  RecipeComment({
    required this.id,
    required this.userId,
    required this.content,
    required this.createdAt,
  });

  factory RecipeComment.fromJson(Map<String, dynamic> json) {
    return RecipeComment(
      id: json['id'],
      content: json['comment_text'],
      userId: json['user_id'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}