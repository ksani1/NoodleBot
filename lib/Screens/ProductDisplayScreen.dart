import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ramen_kiosk/Screens/menu_screen.dart';

class ProductDisplayScreen extends StatefulWidget {
  const ProductDisplayScreen({Key? key}) : super(key: key);

  @override
  _ProductDisplayScreenState createState() => _ProductDisplayScreenState();
}

class _ProductDisplayScreenState extends State<ProductDisplayScreen> {
  late PageController _pageController;
  int _currentIndex = 0;

  final List<Map<String, String>> _products = [
    {
      'image': 'assets/1a.jpeg',
      'name': 'INDOMIE',
    },
    {
      'image': 'assets/1b.jpeg',
      'name': 'SHOYU',
    },
    {
      'image': 'assets/1c.jpeg',
      'name': 'MISO',
    },
    {
      'image': 'assets/register.jpeg',
      'name': 'TONKOTSU',
    },
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _startSlideshow();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _startSlideshow() {
    Timer.periodic(Duration(seconds: 3), (timer) {
      if (_pageController.hasClients) {
        _currentIndex = (_currentIndex + 1) % _products.length;
        _pageController.animateToPage(
          _currentIndex,
          duration: Duration(seconds: 1),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(''),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Item name dynamically updated with the image
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text(
                _products[_currentIndex]['name']!, // Dynamically show name based on current index
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  letterSpacing: 2,
                  textBaseline: TextBaseline.alphabetic,
                  fontFamily: 'Arial',
                ),
              ),
            ),
            // Image slideshow container (centered)
            Expanded(  // Use Expanded to make sure the image doesn't overflow
              child: Container(
                width: double.infinity, // Ensures the image container takes up the available width
                child: PageView.builder(
                  controller: _pageController,
                  scrollDirection: Axis.horizontal,
                  itemCount: _products.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentIndex = index; // Update current index when page changes
                    });
                  },
                  itemBuilder: (context, index) {
                    return Center(
                      child: Image.asset(
                        _products[index]['image']!,
                        fit: BoxFit.contain, // Ensures image is contained without cropping
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Ramen Robotic Kiosk!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            // Start order button
            Container(
              width: 300,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(35),
              ),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => MenuScreen(token: '')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(35),
                  ),
                  minimumSize: Size(double.infinity, 70),
                  padding: const EdgeInsets.all(0),
                ),
                child: const Text(
                  'Start Order',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
