import 'dart:convert';
import 'package:http/http.dart' as http;

class EntitySportService {
  static const String baseUrl = 'https://restapi.entitysport.com/v2';
  static const String token = '7e6097d77280407b05b3a124507e1c69';

  static Future<Map<String, dynamic>> _get(String path) async {
    final url = Uri.parse('$baseUrl$path');
    print('DEBUG: EntitySportService GET: $url');
    final response = await http.get(url);
    print('DEBUG: EntitySportService STATUS: ${response.statusCode}');

    if (response.statusCode == 200) {
      final body = response.body;
      print('DEBUG: EntitySportService BODY (start): ${body.length > 200 ? body.substring(0, 200) : body}');
      return json.decode(body) as Map<String, dynamic>;
    } else {
      print('EntitySport API Error: ${response.statusCode} - ${response.body}');
      throw Exception('HTTP ${response.statusCode}');
    }
  }

  // 1. LIVE MATCHES — status=3
  static Future<List<Map<String, dynamic>>> getLiveMatches({
    int perPage = 50,
    int page = 1,
  }) async {
    try {
      final data = await _get(
        '/matches?token=$token&status=3&per_page=$perPage&paged=$page&pre_fetch=true',
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
    int perPage = 50,
    int page = 1,
  }) async {
    try {
      final data = await _get(
        '/matches?token=$token&status=1&per_page=$perPage&paged=$page&pre_fetch=true',
      );
      if (data['status'] == 'ok') {
        final items = (data['response']?['items'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>();
        print('EntitySport getUpcomingMatches returned ${items.length} items');
        return items;
      }
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
    int perPage = 50,
    int page = 1,
  }) async {
    try {
      final data = await _get(
        '/matches?token=$token&status=2&per_page=$perPage&paged=$page&pre_fetch=true',
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

  // 4. LIVE SERIES (Competitions) — Use documented status values
  static Future<List<Map<String, dynamic>>> getLiveSeries({
    int perPage = 50,
    int page = 1,
  }) async {
    try {
      // Possible values are live (currently ongoing), fixture (upcoming), result (completed)
      final data = await _get(
        '/competitions?token=$token&status=live,fixture&per_page=$perPage&paged=$page',
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

  static Future<Map<String, dynamic>> getMatchPoints(int matchId) async {
    try {
      final data = await _get('/matches/$matchId/point?token=$token');
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

  // 13. COMPETITION MATCHES
  static Future<List<Map<String, dynamic>>> getCompetitionMatches(int cid,
      {int perPage = 50, int page = 1}) async {
    try {
      final data = await _get(
          '/competitions/$cid/matches?token=$token&per_page=$perPage&paged=$page&pre_fetch=true');
      if (data['status'] == 'ok')
        return (data['response']?['items'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>();
      return [];
    } catch (_) {
      return [];
    }
  }

  // 14. COMPETITION TEAMS
  static Future<List<Map<String, dynamic>>> getCompetitionTeams(int cid) async {
    try {
      final data = await _get('/competitions/$cid/teams?token=$token');
      if (data['status'] == 'ok')
        return (data['response']?['teams'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
      return [];
    } catch (_) {
      return [];
    }
  }

  // 15. COMPETITION SQUADS
  static Future<Map<String, dynamic>> getCompetitionSquads(int cid) async {
    try {
      final data = await _get('/competitions/$cid/squads?token=$token');
      if (data['status'] == 'ok')
        return data['response'] as Map<String, dynamic>? ?? {};
      return {};
    } catch (_) {
      return {};
    }
  }
}
