import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:recipes/models/recipe.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'main_scaffold.dart';
import 'pages/login_screen.dart';
import 'pages/search_screen.dart';
import 'pages/recipe_detail_screen.dart';
import 'pages/favorite_list_screen.dart';
import 'pages/my_recipes_list_screen.dart';
import 'pages/create_recipe_screen.dart';
import 'pages/all_recipes_screen.dart';
import 'models/allRecipes.dart';

final router = GoRouter(
  initialLocation: '/',
  refreshListenable: GoRouterRefreshStream(
    Supabase.instance.client.auth.onAuthStateChange,
  ),

  routes: [
    GoRoute(path: '/', builder: (context, state) => const MainScaffold()),
    GoRoute(
      path: '/create-recipe',
      builder: (context, state) => const CreateRezeptPages(),
    ),
    GoRoute(
      path: '/edit-recipe',
      builder: (context, state) {
        final recipe = state.extra as Recipe;
        return CreateRezeptPages(recipeToEdit: recipe);
      },
    ),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(path: '/search', builder: (context, state) => const SearchScreen()),

    GoRoute(
      path: '/recipes/:id',
      builder: (context, state) {
        final id = state.pathParameters['id'];
        return RecipeDetailScreen(recipeId: id!);
      },
    ),

    GoRoute(
      path: '/favorites', 
      builder: (context, state) => const FavoriteListScreen(),
    ),

    GoRoute(
      path: '/my-recipes', 
      builder: (context, state) => const MyRecipesListScreen(),
    ),
    GoRoute(
      path: '/all-recipes',
      builder: (context, state) {
        final args = state.extra as AllRecipesArgs;
        return AllRecipesScreen(args: args);
      },
    ),
  ],

  redirect: (context, state) {
    final session = Supabase.instance.client.auth.currentSession;

    final isLoggingIn = state.uri.toString() == '/login';

    final userIsLoggedIn = session != null;

    if (!userIsLoggedIn && !isLoggingIn) {
      return '/login';
    }

    if (userIsLoggedIn && isLoggingIn) {
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
