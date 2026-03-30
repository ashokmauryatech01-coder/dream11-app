import 'dart:convert';
import 'api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProfileService {
  // Get ID from SharedPreferences safely
  static Future<int> getSavedUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt('user_id') ?? 0;
    } catch (_) {
      return 0;
    }
  }

  // Get user profile details
  static Future<Map<String, dynamic>?> getUserProfile(int userId) async {
    try {
      final res = await ApiClient.get('/user/profile');
      if (res is Map && res['success'] == true) {
        return res['data'] as Map<String, dynamic>?;
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
      final res = await ApiClient.get('/user/get-wallets/$userId');
      if (res is Map && (res['success'] == true || res.containsKey('data'))) {
        return res['data'] as Map<String, dynamic>?;
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
      final res = await ApiClient.get('/user/details/$userId');
      if (res is Map && res['success'] == true) {
        return res['data'] as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      print('Error getting complete user profile: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> updateUserProfile({
    required int userId,
    String? name,
    String? email,
    String? phone,
    String? upiId,
    String? password,
    String? passwordConfirmation,
    String? userType = 'user',
  }) async {
    try {
      final body = {
        'user_id': userId,
        if (name != null) 'name': name,
        if (email != null) 'email': email,
        if (phone != null) 'phone': phone,
        if (upiId != null) 'upi_id': upiId,
        if (password != null) 'password': password,
        if (passwordConfirmation != null) 'password_confirmation': passwordConfirmation,
        'user_type': userType,
      };

      final res = await ApiClient.post('/user/profile-update', body);
      if (res is Map && res['success'] == true) {
        return res['data'] as Map<String, dynamic>?;
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
      final res = await ApiClient.get('/user/transactions/$userId?limit=$limit');
      if (res is Map && res['success'] == true) {
        return (res['data'] as List<dynamic>?)
            ?.cast<Map<String, dynamic>>() ?? [];
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
      
      // Handle nested user data if present
      final user = userData.containsKey('user') ? userData['user'] : userData;
      
      // Flattened logic for cross-key ID identification (user_id, userid vs id)
      int parseId(dynamic obj) {
        if (obj == null) return 0;
        final val = obj['user_id'] ?? obj['userid'] ?? obj['id'];
        if (val == null) return 0;
        if (val is int) return val;
        return int.tryParse(val.toString()) ?? 0;
      }
      
      final int userIdValue = parseId(user);
      await prefs.setInt('user_id', userIdValue);
      await prefs.setString('user_name', user['name'] ?? user['full_name'] ?? '');
      await prefs.setString('user_email', user['email'] ?? '');
      await prefs.setString('user_phone', user['phone'] ?? '');
      await prefs.setString('user_upi_id', user['upi_id'] ?? '');
      
      // Robust balance extraction from any data variant (profile, history, or get-wallets)
      final balanceValue = userData['wallet_balance'] ?? 
                          user['wallet_balance'] ?? 
                          userData['current_balance'] ?? 
                          user['current_balance'] ?? 
                          (userData.containsKey('wallet') ? userData['wallet']['balance'] : null) ??
                          0;
      await prefs.setString('wallet_balance', balanceValue.toString());
    } catch (e) {
      print('Error saving user data locally: $e');
    }
  }

  // Get saved user data
  static Future<Map<String, dynamic>> getSavedUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('user_data') ?? '{}';
      final Map<String, dynamic> map = jsonDecode(userDataString) as Map<String, dynamic>;
      // Backfill the integer user_id if it's not present in the map
      if (!map.containsKey('user_id') && prefs.containsKey('user_id')) {
         map['user_id'] = prefs.getInt('user_id');
      }
      return map;
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
