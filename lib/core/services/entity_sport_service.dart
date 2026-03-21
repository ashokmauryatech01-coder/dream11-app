import 'dart:convert';
import 'package:http/http.dart' as http;

class EntitySportService {
  static const String baseUrl = 'https://restapi.entitysport.com/v2';
  static const String token = '44b16e8558165c3b9fed0b6ad7814377';

  static Future<Map<String, dynamic>> _get(String path) async {
    final uri = Uri.parse('$baseUrl$path');
    print('EntitySport API Request: $uri');
    final response = await http
        .get(uri, headers: {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      print('EntitySport API Error: ${response.statusCode} - ${response.body}');
      throw Exception('HTTP ${response.statusCode}');
    }
  }

  // 1. LIVE MATCHES — status=3
  static Future<List<Map<String, dynamic>>> getLiveMatches({
    int perPage = 20,
    int page = 1,
  }) async {
    try {
      final data = await _get(
        '/matches?token=$token&status=3&per_page=$perPage&paged=$page',
      );
      if (data['status'] == 'ok')
        return (data['response']?['items'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>();
      print('EntitySport getLiveMatches returned status: ${data['status']}');
      return [];
    } catch (e) {
      print('Error in getLiveMatches: $e');
      return [];
    }
  }

  // 2. UPCOMING MATCHES — status=1
  static Future<List<Map<String, dynamic>>> getUpcomingMatches({
    int perPage = 20,
    int page = 1,
  }) async {
    try {
      final data = await _get(
        '/matches?token=$token&status=1&per_page=$perPage&paged=$page',
      );
      if (data['status'] == 'ok')
        return (data['response']?['items'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>();
      print(
        'EntitySport getUpcomingMatches returned status: ${data['status']}',
      );
      return [];
    } catch (e) {
      print('Error in getUpcomingMatches: $e');
      return [];
    }
  }

  // 3. FINISHED MATCHES — status=2
  static Future<List<Map<String, dynamic>>> getFinishedMatches({
    int perPage = 20,
    int page = 1,
  }) async {
    try {
      final data = await _get(
        '/matches?token=$token&status=2&per_page=$perPage&paged=$page',
      );
      if (data['status'] == 'ok')
        return (data['response']?['items'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>();
      print(
        'EntitySport getFinishedMatches returned status: ${data['status']}',
      );
      return [];
    } catch (e) {
      print('Error in getFinishedMatches: $e');
      return [];
    }
  }

  // 4. LIVE SERIES (Competitions) — Use broader status filter
  static Future<List<Map<String, dynamic>>> getLiveSeries({
    int perPage = 20,
    int page = 1,
  }) async {
    try {
      // Trying status=active first, then try status=upcoming if needed
      final data = await _get(
        '/competitions?token=$token&status=active,upcoming&per_page=$perPage&paged=$page',
      );
      if (data['status'] == 'ok')
        return (data['response']?['items'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>();

      return [];
    } catch (e) {
      print('Error in getLiveSeries: $e');
      return [];
    }
  }

  // 5. FANTASY MATCH SQUAD — with player images + stats
  static Future<Map<String, dynamic>> getFantasySquad(int matchId) async {
    try {
      // Try /fantasy first as it's better for fantasy apps
      final fantasyData = await _get('/matches/$matchId/fantasy?token=$token');
      if (fantasyData['status'] == 'ok' && fantasyData['response'] != null) {
        return fantasyData['response'] as Map<String, dynamic>;
      }

      // Fallback to /squads
      final data = await _get('/matches/$matchId/squads?token=$token');
      if (data['status'] == 'ok')
        return data['response'] as Map<String, dynamic>? ?? {};

      return {};
    } catch (_) {
      // Last resort fallback
      try {
        final data = await _get('/matches/$matchId/squads?token=$token');
        if (data['status'] == 'ok')
          return data['response'] as Map<String, dynamic>? ?? {};
      } catch (__) {}
      return {};
    }
  }

  // 6. FANTASY MATCH POINTS
  static Future<Map<String, dynamic>> getFantasyPoints(int matchId) async {
    try {
      final data = await _get('/matches/$matchId/fpoints?token=$token');
      if (data['status'] == 'ok')
        return data['response'] as Map<String, dynamic>? ?? {};
      return {};
    } catch (_) {
      return {};
    }
  }

  // 7. MATCH SCORECARD — batting/bowling stats
  static Future<Map<String, dynamic>> getScorecard(int matchId) async {
    try {
      final data = await _get('/matches/$matchId/scorecard?token=$token');
      if (data['status'] == 'ok')
        return data['response'] as Map<String, dynamic>? ?? {};
      return {};
    } catch (_) {
      return {};
    }
  }

  // 8. MATCH INFO
  static Future<Map<String, dynamic>> getMatchInfo(int matchId) async {
    try {
      final data = await _get('/matches/$matchId?token=$token');
      if (data['status'] == 'ok')
        return data['response'] as Map<String, dynamic>? ?? {};
      return {};
    } catch (_) {
      return {};
    }
  }

  // 9. TEAM PLAYERS
  static Future<List<Map<String, dynamic>>> getTeamPlayers(int tid) async {
    try {
      final data = await _get('/teams/$tid/players?token=$token');
      if (data['status'] == 'ok') {
        final items = data['response']?['items'] as Map<String, dynamic>?;
        final players = items?['players'] as Map<String, dynamic>?;
        for (final format in ['t20', 'odi', 'test']) {
          final list = players?[format] as List<dynamic>?;
          if (list != null && list.isNotEmpty)
            return list.cast<Map<String, dynamic>>();
        }
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  // 10. PLAYER PROFILE
  static Future<Map<String, dynamic>> getPlayerProfile(int pid) async {
    try {
      final data = await _get('/players/$pid?token=$token');
      if (data['status'] == 'ok')
        return data['response']?['player'] as Map<String, dynamic>? ?? {};
      return {};
    } catch (_) {
      return {};
    }
  }

  // 11. PLAYERS BY MATCH
  static Future<List<Map<String, dynamic>>> getPlayersByMatch(
    int matchId,
  ) async {
    try {
      final data = await _get(
        '/players?token=$token&recent_match=$matchId&per_page=20',
      );
      if (data['status'] == 'ok') {
        return (data['response']?['items'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  // 12. LIVE MATCH DATA
  static Future<Map<String, dynamic>> getLiveScore(int matchId) async {
    try {
      final data = await _get('/matches/$matchId/live?token=$token');
      if (data['status'] == 'ok')
        return data['response'] as Map<String, dynamic>? ?? {};
      return {};
    } catch (_) {
      return {};
    }
  }
}
