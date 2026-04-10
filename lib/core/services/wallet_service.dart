import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart';

class WalletService {
  // Get wallet balance fetch from API
  static Future<double> getBalance(int userId) async {
    final wallet = await getWallets(userId);
    return (wallet?['balance'] ?? 0.0).toDouble();
  }

  static Future<Map<String, dynamic>?> createWallet({
    required int userId,
    required double initialBalance,
    String description = 'Wallet created',
  }) async {
    try {
      final response = await ApiClient.post(
        '/user/wallets/$userId/create',
        {
          'user_id': userId,
          'initial_balance': initialBalance,
          'description': description,
        },
      );

      if (response != null && response['success'] == true) {
        return response['data'] as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      print('Error creating wallet: $e');
      return null;
    }
  }

  // 2. Get Wallet
  static Future<Map<String, dynamic>?> getWallets(int userId) async {
    if (userId <= 0) return null;
    try {
      final response = await ApiClient.get('/user/get-wallets/$userId');
      if (response != null && (response['success'] == true || response.containsKey('data'))) {
        return response['data'] as Map<String, dynamic>?;
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
    required double amount,
    required dynamic transactionId,
    String paymentMethod = 'upi',
  }) async {
    try {
      final body = {
        'user_id': userId,
        'wallet_id': walletId,
        'amount': amount,
        'transaction_id': transactionId,
        'payment_method': paymentMethod,
      };
      
      final response = await ApiClient.post('/user/recharge-wallet', body);
      
      if (response != null && (response['success'] == true || response.containsKey('data'))) {
        return response['data'] as Map<String, dynamic>?;
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
      final body = {
        'user_id': userId,
        'amount': amount,
        'contest_id': contestId,
        'team_id': teamId,
        'rank': rank,
        'description': description,
        'reference_id': referenceId ?? 'WIN_CONTEST_${contestId}_RANK_${rank}',
        'admin_notes': adminNotes ?? 'Automatic winning distribution',
      };
      
      final response = await ApiClient.post('/user/add-winning', body);
      if (response != null && response['success'] == true) {
        return response['data'] as Map<String, dynamic>?;
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
    String purpose = 'withdrawal',
  }) async {
    try {
      final body = {
        'user_id': userId,
        'amount': amount,
        'upi_id': upiId,
        'recipient_name': recipientName,
        'wallet_id': walletId,
        'description': description,
        'transaction_type': transactionType,
        'purpose': purpose,
        'wallet_balance': amount, // Adding this as the backend error explicitly mentions it
      };
      
      final response = await ApiClient.post('/user/upi-transfer/create', body);
      if (response != null && response['success'] == true) {
        return response['data'] as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      print('Error making UPI transfer: $e');
      return null;
    }
  }

  // Get transaction history from the updated /history endpoint
  static Future<List<Map<String, dynamic>>> getTransactionHistory(int userId, {int limit = 50}) async {
    try {
      // Endpoint changed to /history as seen in user logs
      final response = await ApiClient.get('/history?type=all&page=1&limit=$limit');
      if (response != null && response['success'] == true) {
        final data = response['data'] as Map<String, dynamic>?;
        if (data != null && data.containsKey('transactions')) {
          return (data['transactions'] as List<dynamic>?)
              ?.cast<Map<String, dynamic>>() ?? [];
        }
      }
      return [];
    } catch (e) {
      print('Error getting transaction history: $e');
      return [];
    }
  }

  // Special method to fetch the latest summary including balance
  static Future<Map<String, dynamic>?> getWalletSummary(int userId) async {
    try {
      final response = await ApiClient.get('/history?type=all&page=1&limit=1');
      if (response != null && response['success'] == true) {
        return response['data'] as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      print('Error getting wallet summary: $e');
      return null;
    }
  }

  // Get wallet balance with fallback to history API
  static Future<double?> getWalletBalance(int userId) async {
    try {
      // Try get-wallets first
      final walletData = await getWallets(userId);
      if (walletData != null) {
        final balance = double.tryParse(walletData['balance']?.toString() ?? '0');
        if (balance != null && balance > 0) return balance;
      }
      
      // Fallback to history summary if balance is 0 or null (as it reflects real-time recharge better)
      final summary = await getWalletSummary(userId);
      if (summary != null) {
        return double.tryParse(summary['current_balance']?.toString() ?? '0') ?? 0.0;
      }
      return 0.0;
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
      final body = {
        'user_id': userId,
        'wallet_id': walletId,
        'amount': amount,
        'payment_id': paymentId,
        'payment_method': paymentMethod,
        'description': 'Funds added via $paymentMethod',
      };
      
      final response = await ApiClient.post('/user/add-funds', body);
      if (response != null && response['success'] == true) {
        return response['data'] as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      print('Error adding funds: $e');
      return null;
    }
  }

  // Payment Callback
  static Future<Map<String, dynamic>?> paymentCallback({
    required String orderNo,
    required double amount,
    required dynamic txnId,
    String paymentUrl = 'deposit',
    String status = 'success',
  }) async {
    try {
      final body = {
        'orderNo': orderNo,
        'amount': amount,
        'txnId': txnId,
        'payment_url': paymentUrl,
        'status': status,
      };
      
      final response = await ApiClient.post('/user/payment-callback', body);
      if (response != null) {
        return response;
      }
      return null;
    } catch (e) {
      print('Error in payment callback: $e');
      return null;
    }
  }
}
