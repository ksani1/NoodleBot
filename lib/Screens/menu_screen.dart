import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'login_screen.dart';
import 'dart:math';

class MenuScreen extends StatefulWidget {
  final String token;

  const MenuScreen({Key? key, required this.token}) : super(key: key);

  @override
  _MenuScreenState createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  Map<String, List<dynamic>> menu = {};
  Map<dynamic, int> cart = {};
  final List<String> descriptions = [
    'A delicious treat packed with flavor.',
    'Perfect for any occasion, savory and satisfying.',
    'Experience the taste of tradition in every bite.',
    'A delightful combination of ingredients that dance on your palate.',
    'A classic dish with a modern twist.',
    'Freshly made with love and care.',
    'An explosion of flavors that you won’t forget.',
    'An irresistible option for food lovers.',
    'Light, refreshing, and perfect for summer days.',
    'Rich and hearty, ideal for those with a big appetite.',
  ];

  @override
  void initState() {
    super.initState();
    fetchMenu();
  }

  double generateRandomPrice() {
    final random = Random();
    return (random.nextDouble() * (20 - 5) + 5).roundToDouble();
  }

  String getRandomDescription() {
    final random = Random();
    return descriptions[random.nextInt(descriptions.length)];
  }

  Future<void> fetchMenu() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:8000/menu'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (response.statusCode == 200) {
        final fetchedMenu = Map<String, List<dynamic>>.from(json.decode(response.body));

        for (var category in fetchedMenu.keys) {
          for (var item in fetchedMenu[category]!) {
            item['description'] = getRandomDescription();
            if (category.toLowerCase() != 'spicy') {
              item['price'] = generateRandomPrice();
            } else {
              item['price'] = null;
            }
          }
        }

        setState(() {
          menu = fetchedMenu;
        });
      } else {
        throw Exception('Failed to load menu');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void addToCart(dynamic item) {
    setState(() {
      cart[item] = (cart[item] ?? 0) + 1;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${item['name']} added to cart')),
    );
  }

  void updateCartItemQuantity(dynamic item, int quantity) {
    setState(() {
      if (quantity <= 0) {
        cart.remove(item);
      } else {
        cart[item] = quantity;
      }
    });
  }

  void checkout() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderSummaryPage(
          cart: cart,
          onCheckoutComplete: () {
            cart.clear();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Thank you for your order!')),
            );
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu'),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CartPage(
                    cart: cart,
                    onUpdateQuantity: updateCartItemQuantity,
                    onCheckout: checkout,
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/1c.jpeg',
            fit: BoxFit.cover,
          ),
          menu.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  children: [
                    ...menu.keys.map((category) {
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Container(
                          padding: const EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                category.replaceAll('_', ' ').toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              ...menu[category]!.map((item) {
                                return ListTile(
                                  title: Text(
                                    item['name'],
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  subtitle: Text(
                                    '${item['description'] ?? 'No description available'}\n${item['price'] != null ? 'Price: \$${item['price']?.toStringAsFixed(2) ?? 'N/A'}' : 'Price: N/A'}',
                                    style: const TextStyle(color: Colors.white70),
                                  ),
                                  trailing: ElevatedButton(
                                    onPressed: () => addToCart(item),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange,
                                    ),
                                    child: const Text(
                                      'Add to Cart',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
        ],
      ),
    );
  }
}

class CartPage extends StatefulWidget {
  final Map<dynamic, int> cart;
  final Function(dynamic, int) onUpdateQuantity;
  final VoidCallback onCheckout;

  const CartPage({super.key, required this.cart, required this.onUpdateQuantity, required this.onCheckout});

  @override
  _CartPageState createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = Tween<double>(begin: 1.0, end: 1.1).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cart'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/1c.jpeg',
            fit: BoxFit.cover,
            color: Colors.black54,
            colorBlendMode: BlendMode.darken,
          ),
          widget.cart.isEmpty
              ? const Center(child: Text('Your cart is empty', style: TextStyle(color: Colors.white)))
              : ListView.builder(
                  itemCount: widget.cart.keys.length,
                  itemBuilder: (context, index) {
                    var item = widget.cart.keys.elementAt(index);
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item['name'], style: const TextStyle(color: Colors.white)),
                                Text(
                                  'Price: \$${item['price']?.toStringAsFixed(2) ?? 'N/A'}',
                                  style: const TextStyle(color: Colors.white70),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove, color: Colors.red),
                                  onPressed: () {
                                    int newQuantity = widget.cart[item]! - 1;
                                    widget.onUpdateQuantity(item, newQuantity);
                                  },
                                ),
                                Text('${widget.cart[item]}', style: const TextStyle(color: Colors.white)),
                                IconButton(
                                  icon: const Icon(Icons.add, color: Colors.green),
                                  onPressed: () {
                                    int newQuantity = widget.cart[item]! + 1;
                                    widget.onUpdateQuantity(item, newQuantity);
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () {
                                    widget.onUpdateQuantity(item, 0);
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ],
      ),
      floatingActionButton: ScaleTransition(
        scale: _animation,
        child: FloatingActionButton.extended(
          onPressed: () {
            _controller.forward().then((_) {
              _controller.reverse();
              widget.onCheckout(); // Trigger checkout
            });
          },
          label: const Text('Checkout', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.green,
        ),
      ),
    );
  }
}

class OrderSummaryPage extends StatelessWidget {
  final Map<dynamic, int> cart;
  final VoidCallback onCheckoutComplete;

  const OrderSummaryPage({Key? key, required this.cart, required this.onCheckoutComplete}) : super(key: key);

  double getTotalAmount() {
    double total = 0.0;
    cart.forEach((item, quantity) {
      total += (item['price'] ?? 0) * quantity;
    });
    return total;
  }

  double getTaxes(double totalAmount) {
    return totalAmount * 0.10; // 10% tax
  }

  @override
  Widget build(BuildContext context) {
    double totalAmount = getTotalAmount();
    double taxes = getTaxes(totalAmount);
    double finalAmount = totalAmount + taxes;

    return Scaffold(
      appBar: AppBar(title: const Text('Order Summary')),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/1c.jpeg',
            fit: BoxFit.cover,
            color: Colors.black54,
            colorBlendMode: BlendMode.darken,
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Items:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
                ...cart.entries.map((entry) {
                  var item = entry.key;
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            item['name'],
                            style: const TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ),
                        Text(
                          'Price: \$${item['price']?.toStringAsFixed(2)} x ${entry.value}',
                          style: const TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Total: \$${(item['price'] ?? 0) * entry.value}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                const SizedBox(height: 20),
                Text('Subtotal: \$${totalAmount.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white)),
                Text('Taxes (10%): \$${taxes.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white)),
                const SizedBox(height: 10),
                Text('Total Amount: \$${finalAmount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
                const Spacer(),
                ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: const Color.fromARGB(255, 249, 244, 244),
                        title: const Text(
                          'Thank you for your order!',
                          style: TextStyle(color: Color.fromARGB(255, 5, 5, 5)),
                        ),
                        content: const Text(
                          'Your ramen is on its way! 🍜.',
                          style: TextStyle(color: Color.fromARGB(255, 13, 13, 13)),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              onCheckoutComplete(); 
                              Navigator.pop(context); 
                              Navigator.pop(context); 
                              Navigator.pushReplacementNamed(context, '/'); 
                            },
                            child: const Text(
                              'Okay',
                              style: TextStyle(color: Color.fromARGB(255, 9, 193, 55)),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: const Text('Confirm Order'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
