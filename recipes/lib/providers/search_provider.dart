import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/recipe.dart';

final searchRecipesProvider =
    FutureProvider.family<List<Recipe>, ({String query, String categoriesKey})>(
      (ref, params) async {
        final supabase = Supabase.instance.client;

        final categories = params.categoriesKey.isEmpty
            ? <String>[]
            : params.categoriesKey.split(',');

        if (params.query.isEmpty && categories.isEmpty) {
          return [];
        }

        List<String>? recipeIds;

        if (categories.isNotEmpty) {
          final res = await supabase
              .from('recipe_categories')
              .select('recipe_id, category_id')
              .inFilter('category_id', categories);

          final Map<String, Set<String>> recipeCategoryMap = {};

          for (final row in res) {
            final recipeId = row['recipe_id'] as String;
            final categoryId = row['category_id'] as String;

            recipeCategoryMap.putIfAbsent(recipeId, () => <String>{});
            recipeCategoryMap[recipeId]!.add(categoryId);
          }

          recipeIds = recipeCategoryMap.entries
              .where(
                (entry) => categories.every((cat) => entry.value.contains(cat)),
              )
              .map((entry) => entry.key)
              .toList();

          if (recipeIds.isEmpty) {
            return [];
          }
        }

        var q = supabase.from('recipes').select('*');

        if (params.query.isNotEmpty) {
          q = q.ilike('name', '%${params.query}%');
        }

        if (recipeIds != null) {
          q = q.inFilter('id', recipeIds);
        }

        final res = await q;
        return res.map((json) => Recipe.fromJson(json)).toList();
      },
    );
