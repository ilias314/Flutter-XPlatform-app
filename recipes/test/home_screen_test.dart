import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipes/pages/home_screen.dart';

void main() {
  group('StartseitePages Widget Tests', () {
    testWidgets('Struktur der Startseite wird korrekt angezeigt', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: StartseitePages()));

      expect(
        find.text('RecipeS'),
        findsOneWidget,
        reason: 'Der Titel der App sollte sichtbar sein.',
      );

      expect(
        find.byIcon(Icons.search),
        findsOneWidget,
        reason: 'Das Such-Icon sollte sichtbar sein.',
      );

      expect(
        find.text('Top Rezepte je nach Profil'),
        findsOneWidget,
        reason: 'Der Top Rezepte nach Profil-Abschnitt sollte vorhanden sein.',
      );

      expect(
        find.text('Neueste Rezepte der Woche'),
        findsOneWidget,
        reason: 'Der Neueste Rezepte-Abschnitt sollte vorhanden sein.',
      );

      expect(
        find.text('Top Rezepte des Monats'),
        findsOneWidget,
        reason: 'Der Top Rezepte des Monats-Abschnitt sollte vorhanden sein.',
      );
    });

    testWidgets('Klick auf das Such-Icon löst eine Aktion aus (Placeholder)', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              actions: [
                IconButton(
                  key: const Key('searchIconButton'),
                  icon: const Icon(Icons.search),
                  onPressed: () {},
                ),
              ],
            ),
            body: const StartseitePages(),
          ),
        ),
      );

      final searchIconFinder = find.byKey(const Key('searchIconButton'));

      expect(
        searchIconFinder,
        findsOneWidget,
        reason: 'Das Such-Icon in der AppBar muss eindeutig gefunden werden.',
      );

      await tester.tap(searchIconFinder);
      await tester.pump();
    });
  });
}
