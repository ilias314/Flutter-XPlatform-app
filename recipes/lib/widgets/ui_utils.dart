import 'package:flutter/material.dart';

/// Funktion zum Anzeigen eines Snackbars mit einer "Noch nicht implementiert"-Nachricht.
void showNotImplementedSnackbar(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Noch nicht implementiert.'),
      duration: Duration(milliseconds: 1000),
    ),
  );
}

/// Helferfunktion zum Simulieren der Navigation zwischen Seiten, die noch nicht existieren.
void navigateToPlaceholderPage(BuildContext context, String pageName) {
  // Hier zeigen wir die Nachricht an, aber in der echten Anwendung würden wir zur Seite navigieren.
  showNotImplementedSnackbar(context);
  // Beispiel für zukünftige Navigation:
  // if (pageName == 'Profil') {
  //   Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfilPages()));
  // }
}