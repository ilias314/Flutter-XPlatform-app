import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/search_provider.dart';
import '../providers/search_suggestions_provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/categories_provider.dart';


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


  @override
  Widget build(BuildContext context) {
    final results = ref.watch(
  searchRecipesProvider((
    query: _query,
    categoriesKey: (_selectedCategoryIds.toList()..sort()).join(','),
  )),
);

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
                            controller: _controller,
                            onChanged: (text) {
                              setState(() {
                                _query = text.trim();
                                _showSuggestions = true;
                              });
                            },
                            decoration: InputDecoration(
                              hintText: "Rezept suchen...",
                              prefixIcon: const Icon(Icons.search),
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
                Consumer(
                  builder: (context, ref, _) {
                    final categories = ref.watch(categoriesProvider);
                    return categories.when(
                      data: (items) {
                        return Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: items.map((cat) {
                            final selected = _selectedCategoryIds.contains(cat.id);
                            return FilterChip(
                              label: Text(cat.name),
                              selected: selected,
                              onSelected: (value) {
                                setState(() {
                                  value
                                  ? _selectedCategoryIds.add(cat.id)
                                  : _selectedCategoryIds.remove(cat.id);
                                });
                              },
                            );
                          }).toList(),
                        );
                      },
                      loading: () => const CircularProgressIndicator(),
                      error: (e, _) => Text("Fehler: $e"),
                    );
                  },
                ),
                Expanded(
                  child: results.when(
                    data: (recipes) {
                      if (_query.isEmpty && _selectedCategoryIds.isEmpty) {
                        return const Center(
                          child: Text("Such etwas..."),
                        );
                      }

                      if (recipes.isEmpty) {
                        return const Center(
                          child: Text("Keine Ergebnisse gefunden"),
                        );
                      }

                      return ListView.builder(
                        itemCount: recipes.length,
                        itemBuilder: (context, index) {
                          final recipe = recipes[index];
                          return _RecipeCard(recipe: recipe);
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
class _RecipeCard extends StatelessWidget {
  final Map<String, dynamic> recipe;

  const _RecipeCard({required this.recipe});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          // Recipe Image
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
            child: Image.network(
              recipe['image_url'] ?? "",
              width: 120,
              height: 120,
              fit: BoxFit.cover,
            ),
          ),

          const SizedBox(width: 12),

          // Text Info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe['name'] ?? "",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    "Dauer: ${recipe['preparation_time']} Min",
                    style: TextStyle(color: Colors.grey.shade700),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    "Portionen: ${recipe['portions']}",
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
