import 'package:fantasy_crick/core/services/entity_sport_service.dart';
import 'package:fantasy_crick/models/match_model.dart';

class MatchService {
  // Instance methods for compatibility with existing screens
  Future<List<MatchModel>> getLiveMatches() async {
    try {
      final matches = await EntitySportService.getLiveMatches();
      return matches.map((m) => MatchModel.fromEntitySport(m)).toList();
    } catch (e) {
      print('MatchService: Error in getLiveMatches: $e');
      return [];
    }
  }

  Future<List<MatchModel>> getUpcomingMatches() async {
    try {
      final matches = await EntitySportService.getUpcomingMatches();
      return matches.map((m) => MatchModel.fromEntitySport(m)).toList();
    } catch (e) {
      print('MatchService: Error in getUpcomingMatches: $e');
      return [];
    }
  }

  Future<List<MatchModel>> getFinishedMatches() async {
    try {
      final matches = await EntitySportService.getFinishedMatches();
      return matches.map((m) => MatchModel.fromEntitySport(m)).toList();
    } catch (e) {
      print('MatchService: Error in getFinishedMatches: $e');
      return [];
    }
  }

  // Static methods for general use — NOW ENTITY SPORT ONLY
  static Future<List<Map<String, dynamic>>> getMatches(String type) async {
    try {
      if (type == 'all' || type == 'live' || type == 'upcoming' || type == 'finished') {
        List<Map<String, dynamic>> matches = [];
        
        if (type == 'all') {
          // Parallelize but wrap each to ensure partial success
          final results = await Future.wait([
            EntitySportService.getLiveMatches().catchError((_) => <Map<String, dynamic>>[]),
            EntitySportService.getUpcomingMatches().catchError((_) => <Map<String, dynamic>>[]),
            EntitySportService.getFinishedMatches().catchError((_) => <Map<String, dynamic>>[]),
          ]);
          matches = [...results[0], ...results[1], ...results[2]];
        } else if (type == 'live') {
          matches = await EntitySportService.getLiveMatches();
        } else if (type == 'upcoming') {
          matches = await EntitySportService.getUpcomingMatches();
        } else if (type == 'finished') {
          matches = await EntitySportService.getFinishedMatches();
        }

        if (matches.isNotEmpty) {
          return matches.map((m) {
            final transformed = _transformMatch(m);
            transformed['raw'] = m;
            return transformed;
          }).toList();
        }
      }
      return [];
    } catch (e) {
      print('MatchService: Error fetching matches from EntitySport: $e');
      return [];
    }
  }

  static Map<String, dynamic> _transformMatch(Map<String, dynamic> m) {
    // If it's already an EntitySport response, keep it mostly as is but ensure some base fields
    if (m.containsKey('match_id') && m.containsKey('teama')) {
      return {
        ...m,
        'id': m['match_id'],
        'title': m['title'] ?? '${m['teama']?['short_name'] ?? 'T1'} vs ${m['teamb']?['short_name'] ?? 'T2'}',
        'status': int.tryParse(m['status']?.toString() ?? '1') ?? 1,
        'competition': m['competition'] ?? {'title': 'Cricket Match'},
      };
    }

    // Existing transform for internal API
    int statusInt = 1;
    final statusStr = m['status']?.toString().toLowerCase() ?? '';
    if (statusStr == 'live' || statusStr == '3') {
      statusInt = 3;
    } else if (statusStr == 'finished' ||
        statusStr == 'completed' ||
        statusStr == '2' ||
        m['status_text']?.toString().contains('Won') == true) {
      statusInt = 2;
    }

    return {
      'match_id': int.tryParse(m['additional_match_id']?.toString() ?? m['id']?.toString() ?? m['match_id']?.toString() ?? '0') ?? 0,
      'id': int.tryParse(m['additional_match_id']?.toString() ?? m['id']?.toString() ?? m['match_id']?.toString() ?? '0') ?? 0,
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
      'date_start_ist': m['time'] ?? m['date_start'] ?? '',
      'date_start': m['time'] ?? m['date_start'] ?? '',
      'venue': {
        'name': m['venue'] is Map ? m['venue']['name'] : (m['venue'] ?? ''),
        'location': m['venue'] is Map ? m['venue']['location'] : (m['title']?.toString().contains('•') == true
            ? m['title'].toString().split('•').last.trim()
            : ''),
      },
      'subtitle': m['title']?.toString().contains('•') == true
          ? m['title'].toString().split('•').last.trim()
          : (m['subtitle'] ?? ''),
    };
  }
}
