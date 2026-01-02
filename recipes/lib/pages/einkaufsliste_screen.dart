import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EinkaufslisteScreen extends StatefulWidget {
  const EinkaufslisteScreen({super.key});

  @override
  State<EinkaufslisteScreen> createState() => _EinkaufslisteScreenState();
}

class _EinkaufslisteScreenState extends State<EinkaufslisteScreen> {
  final client = Supabase.instance.client;
  List<Map<String, dynamic>> _items = [];
  bool _isLoading = true;

  // Für die Mehrfachauswahl
  final Set<String> _selectedIds = {};
  bool _isSelectionMode = false;

  @override
  void initState() {
    super.initState();
    _fetchItems();
  }

  Future<void> _fetchItems() async {
    try {
      final data = await client
          .from('shopping_list_items')
          .select()
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _items = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Erreur de chargement: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- ACTIONS ---

  Future<String> _getShoppingListId() async {
    final userId = client.auth.currentUser!.id;

    final list = await client
        .from('shopping_lists')
        .upsert({'user_id': userId, 'name': 'Meine Liste'})
        .select()
        .maybeSingle();

    return list?['id'];
  }

  Future<void> _updateQuantity(
    String id,
    double currentQty,
    double change,
  ) async {
    final newQty = currentQty + change;
    if (newQty <= 0) return;
    await client
        .from('shopping_list_items')
        .update({'quantity': newQty})
        .eq('id', id);
    _fetchItems();
  }

  Future<void> _deleteSelectedItems() async {
    try {
      await client
          .from('shopping_list_items')
          .delete()
          .inFilter('id', _selectedIds.toList());

      setState(() {
        _selectedIds.clear();
        _isSelectionMode = false;
      });
      _fetchItems();
    } catch (e) {
      debugPrint("Erreur suppression: $e");
    }
  }

  Future<void> upsertShoppingItem({
    required String listId,
    String? ingredientId,
    required String name,
    required double quantity,
    required String unit,
  }) async {
    final normalizedName = normalize(name);
    final normalizedUnit = normalize(unit);

    final baseQuery = client
        .from('shopping_list_items')
        .select()
        .eq('shopping_list_id', listId)
        .eq('is_checked', false);

    final existing = ingredientId != null
        ? await baseQuery.eq('ingredient_id', ingredientId).maybeSingle()
        : await baseQuery
              .eq('normalized_name', normalizedName)
              .eq('unit', normalizedUnit)
              .maybeSingle();

    if (existing != null) {
      final oldQty = (existing['quantity'] ?? 0).toDouble();
      await client
          .from('shopping_list_items')
          .update({'quantity': oldQty + quantity})
          .eq('id', existing['id']);
    } else {
      await client.from('shopping_list_items').insert({
        'shopping_list_id': listId,
        'ingredient_id': ingredientId,
        'custom_name': name,
        'normalized_name': normalizedName,
        'quantity': quantity,
        'unit': normalizedUnit,
        'is_checked': false,
      });
    }

    await _fetchItems();
  }

  Future<void> _addItemAggregated(String name, double qty, String unit) async {
    final listId = await _getShoppingListId();

    await upsertShoppingItem(
      listId: listId,
      ingredientId: null, // manual item
      name: name,
      quantity: qty,
      unit: unit,
    );
  }

  // --- UI HELPER ---

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        if (_selectedIds.isEmpty) _isSelectionMode = false;
      } else {
        _selectedIds.add(id);
        _isSelectionMode = true;
      }
    });
  }

  String normalize(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isSelectionMode
              ? "${_selectedIds.length} ausgewählt"
              : "Einkaufsliste",
        ),
        actions: _isSelectionMode
            ? [
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: _deleteSelectedItems,
                ),
              ]
            : null,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddManualDialog,
        backgroundColor: Colors.orange,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
          ? const Center(child: Text("Deine Liste ist leer."))
          : ListView.builder(
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                final String id = item['id'];
                final bool isSelected = _selectedIds.contains(id);

                return ListTile(
                  selected: isSelected,
                  selectedTileColor: Colors.orange.withOpacity(0.1),
                  onLongPress: () => _toggleSelection(id),
                  onTap: () {
                    if (_isSelectionMode) {
                      _toggleSelection(id);
                    }
                  },
                  leading: _isSelectionMode
                      ? Checkbox(
                          value: isSelected,
                          onChanged: (_) => _toggleSelection(id),
                        )
                      : Checkbox(
                          value: item['is_checked'] ?? false,
                          onChanged: (val) async {
                            await client
                                .from('shopping_list_items')
                                .update({'is_checked': val})
                                .eq('id', id);
                            _fetchItems();
                          },
                        ),
                  title: Text("${item['custom_name']} (${item['unit']})"),
                  trailing: _isSelectionMode
                      ? null
                      : _buildQuantityPicker(item),
                );
              },
            ),
    );
  }

  Widget _buildQuantityPicker(Map<String, dynamic> item) {
    final double qty = (item['quantity'] ?? 0).toDouble();
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.brown.shade200),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove, size: 18),
            onPressed: () => _updateQuantity(item['id'], qty, -1),
          ),
          Text(qty % 1 == 0 ? qty.toInt().toString() : qty.toStringAsFixed(1)),
          IconButton(
            icon: const Icon(Icons.add, size: 18),
            onPressed: () => _updateQuantity(item['id'], qty, 1),
          ),
        ],
      ),
    );
  }

  // --- DIALOG ---

  void _showAddManualDialog() {
    final nameCtrl = TextEditingController();
    final qtyCtrl = TextEditingController(text: "1");
    final unitCtrl = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false, 
      builder: (context) => AlertDialog(
        title: const Text("Zutat hinzufügen"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: "Name"),
            ),
            TextField(
              controller: qtyCtrl,
              decoration: const InputDecoration(labelText: "Menge"),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: unitCtrl,
              decoration: const InputDecoration(labelText: "Einheit"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Abbrechen"),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              final qty = double.tryParse(qtyCtrl.text) ?? 1.0;
              if (name.isNotEmpty) {
                Navigator.pop(
                  context,
                ); 
                await _addItemAggregated(name, qty, unitCtrl.text.trim());
              }
            },
            child: const Text("Hinzufügen"),
          ),
        ],
      ),
    );
  }
}
