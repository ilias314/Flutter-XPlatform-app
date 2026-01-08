import 'package:flutter/material.dart';

void showNotImplementedSnackbar(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Noch nicht implementiert.'),
      duration: Duration(milliseconds: 1000),
    ),
  );
}

void navigateToPlaceholderPage(BuildContext context, String pageName) {
  showNotImplementedSnackbar(context);
}