import 'package:flutter/material.dart';
import 'package:recipes/widgets/ui_utils.dart'; 

/// Eine spezielle Version der Rezeptkarte, die für den Wochenplan
/// optimiert ist (Layout: Bild links, Textdetails rechts).
class WochenplanRecipeCard extends StatelessWidget {
  const WochenplanRecipeCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2.0,
      child: InkWell(
        onTap: () => showNotImplementedSnackbar(context),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start, 
            children: <Widget>[
              
              // 1. Linke Seite: Bild-Placeholder (GRÖSSE WIRD HIER ANGEPASST)
              Container(
                // ANPASSUNG DER BREITE: Hier können Sie die Zahl ändern, z.B. 140
                width: 200, // Erhöhte Breite für die Foto-Anzeige
                height: double.infinity, 
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(4.0),
                  color: Colors.grey.shade100,
                ),
                child: const Center(
                  child: Icon(
                    Icons.photo_size_select_actual_outlined,
                    size: 40, // Optional: Icon-Größe anpassen
                    color: Colors.grey,
                  ),
                ),
              ),
              
              const SizedBox(width: 10.0), 
              
              // 2. Rechte Seite: Textdetails
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, 
                  mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                  children: <Widget>[
                    
                    // A. Name des Rezepts und Favoriten-Icon
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text(
                            'Name des Rezepts', 
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        const Icon(Icons.favorite_border, size: 20),
                      ],
                    ),
                    const SizedBox(width: 5),
                    // B. Bewertung und Schwierigkeit 
                    const Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber, size: 15),
                        Text('4.5', style: TextStyle(fontSize: 12)),
                        SizedBox(width: 15),
                        Text('Einfach', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                    const SizedBox(width: 5),
                    // C. Zeit und Gerichttyp
                    const Row(
                      children: [
                        Icon(Icons.timer, size: 13),
                        Text('Zeit', style: TextStyle(fontSize: 12)),
                        SizedBox(width: 15),
                        Icon(Icons.restaurant, size: 13),
                        Text('Gerichttyp', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                    const SizedBox(width: 5),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}