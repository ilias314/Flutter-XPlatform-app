import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async'; 

// Import your screens
import 'main_scaffold.dart'; 
import 'pages/login_screen.dart';
import 'pages/register_screen.dart';
import 'pages/search_screen.dart';
import 'main_scaffold.dart';

final router = GoRouter(
  initialLocation: '/',
  
  // Listen to Auth Changes
  refreshListenable: GoRouterRefreshStream(Supabase.instance.client.auth.onAuthStateChange),

  routes: [
    // 1. HOME (Private)
    // We do NOT pass a child. MainScaffold handles the tabs internally.
    GoRoute(
      path: '/',
      builder: (context, state) => const MainScaffold(), 
    ),

    // 2. LOGIN (Public)
    // We do NOT wrap this in MainScaffold. It should be full screen.
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),

    // 3. SIGNUP (Public)
    GoRoute(
      path: '/signup',
      builder: (context, state) => const SignupScreen(),
    ),

    // 4. SEARCH (Standalone)
    // Usually, search is a full-screen page that sits on top of everything.
    GoRoute(
      path: '/search',
      builder: (context, state) => const SearchScreen(),
    ),
  ],

  // THE GUARD (Bouncer)
  redirect: (context, state) {
    final session = Supabase.instance.client.auth.currentSession;
    
    // Check where the user is trying to go
    final isLoggingIn = state.uri.toString() == '/login';
    final isSigningUp = state.uri.toString() == '/signup';
    final userIsLoggedIn = session != null;

    // Rule 1: If NOT logged in, and trying to go to a private page -> Force Login
    if (!userIsLoggedIn && !isLoggingIn && !isSigningUp) {
      return '/login';
    }

    // Rule 2: If ALREADY logged in, and trying to go to Login -> Force Home
    if (userIsLoggedIn && (isLoggingIn || isSigningUp)) {
      return '/';
    }

    return null; 
  },
);

// HELPER CLASS
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