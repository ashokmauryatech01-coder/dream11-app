import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class LocationService {
  static const String _geoApiUrl = 'https://ipapi.co/json/';

  static List<Map<String, dynamic>> get countries => [
    {'name': 'India', 'code': 'IN', 'currency': 'INR', 'symbol': '₹'},
    {'name': 'United States', 'code': 'US', 'currency': 'USD', 'symbol': r'$'},
    {'name': 'Pakistan', 'code': 'PK', 'currency': 'PKR', 'symbol': 'Rs'},
    {'name': 'Bangladesh', 'code': 'BD', 'currency': 'BDT', 'symbol': '৳'},
    {'name': 'UK', 'code': 'GB', 'currency': 'GBP', 'symbol': '£'},
    {'name': 'Europe', 'code': 'EU', 'currency': 'EUR', 'symbol': '€'},
    {'name': 'UAE', 'code': 'AE', 'currency': 'AED', 'symbol': 'DH'},
  ];

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
    return countries.first;
  }

  static Future<void> setCountry(Map<String, dynamic> country) async {
    final prefs = await SharedPreferences.getInstance();
    final data = {
      'country_name': country['name'] ?? country['country_name'],
      'country_code': country['code'] ?? country['country_code'],
      'currency': country['currency'],
      'currency_symbol': country['symbol'] ?? country['currency_symbol'],
    };
    await prefs.setString('location_data', jsonEncode(data));
  }

  static String getCurrencySymbol(String? currencyCode) {
    switch (currencyCode) {
      case 'USD':
        return r'$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'INR':
        return '₹';
      case 'AED':
        return 'DH';
      case 'PKR':
        return 'Rs';
      case 'BDT':
        return '৳';
      default:
        return '₹';
    }
  }

  static double getRateFromINR(String? currencyCode) {
    switch (currencyCode) {
      case 'USD':
        return 0.012;
      case 'EUR':
        return 0.011;
      case 'GBP':
        return 0.009;
      case 'AED':
        return 0.044;
      case 'PKR':
        return 3.35;
      case 'BDT':
        return 1.32;
      default:
        return 1.0;
    }
  }

  static double convertFromINR(dynamic amount, String? targetCurrency) {
    final double inrAmount = double.tryParse(amount?.toString() ?? '0') ?? 0.0;
    return inrAmount * getRateFromINR(targetCurrency);
  }

  static String formatAmount(dynamic amount, Map<String, dynamic>? location) {
    final symbol = location?['currency_symbol'] ?? '₹';
    final targetCurrency = location?['currency'] ?? 'INR';
    final converted = convertFromINR(amount, targetCurrency);

    // If it's a very large amount, format with K/Lakh/M logic or just fixed 2
    if (converted == 0) return '${symbol}0';
    if (converted < 1) return '${symbol}${converted.toStringAsFixed(2)}';
    return '${symbol}${converted.toStringAsFixed(converted % 1 == 0 ? 0 : 2)}';
  }

  static Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('location_data');
  }
}
