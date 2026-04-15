import 'package:fantasy_crick/models/cricket_team_model.dart';
import 'package:fantasy_crick/core/services/cricket_api_service.dart';
import 'package:fantasy_crick/core/services/api_client.dart';
import 'user_profile_service.dart';

/// ============================================================================
/// TEAMS SERVICE - Updated for CricAPI
/// ============================================================================
///
/// Service layer for fetching team data.
/// Note: CricAPI doesn't have a dedicated teams endpoint.
/// Team data comes from match squad API.
///
/// ============================================================================

class TeamsService {
  final CricketApiService _api = CricketApiService();

  /// Get teams from a specific match squad
  Future<List<CricketTeamModel>> getTeamsFromMatch(String matchId) async {
    try {
      final squadData = await _api.getMatchSquad(matchId);
      final List<CricketTeamModel> teams = [];

      for (final squad in squadData) {
        final teamName = squad['teamName'] as String? ?? '';
        if (teamName.isNotEmpty) {
          teams.add(
            CricketTeamModel(
              id: teamName.hashCode.toString(),
              name: teamName,
              shortName: _getShortName(teamName),
              imageUrl: null,
            ),
          );
        }
      }

      return teams;
    } catch (e) {
      return [];
    }
  }

  /// Get teams from current matches (extracts unique teams)
  Future<List<CricketTeamModel>> getAllTeams() async {
    try {
      final matches = await _api.getCurrentMatches();
      final Set<String> teamNames = {};
      final List<CricketTeamModel> teams = [];

      for (final match in matches) {
        final teamsList = match['teams'] as List<dynamic>? ?? [];
        final teamInfoList = match['teamInfo'] as List<dynamic>? ?? [];

        for (int i = 0; i < teamsList.length; i++) {
          final teamName = teamsList[i].toString();
          if (!teamNames.contains(teamName)) {
            teamNames.add(teamName);

            // Find team info
            String? shortName;
            String? imageUrl;
            if (i < teamInfoList.length) {
              final info = teamInfoList[i] as Map<String, dynamic>;
              shortName = info['shortname'] as String?;
              imageUrl = info['img'] as String?;
            }

            teams.add(
              CricketTeamModel(
                id: teamName.hashCode.toString(),
                name: teamName,
                shortName: shortName ?? _getShortName(teamName),
                imageUrl: imageUrl,
              ),
            );
          }
        }
      }

      // Sort alphabetically
      teams.sort((a, b) => a.name.compareTo(b.name));
      return teams;
    } catch (e) {
      return [];
    }
  }

  /// Fetch international cricket teams
  Future<List<CricketTeamModel>> getInternationalTeams() async {
    return getAllTeams();
  }

  /// Fetch league cricket teams
  Future<List<CricketTeamModel>> getLeagueTeams() async {
    return getAllTeams();
  }

  /// Fetch domestic cricket teams
  Future<List<CricketTeamModel>> getDomesticTeams() async {
    return getAllTeams();
  }

  /// Fetch women's cricket teams
  Future<List<CricketTeamModel>> getWomenTeams() async {
    return getAllTeams();
  }

