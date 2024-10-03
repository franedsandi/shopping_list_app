import 'dart:convert';
import '../data/categories.dart';
import 'package:flutter/material.dart';
import 'package:shopping_list_app/widgets/new_item.dart';
import '../models/grocery_item.dart';
import 'package:http/http.dart' as http;

class GroseryList extends StatefulWidget {
  const GroseryList({super.key});

  @override
  State<GroseryList> createState() => _GroseryListState();
}

class _GroseryListState extends State<GroseryList> {
  /* var _isLoading = true; */

  String? _error;
  List<GroceryItem> _groceryItems = [];
  late Future<List<GroceryItem>> _loadedItems;
  @override
  void initState() {
    super.initState();
    _loadedItems = _loadItems();
  }

  Future<List<GroceryItem>> _loadItems() async {
    final url = Uri.https(
        'flutter-test-30dc3-default-rtdb.firebaseio.com', 'shopping-list.json');

/*     try { */
    final response = await http.get(url);
    if (response.statusCode >= 400) {
      throw Exception('Failed to get data');
/*       setState(() {
        _error = "error on loading the data, please try again later";
      }); */
    }

    if (response.body == 'null') {
/*       setState(() {
        _isLoading = false;
      }); */
      return [];
    }
    final Map<String, dynamic> listData = json.decode(response.body);
    final List<GroceryItem> loadedItems = [];
    for (final item in listData.entries) {
      final category = categories.entries
          .firstWhere(
              (catItem) => catItem.value.title == item.value['category'])
          .value;
      loadedItems.add(
        GroceryItem(
          id: item.key,
          name: item.value['name'],
          quantity: item.value['quantity'],
          category: category,
        ),
      );
    }
    return loadedItems;
    /* setState(() {
        _groceryItems = loadedItems;
        _isLoading = false;
      }); */
    /* } catch (error) {
      setState(
        () {
          _error =
              "Something went wrong while loading the data, please try again later";
        },
      );
    } */
  }

  void _addItem() async {
    final newItem = await Navigator.of(context).push<GroceryItem>(
      MaterialPageRoute(
        builder: (ctx) => const NewItem(),
      ),
    );

    if (newItem == null) {
      return;
    }

    setState(() {
      _groceryItems.add(newItem);
    });
    _loadItems();
  }

  void _removeItem(GroceryItem item) async {
    final groceryIndex = _groceryItems.indexOf(item);
    setState(() {
      _groceryItems.remove(item);
    });
    final url = Uri.https('flutter-test-30dc3-default-rtdb.firebaseio.com',
        'shopping-list/${item.id}.json');
    final response = await http.delete(url);
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: const Text('Item deleted'),
        duration: const Duration(seconds: 3),
      ),
    );

    if (response.statusCode >= 400) {
      setState(() {
        _groceryItems.insert(groceryIndex, item);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
/*     Widget content = const Center(
      child: Text('No items added yet'),
    ); */
    /* if (_isLoading) {
      content = const Center(
        child: CircularProgressIndicator(),
      );
    } */

    /*  if (_groceryItems.isNotEmpty) {
      content = ListView.builder(
        itemCount: _groceryItems.length,
        itemBuilder: (ctx, index) => Dismissible(
          onDismissed: (direction) {
            _removeItem(_groceryItems[index]);
          },
          key: ValueKey(
            _groceryItems[index].id,
          ),
          child: ListTile(
            title: Text(_groceryItems[index].name),
            leading: Container(
              width: 24,
              height: 24,
              color: _groceryItems[index].category.color,
            ),
            trailing: Text(
              _groceryItems[index].quantity.toString(),
            ),
          ),
        ),
      );
    } */
    /* if (_error != null) {
      content = Center(child: Text(_error!));
    } */
    return Scaffold(
      appBar: AppBar(
        title: const Text('Grocery List'),
        actions: [
          IconButton(
            onPressed: _addItem,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: FutureBuilder(
        future: _loadedItems,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }
          if (snapshot.data!.isEmpty) {
            return const Center(
              child: Text('No items added yet'),
            );
          }
          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (ctx, index) => Dismissible(
              onDismissed: (direction) {
                _removeItem(snapshot.data![index]);
              },
              key: ValueKey(
                snapshot.data![index].id,
              ),
              child: ListTile(
                title: Text(snapshot.data![index].name),
                leading: Container(
                  width: 24,
                  height: 24,
                  color: snapshot.data![index].category.color,
                ),
                trailing: Text(
                  snapshot.data![index].quantity.toString(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
