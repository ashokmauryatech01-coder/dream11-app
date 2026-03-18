import 'api_client.dart';
import 'user_profile_service.dart';

class ProfileService {
  /// Fetch user profile (includes user object and basic stats)
  static Future<Map<String, dynamic>?> getProfile() async {
    try {
      final res = await ApiClient.get('/user/profile');
      if (res is Map && res.containsKey('data')) {
        return res['data'] as Map<String, dynamic>?;
      }
      return res as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }

  /// Get user wallet details
  static Future<Map<String, dynamic>?> getUserWallets(int userId) async {
    try {
      final savedData = await UserProfileService.getSavedUserData();
      final currentUserId = savedData['id'] ?? 0;
      return await UserProfileService.getUserWallets(currentUserId);
    } catch (_) {
      return null;
    }
  }

  /// Get wallet balance
  static Future<double?> getWalletBalance() async {
    try {
      final savedData = await UserProfileService.getSavedUserData();
      final currentUserId = savedData['id'] ?? 0;
      return await UserProfileService.getWalletBalance(currentUserId);
    } catch (_) {
      return null;
    }
  }

  /// Get complete user profile with wallet info
  static Future<Map<String, dynamic>?> getCompleteUserProfile() async {
    try {
      final savedData = await UserProfileService.getSavedUserData();
      final currentUserId = savedData['id'] ?? 0;
      return await UserProfileService.getCompleteUserProfile(currentUserId);
    } catch (_) {
      return null;
    }
  }

  /// Update user profile
  static Future<Map<String, dynamic>?> updateProfile({
    String? fullName,
    String? email,
    String? phone,
    String? upiId,
  }) async {
    try {
      final savedData = await UserProfileService.getSavedUserData();
      final currentUserId = savedData['id'] ?? 0;
      
      final res = await UserProfileService.updateUserProfile(
        userId: currentUserId,
        fullName: fullName,
        email: email,
        phone: phone,
        upiId: upiId,
      );

      if (res != null) {
        // Update local data
        final updatedData = Map<String, dynamic>.from(savedData);
        if (fullName != null) updatedData['full_name'] = fullName;
        if (email != null) updatedData['email'] = email;
        if (phone != null) updatedData['phone'] = phone;
        if (upiId != null) updatedData['upi_id'] = upiId;
        
        await UserProfileService.saveUserDataLocally(updatedData);
      }

      return res;
    } catch (_) {
      return null;
    }
  }

  /// Fetch user's teams with pagination
  static Future<List<dynamic>> getMyTeams({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final res = await ApiClient.get('/teams');
      final root = res as Map<String, dynamic>? ?? {};
      final data = root['data'] ?? root;
      if (data is List) return data;
      if (data is Map) {
        return data['teams'] ??
              data['items'] ??
              root['teams'] ??
              root['items'] ??
              [];
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Fetch user's contest/match history
  static Future<List<dynamic>> getHistory({
    String type = 'all',
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final res = await ApiClient.get(
        '/history?type=$type&page=$page&limit=$limit',
      );
      final root = res as Map<String, dynamic>? ?? {};
      final data = root['data'] ?? root;
      if (data is List) return data;
      if (data is Map) {
        return data['history'] ??
              data['items'] ??
              root['history'] ??
              root['items'] ??
              [];
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Fetch leaderboard data with filters
  static Future<List<dynamic>> getLeaderboard({
    String type = 'all-time',
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final res = await ApiClient.get(
        '/leaderboard?type=$type&page=$page&limit=$limit',
      );
      final root = res as Map<String, dynamic>? ?? {};
      final data = root['data'] ?? root;
      if (data is List) return data;
      if (data is Map) {
        return data['leaderboard'] ??
              data['items'] ??
              root['leaderboard'] ??
              root['items'] ??
              [];
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Get transaction history
  static Future<List<Map<String, dynamic>>> getTransactionHistory({int limit = 50}) async {
    try {
      final savedData = await UserProfileService.getSavedUserData();
      final currentUserId = savedData['id'] ?? 0;
      return await UserProfileService.getTransactionHistory(currentUserId, limit: limit);
    } catch (_) {
      return [];
    }
  }

  /// Save user data locally
  static Future<void> saveUserDataLocally(Map<String, dynamic> userData) async {
    await UserProfileService.saveUserDataLocally(userData);
  }

  /// Get saved user data
  static Future<Map<String, dynamic>> getSavedUserData() async {
    return await UserProfileService.getSavedUserData();
  }

  /// Clear saved user data
  static Future<void> clearUserData() async {
    await UserProfileService.clearUserData();
  }
}
