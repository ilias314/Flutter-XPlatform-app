import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recipes/data/auth_repository.dart';
import 'package:recipes/data/profile_repository.dart'; 
import 'package:recipes/widgets/recipe_section.dart';
import 'package:recipes/widgets/ui_utils.dart';

enum DishPreference { alles, pescetarisch, vegetarisch, vegan }

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  DishPreference _currentPreference = DishPreference.alles;
  bool _isLoading = true; 
  bool _isDarkMode = false; 

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  // --- 1. LOAD DATA FROM SUPABASE ---
  Future<void> _loadUserProfile() async {
    final profileData = await ref.read(profileRepositoryProvider).getProfile();
    
    if (profileData != null && profileData['dietary_preferences'] != null) {
      final json = profileData['dietary_preferences'];
      final String? savedPref = json['preference'];

      if (savedPref != null) {
        if (mounted) {
          setState(() {
            _currentPreference = _stringToEnum(savedPref);
          });
        }
      }
    }
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  DishPreference _stringToEnum(String value) {
    switch (value) {
      case 'Pescetarisch': return DishPreference.pescetarisch;
      case 'Vegetarisch': return DishPreference.vegetarisch;
      case 'Vegan': return DishPreference.vegan;
      default: return DishPreference.alles;
    }
  }

  String _enumToString(DishPreference pref) {
    switch (pref) {
      case DishPreference.pescetarisch: return 'Pescetarisch';
      case DishPreference.vegetarisch: return 'Vegetarisch';
      case DishPreference.vegan: return 'Vegan';
      default: return 'Alles';
    }
  }

  // --- 2. SAVE DATA TO SUPABASE ---
  Future<void> _updatePreference(DishPreference? newValue) async {
  if (newValue == null || newValue == _currentPreference) return;
  
  // Update UI immediately for better UX
  setState(() {
    _currentPreference = newValue;
  });
  
  try {
    final String stringValue = _enumToString(newValue);
    print('🔄 Saving preference: $stringValue');
    
    // Save to Supabase in background
    await ref.read(profileRepositoryProvider).updateDietaryPreference(stringValue);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ernährungsweise gespeichert'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  } catch (e) {
    print('❌ Error saving preference: $e');
    
    if (mounted) {
      // Show error and revert UI
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fehler beim Speichern: $e'),
          backgroundColor: Colors.red,
        ),
      );
      
      // Reload from database to get correct state
      await _loadUserProfile();
    }
  }
}

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profil"),
        centerTitle: false,
        actions: [
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
            const SizedBox(height: 30),

            // PROFILBILD
            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  const CircleAvatar(
                    radius: 60, 
                    backgroundColor: Colors.grey,
                    child: Icon(Icons.person, size: 80, color: Colors.white),
                  ),
                  
                  Container(
                    height: 35,
                    width: 35,
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                      onPressed: () => _showEditProfileSheet(context),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 10),
            
            // NAME
            const Text(
              "UserName", 
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w300),
            ),
            
            const SizedBox(height: 20),
            
            // PROFIL BEARBEITEN BUTTON
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: SizedBox(
                height: 48, 
                width: double.infinity, 
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

            // ERNÄHRUNGSWEISE DROPDOWN
            Padding(
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
                    width: double.infinity, 
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
                            _updatePreference(newValue);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 50),

            const RecipeSection(title: "Favoriten"),
            const SizedBox(height: 50),
            const RecipeSection(title: "Meine Rezepte"),
            const SizedBox(height: 40),  
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------
  // FUNKTION 1: PROFIL BEARBEITEN
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
  // FUNKTION 2: EINSTELLUNGEN
  // ---------------------------------------------------
  void _showSettingsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
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
                    secondary: Icon((_isDarkMode) ? Icons.dark_mode : Icons.light_mode),
                    title: const Text("Dark Mode"),
                    value: _isDarkMode,
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
                      Navigator.pop(context);
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