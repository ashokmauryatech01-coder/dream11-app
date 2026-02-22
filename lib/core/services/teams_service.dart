import 'package:fantasy_crick/models/cricket_team_model.dart';
import 'package:fantasy_crick/core/services/cricket_api_service.dart';

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
          teams.add(CricketTeamModel(
            id: teamName.hashCode.toString(),
            name: teamName,
            shortName: _getShortName(teamName),
            imageUrl: null,
          ));
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
            
            teams.add(CricketTeamModel(
              id: teamName.hashCode.toString(),
              name: teamName,
              shortName: shortName ?? _getShortName(teamName),
              imageUrl: imageUrl,
            ));
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

  /// Helper to generate short name
  String _getShortName(String name) {
    final words = name.split(' ');
    if (words.length > 1) {
      return words.map((w) => w.isNotEmpty ? w[0] : '').join().toUpperCase();
    }
    return name.length > 3 ? name.substring(0, 3).toUpperCase() : name.toUpperCase();
  }
}
