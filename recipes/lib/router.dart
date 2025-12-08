import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'pages/login_screen.dart';
import 'pages/register_screen.dart';
import 'main_scaffold.dart'; // From previous response

final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const MainScaffold(), // Your Home/Tabs
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
  // THE GUARD: This redirects the user automatically
  redirect: (context, state) {
    final session = Supabase.instance.client.auth.currentSession;
    final isOnLogin = state.uri.toString() == '/login';
    final isOnSignup = state.uri.toString() == '/signup';

    // If NOT logged in, and trying to go somewhere else -> Send to Login
    if (session == null && !isOnLogin && !isOnSignup) {
      return '/login';
    }

    // If logged in, and trying to go to Login -> Send to Home
    if (session != null && (isOnLogin || isOnSignup)) {
      return '/';
    }

    return null; // No redirect needed
  },
);