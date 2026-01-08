import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/auth_repository.dart';

enum DishPreference { alles, pescetarisch, vegetarisch, vegan }

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

String preferenceToString(DishPreference pref) {
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

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isLoginPasswordVisible = false;
  final _loginFormKey = GlobalKey<FormState>();
  String? _loginError;


  Future<void> _login() async {
    FocusScope.of(context).unfocus();

    if (!_loginFormKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ref
          .read(authRepositoryProvider)
          .signIn(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );
    } catch (e) {
        setState(() {
          _loginError = 'Email oder Passwort falsch';
        });

        _loginFormKey.currentState!.validate();
      } finally {
      if (mounted) setState(() => _isLoading = false);
    }
    _loginError = null;

  }

  void _showRegistrationDialog() {
    final regUsernameController = TextEditingController();
    final regEmailController = TextEditingController();
    final regPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        bool isRegLoading = false;
        bool isRegPasswordVisible = false;
        DishPreference selectedPreference = DishPreference.alles;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> register() async {
              if (!formKey.currentState!.validate()) return;

              setDialogState(() => isRegLoading = true);

              try {
                await ref
                    .read(authRepositoryProvider)
                    .signUp(
                      email: regEmailController.text.trim(),
                      password: regPasswordController.text.trim(),
                      username: regUsernameController.text.trim(),
                      dietaryPreference: preferenceToString(selectedPreference),
                    );
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.toString()),
                      backgroundColor: Colors.red,
                    ),
                  );
                  setDialogState(() => isRegLoading = false);
                }
              }
            }

            return AlertDialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              title: const Text("Registrieren"),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
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

                      TextFormField(
                        controller: regPasswordController,
                        obscureText: !isRegPasswordVisible,
                        decoration: InputDecoration(
                          labelText: 'Passwort',
                          prefixIcon: const Icon(Icons.lock),
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(
                              isRegPasswordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setDialogState(() {
                                isRegPasswordVisible = !isRegPasswordVisible;
                              });
                            },
                          ),
                        ),
                        validator: (value) =>
                            value!.length < 6 ? 'Min. 6 Zeichen' : null,
                      ),
                      const SizedBox(height: 16),

                      DropdownButtonFormField<DishPreference>(
                        value: selectedPreference,
                        decoration: const InputDecoration(
                          labelText: 'Ernährungsweise',
                          prefixIcon: Icon(Icons.eco),
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: DishPreference.alles,
                            child: Text('Alles'),
                          ),
                          DropdownMenuItem(
                            value: DishPreference.pescetarisch,
                            child: Text('Pescetarisch'),
                          ),
                          DropdownMenuItem(
                            value: DishPreference.vegetarisch,
                            child: Text('Vegetarisch'),
                          ),
                          DropdownMenuItem(
                            value: DishPreference.vegan,
                            child: Text('Vegan'),
                          ),
                        ],
                        onChanged: (value) {
                          setDialogState(() {
                            selectedPreference = value!;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("Abbrechen"),
                ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _loginFormKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
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

              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Email erforderlich';
                  }
                  if (!value.contains('@')) {
                    return 'Ungültige Email';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _passwordController,
                obscureText: !_isLoginPasswordVisible,
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
                        _isLoginPasswordVisible = !_isLoginPasswordVisible;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Passwort erforderlich';
                  }
                  if (value.length < 6) {
                    return 'Mindestens 6 Zeichen';
                  }
                  if (_loginError != null) {
                    return _loginError;
                  }
                  return null;
                },
                onChanged: (_) {
                  if (_loginError != null) {
                    setState(() {
                      _loginError = null;
                    });
                  }
                },
              ),

              const SizedBox(height: 24),

              _isLoading
                  ? const CircularProgressIndicator()
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Login'),
                      ),
                    ),

              const SizedBox(height: 20),

              TextButton(
                onPressed: _showRegistrationDialog,
                child: const Text('Kein Profil? Hier registrieren'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
