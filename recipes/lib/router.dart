import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async'; // Required for the stream listener

import 'main_scaffold.dart'; 
import 'pages/login_screen.dart';
import 'pages/search_screen.dart';
import 'pages/recipe_detail_screen.dart'; 
import 'pages/favorite_list_screen.dart';
import 'pages/my_recipes_list_screen.dart';
import 'pages/create_recipe_screen.dart';
 

final router = GoRouter(
  initialLocation: '/',
  
  // ⚡️ CRITICAL ADDITION: This forces the router to re-evaluate 
  // the 'redirect' logic immediately when the user logs in or out.
  refreshListenable: GoRouterRefreshStream(Supabase.instance.client.auth.onAuthStateChange),

  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const MainScaffold(), 
    ),
    GoRoute(
      path: '/create-recipe',
      builder: (context, state) => const CreateRezeptPages(), 
    ),
    GoRoute(
      path: '/login',
      // Wir nutzen jetzt hier deinen neuen Screen, der beides kann (Login + Popup Register)
      builder: (context, state) => const LoginScreen(), 
    ),
    // 4. SEARCH
    GoRoute(
      path: '/search',
      builder: (context, state) => const SearchScreen(),
    ),

    // 5. RECIPE DETAIL (The Missing Route)
    GoRoute(
      path: '/recipes/:id',
      builder: (context, state) {
        // We extract the ID from the URL (e.g. "c5b9...")
        final id = state.pathParameters['id'];
        // Pass the ID to the screen
        return RecipeDetailScreen(recipeId: id!);
      },
    ),

    //6. Favorite Liste
    GoRoute(
      path: '/favorites',  // Darauf wartet dein Burger-Menü
      builder: (context, state) => const FavoriteListScreen(),
    ),

    //7. myRecipes Liste
    GoRoute(
      path: '/my-recipes', // Der Pfad für "Meine Rezepte"
      builder: (context, state) => const MyRecipesListScreen(),
    ),


  ],

  // THE GUARD: Protects private pages
  redirect: (context, state) {
    final session = Supabase.instance.client.auth.currentSession;
    
    // Check where the user is trying to go
    final isLoggingIn = state.uri.toString() == '/login';
    // isSigningUp Check ist nicht mehr nötig, da es keine separate Page ist.
    
    final userIsLoggedIn = session != null;

    // Rule 1: Not logged in? Kick to Login.
    if (!userIsLoggedIn && !isLoggingIn) {
      return '/login';
    }

    // Rule 2: Already logged in? Kick to Home.
    if (userIsLoggedIn && isLoggingIn) {
      return '/';
    }

    // No rules broken? Let them pass.
    return null; 
  },
);

// 🛠️ HELPER CLASS
// This converts the Supabase Stream into something GoRouter can listen to.
class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<AuthState> _subscription;

  GoRouterRefreshStream(Stream<AuthState> stream) {
    notifyListeners();
    _subscription = stream.listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}