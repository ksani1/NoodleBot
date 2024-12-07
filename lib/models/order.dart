import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Order {
  final int flavorId;
  final int soupBaseId;
  final int meatId;
  final int spicyLevelId;

  Order({
    required this.flavorId,
    required this.soupBaseId,
    required this.meatId,
    required this.spicyLevelId,
  });

  Map<String, dynamic> toJson() {
    return {
      'flavor_id': flavorId,
      'soup_base_id': soupBaseId,
      'meat_id': meatId,
      'spicy_level_id': spicyLevelId,
    };
  }
}

class OrderPage extends StatefulWidget {
  final String token;
  final Map<String, List<dynamic>> menu;

  OrderPage({required this.token, required this.menu});

  @override
  _OrderPageState createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  int? flavorId, soupBaseId, meatId, spicyLevelId;

  Future<void> placeOrder() async {
    
    if (flavorId == null || soupBaseId == null || meatId == null || spicyLevelId == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please select all options')));
      return;
    }

    
    Order order = Order(
      flavorId: flavorId!,
      soupBaseId: soupBaseId!,
      meatId: meatId!,
      spicyLevelId: spicyLevelId!,
    );

    try {
      
      final response = await http.post(
        Uri.parse('http://localhost:8000/order'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: json.encode(order.toJson()),
      );

      if (response.statusCode == 200) {
        
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Order placed successfully')));
        Navigator.pop(context);
      } else {
       
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to place order: ${response.body}')));
      }
    } catch (e) {
      
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Place Order')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            
            buildDropdown(
              'Flavor',
              widget.menu['flavors']!,
              flavorId,
              (value) => setState(() => flavorId = value as int?),
            ),
           
            buildDropdown(
              'Soup Base',
              widget.menu['soup_bases']!,
              soupBaseId,
              (value) => setState(() => soupBaseId = value as int?),
            ),
           
            buildDropdown(
              'Meat',
              widget.menu['meats']!,
              meatId,
              (value) => setState(() => meatId = value as int?),
            ),
           
            buildDropdown(
              'Spicy Level',
              widget.menu['spicy_levels']!,
              spicyLevelId,
              (value) => setState(() => spicyLevelId = value as int?),
            ),
            const SizedBox(height: 16),
            // Place Order Button
            ElevatedButton(onPressed: placeOrder, child: const Text('Place Order')),
          ],
        ),
      ),
    );
  }


  Widget buildDropdown<T>(
    String label,
    List<dynamic> items,
    T? selectedId,
    Function(T?) onChanged,
  ) {
    return DropdownButtonFormField<T>(
      value: selectedId,
      items: items.map<DropdownMenuItem<T>>((item) {
        return DropdownMenuItem<T>(
          value: item['id'] as T, 
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(item['name']),
              if (item['id'] == selectedId) const Icon(Icons.check, color: Colors.green), 
            ],
          ),
        );
      }).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(labelText: label),
    );
  }
}
