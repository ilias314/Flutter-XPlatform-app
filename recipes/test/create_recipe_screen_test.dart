import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipes/pages/create_recipe_screen.dart';

void main() {
  group('CreateRezeptPages Widget Tests', () {
    testWidgets('Alle Formularfelder und Buttons werden angezeigt', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: CreateRezeptPages()));

      expect(find.text('Meines Rezept hinzufügen'), findsOneWidget);
      expect(
        find.byIcon(Icons.cloud_upload),
        findsOneWidget,
        reason: 'Upload-Icon fehlt.',
      );
      expect(find.widgetWithText(TextFormField, 'Rezept Name'), findsOneWidget);
      expect(find.text('Zubereitungszeit (Minuten)'), findsOneWidget);
      expect(find.text('Portionen'), findsOneWidget);
      expect(find.text('Zubereitung:'), findsOneWidget);

      expect(find.text('Einfach'), findsOneWidget);
      expect(find.text('Mittel'), findsOneWidget);
      expect(find.text('Schwer'), findsOneWidget);

      expect(
        find.text('Menge'),
        findsOneWidget,
        reason: 'Das Feld für die Menge sollte einmal sichtbar sein.',
      );
      expect(
        find.text('Einheit'),
        findsOneWidget,
        reason: 'Das Feld für die Einheit sollte einmal sichtbar sein.',
      );

      expect(
        find.widgetWithText(ElevatedButton, 'Rezept speichern'),
        findsOneWidget,
      );
    });

    testWidgets('Neue Zutat kann hinzugefügt werden', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: CreateRezeptPages()));

      final initialCount = tester.widgetList(find.byType(TextField)).length;

      final addButtonTextFinder = find.text('Weitere Zutat hinzufügen');

      await tester.ensureVisible(addButtonTextFinder);
      await tester.pumpAndSettle();

      await tester.tap(addButtonTextFinder);
      await tester.pump();

      final newCount = tester.widgetList(find.byType(TextField)).length;
      expect(
        newCount,
        initialCount + 3,
        reason:
            'Es sollten 3 neue Textfelder für die Zutat hinzugefügt werden.',
      );
    });

    testWidgets('Zutat löschen löst Bestätigungsdialog aus', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: CreateRezeptPages()));

      final addButtonTextFinder = find.text('Weitere Zutat hinzufügen');

      await tester.ensureVisible(addButtonTextFinder);
      await tester.pumpAndSettle();

      await tester.tap(addButtonTextFinder);
      await tester.pump();

      final deleteButtons = find.byIcon(Icons.delete_outline);
      expect(
        deleteButtons,
        findsNWidgets(2),
        reason: 'Es sollten zwei Lösch-Icons gefunden werden.',
      );

      await tester.ensureVisible(deleteButtons.last);
      await tester.pumpAndSettle();

      await tester.tap(deleteButtons.last);
      await tester.pump();

      expect(find.text('Datensatz löschen?'), findsOneWidget);

      await tester.tap(find.text('Nein'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.delete_outline), findsNWidgets(2));

      final deleteButtonsFinal = find.byIcon(Icons.delete_outline);

      await tester.ensureVisible(deleteButtonsFinal.last);
      await tester.pumpAndSettle();

      await tester.tap(deleteButtonsFinal.last);
      await tester.pump();

      await tester.tap(find.text('Ja'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    });
  });
}
