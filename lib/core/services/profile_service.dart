import 'api_client.dart';

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
}
