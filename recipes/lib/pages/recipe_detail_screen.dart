import 'package:flutter/material.dart';
import 'package:recipes/widgets/ui_utils.dart'; // Für die Snackbar

/// Dummy-Daten, die später durch echte Rezeptdaten ersetzt werden
const Map<String, dynamic> _dummyRecipeData = {
  'name': 'Marokkanische Kichererbsenpfanne',
  'time': 25, // Zubereitungszeit in Minuten
  'difficulty': 'Einfach', // Schwierigkeitsgrad
  'portions': 4, // Standard-Portionen
  'rating': 4.7,
  // Nährwerte (basierend auf Ihrer Supabase-Struktur)
  'nutrition': [
    {'label': 'Kalorien', 'value': 450, 'unit': 'kcal'},
    {'label': 'Protein', 'value': 25, 'unit': 'g'},
    {'label': 'Kohlenhydrate', 'value': 50, 'unit': 'g'},
    {'label': 'Fett', 'value': 15, 'unit': 'g'},
    {'label': 'Ballaststoffe', 'value': 12, 'unit': 'g'},
    {'label': 'Zucker', 'value': 8, 'unit': 'g'},
  ],
  // Dummy-Zutaten
  'ingredients': [
    '2 Dosen Kichererbsen',
    '1 Zwiebel',
    '2 Knoblauchzehen',
    '400g gehackte Tomaten',
    '1 TL Kreuzkümmel',
    '1/2 TL Kurkuma',
    'Frischer Koriander',
  ],
  // Dummy-Zubereitungsschritte
  'steps': [
    'Schritt 1: Zwiebel und Knoblauch fein hacken.',
    'Schritt 2: In einer Pfanne mit Olivenöl andünsten.',
    'Schritt 3: Kichererbsen, Tomaten und Gewürze hinzufügen und 15 Min köcheln lassen.',
    'Schritt 4: Mit frischem Koriander servieren.',
  ],
};

class RecipeDetailPages extends StatefulWidget {
  const RecipeDetailPages({super.key});

  @override
  State<RecipeDetailPages> createState() => _RecipeDetailPagesState();
}

class _RecipeDetailPagesState extends State<RecipeDetailPages> {
  // Aktuelle Anzahl der Portionen (kann vom Nutzer geändert werden)
  int _currentPortions = _dummyRecipeData['portions'] as int;

  // Controller und Key für das Scrollen zu den Kommentaren
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _commentsKey = GlobalKey();

  // NEU: Controller für das Textfeld des Kommentars
  final TextEditingController _commentController = TextEditingController();

  final List<String> _comments = [
      'Das ist ein tolles Rezept, danke! - Max Mustermann',
      'Ich habe Feta hinzugefügt, sehr lecker. - Anna Schmidt',
   ];

