import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class WalletService {
  static const String _baseUrl = 'https://your-api-base-url.com/api/v1'; // Replace with your actual base URL
  static const String _token = 'your-auth-token'; // Replace with your actual token

  // 1. Create Wallet
  static Future<Map<String, dynamic>?> createWallet({
    required int userId,
    required double initialBalance,
    String description = 'Wallet created',
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/user/wallets/$userId/create');
      final response = await http.post(
        uri,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: jsonEncode({
          'user_id': userId,
          'initial_balance': initialBalance,
          'description': description,
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          return data['data'] as Map<String, dynamic>?;
        }
      }
      return null;
    } catch (e) {
      print('Error creating wallet: $e');
      return null;
    }
  }

  // 2. Get Wallet
  static Future<Map<String, dynamic>?> getWallets(int userId) async {
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
      print('Error getting wallets: $e');
      return null;
    }
  }

  // 3. Recharge Wallet
  static Future<Map<String, dynamic>?> rechargeWallet({
    required int userId,
    required int walletId,
    required double balance,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/user/recharge-wallet');
      final response = await http.post(
        uri,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: jsonEncode({
          'user_id': userId,
          'wallet_id': walletId,
          'balance': balance,
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          return data['data'] as Map<String, dynamic>?;
        }
      }
      return null;
    } catch (e) {
      print('Error recharging wallet: $e');
      return null;
    }
  }

  // 4. Add Winning
  static Future<Map<String, dynamic>?> addWinning({
    required int userId,
    required double amount,
    required int contestId,
    required int teamId,
    required int rank,
    required String description,
    String? referenceId,
    String? adminNotes,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/user/add-winning');
      final response = await http.post(
        uri,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: jsonEncode({
          'user_id': userId,
          'amount': amount,
          'contest_id': contestId,
          'team_id': teamId,
          'rank': rank,
          'description': description,
          'reference_id': referenceId ?? 'WIN_CONTEST_${contestId}_RANK_${rank}',
          'admin_notes': adminNotes ?? 'Automatic winning distribution',
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          return data['data'] as Map<String, dynamic>?;
        }
      }
      return null;
    } catch (e) {
      print('Error adding winning: $e');
      return null;
    }
  }

  // 5. Transfer Amount via UPI
  static Future<Map<String, dynamic>?> upiTransfer({
    required int userId,
    required double amount,
    required String upiId,
    required String recipientName,
    required int walletId,
    required String description,
    String transactionType = 'withdrawal',
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/user/upi-transfer/create');
      final response = await http.post(
        uri,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: jsonEncode({
          'user_id': userId,
          'amount': amount,
          'upi_id': upiId,
          'recipient_name': recipientName,
          'wallet_id': walletId,
          'description': description,
          'transaction_type': transactionType,
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          return data['data'] as Map<String, dynamic>?;
        }
      }
      return null;
    } catch (e) {
      print('Error making UPI transfer: $e');
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

  // Get wallet balance
  static Future<double?> getWalletBalance(int userId) async {
    try {
      final walletData = await getWallets(userId);
      if (walletData != null) {
        return (walletData['balance'] ?? 0.0).toDouble();
      }
      return null;
    } catch (e) {
      print('Error getting wallet balance: $e');
      return null;
    }
  }

  // Save wallet data locally
  static Future<void> saveWalletDataLocally(Map<String, dynamic> walletData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('wallet_data', jsonEncode(walletData));
      await prefs.setString('wallet_balance', (walletData['balance'] ?? 0.0).toString());
    } catch (e) {
      print('Error saving wallet data locally: $e');
    }
  }

  // Get saved wallet data
  static Future<Map<String, dynamic>> getSavedWalletData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final walletDataString = prefs.getString('wallet_data') ?? '{}';
      return jsonDecode(walletDataString) as Map<String, dynamic>;
    } catch (e) {
      print('Error getting saved wallet data: $e');
      return {};
    }
  }

  // Clear saved wallet data
  static Future<void> clearWalletData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('wallet_data');
      await prefs.remove('wallet_balance');
    } catch (e) {
      print('Error clearing wallet data: $e');
    }
  }

  // Create welcome bonus wallet
  static Future<Map<String, dynamic>?> createWelcomeWallet(int userId, double welcomeBonus) async {
    return await createWallet(
      userId: userId,
      initialBalance: welcomeBonus,
      description: 'Welcome bonus wallet created',
    );
  }

  // Add funds after successful payment
  static Future<Map<String, dynamic>?> addFunds({
    required int userId,
    required int walletId,
    required double amount,
    String paymentId = '',
    String paymentMethod = 'razorpay',
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/user/add-funds');
      final response = await http.post(
        uri,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: jsonEncode({
          'user_id': userId,
          'wallet_id': walletId,
          'amount': amount,
          'payment_id': paymentId,
          'payment_method': paymentMethod,
          'description': 'Funds added via $paymentMethod',
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          return data['data'] as Map<String, dynamic>?;
        }
      }
      return null;
    } catch (e) {
      print('Error adding funds: $e');
      return null;
    }
  }
}
