import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recipes/data/einkaufsliste_repository.dart';
import 'package:recipes/data/recipe_repository.dart';
import 'package:recipes/models/comment.dart';
import 'package:recipes/providers/favorites_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:recipes/models/recipe.dart';
import 'package:recipes/data/recipe_repository.dart';
import 'package:recipes/widgets/ui_utils.dart';
import 'package:recipes/data/weekly_plan_repository.dart';
import 'package:share_plus/share_plus.dart';

class RecipeDetailScreen extends ConsumerStatefulWidget {
  // We accept the ID string now, not the full object
  final String recipeId;

  const RecipeDetailScreen({super.key, required this.recipeId});

  @override
  ConsumerState<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends ConsumerState<RecipeDetailScreen> {
  late Future<Recipe> _recipeFuture;
  Future<List<Map<String, dynamic>>>? _ingredientsFuture;
  final GlobalKey _commentsKey = GlobalKey();
  final ScrollController _scrollController = ScrollController();
  bool _isVisible = true;
  double _userRating = 0.0;

  // State for portions
  int _currentPortions = 1;

  // Controllers
  final TextEditingController _commentController = TextEditingController();
  List<RecipeComment> _comments = [];
  @override
  void initState() {
    super.initState();
    // 1. Start fetching the recipe immediately
    _recipeFuture = _fetchRecipe();
    _fetchComments();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    final context = _commentsKey.currentContext;
    if (context == null) return;

    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero).dy;
    final bool isCommentsSectionVisible =
        position < MediaQuery.of(context).size.height - 100;

    if (_isVisible == isCommentsSectionVisible) {
      setState(() {
        _isVisible = !isCommentsSectionVisible;
      });
    }
  }

