import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async'; // Required for the stream listener

// 1. Correct Imports based on your new structure
import 'main_scaffold.dart'; 
import 'pages/login_screen.dart';
import 'pages/register_screen.dart';

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
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/signup',
      builder: (context, state) => const SignupScreen(),
    ),
  ],

  // THE GUARD: Protects private pages
  redirect: (context, state) {
    final session = Supabase.instance.client.auth.currentSession;
    
    // Check where the user is trying to go
    final isLoggingIn = state.uri.toString() == '/login';
    final isSigningUp = state.uri.toString() == '/signup';
    final userIsLoggedIn = session != null;

    // Rule 1: Not logged in? Kick to Login.
    if (!userIsLoggedIn && !isLoggingIn && !isSigningUp) {
      return '/login';
    }

    // Rule 2: Already logged in? Kick to Home.
    if (userIsLoggedIn && (isLoggingIn || isSigningUp)) {
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