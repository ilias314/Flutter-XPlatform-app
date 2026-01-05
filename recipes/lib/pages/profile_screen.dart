import 'dart:io';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recipes/data/auth_repository.dart';
import 'package:recipes/data/profile_repository.dart';
import 'package:recipes/main_scaffold.dart';

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

  String _userName = "UserName";
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  // --------------------------------------------------------------------------
  // 1. LOAD DATA
  // --------------------------------------------------------------------------
  Future<void> _loadUserProfile() async {
    if (ref.read(authRepositoryProvider).currentUser == null) return;

    final profileData = await ref.read(profileRepositoryProvider).getProfile();

    if (profileData != null) {
      if (profileData['display_name'] != null) {
        setState(() {
          _userName = profileData['display_name'];
        });
      }

      if (profileData['avatar_url'] != null) {
        setState(() {
          _avatarUrl = profileData['avatar_url'];
        });
      }

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

  // --------------------------------------------------------------------------
  // HELPER (Enum <-> String)
  // --------------------------------------------------------------------------
  DishPreference _stringToEnum(String value) {
    switch (value) {
      case 'Pescetarisch':
        return DishPreference.pescetarisch;
      case 'Vegetarisch':
        return DishPreference.vegetarisch;
      case 'Vegan':
        return DishPreference.vegan;
      default:
        return DishPreference.alles;
    }
  }

  String _enumToString(DishPreference pref) {
    switch (pref) {
      case DishPreference.pescetarisch:
        return 'Pescetarisch';
      case DishPreference.vegetarisch:
        return 'Vegetarisch';
      case DishPreference.vegan:
        return 'Vegan';
      default:
        return 'Alles';
    }
  }

  Future<void> _updatePreference(DishPreference? newValue) async {
    if (newValue == null || newValue == _currentPreference) return;

    setState(() {
      _currentPreference = newValue;
    });

    try {
      final String stringValue = _enumToString(newValue);
      await ref
          .read(profileRepositoryProvider)
          .updateDietaryPreference(stringValue);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ernährungsweise gespeichert'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // --------------------------------------------------------------------------
  // PROFILE PICTURE ACTIONS
  // --------------------------------------------------------------------------
  Future<void> _changeProfilePicture() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) return;

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Bild wird hochgeladen...")));
    }

    try {
      final newUrl = await ref
          .read(profileRepositoryProvider)
          .uploadProfilePicture(image);

      if (mounted) {
        setState(() {
          _avatarUrl = newUrl;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Profilbild aktualisiert!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Upload-Fehler: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteProfilePicture() async {
    try {
      await ref.read(profileRepositoryProvider).deleteProfileImage();

      if (mounted) {
        setState(() {
          _avatarUrl = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Profilbild entfernt"),
            backgroundColor: Colors.grey,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Fehler beim Löschen: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // --------------------------------------------------------------------------
  // MAIN UI
  // --------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profil"),
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            ref.read(bottomNavIndexProvider.notifier).state = 0;
          },
        ),
        actions: [
          // THE SETTINGS BUTTON (Now contains "Edit Profile")
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => _showSettingsSheet(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 30),

            // 1. PROFILE PICTURE
            Center(
              child: CircleAvatar(
                radius: 60,
                backgroundColor:
                    _avatarUrl != null ? Colors.transparent : Colors.grey,
                backgroundImage:
                    _avatarUrl != null ? NetworkImage(_avatarUrl!) : null,
                child: _avatarUrl == null
                    ? const Icon(Icons.person, size: 80, color: Colors.white)
                    : null,
              ),
            ),

            const SizedBox(height: 10),

            // 2. NAME
            Text(
              _userName,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w300),
            ),

            const SizedBox(height: 40),

            // 3. DIETARY PREFERENCE DROPDOWN (Kept as requested)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 10.0, bottom: 8.0),
                    child: Text(
                      'Deine Ernährungsweise:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
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
                        hint: const Text("Bitte wählen"),
                        isExpanded: true,
                        icon: const Icon(
                          Icons.arrow_drop_down_circle_outlined,
                          color: Colors.black,
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: DishPreference.alles,
                            child: Text("Alles"),
                          ),
                          DropdownMenuItem(
                            value: DishPreference.pescetarisch,
                            child: Text("Pescetarier"),
                          ),
                          DropdownMenuItem(
                            value: DishPreference.vegetarisch,
                            child: Text("Vegetarisch"),
                          ),
                          DropdownMenuItem(
                            value: DishPreference.vegan,
                            child: Text("Vegan"),
                          ),
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

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // SETTINGS SHEET (Now includes "Profil bearbeiten")
  // ===========================================================================
  void _showSettingsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: StatefulBuilder(
              builder: (BuildContext context, StateSetter setSheetState) {
                return SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 20,
                      horizontal: 10,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 40,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          "Einstellungen",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        // --- NEW: EDIT PROFILE OPTION ---
                        ListTile(
                          leading: const Icon(Icons.edit, color: Colors.blue),
                          title: const Text("Profil bearbeiten"),
                          onTap: () {
                            Navigator.pop(context); // Close Settings
                            _showEditProfileSheet(context); // Open Edit Sheet
                          },
                        ),
                        const Divider(),

                        SwitchListTile(
                          secondary: Icon(
                            (_isDarkMode) ? Icons.dark_mode : Icons.light_mode,
                          ),
                          title: const Text("Dark Mode"),
                          value: _isDarkMode,
                          onChanged: (bool value) {
                            setSheetState(() => _isDarkMode = value);
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
                          leading: const Icon(
                            Icons.delete_forever,
                            color: Colors.red,
                          ),
                          title: const Text(
                            "Profil löschen",
                            style: TextStyle(color: Colors.red),
                          ),
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
              },
            ),
          ),
        );
      },
    );
  }

  // ===========================================================================
  // EDIT PROFILE SHEET (Avatar, Name, Email, Password)
  // ===========================================================================
  void _showEditProfileSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        return ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              top: 20,
              left: 20,
              right: 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  const SizedBox(height: 25),
                  const Text(
                    "Profil bearbeiten",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 40),

                  // 1. AVATAR with CHANGE & DELETE
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 70,
                        backgroundColor: _avatarUrl != null
                            ? Colors.transparent
                            : Colors.grey,
                        backgroundImage: _avatarUrl != null
                            ? NetworkImage(_avatarUrl!)
                            : null,
                        child: _avatarUrl == null
                            ? const Icon(
                                Icons.person,
                                size: 80,
                                color: Colors.white,
                              )
                            : null,
                      ),

                      // Change Button (Blue)
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          _changeProfilePicture();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                            border: Border.fromBorderSide(
                              BorderSide(color: Colors.white, width: 2),
                            ),
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),

                      // Delete Button (Red) - Only if image exists
                      if (_avatarUrl != null)
                        Positioned(
                          left: 0,
                          bottom: 0,
                          child: GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                              _deleteProfilePicture();
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                                border: Border.fromBorderSide(
                                  BorderSide(color: Colors.white, width: 2),
                                ),
                              ),
                              child: const Icon(
                                Icons.delete_outline,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 40),

                  // 2. EDIT OPTIONS
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading:
                        const Icon(Icons.person_outline, color: Colors.black),
                    title: const Text('Benutzernamen ändern'),
                    onTap: () {
                      Navigator.pop(context);
                      _showChangeUsernameDialog();
                    },
                  ),
                  const SizedBox(height: 10),

                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading:
                        const Icon(Icons.email_outlined, color: Colors.black),
                    title: const Text('E-Mail ändern'),
                    onTap: () {
                      Navigator.pop(context);
                      _showChangeEmailDialog();
                    },
                  ),
                  const SizedBox(height: 10),

                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading:
                        const Icon(Icons.lock_outline, color: Colors.black),
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
  // DIALOGS
  // ===========================================================================

  void _showChangeUsernameDialog() {
    final TextEditingController nameController = TextEditingController();
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
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Abbrechen"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                try {
                  await ref
                      .read(profileRepositoryProvider)
                      .updateUsername(nameController.text);
                  setState(() => _userName = nameController.text);
                  if (ctx.mounted) Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Benutzername geändert"),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Fehler: $e"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text("Speichern"),
          ),
        ],
      ),
    );
  }

  void _showChangeEmailDialog() {
    final TextEditingController newEmailController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("E-Mail ändern"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Hinweis: Du erhältst eine Bestätigungsmail.",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: newEmailController,
              decoration:
                  const InputDecoration(labelText: "Neue E-Mail Adresse"),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Abbrechen"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (newEmailController.text.contains('@')) {
                try {
                  await ref
                      .read(authRepositoryProvider)
                      .updateEmail(newEmailController.text);
                  if (ctx.mounted) Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Bestätigungsmail gesendet!"),
                      backgroundColor: Colors.blue,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Fehler: $e"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text("Ändern"),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    final TextEditingController oldPassController = TextEditingController();
    final TextEditingController newPassController = TextEditingController();
    final TextEditingController confirmPassController = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    bool obscureOld = true;
    bool obscureNew = true;
    bool obscureConfirm = true;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Passwort ändern"),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: oldPassController,
                        decoration: InputDecoration(
                          labelText: "Altes Passwort",
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscureOld
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () =>
                                setState(() => obscureOld = !obscureOld),
                          ),
                        ),
                        obscureText: obscureOld,
                        validator: (value) => (value == null || value.isEmpty)
                            ? 'Bitte altes Passwort eingeben'
                            : null,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: newPassController,
                        decoration: InputDecoration(
                          labelText: "Neues Passwort",
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscureNew
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () =>
                                setState(() => obscureNew = !obscureNew),
                          ),
                        ),
                        obscureText: obscureNew,
                        validator: (value) {
                          if (value == null || value.isEmpty)
                            return 'Pflichtfeld';
                          if (value.length < 6) return 'Mindestens 6 Zeichen';
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: confirmPassController,
                        decoration: InputDecoration(
                          labelText: "Wiederholen",
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscureConfirm
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () => setState(
                              () => obscureConfirm = !obscureConfirm,
                            ),
                          ),
                        ),
                        obscureText: obscureConfirm,
                        validator: (value) {
                          if (value != newPassController.text)
                            return 'Stimmt nicht überein';
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Abbrechen"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      try {
                        await ref
                            .read(authRepositoryProvider)
                            .reauthenticate(oldPassController.text);
                        await ref
                            .read(authRepositoryProvider)
                            .updatePassword(newPassController.text);
                        if (ctx.mounted) Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Passwort erfolgreich geändert"),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Fehler: $e"),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  child: const Text("Speichern"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Profil wirklich löschen?"),
        content: const Text(
          "Diese Aktion kann nicht rückgängig gemacht werden. Alle deine Daten und Rezepte werden dauerhaft gelöscht.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Abbrechen"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                if (!mounted) return;
                setState(() => _isLoading = true);
                await ref.read(authRepositoryProvider).deleteAccount();
              } catch (e) {
                if (mounted) {
                  setState(() => _isLoading = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Fehler: $e"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text(
              "Endgültig löschen",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}