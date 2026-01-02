import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:recipes/models/recipe.dart';
import 'package:recipes/widgets/ui_utils.dart';
import 'package:recipes/widgets/weekly_recipe_card.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// --- Hilfsdaten / Setup ---
final List<String> _weekdays = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];

class WochenplanPages extends StatefulWidget {
  const WochenplanPages({super.key});

  @override
  State<WochenplanPages> createState() => _WochenplanPagesState();
}

class _WochenplanPagesState extends State<WochenplanPages> {
  // Das Datum, ab dem die Woche angezeigt wird (Montag der aktuellen Woche)
  late DateTime _startDate;
  // Der Index des aktuell ausgewählten Tages (0=Montag, 6=Sonntag)
  int _selectedDayIndex = 0;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Setze das Startdatum auf den Montag der aktuellen Woche
    _startDate = _findStartOfWeek(DateTime.now());
  }

  /// Findet den Montag (oder den ersten Tag) der Woche, zu der das gegebene Datum gehört.
  DateTime _findStartOfWeek(DateTime date) {
    // 1 = Montag, ..., 7 = Sonntag
    int daysToSubtract = date.weekday - 1;
    return date.subtract(Duration(days: daysToSubtract));
  }

  /// Setzt das Startdatum der Wochenansicht auf den Montag der vom Nutzer gewählten Woche.
  void _jumpToSelectedWeek(DateTime selectedDate) {
    setState(() {
      _startDate = _findStartOfWeek(selectedDate);
      // Optional: Setze den ausgewählten Tag auf den Tag, den der Nutzer geklickt hat.
      _selectedDayIndex = selectedDate.weekday - 1;
    });
    // Setze den ScrollView zurück auf den Anfang der Woche (optional, aber hilfreich)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.jumpTo(0);
    });
  }

  //  NEUE FUNKTION: Zeigt den DatePicker als Popup an
  Future<void> _showCalendarPopup(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate.add(
        Duration(days: _selectedDayIndex),
      ), // Aktuell angezeigter Tag
      firstDate: DateTime(2000), // Frühestes Datum im Kalender
      lastDate: DateTime(2101), // Spätestes Datum im Kalender
      locale: const Locale('de', 'DE'), // Setze die deutsche Lokalisierung
      helpText: 'Woche auswählen', // Titel des Dialogs
    );

    // Wenn der Nutzer ein Datum auswählt, springe zu dieser Woche
    if (picked != null) {
      _jumpToSelectedWeek(picked);
    }
  }

  // --- Widget Builder Methoden ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mein Wochenplan'),
        automaticallyImplyLeading: false,

        //  NEUE AKTION: Kalender-Icon
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () => _showCalendarPopup(context),
            tooltip: 'Zu Datum springen',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: <Widget>[
          // 1. Kopfzeile mit Wochentagen und Daten (Jetzt scrollbar)
          _buildScrollableWeekdayHeader(context),

          // 2. Trennlinie
          const Divider(height: 1, thickness: 1),

          // 3. Rezeptliste für den ausgewählten Tag
          Expanded(child: _buildRecipeList(context)),
        ],
      ),
    );
  }

  /// Erstellt die horizontal scrollbare Kopfzeile mit den Wochentagen.
  Widget _buildScrollableWeekdayHeader(BuildContext context) {
    final List<DateTime> weekDates = List.generate(7, (index) {
      return _startDate.add(Duration(days: index));
    });

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: SizedBox(
        height: 70,
        child: ListView.builder(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          itemCount: weekDates.length,
          itemBuilder: (context, index) {
            final DateTime day = weekDates[index];
            final isSelected = index == _selectedDayIndex;

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedDayIndex = index;
                });
              },
              child: Container(
                width: MediaQuery.of(context).size.width / 7.5,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                child: Column(
                  children: [
                    // Wochentag (Mo, Di, Mi, ...)
                    Text(
                      _weekdays[index],
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? Theme.of(context).primaryColor
                            : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Kalendertag (Aktuelle Zahl)
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Theme.of(context).primaryColor
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color:
                              (day.day == DateTime.now().day &&
                                  day.month == DateTime.now().month &&
                                  !isSelected)
                              ? Theme.of(context).colorScheme.secondary
                              : Colors.transparent,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        DateFormat('d').format(day),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : Colors.black54,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Erstellt die Liste der geplanten Rezepte für den ausgewählten Tag.
  Widget _buildRecipeList(BuildContext context) {
    final DateTime selectedDate = _startDate.add(
      Duration(days: _selectedDayIndex),
    );
    final String dateString = DateFormat('yyyy-MM-dd').format(selectedDate);

    return FutureBuilder(
      future: Supabase.instance.client
          .from('weekly_plan_recipes')
          .select('*, recipes(*)')
          .eq('scheduled_date', dateString),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data as List<dynamic>? ?? [];

        if (data.isEmpty) {
          return _buildEmptyRecipeSlot(context);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(10),
          itemCount: data.length,
          itemBuilder: (context, index) {
            final recipeMap = data[index]['recipes'];

            final recipeObject = Recipe.fromJson(recipeMap);

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: SizedBox(
                height: 150,
                child: WochenplanRecipeCard(recipe: recipeObject),
              ),
            );
          },
        );
      },
    );
  }

  /// Erstellt eine leere Karte, um ein Rezept hinzuzufügen.
  Widget _buildEmptyRecipeSlot(BuildContext context) {
    return Card(
      elevation: 1.0,
      color: Colors.grey[50],
      child: InkWell(
        onTap: () {
          showNotImplementedSnackbar(context);
        },
        child: const SizedBox(
          height: 100,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_circle_outline, size: 30, color: Colors.grey),
                SizedBox(height: 5),
                Text('Rezept hinzufügen', style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
