
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  // 1. Prepare Flutter to run async code
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Connect to Supabase
  await Supabase.initialize(
    url: 'https://usfrnaywpgtfgqodzqsn.supabase.co', 
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVzZnJuYXl3cGd0Zmdxb2R6cXNuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjUwMzY2OTUsImV4cCI6MjA4MDYxMjY5NX0.Hjd7exAONRd9zMj_s24oqHqSB6Wr1MNSM3dWB7dEDNI',
  );

  // 3. Start the App
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Text(
            'Supabase is Connected!', 
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
