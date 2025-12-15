import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:recipes/models/recipe.dart';
import 'package:recipes/data/recipe_repository.dart';
import 'package:recipes/widgets/ui_utils.dart';

class RecipeDetailScreen extends StatefulWidget {
  // We accept the ID string now, not the full object
  final String recipeId; 

  const RecipeDetailScreen({super.key, required this.recipeId});

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  late Future<Recipe> _recipeFuture;
  Future<List<Map<String, dynamic>>>? _ingredientsFuture;
  
  // State for portions
  int _currentPortions = 1;
  
  // Controllers
  final TextEditingController _commentController = TextEditingController();
  final List<String> _comments = []; // Dummy comments

  @override
  void initState() {
    super.initState();
    // 1. Start fetching the recipe immediately
    _recipeFuture = _fetchRecipe();
  }

  Future<Recipe> _fetchRecipe() async {
    // Fetch the recipe row from Supabase
    final response = await Supabase.instance.client
        .from('recipes')
        .select()
        .eq('id', widget.recipeId)
        .single();
    
    // Create the Recipe object
    final recipe = Recipe.fromJson(response);
    
    // 2. Once we have the recipe, initialize portions and fetch ingredients
    // We do this inside the future or setState, but to keep it simple we set defaults here.
    _currentPortions = recipe.portions > 0 ? recipe.portions : 1;
    
    // Start fetching ingredients
    final repo = RecipeRepository(Supabase.instance.client);
    _ingredientsFuture = repo.getRecipeIngredients(recipe.id!);
    
    return recipe;
  }

  // Calculate ingredient amount based on portions
  double _calculateAmount(double baseAmount, int originalPortions) {
    if (originalPortions == 0) return baseAmount;
    return (baseAmount / originalPortions) * _currentPortions;
  }

  void _addComment() {
    if (_commentController.text.trim().isNotEmpty) {
      setState(() {
        _comments.add("${_commentController.text.trim()} - User");
        _commentController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                        _buildActionButtons(context),
                        const SizedBox(height: 30),
                        _buildStepsSection(context, r),
                        const SizedBox(height: 30),
                        _buildCommentsSection(context),
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

  Widget _buildSliverAppBar(BuildContext context, Recipe r) {
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
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          r.name, 
          style: const TextStyle(
            color: Colors.white, 
            fontSize: 16, 
            shadows: [Shadow(color: Colors.black, blurRadius: 10)]
          )
        ),
        background: r.imageUrl != null 
          ? Image.network(r.imageUrl!, fit: BoxFit.cover)
          : Container(
              color: Colors.grey.shade200,
              child: const Icon(Icons.restaurant, size: 80, color: Colors.grey),
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
          ],
        ),
      ],
    );
  }

  Widget _buildNutritionSection(BuildContext context, Recipe r) {
    final nutrition = [
      {'label': 'Kalorien', 'value': r.calories, 'unit': 'kcal'},
      {'label': 'Protein', 'value': r.protein, 'unit': 'g'},
      {'label': 'Kohlenhydrate', 'value': r.carbs, 'unit': 'g'},
      {'label': 'Fett', 'value': r.fat, 'unit': 'g'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Nährwerte (pro Portion)', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: nutrition.map((n) {
              return _buildNutritionChip(
                context, 
                label: n['label'] as String, 
                value: (n['value'] as double).round().toString(), 
                unit: n['unit'] as String
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildNutritionChip(BuildContext context, {required String label, required String value, required String unit}) {
    return Container(
      width: 90,
      padding: const EdgeInsets.all(8.0),
      margin: const EdgeInsets.only(right: 10.0),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.orange)),
          Text(unit, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 11), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildIngredientsAndPortions(BuildContext context, int originalPortions) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Ingredients List
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Zutaten', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              
              // We check if the future is initialized
              if (_ingredientsFuture == null) 
                 const LinearProgressIndicator()
              else
                 FutureBuilder<List<Map<String, dynamic>>>(
                  future: _ingredientsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) return const LinearProgressIndicator();
                    if (snapshot.hasError) return const Text("Zutaten konnten nicht geladen werden");
                    
                    final ingredients = snapshot.data ?? [];
                    if (ingredients.isEmpty) return const Text("Keine Zutaten hinterlegt.");

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: ingredients.length,
                      itemBuilder: (context, index) {
                        final ing = ingredients[index];
                        // Calculate dynamic amount based on _currentPortions vs originalPortions
                        final double amount = _calculateAmount(ing['quantity'] ?? 0.0, originalPortions);
                        
                        final String amountStr = amount % 1 == 0 ? amount.toInt().toString() : amount.toStringAsFixed(1);
                        
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Text('• $amountStr ${ing['unit']} ${ing['name']}'),
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
                        if (_currentPortions > 1) setState(() => _currentPortions--);
                      },
                    ),
                    Text('$_currentPortions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Theme.of(context).primaryColor)),
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

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => showNotImplementedSnackbar(context),
            icon: const Icon(Icons.shopping_cart),
            label: const Text('Zur Einkaufsliste'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepsSection(BuildContext context, Recipe r) {
    final steps = r.description.split('\n').where((s) => s.trim().isNotEmpty).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Zubereitung', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
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
                      child: Text('${index + 1}', style: const TextStyle(color: Colors.white, fontSize: 12)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(steps[index], style: const TextStyle(fontSize: 15))),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildCommentsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Kommentare (${_comments.length})', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
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
            return ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(_comments[index], style: const TextStyle(fontSize: 14)),
              leading: const Icon(Icons.chat_bubble_outline, size: 16),
            );
          },
        ),
      ],
    );
  }
}