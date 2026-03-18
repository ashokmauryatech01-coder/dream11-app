import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class UserProfileService {
  static const String _baseUrl = 'https://your-api-base-url.com/api/v1'; // Replace with your actual base URL
  static const String _token = 'your-auth-token'; // Replace with your actual token

  // Get user profile details
  static Future<Map<String, dynamic>?> getUserProfile(int userId) async {
    try {
      final uri = Uri.parse('$_baseUrl/user/profile/$userId');
      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $_token',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          return data['data'] as Map<String, dynamic>?;
        }
      }
      return null;
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  // Get user wallet details
  static Future<Map<String, dynamic>?> getUserWallets(int userId) async {
    try {
      final uri = Uri.parse('$_baseUrl/user/get-wallets/$userId');
      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $_token',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          return data['data'] as Map<String, dynamic>?;
        }
      }
      return null;
    } catch (e) {
      print('Error getting user wallets: $e');
      return null;
    }
  }

  // Get complete user details including wallet info
  static Future<Map<String, dynamic>?> getCompleteUserProfile(int userId) async {
    try {
      final uri = Uri.parse('$_baseUrl/user/details/$userId');
      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $_token',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          return data['data'] as Map<String, dynamic>?;
        }
      }
      return null;
    } catch (e) {
      print('Error getting complete user profile: $e');
      return null;
    }
  }

  // Update user profile
  static Future<Map<String, dynamic>?> updateUserProfile({
    required int userId,
    String? fullName,
    String? email,
    String? phone,
    String? upiId,
    String? avatar,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/user/update-profile/$userId');
      final body = {
        if (fullName != null) 'full_name': fullName,
        if (email != null) 'email': email,
        if (phone != null) 'phone': phone,
        if (upiId != null) 'upi_id': upiId,
        if (avatar != null) 'avatar': avatar,
      };

      final response = await http.post(
        uri,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          return data['data'] as Map<String, dynamic>?;
        }
      }
      return null;
    } catch (e) {
      print('Error updating user profile: $e');
      return null;
    }
  }

  // Get wallet balance
  static Future<double?> getWalletBalance(int userId) async {
    try {
      final walletData = await getUserWallets(userId);
      if (walletData != null) {
        return (walletData['balance'] ?? 0.0).toDouble();
      }
      return null;
    } catch (e) {
      print('Error getting wallet balance: $e');
      return null;
    }
  }

  // Get transaction history
  static Future<List<Map<String, dynamic>>> getTransactionHistory(int userId, {int limit = 50}) async {
    try {
      final uri = Uri.parse('$_baseUrl/user/transactions/$userId?limit=$limit');
      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $_token',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          return (data['data'] as List<dynamic>?)
              ?.cast<Map<String, dynamic>>() ?? [];
        }
      }
      return [];
    } catch (e) {
      print('Error getting transaction history: $e');
      return [];
    }
  }

  // Save user data locally
  static Future<void> saveUserDataLocally(Map<String, dynamic> userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_data', jsonEncode(userData));
      await prefs.setInt('user_id', userData['id'] ?? 0);
      await prefs.setString('user_name', userData['full_name'] ?? '');
      await prefs.setString('user_email', userData['email'] ?? '');
      await prefs.setString('user_phone', userData['phone'] ?? '');
      await prefs.setString('user_upi_id', userData['upi_id'] ?? '');
      await prefs.setString('wallet_balance', (userData['wallet_balance'] ?? 0).toString());
    } catch (e) {
      print('Error saving user data locally: $e');
    }
  }

  // Get saved user data
  static Future<Map<String, dynamic>> getSavedUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('user_data') ?? '{}';
      return jsonDecode(userDataString) as Map<String, dynamic>;
    } catch (e) {
      print('Error getting saved user data: $e');
      return {};
    }
  }

  // Clear saved user data
  static Future<void> clearUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_data');
      await prefs.remove('user_id');
      await prefs.remove('user_name');
      await prefs.remove('user_email');
      await prefs.remove('user_phone');
      await prefs.remove('user_upi_id');
      await prefs.remove('wallet_balance');
    } catch (e) {
      print('Error clearing user data: $e');
    }
  }
}
