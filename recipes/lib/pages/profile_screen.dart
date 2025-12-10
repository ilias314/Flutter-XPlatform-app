import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '/data/auth_repository.dart'; // Import your Auth Repository
import 'package:recipes/widgets/recipe_section.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});
  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  // Dummy-Status für die Checkboxen (nur für die UI-Demo)
  bool _isVegan = false;
  bool _isVegetarian = false;
  bool _isPescetarian = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profil"),
        
        actions: [
          // Das Zahnrad-Icon oben rechts (laut Skizze)
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              // Hier Logik für Navigation zu Einstellungen / Profil löschen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Zu den Einstellungen...")),
              );
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            
            // ------------------------------------------
            // TEIL 1: NAME & PROFIL BEARBEITEN
            // ------------------------------------------
            const Text(
              "Name", // Hier später dynamischen User-Namen einfügen
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w300),
            ),
            const SizedBox(height: 8),
            
            // Der "Profil bearbeiten" Button (Pill Shape)
            OutlinedButton(
              onPressed: () {
                 // Logik zum Bearbeiten
              },
              style: OutlinedButton.styleFrom(
                shape: const StadiumBorder(), // Macht den Button rund wie auf der Skizze
                side: const BorderSide(color: Color.fromARGB(255, 102, 99, 99)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Profil bearbeiten", style: TextStyle(color: Colors.black)),
                  SizedBox(width: 5),
                  Icon(Icons.edit, size: 16, color: Colors.black),
                ],
              ),
            ),
            
            const SizedBox(height: 20),

            // ------------------------------------------
            // TEIL 2: ERNÄHRUNGS-CHECKBOXEN
            // ------------------------------------------
            // Wir nutzen Padding, damit es nicht am Rand klebt
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: Column(
                children: [
                  _buildCheckboxRow("Vegan", _isVegan, (v) => setState(() => _isVegan = v!)),
                  _buildCheckboxRow("Vegetarisch", _isVegetarian, (v) => setState(() => _isVegetarian = v!)),
                  _buildCheckboxRow("Pescetarier", _isPescetarian, (v) => setState(() => _isPescetarian = v!)),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // ------------------------------------------
            // TEIL 3: REZEPTE (Wiederverwendung von Startseite)
            // ------------------------------------------

          // 1. Favoriten Sektion

            const RecipeSection(title: "Favoriten"),
            
            const SizedBox(height: 40),

            // 2. Meine Rezepte Sektion
            const RecipeSection(title: "Meine Rezepte"),

           
            const SizedBox(height: 40),  

            // ------------------------------------------
            // TEIL 4: LOGOUT BUTTON (Dein existierender Code)
            // ------------------------------------------
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50), // Breiter Button
                ),
                icon: const Icon(Icons.logout),
                label: const Text("Sign Out"),
                onPressed: () async {
                  await ref.read(authRepositoryProvider).signOut();
                },
              ),
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Kleines Hilfs-Widget um die Checkbox-Reihen wie auf der Skizze zu bauen
  Widget _buildCheckboxRow(String label, bool value, ValueChanged<bool?> onChanged) {
    return Row(
      children: [
        Transform.scale(
          scale: 1.1, // Checkboxen etwas größer machen
          child: Checkbox(
            value: value,
            onChanged: onChanged,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            activeColor: const Color.fromARGB(255, 9, 20, 172), 
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 16),
        ),
      ],
    );
  }
}