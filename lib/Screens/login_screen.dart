import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ramen_kiosk/Screens/ProductDisplayScreen.dart';
import 'dart:convert';
import 'package:video_player/video_player.dart';
import 'register_screen.dart';



class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  late VideoPlayerController _controller1;
  late VideoPlayerController _controller2;
  late VideoPlayerController _controller3;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller1 = VideoPlayerController.asset('assets/login.mp4')
      ..setLooping(true)
      ..setVolume(0) 
      ..initialize().then((_) {
        setState(() {});
        _controller1.play();
      });
    _controller2 = VideoPlayerController.asset('assets/login.mp4')
      ..setLooping(true)
      ..setVolume(0) 
      ..initialize().then((_) {
        setState(() {});
        _controller2.play();
      });
    _controller3 = VideoPlayerController.asset('assets/login.mp4')
      ..setLooping(true)
      ..setVolume(0) 
      ..initialize().then((_) {
        setState(() {});
        _controller3.play();
      });
  }

  @override
  void dispose() {
    _controller1.dispose();
    _controller2.dispose();
    _controller3.dispose();
    super.dispose();
  }


  Future<void> _login() async {
    setState(() {
      _isLoading = true; 
    });

    try {
      final response = await http.post(
        Uri.parse('http://localhost:8000/token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': _usernameController.text,
          'password': _passwordController.text,
        }),
      );

      setState(() {
        _isLoading = false; 
      });

      if (response.statusCode == 200) {        
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ProductDisplayScreen()),
        );
      } else {
        
        String message = 'Login failed. Please try again.';
        if (response.statusCode == 401) {
          message = 'Invalid credentials, please check your username and password.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false; // Hide loading spinner
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Video Players (with added blur and effects)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: _controller1.value.isInitialized
                    ? AspectRatio(
                        aspectRatio: _controller1.value.aspectRatio,
                        child: VideoPlayer(_controller1),
                      )
                    : Container(),
              ),
              Expanded(
                child: _controller2.value.isInitialized
                    ? AspectRatio(
                        aspectRatio: _controller2.value.aspectRatio,
                        child: VideoPlayer(_controller2),
                      )
                    : Container(),
              ),
              Expanded(
                child: _controller3.value.isInitialized
                    ? AspectRatio(
                        aspectRatio: _controller3.value.aspectRatio,
                        child: VideoPlayer(_controller3),
                      )
                    : Container(),
              ),
            ],
          ),
          
          // Semi-transparent overlay for better text visibility
          Container(
            color: Colors.black.withOpacity(0.5), // Darker overlay
          ),

          // Login Form UI
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Username field with icon and smooth border
                  TextField(
                    controller: _usernameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Username',
                      labelStyle: const TextStyle(color: Colors.white),
                      filled: true,
                      fillColor: Colors.black.withOpacity(0.7),
                      prefixIcon: const Icon(Icons.person, color: Colors.white),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Password field with icon and smooth border
                  TextField(
                    controller: _passwordController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      labelStyle: const TextStyle(color: Colors.white),
                      filled: true,
                      fillColor: Colors.black.withOpacity(0.7),
                      prefixIcon: const Icon(Icons.lock, color: Colors.white),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 16),

                  // Login button with rounded corners and smooth hover effect
                  ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ), backgroundColor: Colors.blue,
                      minimumSize: Size(double.infinity, 50),
                    ), // Disable button while loading
                    child: _isLoading
                        ? CircularProgressIndicator(color: Colors.white) // Show loading spinner
                        : const Text('Login'),
                  ),
                  const SizedBox(height: 16),

                  // Register button
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => RegisterScreen()),
                    ),
                    child: const Text(
                      'Don\'t have an account? Register here.',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
