import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recipes/models/ingredient.dart';
import 'package:recipes/models/recipe.dart';
import 'package:recipes/providers/home_provider.dart';
import 'package:recipes/widgets/ui_utils.dart';
import '../data/recipe_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:recipes/services/image_upload_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:recipes/models/category.dart';
import 'package:recipes/main_scaffold.dart';

enum Difficulty { einfach, mittel, schwer }

class CreateRezeptPages extends ConsumerStatefulWidget {
  final Recipe? recipeToEdit;

  const CreateRezeptPages({super.key, this.recipeToEdit});

  @override
  ConsumerState<CreateRezeptPages> createState() => _CreateRezeptPagesState();
}

class _CreateRezeptPagesState extends ConsumerState<CreateRezeptPages> {
  final _formKey = GlobalKey<FormState>();
  dynamic _selectedImage;
  bool _isLoading = false;

  final List<String> _unitOptions = [
    'g',
    'kg',
    'ml',
    'l',
    'TL',
    'EL',
    'Stück',
    'Prise',
    'Dose',
    'Packung',
    'Bund',
    'Scheibe(n)',
  ];

  Difficulty? _selectedDifficulty = Difficulty.einfach;
  final List<IngredientInput> _ingredients = [IngredientInput()];

  List<RecipeCategory> _availableCategories = [];
  Set<String> _selectedCategoryIds = {};
  bool _isCategoriesLoading = true;

