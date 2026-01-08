import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:recipes/pages/create_recipe_screen.dart';
import 'package:recipes/pages/einkaufsliste_screen.dart';
import 'package:recipes/pages/weekly_plan_screen.dart';
import 'package:recipes/widgets/bottom_navbar.dart';
import 'package:recipes/pages/home_screen.dart';
import 'package:recipes/pages/profile_screen.dart';

final bottomNavIndexProvider = StateProvider<int>((ref) => 0);

class MainScaffold extends ConsumerStatefulWidget {
  const MainScaffold({super.key});

  @override
  ConsumerState<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends ConsumerState<MainScaffold> {
  final List<Widget> _pages = [
    const StartseitePages(),
    const WochenplanPages(),
    const CreateRezeptPages(),
    const EinkaufslisteScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final selectedIndex = ref.watch(bottomNavIndexProvider);

    return Scaffold(
      body: _pages[selectedIndex],

      bottomNavigationBar: AppBottomNavBar(
        currentIndex: selectedIndex,
        onTapped: (index) {
          ref.read(bottomNavIndexProvider.notifier).state = index;
        },
      ),
    );
  }
}
