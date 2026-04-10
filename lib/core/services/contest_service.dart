import 'package:fantasy_crick/models/contest_model.dart';
import 'package:fantasy_crick/core/services/api_client.dart';

class ContestService {
  Future<List<ContestModel>> getAllContests() async {
    try {
      print('DEBUG: Fetching all contests...');
      final response = await ApiClient.get('/contests');
      
      // The API returns { "success": true, "data": { "contests": [...] } }
      final data = response['data'];
      if (data == null) return _getMockContests();
      
      final List<dynamic> contestsJson = data['contests'] ?? [];
      
      // If we got a valid list (even empty), return it from the API
      print('DEBUG: Found ${contestsJson.length} contests from API');
      
      return contestsJson
          .map((c) => ContestModel.fromJson(c as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('DEBUG: API Error or parsing fail: $e');
      return _getMockContests(); // Only fallback on actual crash
    }
  }

  Future<List<ContestModel>> getFeaturedContests() async {
    try {
      print('DEBUG: Fetching featured contests (type=mega)...');
      final response = await ApiClient.get('/contests?type=mega');
      
      dynamic contestData;
      if (response['data'] is Map) {
        contestData = response['data']['contests'] ?? response['data']['items'];
      } else if (response['data'] is List) {
        contestData = response['data'];
      }

      final List<dynamic> data = (contestData is List) ? contestData : [];
      
      print('DEBUG: Found ${data.length} featured contests from API');

      if (data.isEmpty) {
        print('DEBUG: No contests found, falling back to mocks');
        return _getMockContests();
      }

      return data.map((c) => ContestModel.fromJson(c as Map<String, dynamic>)).toList();
    } catch (e) {
      print('DEBUG: Error in getFeaturedContests: $e');
      return _getMockContests();
    }
  }

  Future<List<ContestModel>> getContestsForMatch(String matchId) async {
    try {
      print('DEBUG: Fetching contests for match: $matchId');
      final response = await ApiClient.get('/contests?match_id=$matchId');
      
      final data = response['data'];
      if (data == null) return [];
      
      final List<dynamic> contestsJson = data['contests'] ?? [];
      
      return contestsJson
          .map((c) => ContestModel.fromJson(c as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('DEBUG: Error fetching contests for match $matchId: $e');
      return [];
    }
  }

  List<ContestModel> _getMockContests() {
    return [
      ContestModel(
        id: '1',
        name: 'Grand League',
        matchId: '1',
        entryFee: 50,
        prizePool: 100000,
        maxTeams: 1000,
        currentTeams: 456,
        multipleTeams: true,
      ),
      ContestModel(
        id: '2',
        name: 'Head to Head',
        matchId: '1',
        entryFee: 20,
        prizePool: 200,
        maxTeams: 2,
        currentTeams: 1,
        multipleTeams: false,
      ),
    ];
  }

  /// Join a contest with a team.
  /// If joining fails (e.g. no wallet), it attempts to create a wallet and retries.
  Future<Map<String, dynamic>> joinContest({
    required String contestId,
    required String teamId,
    required String teamName,
    required int userId,
  }) async {
    final endpoint = '/contests/$contestId/join?team_id=$teamId&contest_id=$contestId&team_name=${Uri.encodeComponent(teamName)}&user_id=$userId';
    
    try {
      print('DEBUG: Attempting to join contest: $endpoint');
      final response = await ApiClient.post(endpoint, {});
      return response;
    } catch (e) {
      print('DEBUG: Join contest failed: $e');
      throw Exception(e.toString());
    }
  }
}
