import 'package:fantasy_crick/models/contest_model.dart';
import 'package:fantasy_crick/core/services/api_client.dart';

class ContestService {
  Future<List<ContestModel>> getFeaturedContests() async {
    try {
      final response = await ApiClient.get('/contests?type=mega');
      final data = response['data'] as List<dynamic>? ?? [];
      if (data.isEmpty) {
        // Fallback mock data if API is empty or down for local demo
        return _getMockContests();
      }
      return data.map((c) => ContestModel.fromJson(c as Map<String, dynamic>)).toList();
    } catch (_) {
      return _getMockContests();
    }
  }

  Future<List<ContestModel>> getContestsForMatch(String matchId) async {
    try {
      final response = await ApiClient.get('/contests?match_id=$matchId&type=all');
      final data = response['data']?['contests'] as List<dynamic>? ?? 
                   response['data'] as List<dynamic>? ?? [];
      return data.map((c) => ContestModel.fromJson(c as Map<String, dynamic>)).toList();
    } catch (_) {
      return _getMockContests();
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
}
