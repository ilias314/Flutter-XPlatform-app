import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:recipes/models/recipe.dart';
import 'package:recipes/pages/home_screen.dart';
import 'package:recipes/widgets/weekly_recipe_card.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:recipes/main_scaffold.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final List<String> _weekdays = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];

class WochenplanPages extends ConsumerStatefulWidget {
  const WochenplanPages({super.key});

  @override
  ConsumerState<WochenplanPages> createState() => _WochenplanPagesState();
}

class _WochenplanPagesState extends ConsumerState<WochenplanPages> {
  late DateTime _startDate;
  int _selectedDayIndex = 0;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _startDate = _findStartOfWeek(DateTime.now());
  }

  DateTime _findStartOfWeek(DateTime date) {
    int daysToSubtract = date.weekday - 1;
    return date.subtract(Duration(days: daysToSubtract));
  }

  void _jumpToSelectedWeek(DateTime selectedDate) {
    setState(() {
      _startDate = _findStartOfWeek(selectedDate);
      _selectedDayIndex = selectedDate.weekday - 1;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.jumpTo(0);
    });
  }

  Future<void> _showCalendarPopup(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate.add(Duration(days: _selectedDayIndex)),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      locale: const Locale('de', 'DE'),
      helpText: 'Woche auswählen',
    );

    if (picked != null) {
      _jumpToSelectedWeek(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mein Wochenplan'),
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            ref.read(bottomNavIndexProvider.notifier).state = 0;
          },
        ),

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
          _buildScrollableWeekdayHeader(context),

          const Divider(height: 1, thickness: 1),

          Expanded(child: _buildRecipeList(context)),
        ],
      ),
    );
  }

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

  Widget _buildEmptyRecipeSlot(BuildContext context) {
    return Card(
      elevation: 1.0,
      color: Colors.grey[50],
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const StartseitePages()),
          );
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
