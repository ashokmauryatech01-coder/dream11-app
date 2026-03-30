import 'api_client.dart';
import 'user_profile_service.dart';

class ProfileService {
  /// Get user profile: Automatically hit /v1/user/profile
  static Future<Map<String, dynamic>?> getProfile({int? userId}) async {
    try {
      int uid = userId ?? 0;
      if (uid <= 0) {
        uid = await UserProfileService.getSavedUserId();
      }

      final userData = await UserProfileService.getUserProfile(uid);
      if (userData != null) {
        // Automatically save the data locally so other services can use the user_id
        await UserProfileService.saveUserDataLocally(userData);
      }
      return userData;
    } catch (e) {
      return null;
    }
  }

  /// Get user wallet details: Automatically unwraps the nested 'wallet' key if present
  /// and performs a fallback check to the history API if the balance is 0.
  static Future<Map<String, dynamic>?> getUserWallets([int? userId]) async {
    try {
      int uid = userId ?? 0;
      if (uid <= 0) {
        uid = await UserProfileService.getSavedUserId();
      }
      final response = await UserProfileService.getUserWallets(uid);

      Map<String, dynamic>? wallet;
      if (response != null) {
        if (response.containsKey('wallet')) {
          wallet = Map<String, dynamic>.from(response['wallet'] as Map);
        } else if (response.containsKey('data') &&
            (response['data'] as Map).containsKey('wallet')) {
          wallet = Map<String, dynamic>.from(
            (response['data'] as Map)['wallet'] as Map,
          );
        } else {
          wallet = Map<String, dynamic>.from(response);
        }

        // SMART FALLBACK: If balance is 0, try to get the real balance from history
        final currentBal =
            double.tryParse(wallet['balance']?.toString() ?? '0') ?? 0.0;
        if (currentBal == 0) {
          final historyBalance = await UserProfileService.getWalletBalance(uid);
          if (historyBalance != null && historyBalance > 0) {
            wallet['balance'] = historyBalance;
          }
        }
      }
      return wallet;
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> createWallet({
    required int userId,
    required double initialBalance,
    String description = 'Wallet created',
  }) async {
    return await UserProfileService.updateUserProfile(userId: userId);
  }

  static Future<double?> getWalletBalance() async {
    try {
      final currentUserId = await UserProfileService.getSavedUserId();
      return await UserProfileService.getWalletBalance(currentUserId);
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> updateProfile({
    String? name,
    String? email,
    String? phone,
    String? upiId,
    String? password,
    String? passwordConfirmation,
    String? userType,
  }) async {
    try {
      final savedData = await UserProfileService.getSavedUserData();
      final currentUserId = await UserProfileService.getSavedUserId();

      final res = await UserProfileService.updateUserProfile(
        userId: currentUserId,
        name: name,
        email: email,
        phone: phone,
        upiId: upiId,
        password: password,
        passwordConfirmation: passwordConfirmation,
        userType: userType,
      );

      if (res != null) {
        final updatedData = Map<String, dynamic>.from(savedData);
        final userData = updatedData.containsKey('user')
            ? updatedData['user']
            : updatedData;

        if (name != null) userData['name'] = name;
        if (email != null) userData['email'] = email;
        if (phone != null) userData['phone'] = phone;
        if (upiId != null) userData['upi_id'] = upiId;

        await UserProfileService.saveUserDataLocally(updatedData);
      }
      return res;
    } catch (_) {
      return null;
    }
  }

  static Future<List<dynamic>> getMyTeams({
    int page = 1,
    int limit = 20,
    int? userId,
  }) async {
    try {
      int uid = userId ?? 0;
      if (uid <= 0) uid = await UserProfileService.getSavedUserId();
      if (uid <= 0) return [];

      final res = await ApiClient.post(
        '/teams/show-contest-teams?user_id=$uid',
        {'user_id': uid},
      );

      if (res != null && res['success'] == true) {
        final data = res['data'];
        if (data is List) return data;
        if (data is Map && data.containsKey('teams')) {
          return data['teams'] as List<dynamic>? ?? [];
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getTransactionHistory({
    int limit = 50,
  }) async {
    try {
      int userId = await UserProfileService.getSavedUserId();
      return await UserProfileService.getTransactionHistory(
        userId,
        limit: limit,
      );
    } catch (_) {
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getHistory() async {
    return await getTransactionHistory();
  }

  static Future<void> saveUserDataLocally(Map<String, dynamic> data) async {
    await UserProfileService.saveUserDataLocally(data);
  }

  static Future<List<dynamic>> getLeaderboard({
    String type = 'global',
    int limit = 20,
  }) async {
    try {
      final res = await ApiClient.get('/leaderboard?type=$type&limit=$limit');
      if (res != null && res['success'] == true) {
        final data = res['data'];
        if (data is List) return data;
        if (data is Map && data.containsKey('leaderboard')) {
          final lb = data['leaderboard'];
          if (lb is Map && lb.containsKey('data'))
            return lb['data'] as List<dynamic>;
          if (lb is List) return lb;
        }
        return data as List<dynamic>? ?? [];
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> getSavedUserData() async {
    return await UserProfileService.getSavedUserData();
  }
}
