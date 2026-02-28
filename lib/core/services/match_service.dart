import 'package:fantasy_crick/core/services/api_client.dart';
import 'package:fantasy_crick/models/match_model.dart';

class MatchService {
  // Instance methods for compatibility with existing screens
  Future<List<MatchModel>> getLiveMatches() async {
    final matches = await getMatches('all');
    return _convertToModels(matches.where((m) => m['status'] == 3).toList());
  }

  Future<List<MatchModel>> getUpcomingMatches() async {
    final matches = await getMatches('all');
    return _convertToModels(matches.where((m) => m['status'] == 1).toList());
  }

  Future<List<MatchModel>> getFinishedMatches() async {
    final matches = await getMatches('all');
    return _convertToModels(matches.where((m) => m['status'] == 2).toList());
  }

  List<MatchModel> _convertToModels(List<Map<String, dynamic>> maps) {
    // This is tricky because MatchModel needs specific fields
    // We'll use a new factory or transform back
    return maps
        .map((m) => MatchModel.fromNewApi(m['raw'] as Map<String, dynamic>))
        .toList();
  }

  // Static methods for general use
  static Future<List<Map<String, dynamic>>> getMatches(String type) async {
    try {
      final response = await ApiClient.get(
        '/matches?type=$type&page=1&limit=50',
      );
      final list = response?['data']?['matches'] as List<dynamic>? ?? [];
      return list.map((m) {
        final map = m as Map<String, dynamic>;
        final transformed = _transformMatch(map);
        transformed['raw'] =
            map; // Keep raw for MatchModel conversion if needed
        return transformed;
      }).toList();
    } catch (e) {
      print('Error fetching matches: $e');
      return [];
    }
  }

  static Map<String, dynamic> _transformMatch(Map<String, dynamic> m) {
    // Determine status integer for UI: 1=upcoming, 3=live, 2=finished
    int statusInt = 1;
    final statusStr = m['status']?.toString().toLowerCase() ?? '';
    if (statusStr == 'live') {
      statusInt = 3;
    } else if (statusStr == 'finished' ||
        statusStr == 'completed' ||
        m['status_text']?.toString().contains('Won') == true) {
      statusInt = 2;
    }

    return {
      'match_id': m['id'],
      'id': m['id'],
      'title': m['title'],
      'status': statusInt,
      'status_str': statusStr,
      'status_note': m['status_text'] ?? '',
      'teama': {
        'team_id': 1,
        'short_name': m['team1_code'] ?? 'T1',
        'name': m['team1_code'] ?? 'Team 1',
        'logo_url': m['team1_flag']?.toString() ?? '',
        'scores': m['team1_score'] ?? '',
        'scores_full': m['team1_score'] ?? '',
      },
      'teamb': {
        'team_id': 2,
        'short_name': m['team2_code'] ?? 'T2',
        'name': m['team2_code'] ?? 'Team 2',
        'logo_url': m['team2_flag']?.toString() ?? '',
        'scores': m['team2_score'] ?? '',
        'scores_full': m['team2_score'] ?? '',
      },
      'competition': {
        'title': m['title']?.toString().contains('•') == true
            ? m['title'].toString().split('•').first.trim()
            : 'Cricket Match',
        'abbr': m['title']?.toString().contains('•') == true
            ? m['title'].toString().split('•').first.trim()
            : 'Match',
      },
      'date_start_ist': m['time'] ?? '',
      'date_start': m['time'] ?? '',
      'venue': {
        'name': m['venue'] ?? '',
        'location': m['title']?.toString().contains('•') == true
            ? m['title'].toString().split('•').last.trim()
            : '',
      },
      'subtitle': m['title']?.toString().contains('•') == true
          ? m['title'].toString().split('•').last.trim()
          : '',
    };
  }
}
