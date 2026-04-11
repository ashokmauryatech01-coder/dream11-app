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
      if (data['status'] == 'ok') {
        return (data['response']?['items'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>();
      }
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
        return (data['response']?['items'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      print('Error in getUpcomingMatches: $e');
      return [];
    }
  }

  // 3. COMPLETED MATCHES — status=2
  static Future<List<Map<String, dynamic>>> getCompletedMatches({
    int perPage = 50,
    int page = 1,
  }) async {
    try {
      final data = await _get(
        '/matches?token=$token&status=2&per_page=$perPage&paged=$page',
      );
      if (data['status'] == 'ok') {
        return (data['response']?['items'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      print('Error in getCompletedMatches: $e');
      return [];
    }
  }

  // Alias for backward compatibility
  static Future<List<Map<String, dynamic>>> getFinishedMatches({
    int perPage = 50,
    int page = 1,
  }) => getCompletedMatches(perPage: perPage, page: page);

  static Future<Map<String, dynamic>> findIPLData() async {
    try {
      final data = await _get('/competitions?token=$token&per_page=100&type=t20');
      if (data['status'] == 'ok') {
        final comps = (data['response']?['items'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
        
        final iplComp = comps.firstWhere(
          (c) => c['abbr']?.toString().toUpperCase() == 'IPL' || 
                 c['title']?.toString().toLowerCase().contains('ipl') == true || 
                 c['title']?.toString().toLowerCase().contains('indian premier league') == true,
          orElse: () => {},
        );

        if (iplComp.isNotEmpty) {
          final cid = int.tryParse(iplComp['cid']?.toString() ?? '129908') ?? 129908;
          final matches = await getCompetitionMatches(cid);
          return {
            'matches': matches,
            'competition': iplComp,
          };
        }
      }
      
      final directMatches = await getCompetitionMatches(129908);
      return {
        'matches': directMatches,
        'competition': {
          'cid': 129908,
          'title': 'Indian Premier League',
          'abbr': 'IPL',
          'season': '2026',
        },
      };
    } catch (_) {
      try {
        final finalMatches = await getCompetitionMatches(129908);
        return {
          'matches': finalMatches,
          'competition': {
            'cid': 129908,
            'title': 'Indian Premier League',
            'abbr': 'IPL',
            'season': '2026',
          },
        };
      } catch (__) {
        return {'matches': [], 'competition': null};
      }
    }
  }

  // Alias for backward compatibility
  static Future<List<Map<String, dynamic>>> findIPLMatches() async {
    final res = await findIPLData();
    return (res['matches'] as List? ?? []).cast<Map<String, dynamic>>();
  }

  static Future<List<Map<String, dynamic>>> getCompetitionMatches(int cid) async {
    try {
      final data = await _get('/competitions/$cid/matches/?token=$token&per_page=100');
      if (data['status'] == 'ok') {
        return (data['response']?['items'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      print('Error in getCompetitionMatches: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getLiveSeries() async {
    try {
      final data = await _get('/competitions?token=$token&status=live&per_page=30');
      if (data['status'] == 'ok') {
        return (data['response']?['items'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> getMatchInfo(int matchId) async {
    try {
      final data = await _get('/matches/$matchId/info?token=$token');
      return data['response'] ?? {};
    } catch (_) {
      return {};
    }
  }

  static Future<Map<String, dynamic>> getScorecard(int matchId) async {
    try {
      final data = await _get('/matches/$matchId/scorecard?token=$token');
      return data['response'] ?? {};
    } catch (_) {
      return {};
    }
  }

  static Future<Map<String, dynamic>> getLiveScore(int matchId) async {
    try {
      final data = await _get('/matches/$matchId/live?token=$token');
      return data['response'] ?? {};
    } catch (_) {
      return {};
    }
  }

  static Future<Map<String, dynamic>> getFantasySquad(int matchId) async {
    try {
      final data = await _get('/matches/$matchId/squads?token=$token');
      return data['response'] ?? {};
    } catch (_) {
      return {};
    }
  }

  static Future<List<Map<String, dynamic>>> getPlayersByMatch(int matchId) async {
    try {
      final data = await _get('/matches/$matchId/squads?token=$token');
      final teams = data['response']?['teams'] as Map<String, dynamic>? ?? {};
      final List<Map<String, dynamic>> players = [];
      teams.forEach((key, team) {
        final teamPlayers = team['squad'] as List? ?? [];
        players.addAll(teamPlayers.cast<Map<String, dynamic>>());
      });
      return players;
    } catch (_) {
      return [];
    }
  }
  
  static Future<Map<String, dynamic>> getMatchPoints(int matchId) async {
    try {
      return await _get('/matches/$matchId/point?token=$token');
    } catch (e) {
      print('Error in getMatchPoints: $e');
      return {};
    }
  }
}
