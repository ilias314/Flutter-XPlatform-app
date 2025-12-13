import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // 1. Import Riverpod
import 'router.dart'; // 2. Import the router we created
import 'package:flutter_localizations/flutter_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    // Keep your actual keys here!
    url: 'https://usfrnaywpgtfgqodzqsn.supabase.co', 
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVzZnJuYXl3cGd0Zmdxb2R6cXNuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjUwMzY2OTUsImV4cCI6MjA4MDYxMjY5NX0.Hjd7exAONRd9zMj_s24oqHqSB6Wr1MNSM3dWB7dEDNI',
  );

  // 3. Wrap MyApp with ProviderScope so the whole app can use Providers
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 4. Use .router instead of standard MaterialApp
    return MaterialApp.router(
      routerConfig: router, // Connects to the logic in router.dart
      debugShowCheckedModeBanner: false,
      title: 'Rezepte App',
      //  Hinzufügen der Lokalisierungs-Einstellungen
      localizationsDelegates: const [
        // Standarddelegierte für Material-Widgets (z.B. DatePicker-Texte)
        GlobalMaterialLocalizations.delegate, 
        // Standarddelegierte für generische Widgets
        GlobalWidgetsLocalizations.delegate,  
        // Standarddelegierte für iOS-ähnliche Widgets
        GlobalCupertinoLocalizations.delegate, 
      ],
      // Unterstützte Sprachen (muss 'de' enthalten, da wir die de-DE Locale im DatePicker verwenden)
      supportedLocales: const [
        Locale('en', 'US'), // Englisch
        Locale('de', 'DE'), // Deutsch
      ],
      // Optional: Setzt die Standard-Locale der App auf Deutsch
      // Dadurch werden Dinge wie Zeitformate standardmäßig auf Deutsch angezeigt.
      locale: const Locale('de', 'DE'),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
        useMaterial3: true,
      ),
    );
  }
}