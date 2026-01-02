import 'package:supabase_flutter/supabase_flutter.dart';

class WeeklyPlanRepository {
  final SupabaseClient _client;
  WeeklyPlanRepository(this._client);

  Future<void> addRecipeToPlan({
    required String recipeId,
    required DateTime scheduledDate,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception("Benutzer nicht eingeloggt");

    // 1. berechnen Sie den Wochenbeginn (Montag) für das geplante Datum
    DateTime weekStart = scheduledDate.subtract(Duration(days: scheduledDate.weekday - 1));
    weekStart = DateTime(weekStart.year, weekStart.month, weekStart.day);

    // 2. Fügen Sie den Wochenplan hinzu oder holen Sie ihn ab
    final wochenplan = await _client
        .from('weekly_plans')
        .upsert({
          'user_id': userId,
          'week_start_date': weekStart.toIso8601String(),
        })
        .select()
        .single();

    // 3. Fügen Sie das Rezept zum Wochenplan hinzu
    await _client.from('weekly_plan_recipes').insert({
      'weekly_plan_id': wochenplan['id'],
      'recipe_id': recipeId,
      'scheduled_date': scheduledDate.toIso8601String(),
      'meal_type': 'Lunch', // Standardwert, kann angepasst werden
    });
  }
}