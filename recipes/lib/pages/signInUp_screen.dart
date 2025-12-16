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
  // Controller für Login
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  // Status für Login
  bool _isLoading = false;
  bool _isLoginPasswordVisible = false; // Für das Augen-Icon im Login

  // Login Funktion
  Future<void> _login() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(authRepositoryProvider).signIn(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );
      // Navigation wird meistens über einen Router-Listener gehandhabt, 
      // aber falls manuell nötig: context.go('/home');
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

  // --- REGISTRIERUNGS POP-UP ---
  void _showRegistrationDialog() {
    // Eigene Controller für das Pop-up, damit Login-Felder nicht überschrieben werden
    final regUsernameController = TextEditingController();
    final regEmailController = TextEditingController();
    final regPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierDismissible: false, // Man muss auf Abbrechen klicken, um zu schließen
      builder: (context) {
        // StatefulBuilder wird benötigt, damit wir im Pop-up den State (Augen-Icon) ändern können
        return StatefulBuilder(
          builder: (context, setDialogState) {
            bool isRegLoading = false;
            bool isRegPasswordVisible = false;

            // Funktion um State im Dialog zu ändern
            void togglePassword() {
              setDialogState(() {
                isRegPasswordVisible = !isRegPasswordVisible;
              });
            }

            Future<void> register() async {
              if (!formKey.currentState!.validate()) return;
              
              setDialogState(() => isRegLoading = true);
              
              try {
                // Hier rufen wir die Repo-Methode auf. 
                // Hinweis: Dein AuthRepository muss ggf. angepasst werden, um 'username' zu akzeptieren.
                await ref.read(authRepositoryProvider).signUp(
                      email: regEmailController.text.trim(),
                      password: regPasswordController.text.trim(),
                      username: regUsernameController.text.trim(), // Falls dein Repo das unterstützt
                    );

                if (context.mounted) {
                  Navigator.of(context).pop(); // Dialog schließen
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Account erstellt! Bitte einloggen.')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                     SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
                  );
                }
              } finally {
                // Loading im Dialog beenden
                // setDialogState(() => isRegLoading = false); // Nicht zwingend nötig, da Dialog schließt
              }
            }

            return AlertDialog(
              title: const Text("Registrieren"),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min, // Dialog so klein wie möglich halten
                    children: [
                      // USERNAME
                      TextFormField(
                        controller: regUsernameController,
                        decoration: const InputDecoration(
                          labelText: 'Username',
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) => value!.isEmpty ? 'Username benötigt' : null,
                      ),
                      const SizedBox(height: 16),
                      // EMAIL
                      TextFormField(
                        controller: regEmailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) => value!.contains('@') ? null : 'Gültige Email eingeben',
                      ),
                      const SizedBox(height: 16),
                      // PASSWORT (mit Auge im Pop-up)
                      TextFormField(
                        controller: regPasswordController,
                        obscureText: !isRegPasswordVisible,
                        decoration: InputDecoration(
                          labelText: 'Passwort',
                          prefixIcon: const Icon(Icons.lock),
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(isRegPasswordVisible 
                                ? Icons.visibility 
                                : Icons.visibility_off),
                            onPressed: () {
                              // WICHTIG: Wir müssen den State des Dialogs ändern, nicht der Seite
                              setDialogState(() {
                                isRegPasswordVisible = !isRegPasswordVisible;
                              });
                            },
                          ),
                        ),
                        validator: (value) => value!.length < 6 ? 'Passwort muss min. 6 Zeichen haben' : null,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(), // Abbrechen
                  child: const Text("Abbrechen"),
                ),
                isRegLoading
                    ? const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                      )
                    : ElevatedButton(
                        onPressed: register,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                        child: const Text("Registrieren"),
                      ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            const Text("RecipeS", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.orange)),
            const SizedBox(height: 40),
            
            // --- LOGIN EMAIL ---
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email', 
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: 16),
            
            // --- LOGIN PASSWORT (mit Auge) ---
            TextField(
              controller: _passwordController,
              obscureText: !_isLoginPasswordVisible, // Wenn false, ist Text versteckt
              decoration: InputDecoration(
                labelText: 'Passwort', 
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_isLoginPasswordVisible 
                      ? Icons.visibility 
                      : Icons.visibility_off),
                  onPressed: () {
                    setState(() {
                      _isLoginPasswordVisible = !_isLoginPasswordVisible;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // --- LOGIN BUTTON ---
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
                      child: const Text('Login', style: TextStyle(fontSize: 16)),
                    ),
                  ),
            
            const SizedBox(height: 20),
            
            // --- REGISTRIEREN LINK (Öffnet Pop-up) ---
            TextButton(
              onPressed: _showRegistrationDialog, // Ruft das Pop-up auf
              child: const Text('Kein Profil? Hier registrieren'),
            ),
          ],
        ),
      ),
    );
  }
}