  /// Fetch user's teams for a specific match via GET /teams?match_id=...
  Future<List<Map<String, dynamic>>> getMyTeams(int matchId) async {
    try {
      final userId = await UserProfileService.getSavedUserId();
      if (userId == 0) {
        print(
          'DEBUG: TeamsService.getMyTeams - No userId found, returning empty',
        );
        return [];
      }

      if (matchId <= 0) {
        print(
          'DEBUG: TeamsService.getMyTeams - Invalid matchId: $matchId, returning empty',
        );
        return [];
      }

      // Hit the exact endpoint: /api/v1/teams?match_id={{match_id}}&page=1&limit=10
      final endpoint = '/teams?match_id=$matchId&page=1&limit=10';
      print('DEBUG: TeamsService.getMyTeams - GET $endpoint');

      final response = await ApiClient.get(endpoint);
      print('DEBUG: TeamsService.getMyTeams - RAW RESPONSE: $response');

      if (response == null) {
        print(
          'DEBUG: TeamsService.getMyTeams - Response is null, returning empty',
        );
        return [];
      }

      // Check success flag
      final success = response['success'];
      print('DEBUG: TeamsService.getMyTeams - success=$success');

      if (success != true) {
        print(
          'DEBUG: TeamsService.getMyTeams - success is not true, returning empty',
        );
        return [];
      }

      // Parse data — handle all possible shapes
      final data = response['data'];
      print('DEBUG: TeamsService.getMyTeams - data type: ${data.runtimeType}');
      print('DEBUG: TeamsService.getMyTeams - data value: $data');

      List<dynamic> teamsList = [];

      if (data == null) {
        teamsList = [];
      } else if (data is List) {
        teamsList = data;
      } else if (data is Map) {
        // Try all known keys the backend might use
        if (data.containsKey('teams') && data['teams'] is List) {
          teamsList = data['teams'];
        } else if (data.containsKey('items') && data['items'] is List) {
          teamsList = data['items'];
        } else if (data.containsKey('team') && data['team'] is Map) {
          teamsList = [data['team']];
        } else if (data.containsKey('team') && data['team'] is List) {
          teamsList = data['team'];
        } else if (data.containsKey('id')) {
          // data itself IS a single team object
          teamsList = [data];
        } else {
          // Try 'list' key as final fallback
          teamsList = data['list'] ?? [];
        }
      }

      final results = <Map<String, dynamic>>[];
      for (final t in teamsList) {
        if (t is Map<String, dynamic>) {
          results.add(t);
        } else if (t is Map) {
          results.add(Map<String, dynamic>.from(t));
        }
      }

      print(
        'DEBUG: TeamsService.getMyTeams - Parsed ${results.length} teams from primary API for matchId=$matchId',
      );

      // FALLBACK: If primary endpoint returns empty, try the profile's working endpoint
      if (results.isEmpty) {
        print(
          'DEBUG: TeamsService.getMyTeams - Fallback: trying show-contest-teams for matchId=$matchId',
        );
        final fallbackRes = await ApiClient.post(
          '/teams/show-contest-teams?user_id=$userId',
          {
            'user_id': userId,
            'match_id': matchId, // Include match_id in the body
            'matchId': matchId,   // Some backends use camelCase
          },
        );

        if (fallbackRes != null && fallbackRes['success'] == true) {
          final fbData = fallbackRes['data'];
          List<dynamic> fbList = [];
          if (fbData is List) {
            fbList = fbData;
          } else if (fbData is Map && fbData.containsKey('teams')) {
            fbList = fbData['teams'] as List<dynamic>? ?? [];
          }

          for (final t in fbList) {
            final teamMap = Map<String, dynamic>.from(t as Map);
            // LENIENT MATCHING: check match_id, matchId, or contest_id
            final rawTMatchId = (teamMap['match_id'] ?? teamMap['matchId'] ?? teamMap['contest_match_id'])?.toString().trim() ?? '';
            final targetMatchId = matchId.toString().trim();
            
            print('DEBUG: TeamsService.getMyTeams (Eval) - Team ID ${teamMap['id']} ("${teamMap['name']}") has match_id: "$rawTMatchId", looking for: "$targetMatchId"');

            if (rawTMatchId == targetMatchId || 
                (rawTMatchId.isNotEmpty && targetMatchId.isNotEmpty && targetMatchId.contains(rawTMatchId)) ||
                (rawTMatchId.isNotEmpty && targetMatchId.isNotEmpty && rawTMatchId.contains(targetMatchId))) {
              results.add(teamMap);
            }
          }
          print(
            'DEBUG: TeamsService.getMyTeams - Found ${results.length} teams via fallback for matchId=$matchId (Total user teams: ${fbList.length})',
          );
        }
      }

      for (int i = 0; i < results.length; i++) {
        print(
          'DEBUG:   Team[$i]: id=${results[i]['id']}, name=${results[i]['name']}',
        );
      }

      return results;
    } catch (e) {
      print('DEBUG: TeamsService.getMyTeams - EXCEPTION: $e');
      return [];
    }
  }

  /// Save a new team to the backend
  Future<Map<String, dynamic>> saveTeam({
    required String name,
    required int matchId,
    required List<int> playerIds,
    required int captainId,
    required int viceCaptainId,
  }) async {
    print("playerIds: $playerIds");
    print("matchId: $matchId");
    final response = await ApiClient.post('/teams', {
      'name': name,
      'match_id': matchId,
      'players': playerIds,
      'captain_id': captainId,
      'vice_captain_id': viceCaptainId,
    });
    print("responseeeeeeeeeeeeeeeeeeeeeeeee: $response");

    if (response != null && response['success'] != false) {
      return response;
    }

    throw Exception(response?['message'] ?? 'Failed to save team.');
  }

  /// Show team details: GET /teams/show-contest-teams?teamId=X&user_id=Y
  Future<Map<String, dynamic>> showTeam({
    required int teamId,
    required int userId,
  }) async {
    try {
      final endpoint =
          '/teams/show-contest-teams?teamId=$teamId&user_id=$userId';
      print('DEBUG: TeamsService.showTeam - GET $endpoint');
      final response = await ApiClient.get(endpoint);
      print('DEBUG: TeamsService.showTeam - Response: $response');
      if (response != null && response['success'] == true) {
        return response['data'] ?? response;
      }
      return response ?? {};
    } catch (e) {
      print('DEBUG: TeamsService.showTeam - ERROR: $e');
      rethrow;
    }
  }

