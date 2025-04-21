// Import required packages
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shopping_list/data/categories.dart';
import 'package:shopping_list/models/grocery_item.dart';
import 'package:shopping_list/widget/new_item.dart';

// Main GroceryList widget (stateful)
class GroceryList extends StatefulWidget {
  const GroceryList({super.key});

  @override
  State<GroceryList> createState() => _GroceryListState();
}

// State class for GroceryList widget
class _GroceryListState extends State<GroceryList> {
  // List to store grocery items
  List<GroceryItem> _groceryItem = [];
  // Boolean to check if data is being loaded
  var _isLoading = true;
  // Variable to store error message
  String? _error;

  @override
  void initState() {
    super.initState();
    // Load items from database when the widget is first created
    _loadItems();
  }

  // Function to load grocery items from Firebase Realtime Database
  void _loadItems() async {
    final url = Uri.https(
      'shopping-list-942a2-default-rtdb.firebaseio.com',
      'shopping-list.json',
    );
    try {
      // Send GET request to fetch data
      final response = await http.get(url);
      // Check if there’s a server error
      if (response.statusCode >= 400) {
        setState(() {
          _error = 'Failed To Fetch Data, Please try again later.';
        });
      }
      // If no data found
      if (response.body == 'null') {
        setState(() {
          _isLoading = false;
        });
        return;
      }
      // Decode the JSON response
      final Map<String, dynamic> listData = json.decode(response.body);
      final List<GroceryItem> loadItems = [];

      // Loop through each item from the response and convert to GroceryItem object
      for (final item in listData.entries) {
        // Find the category by matching the title
        final category =
            categories.entries
                .firstWhere(
                  (catItem) => catItem.value.title == item.value['category'],
                )
                .value;
        // Add item to the list
        loadItems.add(
          GroceryItem(
            id: item.key,
            name: item.value['name'],
            quantity: item.value['quantity'],
            category: category,
          ),
        );
      }
      // Update the state with loaded items
      setState(() {
        _groceryItem = loadItems;
        _isLoading = false;
      });
    } catch (error) {
      // Handle errors
      setState(() {
        _error = 'Something Went Wrong! Please try again later.';
      });
    }
  }

  // Function to add a new item
  void _addItem() async {
    // Navigate to NewItem screen and wait for the result
    final newItem = await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (ctx) => NewItem()));
    // If no item was added, return
    if (newItem == null) {
      return;
    }
    // Add the new item to the list
    setState(() {
      _groceryItem.add(newItem);
    });
  }

  // Function to delete an item from both the list and database
  void _deleteItem(GroceryItem item) async {
    final index = _groceryItem.indexOf(item);
    // Remove item from local list
    setState(() {
      _groceryItem.remove(item);
    });
    final url = Uri.https(
      'shopping-list-942a2-default-rtdb.firebaseio.com',
      'shopping-list/${item.id}.json',
    );
    // Send DELETE request to remove item from database
    final response = await http.delete(url);
    // If delete fails, put the item back and show error message
    if (response.statusCode >= 400) {
      setState(() {
        _groceryItem.insert(index, item);
      });
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed To Delete, Please Try again later.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Widget to display content based on the state
    Widget content = const Center(child: Text('No Items added yet.'));

    // If data is still loading, show a loading indicator
    if (_isLoading) {
      content = const Center(child: CircularProgressIndicator());
    }

    // If there are grocery items, show them in a ListView
    if (_groceryItem.isNotEmpty) {
      content = ListView.builder(
        itemCount: _groceryItem.length,
        itemBuilder:
            (ctx, index) => Dismissible(
              onDismissed: (direction) {
                // Delete the item when dismissed
                _deleteItem(_groceryItem[index]);
              },
              key: ValueKey(_groceryItem[index].id),
              child: ListTile(
                title: Text(_groceryItem[index].name),
                leading: Container(
                  width: 24,
                  height: 24,
                  // Display color based on category
                  color: _groceryItem[index].category.color,
                ),
                trailing: Text(_groceryItem[index].quantity.toString()),
              ),
            ),
      );
    }

    // If an error occurred, display the error message
    if (_error != null) {
      content = Center(child: Text(_error!));
    }

    // Return the main UI structure
    return Scaffold(
      appBar: AppBar(
        title: const Text('GroceryItems'),
        actions: [
          // Button to add new item
          IconButton(onPressed: _addItem, icon: Icon(Icons.add)),
        ],
      ),
      body: content,
    );
  }
}
