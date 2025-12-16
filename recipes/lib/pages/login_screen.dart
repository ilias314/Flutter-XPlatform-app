import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/auth_repository.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  // ------------------------------------------
  // TEIL 1: CONTROLLER & STATE FÜR LOGIN
  // ------------------------------------------
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Zeigt an, ob der Login-Prozess gerade läuft (Ladekreis)
  bool _isLoading = false;

  // Steuert, ob das Passwort im Login-Feld sichtbar ist
  bool _isLoginPasswordVisible = false;

  // ------------------------------------------
  // TEIL 2: LOGIN-FUNKTION
  // ------------------------------------------
  Future<void> _login() async {
    // Tastatur ausblenden
    FocusScope.of(context).unfocus();

    setState(() => _isLoading = true);

    try {
      // Aufruf an Supabase/Backend über Riverpod
      await ref
          .read(authRepositoryProvider)
          .signIn(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );
      // Erfolg: Der Router (GoRouter) merkt das automatisch und leitet um.
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Fehler: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ------------------------------------------
  // TEIL 3: REGISTRIERUNGS-POP-UP (DIALOG)
  // ------------------------------------------
  void _showRegistrationDialog() {
    // Eigene Controller für das Pop-up (damit Login-Felder sauber bleiben)
    final regUsernameController = TextEditingController();
    final regEmailController = TextEditingController();
    final regPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierDismissible: false, // Dialog schließt nicht beim Klick daneben
      builder: (context) {
        // ------------------------------------------
        // WICHTIG: STATE FÜR DIALOG
        // Diese Variablen müssen HIER (außerhalb vom Builder) stehen,
        // damit sie ihren Wert behalten, wenn man auf das Auge klickt.
        // ------------------------------------------
        bool isRegLoading = false;
        bool isRegPasswordVisible = false;

        // StatefulBuilder ermöglicht setState INNERHALB des Pop-ups
        return StatefulBuilder(
          builder: (context, setDialogState) {
            // Interne Funktion zum Registrieren
            Future<void> register() async {
              if (!formKey.currentState!.validate()) return;

              // Ladekreis im Dialog starten
              setDialogState(() => isRegLoading = true);

              try {
                await ref
                    .read(authRepositoryProvider)
                    .signUp(
                      email: regEmailController.text.trim(),
                      password: regPasswordController.text.trim(),
                      username: regUsernameController.text.trim(), // Falls dein Backend das unterstützt
                    );

                if (context.mounted) {
                  Navigator.of(context).pop(); // Dialog schließen
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Account erstellt! Bitte einloggen.'),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.toString()),
                      backgroundColor: Colors.red,
                    ),
                  );
                  // Bei Fehler Loading beenden, damit man es nochmal versuchen kann
                  setDialogState(() => isRegLoading = false);
                }
              }
            }

            // ------------------------------------------
            // UI POP-UP
            // ------------------------------------------
            return AlertDialog(
              backgroundColor: Colors.white, 
              surfaceTintColor: Colors.transparent,
              title: const Text("Registrieren"),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize:
                        MainAxisSize.min, // Dialog so klein wie möglich
                    children: [
                      // --- EINGABE: USERNAME ---
                      TextFormField(
                        controller: regUsernameController,
                        decoration: const InputDecoration(
                          labelText: 'Username',
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) =>
                            value!.isEmpty ? 'Username benötigt' : null,
                      ),
                      const SizedBox(height: 16),

                      // --- EINGABE: EMAIL ---
                      TextFormField(
                        controller: regEmailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) => value!.contains('@')
                            ? null
                            : 'Gültige Email eingeben',
                      ),
                      const SizedBox(height: 16),

                      // --- EINGABE: PASSWORT (MIT AUGE) ---
                      TextFormField(
                        controller: regPasswordController,
                        // Wenn visible=false -> Text verstecken (obscureText=true)
                        obscureText: !isRegPasswordVisible,
                        decoration: InputDecoration(
                          labelText: 'Passwort',
                          prefixIcon: const Icon(Icons.lock),
                          border: const OutlineInputBorder(),
                          // Das Augen-Icon
                          suffixIcon: IconButton(
                            icon: Icon(
                              isRegPasswordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              // Ändert nur den State des Dialogs!
                              setDialogState(() {
                                isRegPasswordVisible = !isRegPasswordVisible;
                              });
                            },
                          ),
                        ),
                        validator: (value) =>
                            value!.length < 6 ? 'Min. 6 Zeichen' : null,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                // Button: Abbrechen
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("Abbrechen"),
                ),
                // Button: Registrieren (oder Ladekreis)
                isRegLoading
                    ? const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : ElevatedButton(
                        onPressed: register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text("Registrieren"),
                      ),
              ],
            );
          },
        );
      },
    );
  }

  // ------------------------------------------
  // TEIL 4: HAUPT-UI (LOGIN SCREEN)
  // ------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // --- LOGO & TITEL ---
            const Icon(Icons.restaurant_menu, size: 80, color: Colors.orange),
            const SizedBox(height: 20),
            const Text(
              "RecipeS",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 40),

            // --- LOGIN FELD: EMAIL ---
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: 16),

            // --- LOGIN FELD: PASSWORT (MIT AUGE) ---
            TextField(
              controller: _passwordController,
              obscureText: !_isLoginPasswordVisible, // State vom Haupt-Widget
              decoration: InputDecoration(
                labelText: 'Passwort',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isLoginPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      // <--- Aktualisiert die ganze Seite
                      _isLoginPasswordVisible = !_isLoginPasswordVisible;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),

            // --- LOGIN BUTTON (ODER LADEKREIS) ---
            _isLoading
                ? const CircularProgressIndicator()
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      onPressed: _login,
                      child: const Text(
                        'Login',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),

            const SizedBox(height: 20),

            // --- LINK ZUM REGISTRIEREN ---
            TextButton(
              onPressed: _showRegistrationDialog, // Öffnet das Pop-up
              child: const Text('Kein Profil? Hier registrieren'),
            ),
          ],
        ),
      ),
    );
  }
}
