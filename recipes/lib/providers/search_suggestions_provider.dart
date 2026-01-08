import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final searchSuggestionsProvider = FutureProvider.family<List<String>, String>((
  ref,
  query,
) async {
  final supabase = Supabase.instance.client;

  if (query.isEmpty) return [];

  final data = await supabase
      .from('recipes')
      .select('name')
      .ilike('name', '%$query%');

  final q = query.toLowerCase();

  final names = data.map<String>((row) => row['name'] as String).toList();

  final startsWith = names.where((n) => n.toLowerCase().startsWith(q)).toList()
    ..sort();

  final contains =
      names
          .where(
            (n) =>
                !n.toLowerCase().startsWith(q) && n.toLowerCase().contains(q),
          )
          .toList()
        ..sort();

  return [...startsWith, ...contains].take(5).toList();
});
