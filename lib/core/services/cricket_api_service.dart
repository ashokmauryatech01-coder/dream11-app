import 'api_client.dart';

class CricketApiService {
  Future<List<Map<String, dynamic>>> getCurrentMatches({int offset = 0}) async {
    try {
      final response = await ApiClient.get('/cricket/matches');
      return List<Map<String, dynamic>>.from(response['data'] ?? []);
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getMatchesList({int offset = 0}) async {
    try {
      final response = await ApiClient.get('/cricket/matches');
      return List<Map<String, dynamic>>.from(response['data'] ?? []);
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getMatchesLive() async {
    try {
      final response = await ApiClient.get('/cricket/live-matches');
      return List<Map<String, dynamic>>.from(response['data'] ?? []);
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>> getMatchInfo(String matchId) async {
    try {
      final response = await ApiClient.get('/cricket/matches/$matchId');
      return response['data'] as Map<String, dynamic>? ?? {};
    } catch (_) {
      return {};
    }
  }

  Future<Map<String, dynamic>> getMatchScorecard(String matchId) async {
    try {
      final response = await ApiClient.get('/cricket/matches/$matchId/scorecard');
      return response['data'] as Map<String, dynamic>? ?? {};
    } catch (_) {
      return {};
    }
  }

  Future<List<Map<String, dynamic>>> getMatchSquad(String matchId) async {
    try {
      final response = await ApiClient.get('/cricket/matches/$matchId/squad');
      return List<Map<String, dynamic>>.from(response['data'] ?? []);
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getSeriesList({int offset = 0, String? search}) async {
    try {
      final response = await ApiClient.get('/cricket/live-series');
      return List<Map<String, dynamic>>.from(response['data'] ?? []);
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>> getSeriesInfo(String seriesId) async {
    try {
      final response = await ApiClient.get('/cricket/series/$seriesId');
      return response['data'] as Map<String, dynamic>? ?? {};
    } catch (_) {
      return {};
    }
  }

  Future<List<Map<String, dynamic>>> getSchedule() async {
    return getSeriesList();
  }

  Future<List<Map<String, dynamic>>> getPlayersList({int offset = 0, String? search}) async {
    try {
      final response = await ApiClient.get('/players?page=1&limit=20');
      return List<Map<String, dynamic>>.from(response['data'] ?? []);
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>> getPlayerInfo(String playerId) async {
    try {
      final response = await ApiClient.get('/players/$playerId');
      return response['data'] as Map<String, dynamic>? ?? {};
    } catch (_) {
      return {};
    }
  }

  Future<Map<String, dynamic>> getMatchPoints(String matchId, {int ruleset = 0}) async {
    try {
      final response = await ApiClient.get('/matches/$matchId');
      return response['data'] as Map<String, dynamic>? ?? {};
    } catch (_) {
      return {};
    }
  }

  // Legacy
  Future<List<Map<String, dynamic>>> getUpcomingMatches({int offset = 0}) async {
    try {
      final response = await ApiClient.get('/cricket/upcoming-matches');
      return List<Map<String, dynamic>>.from(response['data'] ?? []);
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getRecentMatches({int offset = 0}) async {
    try {
      final response = await ApiClient.get('/cricket/finished-matches');
      return List<Map<String, dynamic>>.from(response['data'] ?? []);
    } catch (_) {
      return [];
    }
  }

  void dispose() {}
}
