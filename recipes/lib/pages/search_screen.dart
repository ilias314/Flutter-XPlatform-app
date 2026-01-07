import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/search_provider.dart';
import '../providers/search_suggestions_provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/categories_provider.dart';
import '../models/category.dart';
import '../providers/home_provider.dart';
import '../models/recipe.dart';


enum SortMode {
  none,
  alphabeticalAsc,
  alphabeticalDesc,
  newestFirst,
  oldestFirst,
  ratingDesc,
  ratingAsc,
  prepTimeAsc,
  prepTimeDesc
}
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}


class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  String _query = "";
  bool _showSuggestions = true;
  bool _showFilters = false;
  Set<String> _selectedCategoryIds = {};
  SortMode _sortMode = SortMode.none;
  String _submittedQuery = "";

  void _submitSearch() {
    setState(() {
      _submittedQuery = _query.trim();
      _showSuggestions = false;
    });
  }


  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final bool useAllRecipes =
    _sortMode != SortMode.none &&
    _query.isEmpty &&
    _selectedCategoryIds.isEmpty;

final recipesAsync = useAllRecipes
    ? ref.watch(allRecipesProvider)
    : ref.watch(
        searchRecipesProvider((
          query: _submittedQuery,
          categoriesKey: (_selectedCategoryIds.toList()..sort()).join(','),
        )),
      );

    void _openCategoryDialog(AsyncValue<List<RecipeCategory>> categoriesAsync) {
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


    final suggestions = ref.watch(searchSuggestionsProvider(_query));

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
                            onChanged: (text) {
                              setState(() {
                                _query = text;
                                _showSuggestions = text.isNotEmpty;
                              });
                            },
                            onSubmitted: (_) => _submitSearch(),
                            decoration: InputDecoration(
                              hintText: "Rezept suchen...",
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.arrow_forward),
                                onPressed: _submitSearch,
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
                        : () => _openCategoryDialog(categoriesAsync),
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
                    child: recipesAsync.when(
                      data: (recipes) {
                        if (recipes.isEmpty) {
                          return const Center(
                            child: Text("Keine Ergebnisse gefunden"),
                          );
                        }

                        final sortedRecipes = List.from(recipes);

                        switch (_sortMode) {
                          case SortMode.alphabeticalAsc:
                            sortedRecipes.sort((a, b) => a.name.compareTo(b.name));
                            break;

                          case SortMode.alphabeticalDesc:
                            sortedRecipes.sort((a, b) => b.name.compareTo(a.name));
                            break;

                          case SortMode.newestFirst:
                            sortedRecipes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
                            break;

                          case SortMode.oldestFirst:
                            sortedRecipes.sort((a, b) => a.createdAt.compareTo(b.createdAt));
                            break;

                          case SortMode.ratingDesc:
                            sortedRecipes.sort((a, b) => b.avgRating.compareTo(a.avgRating));
                            break;

                          case SortMode.ratingAsc:
                            sortedRecipes.sort((a, b) => a.avgRating.compareTo(b.avgRating));
                            break;

                          case SortMode.prepTimeAsc:
                            sortedRecipes.sort(
                              (a, b) => a.preparationTime.compareTo(b.preparationTime),
                            );
                            break;

                          case SortMode.prepTimeDesc:
                            sortedRecipes.sort(
                              (a, b) => b.preparationTime.compareTo(a.preparationTime),
                            );
                            break;

                          case SortMode.none:
                            break;

                        }


                        return ListView.builder(
                          itemCount: sortedRecipes.length,
                          itemBuilder: (context, index) {
                            return _RecipeCard(recipe: sortedRecipes[index]);
                          },
                        );
                      },
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (error, stack) =>
                          Center(child: Text("Fehler: $error")),
                    ),
                  ),
                ],
              ),

            if (_query.isNotEmpty && _showSuggestions)
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
                                _query = suggestion;
                              });
                              _submitSearch();
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
class _RecipeCard extends StatelessWidget {
  final Recipe recipe;

  const _RecipeCard({required this.recipe});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        if (recipe.id == null) return;  
        context.push('/recipes/${recipe.id}');
      },
      child: Card(
        elevation: 4,
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
              child: _buildRecipeImage(recipe.imageUrl),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
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
                        const Icon(Icons.bar_chart, size: 16, color: Colors.grey),
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
            )
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
      child: const Icon(
        Icons.restaurant,
        size: 40,
        color: Colors.grey,
      ),
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
        child: const Icon(
          Icons.restaurant,
          size: 40,
          color: Colors.grey,
        ),
      );
    },
  );
}
