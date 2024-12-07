import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../models/order.dart';

class ApiService {
  final String baseUrl = 'http://localhost:8000'; 

  Future<String> login(User user) async {
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/token'),
      headers: {'Content-Type': 'application/json'}, 
      body: jsonEncode({
        'username': user.username,
        'password': user.password,
      }),
    );

    if (response.statusCode == 200) {
      
      final responseData = jsonDecode(response.body);
      return responseData['access_token'];
    } else {
      
      final errorResponse = jsonDecode(response.body);
      throw Exception('Login failed: ${errorResponse['detail'] ?? 'Unknown error'}');
    }
  } catch (e) {
    throw Exception('Login error: $e');
  }
}

  
  Future<void> register(User user) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': user.username,
          'password': user.password,
          'is_admin': false,  
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Registration failed: ${response.body}');
      }
    } catch (e) {
      throw Exception('Registration error: $e');
    }
  }

  
  Future<Map<String, List<dynamic>>> getMenu() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/menu'));

      if (response.statusCode == 200) {
      
        return Map<String, List<dynamic>>.from(jsonDecode(response.body));
      } else {
        
        final errorResponse = jsonDecode(response.body);
        throw Exception('Failed to load menu: ${errorResponse['detail'] ?? 'Unknown error'}');
      }
    } catch (e) {
      throw Exception('Menu loading error: $e');
    }
  }


  Future<void> createOrder(String token, Order order) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/order'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'flavor_id': order.flavorId,
          'soup_base_id': order.soupBaseId,
          'meat_id': order.meatId,
          'spicy_level_id': order.spicyLevelId,
        }),  
      );

      if (response.statusCode == 200) {
      
        print('Order placed successfully');
      } else {
        
        final errorResponse = jsonDecode(response.body);
        throw Exception('Failed to place order: ${errorResponse['detail'] ?? 'Unknown error'}');
      }
    } catch (e) {
      throw Exception('Order placement error: $e');
    }
  }
}
