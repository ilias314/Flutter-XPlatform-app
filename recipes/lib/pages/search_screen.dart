import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/search_suggestions_provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/categories_provider.dart';
import '../models/category.dart';
import '../models/recipe.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/favorites_provider.dart';

enum SortMode {
  none,
  alphabeticalAsc,
  alphabeticalDesc,
  newestFirst,
  oldestFirst,
  ratingDesc,
  ratingAsc,
  prepTimeAsc,
  prepTimeDesc,
}

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _showSuggestions = true;
  bool _showFilters = false;
  Set<String> _selectedCategoryIds = {};
  SortMode _sortMode = SortMode.none;
  String _submittedQuery = "";

  Future<List<Recipe>> _fetchRecipesRealtime() async {
    final supabase = Supabase.instance.client;

    final bool hasSearch = _submittedQuery.isNotEmpty;
    final bool hasCategories = _selectedCategoryIds.isNotEmpty;
    final bool hasSort = _sortMode != SortMode.none;

    if (!hasSearch && !hasCategories && !hasSort) {
      return [];
    }

    List<String>? recipeIds;

    if (hasCategories) {
      final res = await supabase
          .from('recipe_categories')
          .select('recipe_id, category_id')
          .inFilter('category_id', _selectedCategoryIds.toList());

      final Map<String, Set<String>> map = {};

      for (final row in res) {
        final r = row['recipe_id'] as String;
        final c = row['category_id'] as String;
        map.putIfAbsent(r, () => {}).add(c);
      }

      recipeIds = map.entries
          .where((e) => _selectedCategoryIds.every((c) => e.value.contains(c)))
          .map((e) => e.key)
          .toList();

      if (recipeIds.isEmpty) return [];
    }

    var q = supabase.from('recipes').select('*');

    if (hasSearch) {
      q = q.ilike('name', '%$_submittedQuery%');
    }

    if (recipeIds != null) {
      q = q.inFilter('id', recipeIds);
    }

    final res = await q;
    return res.map((e) => Recipe.fromJson(e)).toList();
  }

  List<Recipe> _applySorting(List<Recipe> recipes) {
    final list = List<Recipe>.from(recipes);

    switch (_sortMode) {
      case SortMode.alphabeticalAsc:
        list.sort((a, b) => a.name.compareTo(b.name));
        break;
      case SortMode.alphabeticalDesc:
        list.sort((a, b) => b.name.compareTo(a.name));
        break;
      case SortMode.newestFirst:
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case SortMode.oldestFirst:
        list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case SortMode.ratingDesc:
        list.sort((a, b) => b.avgRating.compareTo(a.avgRating));
        break;
      case SortMode.ratingAsc:
        list.sort((a, b) => a.avgRating.compareTo(b.avgRating));
        break;
      case SortMode.prepTimeAsc:
        list.sort((a, b) => a.preparationTime.compareTo(b.preparationTime));
        break;
      case SortMode.prepTimeDesc:
        list.sort((a, b) => b.preparationTime.compareTo(a.preparationTime));
        break;
      case SortMode.none:
        break;
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);

    void openCategoryDialog(AsyncValue<List<RecipeCategory>> categoriesAsync) {
      final initialSelected = Set<String>.from(_selectedCategoryIds);

      showDialog(
        context: context,
        builder: (context) {
          Set<String> tempSelected = Set<String>.from(initialSelected);

          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: const Text('Kategorien auswählen'),
                content: categoriesAsync.when(
                  data: (items) {
                    return ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxHeight: 350,
                        maxWidth: 320,
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          children: items.map((cat) {
                            return CheckboxListTile(
                              dense: true,
                              title: Text(cat.name),
                              value: tempSelected.contains(cat.id),
                              onChanged: (checked) {
                                setDialogState(() {
                                  checked == true
                                      ? tempSelected.add(cat.id)
                                      : tempSelected.remove(cat.id);
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('Fehler: $e'),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Abbrechen'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _selectedCategoryIds = tempSelected;
                      });
                      Navigator.pop(context);
                    },
                    child: const Text('Übernehmen'),
                  ),
                ],
              );
            },
          );
        },
      );
    }

    void openSortDialog() {
      final initialSort = _sortMode;

      showDialog(
        context: context,
        builder: (context) {
          SortMode tempSort = initialSort;

          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: const Text('Sortierung'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RadioListTile<SortMode>(
                      title: const Text('Keine Sortierung'),
                      value: SortMode.none,
                      groupValue: tempSort,
                      onChanged: (value) {
                        setDialogState(() => tempSort = value!);
                      },
                    ),
                    RadioListTile<SortMode>(
                      title: const Text('Alphabetisch (A → Z)'),
                      value: SortMode.alphabeticalAsc,
                      groupValue: tempSort,
                      onChanged: (value) {
                        setDialogState(() => tempSort = value!);
                      },
                    ),
                    RadioListTile<SortMode>(
                      title: const Text('Alphabetisch (Z → A)'),
                      value: SortMode.alphabeticalDesc,
                      groupValue: tempSort,
                      onChanged: (value) {
                        setDialogState(() => tempSort = value!);
                      },
                    ),
                    RadioListTile<SortMode>(
                      title: const Text('neueste zuerst'),
                      value: SortMode.newestFirst,
                      groupValue: tempSort,
                      onChanged: (value) {
                        setDialogState(() => tempSort = value!);
                      },
                    ),

                    RadioListTile<SortMode>(
                      title: const Text('älteste zuerst'),
                      value: SortMode.oldestFirst,
                      groupValue: tempSort,
                      onChanged: (value) {
                        setDialogState(() => tempSort = value!);
                      },
                    ),
                    RadioListTile<SortMode>(
                      title: const Text('Höchste Bewertung'),
                      value: SortMode.ratingDesc,
                      groupValue: tempSort,
                      onChanged: (value) {
                        setDialogState(() => tempSort = value!);
                      },
                    ),

                    RadioListTile<SortMode>(
                      title: const Text('niedrigste Bewertung'),
                      value: SortMode.ratingAsc,
                      groupValue: tempSort,
                      onChanged: (value) {
                        setDialogState(() => tempSort = value!);
                      },
                    ),
                    RadioListTile<SortMode>(
                      title: const Text('Kürzeste Zubereitungszeit'),
                      value: SortMode.prepTimeAsc,
                      groupValue: tempSort,
                      onChanged: (value) {
                        setDialogState(() => tempSort = value!);
                      },
                    ),

                    RadioListTile<SortMode>(
                      title: const Text('Längste Zubereitungszeit'),
                      value: SortMode.prepTimeDesc,
                      groupValue: tempSort,
                      onChanged: (value) {
                        setDialogState(() => tempSort = value!);
                      },
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Abbrechen'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _sortMode = tempSort;
                      });
                      Navigator.pop(context);
                    },
                    child: const Text('Übernehmen'),
                  ),
                ],
              );
            },
          );
        },
      );
    }

    final suggestions = ref.watch(searchSuggestionsProvider(_controller.text));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        title: const Text("Suche"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Hero(
                        tag: 'search-bar',
                        child: Material(
                          color: Colors.transparent,
                          child: TextField(
                            autofocus: true,
                            controller: _controller,
                            textInputAction: TextInputAction.search,
                            onSubmitted: (value) {
                              FocusScope.of(context).unfocus();
                              setState(() {
                                _submittedQuery = value.trim();
                                _showSuggestions = false;
                              });
                            },
                            onChanged: (_) {
                              setState(() {
                                _showSuggestions = _controller.text.isNotEmpty;
                              });
                            },
                            decoration: InputDecoration(
                              hintText: "Rezept suchen...",
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.arrow_forward),
                                onPressed: () {
                                  FocusScope.of(context).unfocus();
                                  setState(() {
                                    _submittedQuery = _controller.text.trim();
                                    _showSuggestions = false;
                                  });
                                },
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(
                        _showFilters ? Icons.filter_alt_off : Icons.filter_alt,
                      ),
                      onPressed: () {
                        setState(() => _showFilters = !_showFilters);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_showFilters)
                  Row(
                    children: [
                      OutlinedButton.icon(
                        icon: const Icon(Icons.arrow_drop_down),
                        label: Text(
                          _selectedCategoryIds.isEmpty
                              ? 'Alle Kategorien'
                              : '${_selectedCategoryIds.length} Kategorien',
                        ),
                        onPressed: categoriesAsync.isLoading
                            ? null
                            : () => openCategoryDialog(categoriesAsync),
                      ),
                      const SizedBox(width: 8),

                      OutlinedButton.icon(
                        icon: const Icon(Icons.sort_by_alpha),
                        label: const Text('Sortieren'),
                        onPressed: () => openSortDialog(),
                      ),
                    ],
                  ),
                Expanded(
                  child: FutureBuilder(
                    future: _fetchRecipesRealtime(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData ||
                          (snapshot.data as List).isEmpty) {
                        return const Center(
                          child: Text("Keine Ergebnisse gefunden"),
                        );
                      }

                      final recipes = snapshot.data as List<Recipe>;
                      final sortedRecipes = _applySorting(recipes);

                      return ListView.builder(
                        itemCount: sortedRecipes.length,
                        itemBuilder: (context, index) {
                          return _RecipeCard(recipe: sortedRecipes[index]);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),

            if (_controller.text.isNotEmpty && _showSuggestions)
              Positioned(
                left: 0,
                right: 0,
                top: 56,
                child: Material(
                  elevation: 6,
                  borderRadius: BorderRadius.circular(12),
                  child: suggestions.when(
                    data: (items) {
                      if (items.isEmpty) return const SizedBox.shrink();

                      return ListView(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        children: items.map((suggestion) {
                          return ListTile(
                            leading: const Icon(Icons.search),
                            title: Text(suggestion),
                            onTap: () {
                              setState(() {
                                _controller.text = suggestion;
                                _submittedQuery = suggestion;
                                _showSuggestions = false;
                              });
                            },
                          );
                        }).toList(),
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RecipeCard extends ConsumerWidget {
  final Recipe recipe;

  const _RecipeCard({required this.recipe});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favIds = ref.watch(favoritesProvider);
    final isFav = recipe.id != null && favIds.contains(recipe.id);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        if (recipe.id == null) return;
        context.push('/recipes/${recipe.id}');
      },
      child: Card(
        elevation: 4,
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(12),
              ),
              child: _buildRecipeImage(recipe.imageUrl),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            recipe.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            isFav ? Icons.favorite : Icons.favorite_border,
                            color: isFav ? Colors.red : Colors.grey,
                          ),
                          onPressed: () {
                            final id = recipe.id;
                            if (id == null) return;
                            ref
                                .read(favoritesProvider.notifier)
                                .toggleFavorite(id);
                          },
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(Icons.star, size: 16, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          recipe.avgRating > 0
                              ? recipe.avgRating.toStringAsFixed(1)
                              : 'Neu',
                          style: const TextStyle(fontSize: 13),
                        ),
                        const SizedBox(width: 12),
                        const Icon(
                          Icons.bar_chart,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          recipe.difficulty,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Dauer: ${recipe.preparationTime} Min",
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Portionen: ${recipe.portions}",
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _buildRecipeImage(String? imageUrl) {
  if (imageUrl == null || imageUrl.trim().isEmpty) {
    return Container(
      width: 120,
      height: 120,
      color: Colors.grey.shade200,
      alignment: Alignment.center,
      child: const Icon(Icons.restaurant, size: 40, color: Colors.grey),
    );
  }

  return Image.network(
    imageUrl,
    width: 120,
    height: 120,
    fit: BoxFit.cover,
    errorBuilder: (context, error, stackTrace) {
      return Container(
        width: 120,
        height: 120,
        color: Colors.grey.shade200,
        alignment: Alignment.center,
        child: const Icon(Icons.restaurant, size: 40, color: Colors.grey),
      );
    },
  );
}