  /// Update team: POST /teams/update-contest-team
  Future<Map<String, dynamic>> updateTeam({
    required int teamId,
    required String name,
    required List<int> playerIds,
    required int captainId,
    required int viceCaptainId,
  }) async {
    try {
      final body = {
        'teamId': teamId,
        'name': name,
        'players': playerIds,
        'captain_id': captainId,
        'vice_captain_id': viceCaptainId,
      };
      print('DEBUG: TeamsService.updateTeam - POST /teams/update-contest-team');
      print('DEBUG: TeamsService.updateTeam - body: $body');
      final response = await ApiClient.post('/teams/update-contest-team', body);
      print('DEBUG: TeamsService.updateTeam - Response: $response');
      if (response != null && response['success'] != false) {
        return response;
      }
      throw Exception(response?['message'] ?? 'Failed to update team.');
    } catch (e) {
      print('DEBUG: TeamsService.updateTeam - ERROR: $e');
      rethrow;
    }
  }

  /// Delete team: POST /teams/delete-contest-team
  Future<Map<String, dynamic>> deleteTeam({required int teamId}) async {
    try {
      final body = {'teamId': teamId};
      print(
        'DEBUG: TeamsService.deleteTeam - POST /teams/delete-contest-team',
      );
      print('DEBUG: TeamsService.deleteTeam - body: $body');
      final response = await ApiClient.post(
        '/teams/delete-contest-team',
        body,
      );
      print('DEBUG: TeamsService.deleteTeam - Response: $response');
      if (response != null && response['success'] == true) {
        return response;
      }
      throw Exception(response?['message'] ?? 'Failed to delete team.');
    } catch (e) {
      print('DEBUG: TeamsService.deleteTeam - ERROR: $e');
      rethrow;
    }
  }

  /// Get all teams via {{base_url}}/api/v1/teams
  static Future<List<Map<String, dynamic>>> getAllUserTeams() async {
    try {
      final userId = await UserProfileService.getSavedUserId();
      if (userId == 0) {
        print('DEBUG: TeamsService.getAllUserTeams - No userId found, returning empty');
        return [];
      }

      final endpoint = '/teams?page=1&limit=50';
      print('DEBUG: TeamsService.getAllUserTeams - GET $endpoint');
      
      final response = await ApiClient.get(endpoint);
      print('DEBUG: TeamsService.getAllUserTeams - Response: $response');

      if (response == null || response['success'] != true) {
        return [];
      }

      final data = response['data'];
      List<dynamic> teamsList = [];
      
      if (data is List) {
        teamsList = data;
      } else if (data is Map) {
        if (data.containsKey('teams') && data['teams'] is List) {
          teamsList = data['teams'];
        } else if (data.containsKey('items') && data['items'] is List) {
          teamsList = data['items'];
        } else if (data.containsKey('list') && data['list'] is List) {
          teamsList = data['list'];
        }
      }

      final results = <Map<String, dynamic>>[];
      for (final t in teamsList) {
        if (t is Map<String, dynamic>) {
          results.add(t);
        }
      }

      print('DEBUG: TeamsService.getAllUserTeams - Found ${results.length} teams');
      return results;
    } catch (e) {
      print('DEBUG: TeamsService.getAllUserTeams - EXCEPTION: $e');
      return [];
    }
  }

  /// Get team players via {{base_url}}/api/v1/teams/show-contest-teams?teamId=535&page=1&user_id=26
  static Future<Map<String, dynamic>> getTeamPlayers({
    required int teamId,
    required int userId,
    int page = 1,
  }) async {
    try {
      final endpoint = '/teams/show-contest-teams?teamId=$teamId&page=$page&user_id=$userId';
      print('DEBUG: TeamsService.getTeamPlayers - GET $endpoint');
      print('DEBUG: TeamsService.getTeamPlayers - Request params: teamId=$teamId, userId=$userId, page=$page');
      
      final response = await ApiClient.get(endpoint);
      print('DEBUG: TeamsService.getTeamPlayers - RAW JSON Response: $response');
      print('DEBUG: TeamsService.getTeamPlayers - Response Type: ${response.runtimeType}');

      if (response != null) {
        print('DEBUG: TeamsService.getTeamPlayers - Response keys: ${response.keys}');
        
        if (response['success'] == true) {
          final data = response['data'] ?? response;
          print('DEBUG: TeamsService.getTeamPlayers - SUCCESS - Data keys: ${data is Map ? data.keys : "N/A"}');
          return data is Map<String, dynamic> ? data : {};
        } else {
          print('DEBUG: TeamsService.getTeamPlayers - API returned success=false: ${response['message']}');
          // Return empty map but don't throw - let caller handle missing data
          return {};
        }
      }
      
      print('DEBUG: TeamsService.getTeamPlayers - Response is null');
      return {};
    } catch (e) {
      print('DEBUG: TeamsService.getTeamPlayers - EXCEPTION: $e');
      print('DEBUG: TeamsService.getTeamPlayers - Stack trace: ${StackTrace.current}');
      // Return empty map on error instead of throwing
      return {};
    }
  }

  /// Helper to generate short name
  String _getShortName(String name) {
    final words = name.split(' ');
    if (words.length > 1) {
      return words.map((w) => w.isNotEmpty ? w[0] : '').join().toUpperCase();
    }
    return name.length > 3
        ? name.substring(0, 3).toUpperCase()
        : name.toUpperCase();
  }
}
