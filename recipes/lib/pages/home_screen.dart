import 'package:flutter/material.dart';
import 'package:recipes/widgets/ui_utils.dart'; 
import 'package:recipes/widgets/recipe_section.dart'; 
import 'package:recipes/widgets/bottom_navbar.dart'; 

class StartseitePages extends StatefulWidget {
  const StartseitePages({super.key});

  @override
  State<StartseitePages> createState() => _StartseitePagesState();
}

class _StartseitePagesState extends State<StartseitePages> {
  int _selectedIndex = 0; 

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RecipeS'),
        centerTitle: true,
        actions: <Widget>[
          // Icône de recherche
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => showNotImplementedSnackbar(context), 
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: const <Widget>[
            // 1. Top Rezepte je nach Profil
            RecipeSection(title: 'Top Rezepte je nach Profil'),
            
            SizedBox(height: 16.0), 
            
            // 2. Neueste Rezepte der Woche
            RecipeSection(title: 'Neueste Rezepte der Woche'),
            
            SizedBox(height: 16.0),
            
            // 3. Top Rezepte der Woche
            RecipeSection(title: 'Top Rezepte der Woche'),
            
            SizedBox(height: 16.0),
            
            // 4. Top Rezepte des Monats
            RecipeSection(title: 'Top Rezepte des Monats'),
            
            SizedBox(height: 20.0),
          ],
        ),
      ),
    );
  }
}