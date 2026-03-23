import 'package:fantasy_crick/models/contest_model.dart';
import 'package:fantasy_crick/core/services/api_client.dart';

class ContestService {
  Future<List<ContestModel>> getAllContests() async {
    try {
      final response = await ApiClient.get('/contests?type=all&page=1&limit=100');
      final data = response['data']?['contests'] ?? 
                   response['data']?['items'] ?? 
                   response['data'] as List<dynamic>? ?? [];
      
      if (data.isEmpty) return _getMockContests();
      return data.map((c) => ContestModel.fromJson(c as Map<String, dynamic>)).toList();
    } catch (_) {
      return _getMockContests();
    }
  }

  Future<List<ContestModel>> getFeaturedContests() async {
    try {
      final response = await ApiClient.get('/contests?type=mega');
      final data = response['data']?['contests'] ?? 
                   response['data']?['items'] ?? 
                   response['data'] as List<dynamic>? ?? [];
      if (data.isEmpty) return _getMockContests();
      return data.map((c) => ContestModel.fromJson(c as Map<String, dynamic>)).toList();
    } catch (_) {
      return _getMockContests();
    }
  }

  Future<List<ContestModel>> getContestsForMatch(String matchId) async {
    try {
      final response = await ApiClient.get('/contests?match_id=$matchId&type=all');
      final data = response['data']?['contests'] ?? 
                   response['data']?['items'] ?? 
                   response['data'] as List<dynamic>? ?? [];
      if (data.isEmpty) return [];
      return data.map((c) => ContestModel.fromJson(c as Map<String, dynamic>)).toList();
    } catch (_) {
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
}
