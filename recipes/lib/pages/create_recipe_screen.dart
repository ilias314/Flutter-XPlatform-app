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
import 'package:go_router/go_router.dart'; // 

// Enum für die Schwierigkeit
enum Difficulty { einfach, mittel, schwer }

class CreateRezeptPages extends StatefulWidget {
  const CreateRezeptPages({super.key});
  

  @override
  State<CreateRezeptPages> createState() => _CreateRezeptPagesState();
}

class _CreateRezeptPagesState extends State<CreateRezeptPages> {
  final _formKey = GlobalKey<FormState>();
  File? _selectedImage; // (Stores the image on the phone)
  bool _isLoading = false; //(To show loading spinner)
  
  
  
  // Formulardaten
  Difficulty? _selectedDifficulty = Difficulty.einfach;
  final List<IngredientInput> _ingredients = [IngredientInput()]; 
  
  // Controllers für Textfelder
  final TextEditingController _recipeNameController = TextEditingController();
  final TextEditingController _preparationTimeController = TextEditingController();
  final TextEditingController _portionsController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();


  Future<void> _pickImage() async {
    final picker = ImagePicker();
    // Open the gallery
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path); // Update UI to show the image
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
          title: const Text('Datensatz löschen?'), // Löschbestätigungstitel
          content: const Text('Sind Sie sicher, dass Sie diesen Eintrag löschen möchten?'), // Löschbestätigungstext
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
    setState(() => _isLoading = true); // Start spinner

    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser!.id;

      // 1. Upload Image First
      String? uploadedUrl;
      if (_selectedImage != null) {
        print("🟡 Starting Upload..."); // <--- DEBUG PRINT
        
        final imageService = ImageUploadService(supabase);
        uploadedUrl = await imageService.uploadRecipeImage(_selectedImage!, userId);
        
        print("✅ Upload Result: $uploadedUrl"); // <--- CHECK THIS IN CONSOLE
      } else {
        print("🔴 No image selected!");
      }

      // 2. Save Recipe with the URL
      final repo = RecipeRepository(supabase);
      
      // ... prepare ingredients list ...
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
        imageUrl: uploadedUrl, // <--- PASS THE URL HERE
        ingredients: ingredientsData,
        // Don't forget the defaults we fixed earlier!
        calories: 0.0,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gespeichert!')));
        context.pushReplacement('/');
      }
    } catch (e) {
      if(mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if(mounted) setState(() => _isLoading = false); // Stop spinner
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

              // 7. Zutaten
              const Text('Zutaten:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              ..._ingredients.asMap().entries.map((entry) {
                int index = entry.key;
                IngredientInput item = entry.value;
                return IngredientInputField(
                  ingredient: item,
                  // Ruft nun die Bestätigungslogik auf
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

              // 8. Beschreibung / Zubereitung
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
                child: ElevatedButton(
                  onPressed: _saveRecipe,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                  ),
                  child: const Text(
                    'Rezept speichern', // Rezept speichern
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
  
  /// Abschnitt zum Hochladen eines Rezeptbildes (Platzhalter)
 Widget _buildImageUploadSection(BuildContext context) {
    return InkWell(
      onTap: _pickImage, // <--- THIS IS THE FIX (Calls the gallery instead of the snackbar)
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(color: Colors.grey),
          // Logic: If image is selected, show it. Else, show placeholder.
          image: _selectedImage != null 
            ? DecorationImage(
                image: FileImage(_selectedImage!), 
                fit: BoxFit.cover
              )
            : null,
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
            : null, // If image exists, don't show the icon
      ),
    );
  }

  /// Abschnitt für die Auswahl der Schwierigkeitsstufe (Radio Buttons)
  Widget _buildDifficultySection() {
    return Row(
      children: Difficulty.values.map((difficulty) {
        return Expanded(
          child: RadioListTile<Difficulty>(
            // Zeigt "Einfach", "Mittel", "Schwer" an
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
    // Die Tags sollten idealerweise dynamisch aus der Datenbank geladen werden
    const List<String> tags = ['Vegan','Allesfresser','vegetarisch', 'Snack', 'Frühstück', 'Abendessen', 'Käsefrei','Dessert','Halal'];
    return Wrap(
      spacing: 8.0,
      runSpacing: 4.0, // Vertikaler Abstand zwischen den Zeilen der Chips
      children: tags.map((tag) => ActionChip(
        label: Text(tag),
        onPressed: () => showNotImplementedSnackbar(context),
        backgroundColor: Colors.grey[200], 
      )).toList(),
    );
  }
}