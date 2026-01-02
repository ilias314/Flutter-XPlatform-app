import 'package:supabase_flutter/supabase_flutter.dart';

class EinkaufslisteRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<void> addIngredientsToList(
    List<Map<String, dynamic>> ingredients,
  ) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception("Benutzer nicht eingeloggt");

    final einkaufsliste = await _client
        .from('shopping_lists')
        .upsert({'user_id': userId, 'name': 'Meine Liste'})
        .select()
        .maybeSingle();

    if (einkaufsliste == null) {
      throw Exception(
        "Die Einkaufsliste konnte nicht erstellt oder abgerufen werden.",
      );
    }

    final listId = einkaufsliste['id'];

    for (var ing in ingredients) {
      final String ingredientName = ing['name'] ?? 'Unbekannt';

      final existingResponse = await _client
          .from('shopping_list_items')
          .select()
          .eq('shopping_list_id', listId)
          .eq('ingredient_id', ing['ingredient_id'])
          .maybeSingle();

      if (existingResponse != null) {
        final currentQty = (existingResponse['quantity'] ?? 0) as num;
        final addedQty = (ing['quantity'] ?? 0) as num;
        final newQuantity = currentQty + addedQty;

        await _client
            .from('shopping_list_items')
            .update({'quantity': newQuantity})
            .eq('id', existingResponse['id']);
      } else {
        await _client.from('shopping_list_items').insert({
          'shopping_list_id': listId,
          'ingredient_id': ing['ingredient_id'],
          'quantity': ing['quantity'] ?? 0,
          'unit': ing['unit'] ?? '',
          'custom_name': ingredientName,
          'is_checked': false,
        });
      }
    }
  }
}
