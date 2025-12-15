import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async'; 

// Import your screens
import 'main_scaffold.dart'; 
import 'pages/login_screen.dart';
import 'pages/register_screen.dart';
import 'pages/search_screen.dart';
import 'pages/recipe_detail_screen.dart'; 
import 'pages/favorite_list_screen.dart';


final router = GoRouter(
  initialLocation: '/',
  refreshListenable: GoRouterRefreshStream(Supabase.instance.client.auth.onAuthStateChange),

  routes: [
    // 1. HOME
    GoRoute(
      path: '/',
      builder: (context, state) => const MainScaffold(), 
    ),

    // 2. LOGIN
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),

    // 3. SIGNUP
    GoRoute(
      path: '/signup',
      builder: (context, state) => const SignupScreen(),
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
  ],

  redirect: (context, state) {
    final session = Supabase.instance.client.auth.currentSession;
    final isLoggingIn = state.uri.toString() == '/login';
    final isSigningUp = state.uri.toString() == '/signup';
    final userIsLoggedIn = session != null;

    if (!userIsLoggedIn && !isLoggingIn && !isSigningUp) {
      return '/login';
    }

    if (userIsLoggedIn && (isLoggingIn || isSigningUp)) {
      return '/';
    }

    return null; 
  },
);

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