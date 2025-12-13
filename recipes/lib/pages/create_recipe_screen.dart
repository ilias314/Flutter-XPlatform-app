import 'package:flutter/material.dart';
import 'package:recipes/models/ingredient.dart'; 
import 'package:recipes/widgets/ingredient_input_field.dart';
import 'package:recipes/widgets/ui_utils.dart';
import '../data/recipe_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:recipes/services/image_upload_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart'; 

// Enum für die Schwierigkeit
enum Difficulty { einfach, mittel, schwer }

class CreateRezeptPages extends StatefulWidget {
  const CreateRezeptPages({super.key});
  
  @override
  State<CreateRezeptPages> createState() => _CreateRezeptPagesState();
}

class _CreateRezeptPagesState extends State<CreateRezeptPages> {
  final _formKey = GlobalKey<FormState>();
  dynamic _selectedImage; 
  bool _isLoading = false; 
  
  // Formulardaten
  Difficulty? _selectedDifficulty = Difficulty.einfach;
  final List<IngredientInput> _ingredients = [IngredientInput()]; 
  
  // Controllers für Textfelder
  final TextEditingController _recipeNameController = TextEditingController();
  final TextEditingController _preparationTimeController = TextEditingController();
  final TextEditingController _portionsController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  // CONTROLLERS FÜR NÄHRWERTE 
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
          // On web, keep it as XFile
          _selectedImage = pickedFile;
        } else {
          // On mobile, convert to File
          _selectedImage = File(pickedFile.path);
        }
      });
    }
  }
  
  // --- Methoden für die Zutatenliste ---
  
  /// Fügt ein neues leeres Feld zur Zutatenliste hinzu.
  void _addIngredientField() {
    setState(() {
      _ingredients.add(IngredientInput());
    });
  }

  /// Entfernt eine Zutat aus der Liste. Wird nur nach Bestätigung aufgerufen.
  void _removeIngredientField(int index) {
    setState(() {
      _ingredients.removeAt(index);
    });
  }
  
  /// Zeigt den Bestätigungsdialog an, bevor eine Zutat gelöscht wird.
  Future<bool?> _showConfirmDeleteDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Datensatz löschen?'), 
          content: const Text('Sind Sie sicher, dass Sie diesen Eintrag löschen möchten?'), 
          actions: <Widget>[
            // Nein-Button
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false), 
              child: const Text('Nein'),
            ),
            // Ja-Button (wichtig, um die destruktive Aktion hervorzuheben)
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true), 
              child: const Text('Ja'),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
        );
      },
    );
  }

  /// Ruft den Bestätigungsdialog auf und löscht die Zutat bei positiver Bestätigung.
  void _handleRemoveIngredient(int index) async {
    final confirmed = await _showConfirmDeleteDialog(context);

    if (confirmed == true) {
      _removeIngredientField(index);
    }
  }


  // --- Methdode zum Speichern des Rezepts ---
  
  /// Validiert das Formular und speichert die Daten (Placeholder).
  Future<void> _saveRecipe() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final supabase = Supabase.instance.client;
        final userId = supabase.auth.currentUser!.id;

        // 1. Upload Image First
        String? uploadedUrl;
        if (_selectedImage != null) {
          print("🟡 Starting Upload...");
          
          final imageService = ImageUploadService(supabase);
          uploadedUrl = await imageService.uploadRecipeImage(_selectedImage!, userId);
          
          print("✅ Upload Result: $uploadedUrl");
        } else {
          print("🔴 No image selected!");
        }

        // 2. Save Recipe with the URL
        final repo = RecipeRepository(supabase);
        
        final List<Map<String, dynamic>> ingredientsData = _ingredients.map((ing) => {
            'name': ing.name,
            'quantity': ing.quantity,
            'unit': ing.unit,
        }).toList();

        await repo.createRecipe(
          userId: userId,
          name: _recipeNameController.text,
          description: _descriptionController.text,
          prepTime: int.parse(_preparationTimeController.text),
          portions: int.parse(_portionsController.text),
          difficulty: _selectedDifficulty!.name,
          imageUrl: uploadedUrl,
          ingredients: ingredientsData,
          calories: double.tryParse(_caloriesController.text) ?? 0.0,
          protein: double.tryParse(_proteinController.text) ?? 0.0,
          carbs: double.tryParse(_carbsController.text) ?? 0.0,
          fat: double.tryParse(_fatController.text) ?? 0.0,
          fiber: double.tryParse(_fiberController.text) ?? 0.0,
          sugar: double.tryParse(_sugarController.text) ?? 0.0,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gespeichert!'))
          );
          context.pushReplacement('/');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'))
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meines Rezept hinzufügen'), 
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // 1. Bild hochladen
              _buildImageUploadSection(context),
              const SizedBox(height: 20),

              // 2. Rezept Name
              TextFormField(
                controller: _recipeNameController,
                decoration: const InputDecoration(
                  labelText: 'Rezept Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => (value == null || value.isEmpty) ? 'Bitte geben Sie einen Namen ein.' : null,
              ),
              const SizedBox(height: 20),

              // 3. Tags/Kategorien
              const Text('Tags / Gerichte Typ:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              _buildTagsSection(context),
              const SizedBox(height: 20),

              // 4. Schwierigkeit
              const Text('Schwierigkeit:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              _buildDifficultySection(),
              const SizedBox(height: 20),
              
              // 5. Zubereitungszeit (Rezept Dauer)
              TextFormField(
                controller: _preparationTimeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Zubereitungszeit (Minuten)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => (value == null || int.tryParse(value) == null) ? 'Geben Sie eine gültige Dauer an.' : null,
              ),
              const SizedBox(height: 20),
              
              // 6. Portionen
               TextFormField(
                controller: _portionsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Portionen',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => (value == null || int.tryParse(value) == null) ? 'Geben Sie eine gültige Anzahl von Portionen an.' : null,
              ),
              const SizedBox(height: 20),
              
              const Text('Nährwerte pro Portion (Gramm/Kalorien):', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),

              // Kalorien
              _buildNutritionInputField(_caloriesController, 'Kalorien (kcal)'),
              const SizedBox(height: 15),

              // Protein
              _buildNutritionInputField(_proteinController, 'Protein (g)'),
              const SizedBox(height: 15),

              // Kohlenhydrate (Carbs)
              _buildNutritionInputField(_carbsController, 'Kohlenhydrate (g)'),
              const SizedBox(height: 15),

              // Fett (Fat)
              _buildNutritionInputField(_fatController, 'Fett (g)'),
              const SizedBox(height: 15),

              // Ballaststoffe (Fiber)
              _buildNutritionInputField(_fiberController, 'Ballaststoffe (g)'),
              const SizedBox(height: 15),
              
              // Zucker (Sugar)
              _buildNutritionInputField(_sugarController, 'Zucker (g)'),
              const SizedBox(height: 20),

              const Text('Zutaten:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              ..._ingredients.asMap().entries.map((entry) {
                int index = entry.key;
                IngredientInput item = entry.value;
                return IngredientInputField(
                  ingredient: item,
                  onDelete: () => _handleRemoveIngredient(index), 
                  onQuantityChanged: (val) => item.quantity = double.tryParse(val) ?? 0.0,
                  onUnitChanged: (val) => item.unit = val,
                  onNameChanged: (val) => item.name = val,
                );
              }).toList(),

              // Boutton für weitere Zutat
              OutlinedButton.icon(
                onPressed: _addIngredientField,
                icon: const Icon(Icons.add),
                label: const Text('Weitere Zutat hinzufügen'),
              ),
              const SizedBox(height: 20),

              // ------------------------------------------
              // 8. Beschreibung / Zubereitung (Wird jetzt 14. Sektion)
              // ------------------------------------------
              const Text('Zubereitung:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              TextFormField(
                controller: _descriptionController,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText: 'Schreiben Sie hier die Zubereitungsanweisungen...',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => (value == null || value.isEmpty) ? 'Bitte geben Sie die Zubereitung an.' : null,
              ),
              const SizedBox(height: 30),

              // Boutton zum Speichern
              Center(
                child: _isLoading 
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                  onPressed: _saveRecipe,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                  ),
                  child: const Text(
                    'Rezept speichern', 
                    style: TextStyle(fontSize: 18, color: Colors.white),
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

  // --- Widgets Helpers ---
  
  /// Abschnitt zum Hochladen eines Rezeptbildes
 Widget _buildImageUploadSection(BuildContext context) {
  return InkWell(
    onTap: _pickImage,
    child: Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.grey),
      ),
      child: _selectedImage == null
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_upload, size: 40, color: Colors.grey),
                  Text('Bild hochladen (Tippen)'),
                ],
              ),
            )
          : ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: kIsWeb
                  ? Image.network(
                      // On web, XFile doesn't have a path, use network image from blob
                      _selectedImage.path,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        // Fallback: try to load bytes directly
                        return FutureBuilder<Uint8List>(
                          future: _selectedImage.readAsBytes(),
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              return Image.memory(
                                snapshot.data!,
                                fit: BoxFit.cover,
                              );
                            }
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          },
                        );
                      },
                    )
                  : Image.file(
                      _selectedImage as File,
                      fit: BoxFit.cover,
                    ),
            ),
    ),
  );
}

  /// Abschnitt für die Auswahl der Schwierigkeitsstufe (Radio Buttons)
  Widget _buildDifficultySection() {
    return Row(
      children: Difficulty.values.map((difficulty) {
        return Expanded(
          child: RadioListTile<Difficulty>(
            title: Text(difficulty.name.substring(0, 1).toUpperCase() + difficulty.name.substring(1)),
            value: difficulty,
            groupValue: _selectedDifficulty,
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
  
  /// Abschnitt für die Tag-Auswahl (Chips)
  Widget _buildTagsSection(BuildContext context) {
    const List<String> tags = ['Vegan','Alles','vegetarisch', 'Snack', 'Frühstück', 'Abendessen', 'Käsefrei','Dessert','Halal'];
    return Wrap(
      spacing: 8.0,
      runSpacing: 4.0, 
      children: tags.map((tag) => ActionChip(
        label: Text(tag),
        onPressed: () => showNotImplementedSnackbar(context),
        backgroundColor: Colors.grey[200], 
      )).toList(),
    );
  }

  //  HELPER WIDGET FÜR NÄHRWERTE
  Widget _buildNutritionInputField(TextEditingController controller, String labelText) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: labelText,
        border: const OutlineInputBorder(),
        hintText: '0.0',
      ),
      // Optional: Ein Validator, der float-Werte zulässt
      validator: (value) {
        if (value == null || value.isEmpty) return null; // Leere Werte sind erlaubt
        if (double.tryParse(value) == null) {
          return 'Geben Sie eine gültige Zahl an.';
        }
        return null;
      },
    );
  }
}