import 'package:flutter/material.dart';
import 'package:recipes/pages/create_recipe_screen.dart';
import 'package:recipes/pages/einkaufsliste_screen.dart';
import 'package:recipes/pages/weekly_plan_screen.dart';
import 'package:recipes/widgets/bottom_navbar.dart'; 
import 'package:recipes/pages/home_screen.dart'; // Ensure StartseitePages is exported here
import 'package:recipes/pages/profile_screen.dart';

class MainScaffold extends StatefulWidget {
  // ✅ FIX: Removed 'final Widget child;'
  // We don't need it because we use the internal list '_pages' below.
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _selectedIndex = 0;

  // Define the 5 Screens matching your BottomNavBar items
  final List<Widget> _pages = [
    // Index 0: Home
    const StartseitePages(), 
    
    // Index 1: Wochenplan
    const WochenplanPages(), 
    
    // Index 2: Neues Rezept (Add Recipe)
    const CreateRezeptPages(),
    
    // Index 3: Einkaufsliste
    const EinkaufslisteScreen(),
    
    // Index 4: Profil
    const ProfileScreen(), 
  ];

  void _onTabChange(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // This switches the body content based on the index
      body: _pages[_selectedIndex],

      bottomNavigationBar: AppBottomNavBar(
        currentIndex: _selectedIndex,
        onTapped: _onTabChange,
      ),
    );
  }
}