import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MyRecipesListScreen extends StatelessWidget {
  const MyRecipesListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meine Rezepte'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
      ),
      body: const Center(
        child: Text('Hier stehen deine eigenen Rezepte.'),
      ),
      // Optional: Ein Button zum Erstellen neuer Rezepte
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Logik zum Erstellen hinzufügen
          print("Neues Rezept erstellen");
        },
        backgroundColor: Colors.orange,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}