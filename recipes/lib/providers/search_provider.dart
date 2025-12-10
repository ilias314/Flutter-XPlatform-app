import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final searchRecipesProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((ref, query) async {
  final supabase = Supabase.instance.client;

  if (query.trim().isEmpty) {
    return [];
  }

  final response = await supabase
      .from('recipes')
      .select()
      .ilike('name', '$query%');   
  return response;
});
