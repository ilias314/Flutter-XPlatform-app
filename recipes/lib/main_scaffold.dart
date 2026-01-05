import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // <--- THIS WAS MISSING
import 'package:flutter_riverpod/legacy.dart';
import 'package:recipes/pages/create_recipe_screen.dart';
import 'package:recipes/pages/einkaufsliste_screen.dart';
import 'package:recipes/pages/weekly_plan_screen.dart';
import 'package:recipes/widgets/bottom_navbar.dart'; 
import 'package:recipes/pages/home_screen.dart'; 
import 'package:recipes/pages/profile_screen.dart';

// 1. CREATE THE PROVIDER
final bottomNavIndexProvider = StateProvider<int>((ref) => 0);

// 2. MAIN SCAFFOLD
class MainScaffold extends ConsumerStatefulWidget {
  const MainScaffold({super.key});

  @override
  ConsumerState<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends ConsumerState<MainScaffold> {
  // Define the 5 Screens
  final List<Widget> _pages = [
    const StartseitePages(), 
    const WochenplanPages(), 
    const CreateRezeptPages(),
    const EinkaufslisteScreen(),
    const ProfileScreen(), 
  ];

  @override
  Widget build(BuildContext context) {
    // 3. LISTEN TO THE PROVIDER
    final selectedIndex = ref.watch(bottomNavIndexProvider);

    return Scaffold(
      body: _pages[selectedIndex], 

      bottomNavigationBar: AppBottomNavBar(
        currentIndex: selectedIndex,
        onTapped: (index) {
          // 4. UPDATE THE PROVIDER
          ref.read(bottomNavIndexProvider.notifier).state = index;
        },
      ),
    );
  }
}