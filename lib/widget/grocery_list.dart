import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shopping_list/data/categories.dart';
import 'package:shopping_list/models/grocery_item.dart';
import 'package:shopping_list/widget/new_item.dart';

class GroceryList extends StatefulWidget {
  const GroceryList({super.key});

  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  List<GroceryItem> _groceryItem = [];

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  void _loadItems() async {
    final url = Uri.https(
      'shopping-list-942a2-default-rtdb.firebaseio.com',
      'shopping-list.json',
    );
    final response = await http.get(url);
    final Map<String, dynamic> listData = json.decode(response.body);
    final List<GroceryItem> loadItems = [];
    for (final item in listData.entries) {
      final category =
          categories.entries
              .firstWhere(
                (catItem) => catItem.value.title == item.value['category'],
              )
              .value;
      loadItems.add(
        GroceryItem(
          id: item.key,
          name: item.value['name'],
          quantity: item.value['quantity'],
          category: category,
        ),
      );
    }
    setState(() {
      _groceryItem = loadItems;
    });
  }

  void _addItem() async {
    final newItem = await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (ctx) => NewItem()));
    if (newItem == null) {
      return;
    }
    setState(() {
      _groceryItem.add(newItem);
    });
  }

  void _deleteItem(GroceryItem item) {
    _groceryItem.remove(item);
  }

  @override
  Widget build(BuildContext context) {
    Widget content = const Center(child: Text('No Items added Yet'));
    if (_groceryItem.isNotEmpty) {
      content = ListView.builder(
        itemCount: _groceryItem.length,
        itemBuilder:
            (ctx, index) => Dismissible(
              onDismissed: (direction) {
                _deleteItem(_groceryItem[index]);
              },
              key: ValueKey(_groceryItem[index].id),
              child: ListTile(
                title: Text(_groceryItem[index].name),
                leading: Container(
                  width: 24,
                  height: 24,
                  color: _groceryItem[index].category.color,
                ),
                trailing: Text(_groceryItem[index].quantity.toString()),
              ),
            ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('GroceryItems'),

        actions: [IconButton(onPressed: _addItem, icon: Icon(Icons.add))],
      ),
      body: content,
    );
  }
}