  final TextEditingController _recipeNameController = TextEditingController();
  final TextEditingController _preparationTimeController =
      TextEditingController();
  final TextEditingController _portionsController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  final TextEditingController _caloriesController = TextEditingController();
  final TextEditingController _proteinController = TextEditingController();
  final TextEditingController _carbsController = TextEditingController();
  final TextEditingController _fatController = TextEditingController();
  final TextEditingController _fiberController = TextEditingController();
  final TextEditingController _sugarController = TextEditingController();

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        if (kIsWeb) {
          _selectedImage = pickedFile;
        } else {
          _selectedImage = File(pickedFile.path);
        }
      });
    }
  }

  void _addIngredientField() {
    setState(() {
      _ingredients.add(IngredientInput());
    });
  }

  void _removeIngredientField(int index) {
    setState(() {
      _ingredients.removeAt(index);
    });
  }

  Future<bool?> _showConfirmDeleteDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Zutat entfernen?'),
          content: const Text('Möchten Sie diese Zutat wirklich entfernen?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Nein'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('Ja'),
            ),
          ],
        );
      },
    );
  }

  void _handleRemoveIngredient(int index) async {
    if (_ingredients[index].name.isEmpty && _ingredients[index].quantity == 0) {
      _removeIngredientField(index);
      return;
    }

    final confirmed = await _showConfirmDeleteDialog(context);
    if (confirmed == true) {
      _removeIngredientField(index);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadCategories();

    final r = widget.recipeToEdit;
    if (r != null) {
      _recipeNameController.text = r.name;
      _descriptionController.text = r.description;
      _preparationTimeController.text = r.preparationTime.toString();
      _portionsController.text = r.portions.toString();

      _caloriesController.text = r.calories.toString();
      _proteinController.text = r.protein.toString();
      _carbsController.text = r.carbs.toString();
      _fatController.text = r.fat.toString();
      _fiberController.text = r.fiber.toString();
      _sugarController.text = r.sugar.toString();

      _selectedDifficulty = Difficulty.values.firstWhere(
        (d) => d.name == r.difficulty,
        orElse: () => Difficulty.einfach,
      );
    }
  }

  Future<void> _loadCategories() async {
    try {
      final supabase = Supabase.instance.client;
      final repo = RecipeRepository(supabase);
      final categories = await repo.getCategories();

      setState(() {
        _availableCategories = categories;
        _isCategoriesLoading = false;
      });
    } catch (e) {
      print('Error loading categories: $e');
      setState(() => _isCategoriesLoading = false);
    }
  }

  Future<void> _saveRecipe() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bitte füllen Sie alle Pflichtfelder korrekt aus.'),
        ),
      );
      return;
    }

    final hasNewImage = _selectedImage != null;
    final hasExistingImage = widget.recipeToEdit?.imageUrl != null;

    if (!hasNewImage && !hasExistingImage) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bitte laden Sie ein Bild für das Rezept hoch.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser!.id;
      final repo = RecipeRepository(supabase);

      String? imageUrl = widget.recipeToEdit?.imageUrl;

      if (_selectedImage != null) {
        final imageService = ImageUploadService(supabase);
        imageUrl = await imageService.uploadRecipeImage(
          _selectedImage!,
          userId,
        );
      }

      final ingredientsData = _ingredients
          .where((ing) => ing.name.trim().isNotEmpty)
          .map(
            (ing) => {
              'name': ing.name,
              'quantity': ing.quantity,
              'unit': ing.unit,
            },
          )
          .toList();

      if (ingredientsData.isEmpty) {
        throw Exception("Mindestens eine Zutat wird benötigt.");
      }

      double parseNutrient(TextEditingController c) =>
          double.tryParse(c.text.replaceAll(',', '.')) ?? 0;

      if (widget.recipeToEdit == null) {
        final newRecipeId = await repo.createRecipe(
          userId: userId,
          name: _recipeNameController.text.trim(),
          description: _descriptionController.text.trim(),
          prepTime: int.parse(_preparationTimeController.text),
          portions: int.parse(_portionsController.text),
          difficulty: _selectedDifficulty!.name,
          imageUrl: imageUrl,
          ingredients: ingredientsData,
          categoryIds: _selectedCategoryIds.toList(),
          calories: parseNutrient(_caloriesController),
          protein: parseNutrient(_proteinController),
          carbs: parseNutrient(_carbsController),
          fat: parseNutrient(_fatController),
          fiber: parseNutrient(_fiberController),
          sugar: parseNutrient(_sugarController),
        );

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Rezept erstellt!')));

          ref.read(bottomNavIndexProvider.notifier).state = 0;
        }
      } else {
        await repo.updateRecipe(
          recipeId: widget.recipeToEdit!.id!,
          userId: userId,
          name: _recipeNameController.text.trim(),
          description: _descriptionController.text.trim(),
          prepTime: int.parse(_preparationTimeController.text),
          portions: int.parse(_portionsController.text),
          difficulty: _selectedDifficulty!.name,
          imageUrl: imageUrl,
          ingredients: ingredientsData,
          categoryIds: _selectedCategoryIds.toList(),
          calories: parseNutrient(_caloriesController),
          protein: parseNutrient(_proteinController),
          carbs: parseNutrient(_carbsController),
          fat: parseNutrient(_fatController),
          fiber: parseNutrient(_fiberController),
          sugar: parseNutrient(_sugarController),
        );

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Rezept aktualisiert!')));
          Navigator.pop(context);
        }
      }

      ref.invalidate(allRecipesProvider);

      if (mounted && widget.recipeToEdit == null) {
        ref.read(bottomNavIndexProvider.notifier).state = 0;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.recipeToEdit == null ? 'Neues Rezept' : 'Rezept bearbeiten',
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              ref.read(bottomNavIndexProvider.notifier).state = 0;
            }
          },
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _buildImageUploadSection(context),
              const SizedBox(height: 20),

              TextFormField(
                controller: _recipeNameController,
                decoration: const InputDecoration(
                  labelText: 'Rezept Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Bitte geben Sie einen Namen ein.'
                    : null,
              ),
              const SizedBox(height: 20),

              const Text(
                'Tags / Gerichte Typ:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              _buildTagsSection(context),
              const SizedBox(height: 20),

              const Text(
                'Schwierigkeit:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              _buildDifficultySection(),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _preparationTimeController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Zeit (Min)',
                        border: OutlineInputBorder(),
                        suffixText: 'Min',
                      ),
                      validator: (value) =>
                          (value == null || int.tryParse(value) == null)
                          ? 'Ungültig'
                          : null,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: TextFormField(
                      controller: _portionsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Portionen',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          (value == null || int.tryParse(value) == null)
                          ? 'Ungültig'
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              ExpansionTile(
                title: const Text(
                  'Nährwerte pro Portion (Optional)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Column(
                      children: [
                        _buildNutritionInputField(
                          _caloriesController,
                          'Kalorien (kcal)',
                        ),
                        const SizedBox(height: 10),
                        _buildNutritionInputField(
                          _proteinController,
                          'Protein (g)',
                        ),
                        const SizedBox(height: 10),
                        _buildNutritionInputField(
                          _carbsController,
                          'Kohlenhydrate (g)',
                        ),
                        const SizedBox(height: 10),
                        _buildNutritionInputField(_fatController, 'Fett (g)'),
                        const SizedBox(height: 10),
                        _buildNutritionInputField(
                          _sugarController,
                          'Zucker (g)',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              const Text(
                'Zutaten:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              ..._ingredients.asMap().entries.map((entry) {
                int index = entry.key;
                IngredientInput item = entry.value;

                return Padding(
                  key: ObjectKey(item),
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          initialValue: item.name,
                          decoration: const InputDecoration(
                            labelText: 'Zutat',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 15,
                            ),
                          ),
                          onChanged: (val) => item.name = val,
                          validator: (val) =>
                              (val == null || val.trim().isEmpty)
                              ? 'Fehlt'
                              : null,
                        ),
                      ),
                      const SizedBox(width: 8),

                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          initialValue: item.quantity > 0
                              ? item.quantity.toString()
                              : '',
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Menge',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 15,
                            ),
                          ),
                          onChanged: (val) {
                            String v = val.replaceAll(',', '.');
                            item.quantity = double.tryParse(v) ?? 0.0;
                          },
                          validator: (val) {
                            if (val == null || val.isEmpty) return 'Fehlt';
                            if (double.tryParse(val.replaceAll(',', '.')) ==
                                null)
                              return '?';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 8),

                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<String>(
                          value: _unitOptions.contains(item.unit)
                              ? item.unit
                              : null,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Einheit',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 15,
                            ),
                          ),
                          items: _unitOptions.map((String unit) {
                            return DropdownMenuItem<String>(
                              value: unit,
                              child: Text(
                                unit,
                                style: const TextStyle(fontSize: 14),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => item.unit = val);
                            }
                          },
                          validator: (val) =>
                              (val == null || val.isEmpty) ? '!' : null,
                        ),
                      ),

                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.grey),
                        onPressed: () => _handleRemoveIngredient(index),
                      ),
                    ],
                  ),
                );
              }).toList(),

              OutlinedButton.icon(
                onPressed: _addIngredientField,
                icon: const Icon(Icons.add),
                label: const Text('Weitere Zutat hinzufügen'),
              ),
              const SizedBox(height: 20),

              const Text(
                'Zubereitung:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              TextFormField(
                controller: _descriptionController,
                maxLines: 8,
                decoration: const InputDecoration(
                  hintText:
                      'Schritt 1: Ofen vorheizen...\nSchritt 2: Gemüse schneiden...',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    (value == null || value.trim().length < 10)
                    ? 'Bitte beschreiben Sie die Zubereitung (min. 10 Zeichen).'
                    : null,
              ),
              const SizedBox(height: 30),

              Center(
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _saveRecipe,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Rezept speichern',
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageUploadSection(BuildContext context) {
    return InkWell(
      onTap: _pickImage,
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: _selectedImage == null
            ? (_isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_a_photo,
                          size: 50,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Tippen, um Bild hochzuladen',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ))
            : ClipRRect(
                borderRadius: BorderRadius.circular(12.0),
                child: kIsWeb
                    ? Image.network(_selectedImage.path, fit: BoxFit.cover)
                    : Image.file(_selectedImage as File, fit: BoxFit.cover),
              ),
      ),
    );
  }

  Widget _buildDifficultySection() {
    return Row(
      children: Difficulty.values.map((difficulty) {
        return Expanded(
          child: RadioListTile<Difficulty>(
            title: Text(
              difficulty.name.substring(0, 1).toUpperCase() +
                  difficulty.name.substring(1),
              style: const TextStyle(fontSize: 14),
            ),
            value: difficulty,
            groupValue: _selectedDifficulty,
            contentPadding: EdgeInsets.zero,
            onChanged: (Difficulty? value) {
              setState(() {
                _selectedDifficulty = value;
              });
            },
            dense: true,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTagsSection(BuildContext context) {
    if (_isCategoriesLoading) return const LinearProgressIndicator();
    if (_availableCategories.isEmpty)
      return const Text('Keine Kategorien verfügbar.');

    return Wrap(
      spacing: 8.0,
      runSpacing: 4.0,
      children: _availableCategories.map((category) {
        final isSelected = _selectedCategoryIds.contains(category.id);
        return FilterChip(
          label: Text(category.name),
          selected: isSelected,
          onSelected: (bool selected) {
            setState(() {
              if (selected) {
                _selectedCategoryIds.add(category.id);
              } else {
                _selectedCategoryIds.remove(category.id);
              }
            });
          },
          selectedColor: Theme.of(context).colorScheme.primaryContainer,
          checkmarkColor: Theme.of(context).colorScheme.onPrimaryContainer,
        );
      }).toList(),
    );
  }

  Widget _buildNutritionInputField(
    TextEditingController controller,
    String labelText,
  ) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: labelText,
        border: const OutlineInputBorder(),
        hintText: '0.0',
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 15,
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return null;
        if (double.tryParse(value.replaceAll(',', '.')) == null)
          return 'Ungültig';
        return null;
      },
    );
  }

  @override
  void dispose() {
    _recipeNameController.dispose();
    _preparationTimeController.dispose();
    _portionsController.dispose();
    _descriptionController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    _fiberController.dispose();
    _sugarController.dispose();
    super.dispose();
  }
}
