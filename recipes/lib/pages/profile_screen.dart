import 'dart:io';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recipes/data/auth_repository.dart';
import 'package:recipes/data/profile_repository.dart';
import 'package:recipes/main_scaffold.dart';
import 'package:recipes/pages/favorite_list_screen.dart';
import 'package:recipes/pages/my_recipes_list_screen.dart';

enum DishPreference { alles, pescetarisch, vegetarisch, vegan }

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  DishPreference _currentPreference = DishPreference.alles;
  bool _isLoading = true;

  String _userName = "UserName";
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

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

            Center(
              child: CircleAvatar(
                radius: 60,
                backgroundColor: _avatarUrl != null
                    ? Colors.transparent
                    : Colors.grey,
                backgroundImage: _avatarUrl != null
                    ? NetworkImage(_avatarUrl!)
                    : null,
                child: _avatarUrl == null
                    ? const Icon(Icons.person, size: 80, color: Colors.white)
                    : null,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              _userName,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w300),
            ),

            const SizedBox(height: 40),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Card(
                elevation: 2,
                shadowColor: Colors.black12,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.eco,
                      color: Theme.of(context).primaryColor,
                      size: 24,
                    ),
                  ),
                  title: const Text(
                    "Ernährungsweise",
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  trailing: DropdownButtonHideUnderline(
                    child: DropdownButton<DishPreference>(
                      value: _currentPreference,
                      icon: const Icon(
                        Icons.arrow_drop_down,
                        color: Colors.grey,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
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
              ),
            ),

            const SizedBox(height: 15),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                children: [
                  _buildProfileMenuTile(
                    context,
                    icon: Icons.favorite_border,
                    title: "Favoriten",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FavoriteListScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 15),
                  _buildProfileMenuTile(
                    context,
                    icon: Icons.menu_book_outlined,
                    title: "Meine Rezepte",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MyRecipesListScreen(),
                        ),
                      );
                    },
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

  Widget _buildProfileMenuTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Theme.of(context).primaryColor, size: 24),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey,
        ),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

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

                        ListTile(
                          leading: const Icon(Icons.edit, color: Colors.blue),
                          title: const Text("Profil bearbeiten"),
                          onTap: () {
                            Navigator.pop(context);
                            _showEditProfileSheet(context);
                          },
                        ),
                        const Divider(),

                        ListTile(
                          leading: const Icon(Icons.logout),
                          title: const Text("Abmelden"),
                          onTap: () {
                            Navigator.pop(context);
                            _showLogoutConfirmationDialog();
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

                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.person_outline,
                      color: Colors.black,
                    ),
                    title: const Text('Benutzernamen ändern'),
                    onTap: () {
                      Navigator.pop(context);
                      _showChangeUsernameDialog();
                    },
                  ),
                  const SizedBox(height: 10),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.email_outlined,
                      color: Colors.black,
                    ),
                    title: const Text('E-Mail ändern'),
                    onTap: () {
                      Navigator.pop(context);
                      _showChangeEmailDialog();
                    },
                  ),
                  const SizedBox(height: 10),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.lock_outline,
                      color: Colors.black,
                    ),
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
              decoration: const InputDecoration(
                labelText: "Neue E-Mail Adresse",
              ),
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

  void _showLogoutConfirmationDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Abmelden"),
        content: const Text("Möchten Sie sich wirklich abmelden?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Abbrechen"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref.read(authRepositoryProvider).signOut();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Fehler beim Abmelden: $e")),
                  );
                }
              }
            },
            child: const Text("Abmelden"),
          ),
        ],
      ),
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
