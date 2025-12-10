import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final searchSuggestionsProvider =
    FutureProvider.family<List<String>, String>((ref, query) async {
  final supabase = Supabase.instance.client;

  if (query.isEmpty) return [];

  final data = await supabase
      .from('recipes')
      .select('name')
      .ilike('name', '$query%')
      .limit(5);

  return data.map<String>((row) => row['name'] as String).toList();
});
