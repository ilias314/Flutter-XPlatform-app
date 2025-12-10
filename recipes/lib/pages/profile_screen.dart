import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '/data/auth_repository.dart'; 
import 'package:recipes/widgets/recipe_section.dart';
import 'package:recipes/widgets/ui_utils.dart';

// Enum für die Auswahlmöglichkeiten
enum DishPreference { alles, pescetarisch, vegetarisch, vegan }

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  // Standard-Auswahl
  DishPreference _currentPreference = DishPreference.alles;
  
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
            // TEIL 1: NAME & PROFIL BEARBEITEN (Responsive)
            // ------------------------------------------
            const Text(
              "Dein Name", 
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w300),
            ),
            const SizedBox(height: 15),
            
            // RESPONSIVE LÖSUNG: Padding bestimmt die Breite
            Padding(
              // 40 Pixel Abstand links und rechts -> Button füllt den Rest
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: SizedBox(
                height: 48, // Feste Höhe bleibt ok
                width: double.infinity, // Nimm so viel Breite wie möglich (minus Padding)
                child: OutlinedButton(
                  onPressed: () => _showEditProfileSheet(context),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    side: const BorderSide(color: Colors.grey),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Profil bearbeiten", style: TextStyle(color: Colors.black, fontSize: 16)),
                      SizedBox(width: 8),
                       
                      Icon(Icons.edit, size: 18, color: Colors.black),
                      
                    ],
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 30),

            // ------------------------------------------
            // TEIL 2: ERNÄHRUNGSWEISE (Gleiche Breite durch gleiches Padding)
            // ------------------------------------------
            Padding(
              // WICHTIG: Genau dasselbe Padding wie oben (40), damit sie gleich breit sind
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 10.0, bottom: 8.0),
                    child: Text(
                      'Deine Ernährungsweise:',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  
                  Container(
                    height: 48,
                    width: double.infinity, // Füllt den Bereich zwischen den 40px Rändern
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey, width: 1),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    alignment: Alignment.centerLeft,
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<DishPreference>(
                        value: _currentPreference,
                        
                        hint: const Row(
                          children: [
                            Icon(Icons.touch_app_outlined, color: Colors.grey, size: 20),
                            SizedBox(width: 10),
                            Text("Bitte wählen"),
                          ],
                        ),
                        
                        isExpanded: true, 
                        icon: const Icon(Icons.arrow_drop_down_circle_outlined, color: Colors.black),
                        
                        items: const [
                          DropdownMenuItem(
                            value: DishPreference.alles,
                            child: Row(
                              children: [
                                Icon(Icons.restaurant, size: 20), 
                                SizedBox(width: 10), 
                                Text("Alles") 
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
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom, top: 20, left: 20, right: 20
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 8, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(18))),
              const SizedBox(height: 25),
              const Text("Profil bearbeiten", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 30),
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