  void _scrollToComments() {
    final context = _commentsKey.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOut,
        alignment: 0.0,
      );
    }
  }

  Future<Recipe> _fetchRecipe() async {
    final user = Supabase.instance.client.auth.currentUser;

    // holen Sie die Rezeptdetails zusammen mit den Bewertungen
    final response = await Supabase.instance.client
        .from('recipes')
        .select('''
        *,
        ratings(stars)
      ''')
        .eq('id', widget.recipeId)
        .single();

    // Berechnen Sie die durchschnittliche Bewertung
    final List ratings = response['ratings'] as List;
    double average = 0.0;
    if (ratings.isNotEmpty) {
      average =
          ratings.map((r) => r['stars'] as num).reduce((a, b) => a + b) /
          ratings.length;
    }

    final recipe = Recipe.fromJson(response);

    // Setzen Sie die berechnete durchschnittliche Bewertung
    recipe.avgRating = average;

    _currentPortions = recipe.portions > 0 ? recipe.portions : 1;
    final repo = RecipeRepository(Supabase.instance.client);
    _ingredientsFuture = repo.getRecipeIngredients(recipe.id!);

    // Holen Sie die Bewertung des aktuellen Benutzers, falls vorhanden
    if (user != null) {
      final ratingResponse = await Supabase.instance.client
          .from('ratings')
          .select('stars')
          .eq('recipe_id', widget.recipeId)
          .eq('user_id', user.id)
          .maybeSingle();

      if (ratingResponse != null && mounted) {
        setState(() {
          _userRating = (ratingResponse['stars'] as num).toDouble();
        });
      }
    }

    return recipe;
  }

  // Calculate ingredient amount based on portions
  double _calculateAmount(double baseAmount, int originalPortions) {
    if (originalPortions == 0) return baseAmount;
    return (baseAmount / originalPortions) * _currentPortions;
  }

  // 2. Add a method to fetch comments from Supabase
  Future<void> _fetchComments() async {
    final response = await Supabase.instance.client
        .from('comments')
        .select()
        .eq('recipe_id', widget.recipeId)
        .order('created_at', ascending: false);

    if (mounted) {
      setState(() {
        _comments = (response as List)
            .map((data) => RecipeComment.fromJson(data))
            .toList();
      });
    }
  }

  Future<void> _addComment() async {
    final text = _commentController.text.trim();
    final user = Supabase.instance.client.auth.currentUser;

    if (text.isNotEmpty && user != null) {
      try {
        await Supabase.instance.client.from('comments').insert({
          'recipe_id': widget.recipeId,
          'user_id': user.id,
          'comment_text': text,
        });

        _commentController.clear();
        await _fetchComments(); 
        _scrollToComments();
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Fehler beim Senden: $e")));
      }
    }
  }

  Future<void> _saveUserRating(double rating) async {
    final user = Supabase.instance.client.auth.currentUser;

    if (user != null) {
      try {
        
        await Supabase.instance.client.from('ratings').upsert(
          {'recipe_id': widget.recipeId, 'user_id': user.id, 'stars': rating},
          onConflict: 'user_id, recipe_id',
        ); 

        if (mounted) {
          setState(() {
            _recipeFuture = _fetchRecipe();
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Bewertung gespeichert!"),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Fehler beim Speichern der Bewertung: $e")),
          );
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Bitte melden Sie sich an, um zu bewerten."),
        ),
      );
    }
  }

  void _shareRecipe(Recipe recipe) {
    final String text =
        '''
      Check out this delicious recipe: ${recipe.name}!

      ⏱ Preparation time: ${recipe.preparationTime} min

      📊 Difficulty: ${recipe.difficulty}

      Download our App to see the full details!

       ''';

    Share.share(text, subject: 'Look at this recipe: ${recipe.name}');
  }

  Future<void> _handleAddToWeeklyPlan() async {
    // A. Datumsauswahl anzeigen
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('de', 'DE'),
    );

    if (pickedDate != null) {
      try {
        final repo = WeeklyPlanRepository(Supabase.instance.client);
        await repo.addRecipeToPlan(
          recipeId: widget.recipeId,
          scheduledDate: pickedDate,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Rezept zum Wochenplan hinzugefügt!'),
              backgroundColor: Color.fromARGB(255, 5, 145, 22),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Fehler: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _showIngredientSelectionDialog(
    List<Map<String, dynamic>> ingredients,
    int originalPortions,
  ) async {
    // Liste für die ausgewählten Zutaten
    List<Map<String, dynamic>> selectedIngredients = List.from(ingredients);

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          // notwendig, um den Zustand innerhalb des Dialogs zu verwalten
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Zutaten auswählen"),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: ingredients.length,
                  itemBuilder: (context, index) {
                    final ing = ingredients[index];
                    final isSelected = selectedIngredients.contains(ing);

                    return CheckboxListTile(
                      title: Text("${ing['name']}"),
                      subtitle: Text("${ing['quantity']} ${ing['unit']}"),
                      value: isSelected,
                      onChanged: (bool? value) {
                        setDialogState(() {
                          if (value == true) {
                            selectedIngredients.add(ing);
                          } else {
                            selectedIngredients.remove(ing);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Abbrechen"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      // Speichern der ausgewählten Zutaten in der Einkaufsliste
                      final ingredientsToSave = selectedIngredients
                          .map(
                            (ing) => {
                              'ingredient_id': ing['ingredient_id'],
                              'name': ing['name'],
                              'unit': ing['unit'],
                              'quantity': _calculateAmount(
                                ing['quantity'],
                                originalPortions,
                              ),
                            },
                          )
                          .toList();

                      await EinkaufslisteRepository().addIngredientsToList(
                        ingredientsToSave,
                      );

                      if (mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Zur Einkaufsliste hinzugefügt!'),
                            backgroundColor: Color.fromARGB(255, 5, 145, 22),
                          ),
                        );
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text("Fehler: $e")));
                    }
                  },
                  child: const Text("Hinzufügen"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: _isVisible
          ? FloatingActionButton(
              onPressed: _scrollToComments,
              backgroundColor: Theme.of(context).primaryColor,
              child: const Icon(Icons.comment, color: Colors.white),
            )
          : null,

      body: FutureBuilder<Recipe>(
        future: _recipeFuture,
        builder: (context, snapshot) {
          // A. Loading State
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // B. Error State
          if (snapshot.hasError) {
            return Center(child: Text("Fehler: ${snapshot.error}"));
          }

          // C. Data Ready
          if (!snapshot.hasData) {
            return const Center(child: Text("Rezept nicht gefunden."));
          }

          final r = snapshot.data!;

          return CustomScrollView(
            controller: _scrollController,
            slivers: <Widget>[
              // 1. App Bar with Image
              _buildSliverAppBar(context, r),

              // 2. Details Body
              SliverList(
                delegate: SliverChildListDelegate([
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        _buildHeaderSection(context, r),
                        const SizedBox(height: 20),
                        _buildNutritionSection(context, r),
                        const SizedBox(height: 30),
                        // Pass the recipe portions to helper
                        _buildIngredientsAndPortions(context, r.portions),
                        const SizedBox(height: 30),
                        _buildActionButtons(context, r),
                        const SizedBox(height: 30),
                        _buildStepsSection(context, r),
                        const SizedBox(height: 30),
                        _buildCommentsSection(context, key: _commentsKey),
                        const SizedBox(height: 50),
                      ],
                    ),
                  ),
                ]),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildRatingStars(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: List.generate(5, (index) {
        final double starValue = index + 1.0;

        final bool isFilled = starValue <= _userRating;

        return IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          icon: Icon(
            isFilled ? Icons.star : Icons.star_border,
            color: isFilled ? Colors.amber : Colors.grey,
            size: 30,
          ),
          onPressed: () {
            setState(() {
              _userRating = starValue;
              _saveUserRating(_userRating);
            });
          },
        );
      }),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, Recipe r) {
    final isFav = ref.watch(favoritesProvider).any((fav) => fav.id == r.id);
    return SliverAppBar(
      expandedHeight: 250.0,
      pinned: true,
      stretch: true,
      // Back button needs to be visible on top of image
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: const BoxDecoration(
          color: Colors.black26,
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(
            isFav ? Icons.favorite : Icons.favorite_border,
            color: isFav ? Colors.red : Colors.white,
          ),
          onPressed: () {
            ref.read(favoritesProvider.notifier).toggleFavorite(r);
          },
        ),
        IconButton(
          icon: const Icon(Icons.share, color: Colors.white),
          onPressed: () => _shareRecipe(r),
        ),
      ],

      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          r.name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        background: r.imageUrl != null
            ? Image.network(r.imageUrl!, fit: BoxFit.cover)
            : Container(
                color: Colors.grey.shade200,
                child: const Icon(
                  Icons.restaurant,
                  size: 80,
                  color: Colors.grey,
                ),
              ),
      ),
    );
  }

  Widget _buildHeaderSection(BuildContext context, Recipe r) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.star, color: Colors.amber, size: 20),
            const SizedBox(width: 5),
            Text(r.avgRating > 0 ? r.avgRating.toStringAsFixed(1) : "Neu"),

            const SizedBox(width: 20),
            const Icon(Icons.timer, size: 18, color: Colors.grey),
            const SizedBox(width: 5),
            Text('${r.preparationTime} Min'),

            const SizedBox(width: 20),
            const Icon(Icons.bar_chart, size: 18, color: Colors.grey),
            const SizedBox(width: 5),
            Text(r.difficulty),

            const SizedBox(width: 20),
            const Icon(Icons.eco, size: 18, color: Colors.grey),
            const SizedBox(width: 5),
            Text(r.categories.isEmpty ? 'Allgemein' : r.categories.join(', ')),
          ],
        ),
        const SizedBox(height: 10),
        _buildRatingStars(context),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildNutritionSection(BuildContext context, Recipe r) {
    final nutrition = [
      {'label': 'Kalorien', 'value': r.calories, 'unit': 'kcal'},
      {'label': 'Protein', 'value': r.protein, 'unit': 'g'},
      {'label': 'Kohlenhydrate', 'value': r.carbs, 'unit': 'g'},
      {'label': 'Fett', 'value': r.fat, 'unit': 'g'},
      {'label': 'Ballaststoffe', 'value': r.fiber, 'unit': 'g'},
      {'label': 'Zucker', 'value': r.sugar, 'unit': 'g'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nährwerte (pro Portion)',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: nutrition.map((n) {
              return _buildNutritionChip(
                context,
                label: n['label'] as String,
                value: (n['value'] as double).round().toString(),
                unit: n['unit'] as String,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildNutritionChip(
    BuildContext context, {
    required String label,
    required String value,
    required String unit,
  }) {
    return Container(
      width: 95,
      padding: const EdgeInsets.all(8.0),
      margin: const EdgeInsets.only(right: 10.0),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.orange,
            ),
          ),
          Text(unit, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientsAndPortions(
    BuildContext context,
    int originalPortions,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Ingredients List
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Zutaten',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              // We check if the future is initialized
              if (_ingredientsFuture == null)
                const LinearProgressIndicator()
              else
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: _ingredientsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting)
                      return const LinearProgressIndicator();
                    if (snapshot.hasError)
                      return const Text("Zutaten konnten nicht geladen werden");

                    final ingredients = snapshot.data ?? [];
                    if (ingredients.isEmpty)
                      return const Text("Keine Zutaten hinterlegt.");

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: ingredients.length,
                      itemBuilder: (context, index) {
                        final ing = ingredients[index];
                        // Calculate dynamic amount based on _currentPortions vs originalPortions
                        final double amount = _calculateAmount(
                          ing['quantity'] ?? 0.0,
                          originalPortions,
                        );

                        final String amountStr = amount % 1 == 0
                            ? amount.toInt().toString()
                            : amount.toStringAsFixed(1);

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Text(
                            '• $amountStr ${ing['unit']} ${ing['name']}',
                          ),
                        );
                      },
                    );
                  },
                ),
            ],
          ),
        ),
        const SizedBox(width: 20),

        // Portion Calculator
        Expanded(
          flex: 1,
          child: Column(
            children: [
              const Text("Portionen", style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 5),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).primaryColor),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove, size: 20),
                      onPressed: () {
                        if (_currentPortions > 1)
                          setState(() => _currentPortions--);
                      },
                    ),
                    Text(
                      '$_currentPortions',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, size: 20),
                      onPressed: () => setState(() => _currentPortions++),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Erstellt die Buttons zum Speichern der Einkaufsliste und Hinzufügen zum Wochenplan.
  Widget _buildActionButtons(BuildContext context, Recipe r) {
    // ... (unveränderte Logik)
    return Column(
      children: [
        // Button: Einkaufsliste speichern
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () async {
              if (_ingredientsFuture != null) {
                final ingredients = await _ingredientsFuture;
                if (ingredients != null && mounted) {
                  // Speichern der ausgewählten Zutaten in der Einkaufsliste
                  _showIngredientSelectionDialog(ingredients, r.portions);
                }
              }
            },
            icon: const Icon(Icons.shopping_cart),
            label: const Text('Zur Einkaufsliste hinzufügen'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 15),
              foregroundColor: Colors.white,
              backgroundColor: Theme.of(context).primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
        const SizedBox(height: 15),

        // Button: Wochenplan hinzufügen
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _handleAddToWeeklyPlan,
            icon: const Icon(Icons.calendar_month),
            label: const Text('Zum Wochenplan hinzufügen'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 15),
              side: BorderSide(color: Theme.of(context).primaryColor),
              foregroundColor: Theme.of(context).primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepsSection(BuildContext context, Recipe r) {
    final steps = r.description
        .split('\n')
        .where((s) => s.trim().isNotEmpty)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Zubereitung',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),

        if (steps.length <= 1)
          Text(r.description, style: const TextStyle(fontSize: 16, height: 1.5))
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: steps.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 15.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      backgroundColor: Theme.of(context).primaryColor,
                      radius: 12,
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        steps[index],
                        style: const TextStyle(fontSize: 15),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildCommentsSection(BuildContext context, {required Key key}) {
    return Container(
      key: key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Kommentare (${_comments.length})',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _commentController,
            decoration: InputDecoration(
              hintText: 'Kommentar schreiben...',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: const Icon(Icons.send),
                onPressed: _addComment,
              ),
            ),
          ),
          const SizedBox(height: 15),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _comments.length,
            itemBuilder: (context, index) {
              final comment = _comments[index];
              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  comment.content,
                  style: const TextStyle(fontSize: 14),
                ),
                subtitle: Text(
                  "veröffentlicht am ${comment.createdAt.day}/${comment.createdAt.month}",
                  style: const TextStyle(fontSize: 10),
                ),
                leading: const Icon(Icons.chat_bubble_outline, size: 16),
              );
            },
          ),
        ],
      ),
    );
  }
}
