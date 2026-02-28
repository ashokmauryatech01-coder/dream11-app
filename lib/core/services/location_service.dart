import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class LocationService {
  static const String _geoApiUrl = 'https://ipapi.co/json/';

  static Future<Map<String, dynamic>> getLocationData() async {
    try {
      // Check cache first
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('location_data');
      if (cached != null) {
        return jsonDecode(cached);
      }

      final response = await http.get(Uri.parse(_geoApiUrl));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await prefs.setString('location_data', response.body);
        return data;
      }
    } catch (e) {
      print('Location error: $e');
    }
    
    // Default fallback (India)
    return {
      'country_code': 'IN',
      'country_calling_code': '+91',
      'currency': 'INR',
      'currency_symbol': '₹',
      'ip': '127.0.0.1'
    };
  }

  static String getCurrencySymbol(String? currencyCode) {
    switch (currencyCode) {
      case 'USD': return '\$';
      case 'EUR': return '€';
      case 'GBP': return '£';
      case 'INR': return '₹';
      case 'AED': return 'DH';
      case 'PKR': return 'Rs';
      case 'BDT': return '৳';
      default: return '₹';
    }
  }

  static Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('location_data');
  }
}
