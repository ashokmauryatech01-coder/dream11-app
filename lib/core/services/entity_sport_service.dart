import 'dart:convert';
import 'package:http/http.dart' as http;

class EntitySportService {
  static const String baseUrl = 'https://restapi.entitysport.com/v2';
  static const String token = '44b16e8558165c3b9fed0b6ad7814377';

  static Future<Map<String, dynamic>> _get(String path) async {
    final uri = Uri.parse('$baseUrl$path');
    final response = await http.get(uri, headers: {
      'Accept': 'application/json',
    }).timeout(const Duration(seconds: 15));
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('HTTP ${response.statusCode}');
  }

  // 1. LIVE MATCHES — status=3
  static Future<List<Map<String, dynamic>>> getLiveMatches({int perPage = 20, int page = 1}) async {
    try {
      final data = await _get('/matches/?token=$token&status=3&per_page=$perPage&paged=$page');
      if (data['status'] == 'ok') return (data['response']?['items'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
      return [];
    } catch (_) { return []; }
  }

  // 2. UPCOMING MATCHES — status=1
  static Future<List<Map<String, dynamic>>> getUpcomingMatches({int perPage = 20, int page = 1}) async {
    try {
      final data = await _get('/matches/?token=$token&status=1&per_page=$perPage&paged=$page');
      if (data['status'] == 'ok') return (data['response']?['items'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
      return [];
    } catch (_) { return []; }
  }

  // 3. FINISHED MATCHES — status=2
  static Future<List<Map<String, dynamic>>> getFinishedMatches({int perPage = 20, int page = 1}) async {
    try {
      final data = await _get('/matches/?token=$token&status=2&per_page=$perPage&paged=$page');
      if (data['status'] == 'ok') return (data['response']?['items'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
      return [];
    } catch (_) { return []; }
  }

  // 4. LIVE SERIES (Competitions)
  static Future<List<Map<String, dynamic>>> getLiveSeries({int perPage = 20, int page = 1}) async {
    try {
      final data = await _get('/competitions/?token=$token&status=result&per_page=$perPage&paged=$page');
      if (data['status'] == 'ok') return (data['response']?['items'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
      return [];
    } catch (_) { return []; }
  }

  // 5. FANTASY MATCH SQUAD — with player images + stats
  static Future<Map<String, dynamic>> getFantasySquad(int matchId) async {
    try {
      final data = await _get('/matches/$matchId/squads/?token=$token');
      if (data['status'] == 'ok') return data['response'] as Map<String, dynamic>? ?? {};
      return {};
    } catch (_) { return {}; }
  }

  // 6. FANTASY MATCH POINTS
  static Future<Map<String, dynamic>> getFantasyPoints(int matchId) async {
    try {
      final data = await _get('/matches/$matchId/fpoints/?token=$token');
      if (data['status'] == 'ok') return data['response'] as Map<String, dynamic>? ?? {};
      return {};
    } catch (_) { return {}; }
  }

  // 7. MATCH SCORECARD — batting/bowling stats (strike rate, economy, avg)
  static Future<Map<String, dynamic>> getScorecard(int matchId) async {
    try {
      final data = await _get('/matches/$matchId/scorecard/?token=$token');
      if (data['status'] == 'ok') return data['response'] as Map<String, dynamic>? ?? {};
      return {};
    } catch (_) { return {}; }
  }

  // 8. MATCH INFO — detailed match meta
  static Future<Map<String, dynamic>> getMatchInfo(int matchId) async {
    try {
      final data = await _get('/matches/$matchId/?token=$token');
      if (data['status'] == 'ok') return data['response'] as Map<String, dynamic>? ?? {};
      return {};
    } catch (_) { return {}; }
  }

  // 9. TEAM PLAYERS — fetch all players for a team with images
  static Future<List<Map<String, dynamic>>> getTeamPlayers(int tid) async {
    try {
      final data = await _get('/teams/$tid/player?token=$token');
      if (data['status'] == 'ok') {
        final items = data['response']?['items'] as Map<String, dynamic>?;
        final players = items?['players'] as Map<String, dynamic>?;
        // Try t20 first, then odi, then test
        for (final format in ['t20', 'odi', 'test']) {
          final list = players?[format] as List<dynamic>?;
          if (list != null && list.isNotEmpty) return list.cast<Map<String, dynamic>>();
        }
      }
      return [];
    } catch (_) { return []; }
  }

  // 10. PLAYER PROFILE — individual player details
  static Future<Map<String, dynamic>> getPlayerProfile(int pid) async {
    try {
      final data = await _get('/players/$pid?token=$token');
      if (data['status'] == 'ok') return data['response']?['player'] as Map<String, dynamic>? ?? {};
      return {};
    } catch (_) { return {}; }
  }
}
