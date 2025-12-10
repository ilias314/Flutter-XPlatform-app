import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '/data/auth_repository.dart'; 
import 'package:recipes/widgets/recipe_section.dart';
import 'package:recipes/widgets/ui_utils.dart';

// Enum für die Auswahlmöglichkeiten
enum DishPreference { allesfresser, pescetarisch, vegetarisch, vegan }

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  // Standard-Auswahl
  DishPreference _currentPreference = DishPreference.allesfresser;
  
  // Dummy-Status für den Dark Mode (nur für die UI-Demo)
  bool _isDarkMode = false; 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profil"),
        centerTitle: false,
        actions: [
          // ---------------------------------------------------
          // DAS ZAHNRAD (Öffnet jetzt die Einstellungen)
          // ---------------------------------------------------
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              _showSettingsSheet(context);
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            
            // ------------------------------------------
            // TEIL 1: HEADER & BEARBEITEN
            // ------------------------------------------
            const Text(
              "Dein Name", 
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w300),
            ),
            
            const SizedBox(height: 8),
            
            OutlinedButton(
              onPressed: () => _showEditProfileSheet(context),
              style: OutlinedButton.styleFrom(
                shape: const StadiumBorder(),
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
            // TEIL 2: ERNÄHRUNGSWEISE (Dropdown)
            // ------------------------------------------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 4.0, bottom: 8.0),
                    child: Text(
                      'Deine Ernährungsweise:',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey, width: 1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<DishPreference>(
                        value: _currentPreference,
                        isExpanded: true,
                        icon: const Icon(Icons.arrow_drop_down_circle_outlined),
                        items: const [
                          DropdownMenuItem(
                            value: DishPreference.allesfresser,
                            child: Row(
                              children: [
                                Icon(Icons.restaurant, size: 20), 
                                SizedBox(width: 10), 
                                Text("Alles") // Hier steht jetzt nur "Alles"
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: DishPreference.pescetarisch,
                            child: Row(
                              children: [
                                Icon(Icons.set_meal, size: 20), 
                                SizedBox(width: 10), 
                                Text("Pescetarier")
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: DishPreference.vegetarisch,
                            child: Row(
                              children: [
                                Icon(Icons.grass, size: 20), 
                                SizedBox(width: 10), 
                                Text("Vegetarisch")
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: DishPreference.vegan,
                            child: Row(
                              children: [
                                Icon(Icons.eco, size: 20), 
                                SizedBox(width: 10), 
                                Text("Vegan")
                              ],
                            ),
                          ),
                        ],
                        onChanged: (DishPreference? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _currentPreference = newValue;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // ------------------------------------------
            // TEIL 3: REZEPTE
            // ------------------------------------------
            const RecipeSection(title: "Favoriten"),
            const SizedBox(height: 40),
            const RecipeSection(title: "Meine Rezepte"),
            
            const SizedBox(height: 40),  
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------
  // FUNKTION 1: PROFIL BEARBEITEN (Name, Bild, Email)
  // ---------------------------------------------------
  void _showEditProfileSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom, top: 20, left: 20, right: 20
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 20),
              const Text("Profil bearbeiten", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  const CircleAvatar(radius: 50, backgroundColor: Colors.grey, child: Icon(Icons.person, size: 60, color: Colors.white)),
                  Container(
                    decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                    child: IconButton(icon: const Icon(Icons.camera_alt, color: Colors.white, size: 20), onPressed: () => showNotImplementedSnackbar(context)),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              ListTile(
                leading: const Icon(Icons.email_outlined), title: const Text('E-Mail ändern'), onTap: () => showNotImplementedSnackbar(context),
              ),
              ListTile(
                leading: const Icon(Icons.lock_outline), title: const Text('Passwort ändern'), onTap: () => showNotImplementedSnackbar(context),
              ),
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------
  // FUNKTION 2: EINSTELLUNGEN (Sign Out, Delete, Dark Mode)
  // ---------------------------------------------------
  void _showSettingsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        // StatefulBuilder sorgt dafür, dass der Switch sich bewegt
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
                  const SizedBox(height: 20),
                  
                  const Text("Einstellungen", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),

                  // 1. Dark Mode Switch
                  SwitchListTile(
                    // FIX 1: Prüfen ob null, sonst false nehmen
                    secondary: Icon((_isDarkMode ?? false) ? Icons.dark_mode : Icons.light_mode),
                    title: const Text("Dark Mode"),
                    // FIX 2: Auch hier: Wenn null, dann false
                    value: _isDarkMode ?? false,
                    onChanged: (bool value) {
                      setSheetState(() {
                        _isDarkMode = value;
                      });
                    },
                  ),

                  const Divider(),

                  // 2. Sign Out
                  ListTile(
                    leading: const Icon(Icons.logout),
                    title: const Text("Abmelden"),
                    onTap: () async {
                      Navigator.pop(context); // Schließt das Menü
                      await ref.read(authRepositoryProvider).signOut();
                    },
                  ),

                  const Divider(),

                  // 3. Profil löschen
                  ListTile(
                    leading: const Icon(Icons.delete_forever, color: Colors.red),
                    title: const Text("Profil löschen", style: TextStyle(color: Colors.red)),
                    onTap: () {
                      Navigator.pop(context);
                      showNotImplementedSnackbar(context); 
                    },
                  ),
                  
                  const SizedBox(height: 30),
                ],
              ),
            );
          }
        );
      },
    );
  }
}