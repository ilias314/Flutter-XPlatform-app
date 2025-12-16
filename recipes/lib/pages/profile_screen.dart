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
  
  // Lokaler State für den Benutzernamen
  String _userName = "UserName"; 

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  // --- 1. DATEN LADEN ---
  Future<void> _loadUserProfile() async {
    final profileData = await ref.read(profileRepositoryProvider).getProfile();
    
    if (profileData != null) {
      // -----------------------------------------------------------
      // KORREKTUR: Hier lesen wir jetzt 'display_name' statt 'username'
      // -----------------------------------------------------------
      if (profileData['display_name'] != null) { 
         setState(() {
           _userName = profileData['display_name'];
         });
      }

      // Präferenzen laden
      if (profileData['dietary_preferences'] != null) {
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

  // --- 2. DATEN SPEICHERN (PRÄFERENZEN) ---
  Future<void> _updatePreference(DishPreference? newValue) async {
    if (newValue == null || newValue == _currentPreference) return;
    
    setState(() {
      _currentPreference = newValue;
    });
    
    try {
      final String stringValue = _enumToString(newValue);
      await ref.read(profileRepositoryProvider).updateDietaryPreference(stringValue);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ernährungsweise gespeichert'), duration: Duration(seconds: 2)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Fehler: $e'), backgroundColor: Colors.red));
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
            onPressed: () => _showSettingsSheet(context),
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
                ],
              ),
            ),
            
            const SizedBox(height: 10),
            
            // NAME (Wird nun korrekt angezeigt)
            Text(
              _userName, 
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w300),
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
                    child: Text('Deine Ernährungsweise:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                        hint: const Text("Bitte wählen"),
                        isExpanded: true, 
                        icon: const Icon(Icons.arrow_drop_down_circle_outlined, color: Colors.black),
                        items: const [
                          DropdownMenuItem(value: DishPreference.alles, child: Text("Alles")),
                          DropdownMenuItem(value: DishPreference.pescetarisch, child: Text("Pescetarier")),
                          DropdownMenuItem(value: DishPreference.vegetarisch, child: Text("Vegetarisch")),
                          DropdownMenuItem(value: DishPreference.vegan, child: Text("Vegan")),
                        ],
                        onChanged: (val) {
                          if (val != null) _updatePreference(val);
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

  // ===========================================================================
  // MODAL SHEET: PROFIL BEARBEITEN
  // ===========================================================================
  void _showEditProfileSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      builder: (context) {
        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom, top: 20, left: 20, right: 20
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 40, height: 8, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(18))),
                  const SizedBox(height: 25),
                  const Text("Profil bearbeiten", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 40),
                  
                  // 1. PROFILBILD
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      const CircleAvatar(
                        radius: 70, 
                        backgroundColor: Colors.grey, 
                        child: Icon(Icons.person, size: 80, color: Colors.white)
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context); 
                          _changeProfilePicture();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 24),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  
                  // 2. BEARBEITUNGS-OPTIONEN
                  
                  // A) USERNAME
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.person_outline, color: Colors.black), 
                    title: const Text('Benutzernamen ändern'), 
                    onTap: () {
                      Navigator.pop(context);
                      _showChangeUsernameDialog();
                    },
                  ),
                  const SizedBox(height: 10),

                  // B) E-MAIL
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.email_outlined, color: Colors.black), 
                    title: const Text('E-Mail ändern'), 
                    onTap: () {
                      Navigator.pop(context);
                      _showChangeEmailDialog();
                    },
                  ),
                  const SizedBox(height: 10),

                  // C) PASSWORT
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.lock_outline, color: Colors.black), 
                    title: const Text('Passwort ändern'), 
                    onTap: () {
                      Navigator.pop(context);
                      _showChangePasswordDialog();
                    },
                  ),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ===========================================================================
  // DIALOGE FÜR ÄNDERUNGEN
  // ===========================================================================

  // --- 1. PROFILBILD LOGIK ---
  void _changeProfilePicture() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Galerie öffnen...")),
    );
  }

  // --- 2. USERNAME DIALOG ---
  void _showChangeUsernameDialog() {
    final TextEditingController nameController = TextEditingController();
    // Vorbefüllen mit aktuellem Namen
    nameController.text = _userName;
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Benutzernamen ändern"),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: "Neuer Benutzername"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Abbrechen")),
          ElevatedButton(
            onPressed: () async {
              // Speichern Logik
              if (nameController.text.isNotEmpty) {
                try {
                  // WICHTIG: Das Repository sollte jetzt auch 'display_name' speichern
                  await ref.read(profileRepositoryProvider).updateUsername(nameController.text);
                  
                  setState(() {
                    _userName = nameController.text; // UI Update
                  });
                  
                  if (ctx.mounted) Navigator.pop(ctx);
                  
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Benutzername geändert"), backgroundColor: Colors.green));
                } catch (e) {
                   ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Fehler: $e"), backgroundColor: Colors.red));
                }
              }
            },
            child: const Text("Speichern"),
          ),
        ],
      ),
    );
  }

  // --- 3. E-MAIL DIALOG ---
  void _showChangeEmailDialog() {
    final TextEditingController newEmailController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("E-Mail ändern"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
             const Text("Hinweis: Du erhältst eine Bestätigungsmail.", style: TextStyle(fontSize: 12, color: Colors.grey)),
             const SizedBox(height: 10),
            TextField(
              controller: newEmailController,
              decoration: const InputDecoration(labelText: "Neue E-Mail Adresse"),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Abbrechen")),
          ElevatedButton(
            onPressed: () async {
              if (newEmailController.text.contains('@')) {
                try {
                  await ref.read(authRepositoryProvider).updateEmail(newEmailController.text);
                  if (ctx.mounted) Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Bestätigungsmail gesendet!"), backgroundColor: Colors.blue));
                } catch (e) {
                   ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Fehler: $e"), backgroundColor: Colors.red));
                }
              }
            },
            child: const Text("Ändern"),
          ),
        ],
      ),
    );
  }

  // --- 4. PASSWORT DIALOG ---
  void _showChangePasswordDialog() {
    final TextEditingController oldPassController = TextEditingController();
    final TextEditingController newPassController = TextEditingController();
    final TextEditingController confirmPassController = TextEditingController();
    final _formKey = GlobalKey<FormState>(); 

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Passwort ändern"),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: oldPassController,
                  decoration: const InputDecoration(labelText: "Altes Passwort"),
                  obscureText: true,
                  validator: (value) => (value == null || value.isEmpty) ? 'Pflichtfeld' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: newPassController,
                  decoration: const InputDecoration(labelText: "Neues Passwort"),
                  obscureText: true,
                  validator: (value) => (value == null || value.length < 6) ? 'Mind. 6 Zeichen' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: confirmPassController,
                  decoration: const InputDecoration(labelText: "Wiederholen"),
                  obscureText: true,
                  validator: (value) => (value != newPassController.text) ? 'Stimmt nicht überein' : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Abbrechen")),
          ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                try {
                  await ref.read(authRepositoryProvider).reauthenticate(oldPassController.text);
                  await ref.read(authRepositoryProvider).updatePassword(newPassController.text);
                  if (ctx.mounted) Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Passwort erfolgreich geändert"), backgroundColor: Colors.green));
                } catch (e) {
                   ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Fehler: $e"), backgroundColor: Colors.red));
                }
              }
            },
            child: const Text("Speichern"),
          ),
        ],
      ),
    );
  }


  // ===========================================================================
  // MODAL SHEET: EINSTELLUNGEN
  // ===========================================================================
  void _showSettingsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
          child: Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: StatefulBuilder(
              builder: (BuildContext context, StateSetter setSheetState) {
                return SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
                        const SizedBox(height: 20),
                        
                        const Text("Einstellungen", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 20),

                        SwitchListTile(
                          secondary: Icon((_isDarkMode) ? Icons.dark_mode : Icons.light_mode),
                          title: const Text("Dark Mode"),
                          value: _isDarkMode,
                          onChanged: (bool value) {
                            setSheetState(() { _isDarkMode = value; });
                          },
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.logout),
                          title: const Text("Abmelden"),
                          onTap: () async {
                            Navigator.pop(context);
                            await ref.read(authRepositoryProvider).signOut();
                          },
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.delete_forever, color: Colors.red),
                          title: const Text("Profil löschen", style: TextStyle(color: Colors.red)),
                          onTap: () {
                            Navigator.pop(context);
                            _showDeleteConfirmationDialog(); 
                          },
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                );
              }
            ),
          ),
        );
      },
    );
  }
  // --------------------------------------------------------------------------
  // SICHERHEITS-DIALOG ZUM LÖSCHEN
  // --------------------------------------------------------------------------
  void _showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Profil wirklich löschen?"),
        content: const Text(
          "Diese Aktion kann nicht rückgängig gemacht werden. Alle deine Daten und Rezepte werden dauerhaft gelöscht.",
        ),
        actions: [
          // Abbrechen Button
          TextButton(
            onPressed: () => Navigator.pop(ctx), 
            child: const Text("Abbrechen"),
          ),
          
          // Löschen Button (Rot)
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx); // Dialog schließen
              
              try {
                // Ladekreis anzeigen, damit User sieht, dass was passiert
                setState(() => _isLoading = true);

                // REPOSITORY AUFRUFEN (das ruft die SQL-Funktion auf)
                await ref.read(authRepositoryProvider).deleteAccount();
                
                // Hinweis: Nach erfolgreichem Löschen loggt Supabase den User aus.
                // Dein Router (in router.dart) sollte das merken und automatisch 
                // zum Login-Screen wechseln.
                
              } catch (e) {
                // Falls was schiefgeht, Loading beenden und Fehler zeigen
                if (mounted) {
                  setState(() => _isLoading = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Fehler: $e"), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text("Endgültig löschen", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}