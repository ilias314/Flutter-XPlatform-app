import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '/data/auth_repository.dart'; // Import your Auth Repository

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text("Profile")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 50,
              child: Icon(Icons.person, size: 50),
            ),
            const SizedBox(height: 20),
            const Text(
              "User Profile",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            
            // --- THE LOGOUT BUTTON ---
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, // Red for "Danger/Exit"
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.logout),
              label: const Text("Sign Out"),
              onPressed: () async {
                // 1. Call the logic
                await ref.read(authRepositoryProvider).signOut();
                
                // 2. Do NOTHING else. 
                // The router.dart is listening to Supabase. 
                // It will see "User = null" and instantly force the app to '/login'.
              },
            ),
          ],
        ),
      ),
    );
  }
}