  // Funktion zum Scrollen zum Kommentarbereich
  void _scrollToComments() {
    final context = _commentsKey.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        alignment: 0.0, // Scrollt das Element ganz nach oben
      );
    }
  }

  void _addComment() {
      final newComment = _commentController.text.trim();
      if (newComment.isNotEmpty) {
         // Fügen Sie den neuen Kommentar zur Liste hinzu und rufen Sie setState auf
         setState(() {
            _comments.add('$newComment - Du'); // Fügen Sie den Benutzer hinzu (Platzhalter)
            _commentController.clear(); // Löschen Sie das Textfeld
         });
         
         // Optional: Nach dem Hinzufügen zu den Kommentaren scrollen
         _scrollToComments();
      }
   }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController, // Controller hinzufügen
        slivers: <Widget>[
          // 1. App Bar mit Zurück-, Favoriten- und Teilen-Icon (mit Rezeptnamen)
          _buildSliverAppBar(context),

          // 2. Rezept-Details im Body
          SliverList(
            delegate: SliverChildListDelegate([
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    // Name und Basis-Infos
                    _buildHeaderSection(context),

                    const SizedBox(height: 20),

                    // Nährwert-Sektion
                    _buildNutritionSection(context),

                    const SizedBox(height: 30),

                    //  Zutaten und Portionsrechner nebeneinander
                    _buildIngredientsAndPortions(context),

                    const SizedBox(height: 30),

                    // Aktions-Buttons (Einkaufsliste, Wochenplan)
                    _buildActionButtons(context),

                    const SizedBox(height: 30),

                    // Zubereitungsschritte
                    _buildStepsSection(context),

                    const SizedBox(height: 30),

                    // Kommentare (mit GlobalKey)
                    _buildCommentsSection(context, key: _commentsKey),

                    const SizedBox(height: 50),
                  ],
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  // --- Widget Builder Methoden ---

  /// Erstellt die flexible AppBar mit Zurück-, Favoriten- und Teilen-Icon.
  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 250.0,
      pinned: true,
      stretch: true,

      // Titel mit Rezeptnamen, wenn die AppBar reduziert ist
      title: Text(
        _dummyRecipeData['name'],
        style: TextStyle(fontWeight: FontWeight.bold),
      ),

      actions: [
        IconButton(
          icon: const Icon(Icons.favorite_border),
          onPressed: () => showNotImplementedSnackbar(context),
        ),
        IconButton(
          icon: const Icon(Icons.share),
          onPressed: () => showNotImplementedSnackbar(context),
        ),
      ],

      flexibleSpace: FlexibleSpaceBar(
        // Placeholder für das Rezeptbild
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              color: Colors.grey.shade200,
              child: const Center(
                child: Icon(Icons.image, size: 90, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Erstellt den Namen, Bewertung, Zeit und Schwierigkeitsgrad des Rezepts.
  Widget _buildHeaderSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            Row(
              children: [
                // Rezeptname
                Text(
                  _dummyRecipeData['name'],
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
            Positioned(
              // bottom: 10,
              right: 10,
              child: FloatingActionButton(
                heroTag: 'commentBtn',
                mini: true,
                backgroundColor: Theme.of(context).primaryColor,
                onPressed: _scrollToComments,
                child: const Icon(Icons.comment, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // Sterne-Bewertung
        Row(
          children: [
            const Icon(Icons.star, color: Colors.amber, size: 20),
            const SizedBox(width: 5),
            Text(
              _dummyRecipeData['rating'].toString(),
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(width: 35),
            const Icon(Icons.restaurant_menu, size: 18, color: Colors.grey),
            const SizedBox(width: 5),
            const Text('Gerichttyp', style: TextStyle(fontSize: 14)),
          ],
        ),

        const SizedBox(height: 10),

        // Zeit und Schwierigkeit
        Row(
          children: [
            const Icon(Icons.timer, size: 18, color: Colors.grey),
            const SizedBox(width: 5),
            Text(
              '${_dummyRecipeData['time']} Min',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(width: 20),
            const Icon(Icons.tune, size: 18, color: Colors.grey),
            const SizedBox(width: 5),
            Text(
              _dummyRecipeData['difficulty'],
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ],
    );
  }

  /// Erstellt die Sektion der Nährwerte (Kalorien, Protein, Kohlenhydrate, Fett).
  Widget _buildNutritionSection(BuildContext context) {
    final List<Map<String, dynamic>> nutrition =
        _dummyRecipeData['nutrition'] as List<Map<String, dynamic>>;

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

        // Horizontale Liste der Nährwerte
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: nutrition
                .map(
                  (n) => _buildNutritionChip(
                    context,
                    label: n['label'] as String,
                    value: n['value'].toString(),
                    unit: n['unit'] as String,
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  /// Helper-Widget für einzelne Nährwert-Chips
  Widget _buildNutritionChip(
    BuildContext context, {
    required String label,
    required String value,
    required String unit,
  }) {
    // ... (unveränderte Logik)
    return Container(
      width: 100, // Feste Größe für gleichmäßige Darstellung
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
              fontSize: 18,
              color: Colors.orange,
            ),
          ),
          Text(unit, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  /// Erstellt die Zutatenliste links und den Portionsrechner rechts.
  Widget _buildIngredientsAndPortions(BuildContext context) {
    final List<String> ingredients =
        _dummyRecipeData['ingredients'] as List<String>;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Linke Seite: Zutatenliste
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Zutaten (${_currentPortions} Portionen)',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: ingredients.length,
                itemBuilder: (context, index) {
                  // Platzhalter für Zutat und Menge
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Text(
                      '• ${ingredients[index]}', // Menge würde hier bei echtem Code davorstehen
                      style: const TextStyle(fontSize: 15),
                    ),
                  );
                },
              ),
            ],
          ),
        ),

        const SizedBox(width: 20),

        // 2. Rechte Seite: Portionsrechner
        Expanded(
          flex: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // Portionsrechner (Inkrement/Dekrement)
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).primaryColor),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  // Column anstelle von Row für bessere Platznutzung auf kleinerem Expanded-Bereich
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.add, size: 20),
                      color: Theme.of(context).primaryColor,
                      onPressed: () {
                        setState(() {
                          _currentPortions++;
                        });
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
                      icon: const Icon(Icons.remove, size: 20),
                      color: Theme.of(context).primaryColor,
                      onPressed: () {
                        if (_currentPortions > 1) {
                          setState(() {
                            _currentPortions--;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 15),

              // Optional: Zeit und Schwierigkeit hier anzeigen, wenn Platz
            ],
          ),
        ),
      ],
    );
  }

  /// Erstellt die Buttons zum Speichern der Einkaufsliste und Hinzufügen zum Wochenplan.
  Widget _buildActionButtons(BuildContext context) {
    // ... (unveränderte Logik)
    return Column(
      children: [
        // Button: Einkaufsliste speichern
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => showNotImplementedSnackbar(context),
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
            onPressed: () => showNotImplementedSnackbar(context),
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

  /// Erstellt die Sektion der Zubereitungsschritte.
  Widget _buildStepsSection(BuildContext context) {
    // ... (unveränderte Logik)
    final List<String> steps = _dummyRecipeData['steps'] as List<String>;

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

        ListView.builder(
          shrinkWrap: true, // Wichtig für ListView in CustomScrollView
          physics:
              const NeverScrollableScrollPhysics(), // Scrollen wird vom CustomScrollView übernommen
          itemCount: steps.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 15.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Schritt-Nummer
                  CircleAvatar(
                    backgroundColor: Theme.of(context).primaryColor,
                    radius: 12,
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Schritt-Text
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

  /// Erstellt die Sektion für Kommentare (Platzhalter) mit einem Key.
  /// 🚨 MODIFIE: Erstellt die Sektion für Kommentare, ermöglicht Eingabe und Anzeige.
  Widget _buildCommentsSection(BuildContext context, {required Key key}) {
    return Container(
      key: key, // Schlüssel für Scroll-Ziel
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Kommentare (${_comments.length})',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          
          // 🚨 TextField mit Controller und Logik
          TextField(
            controller: _commentController,
            decoration: InputDecoration(
              hintText: 'Kommentar schreiben...',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton( // 🚨 NEU: IconButton pour l'envoi
                icon: const Icon(Icons.send),
                color: Theme.of(context).primaryColor,
                onPressed: _addComment, // 🚨 Appelle la fonction d'ajout
              ),
            ),
            onSubmitted: (value) => _addComment(), // Permet l'envoi avec Entrée/Return
          ),
          
          const SizedBox(height: 15),

          // 🚨 Liste des commentaires
          _comments.isEmpty
              ? Text('Es gibt noch keine Kommentare.', style: TextStyle(color: Colors.grey.shade600))
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _comments.length,
                  itemBuilder: (context, index) {
                    final comment = _comments[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            comment,
                            style: const TextStyle(fontSize: 14),
                          ),
                          Divider(color: Colors.grey.shade300),
                        ],
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }
}

//  Placeholder für AppBottomNavBar (da das Original-Widget nicht verfügbar war)
class AppBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTapped;

  const AppBottomNavBar({
    required this.currentIndex,
    required this.onTapped,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: currentIndex,
      onTap: onTapped,
      selectedItemColor: Theme.of(context).primaryColor,
      unselectedItemColor: Colors.grey,

      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_month),
          label: 'Wochenplan',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.add_circle_outline),
          label: 'Neues Rezept',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.shopping_cart),
          label: 'Einkaufsliste',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
      ],
    );
  }
}
