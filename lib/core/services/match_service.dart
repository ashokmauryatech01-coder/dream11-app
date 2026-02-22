import 'package:fantasy_crick/models/match_model.dart';
import 'package:fantasy_crick/models/scoreboard_model.dart';
import 'package:fantasy_crick/core/services/cricket_api_service.dart';

/// ============================================================================
/// MATCH SERVICE - Updated for CricAPI
/// ============================================================================
/// 
/// Service layer for fetching match data from CricAPI.
/// Uses CricketApiService as the data source.
/// 
/// ============================================================================

class MatchService {
  final CricketApiService _api = CricketApiService();

  /// Fetch current matches (live + recent)
  Future<List<MatchModel>> getCurrentMatches() async {
    try {
      final matchesData = await _api.getCurrentMatches();
      return matchesData.map((m) => MatchModel.fromCricApi(m)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Fetch upcoming matches
  Future<List<MatchModel>> getUpcomingMatches() async {
    try {
      final matchesData = await _api.getUpcomingMatches();
      final matches = matchesData.map((m) => MatchModel.fromCricApi(m)).toList();
      
      // Sort by date, nearest first
      matches.sort((a, b) => a.dateTime.compareTo(b.dateTime));
      
      // Return up to 20 upcoming matches
      return matches.take(20).toList();
    } catch (e) {
      return [];
    }
  }

  /// Fetch live matches
  Future<List<MatchModel>> getLiveMatches() async {
    try {
      final data = await _api.getMatchesLive();
      return data.map((m) => MatchModel.fromCricApi(m)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Fetch recent/completed matches
  Future<List<MatchModel>> getRecentMatches() async {
    try {
      final data = await _api.getRecentMatches();
      return data.map((m) => MatchModel.fromCricApi(m)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Fetch match info by ID
  Future<MatchInfoModel> getMatchInfo(String matchId) async {
    try {
      final data = await _api.getMatchInfo(matchId);
      return MatchInfoModel.fromJson(data);
    } catch (e) {
      return MatchInfoModel(raw: {});
    }
  }

  /// Fetch match scoreboard by ID
  Future<ScoreboardModel> getMatchScoreboard(String matchId) async {
    try {
      final data = await _api.getMatchScorecard(matchId);
      return ScoreboardModel.fromJson(data);
    } catch (e) {
      return ScoreboardModel();
    }
  }

  /// Fetch match squad by ID
  Future<List<Map<String, dynamic>>> getMatchSquad(String matchId) async {
    try {
      return await _api.getMatchSquad(matchId);
    } catch (e) {
      return [];
    }
  }

  /// Fetch all matches with pagination
  Future<List<MatchModel>> getAllMatches({int offset = 0}) async {
    try {
      final matchesData = await _api.getMatchesList(offset: offset);
      return matchesData.map((m) => MatchModel.fromCricApi(m)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get series list
  Future<List<Map<String, dynamic>>> getSeriesList({int offset = 0, String? search}) async {
    try {
      return await _api.getSeriesList(offset: offset, search: search);
    } catch (e) {
      return [];
    }
  }

  /// Get series info
  Future<Map<String, dynamic>> getSeriesInfo(String seriesId) async {
    try {
      return await _api.getSeriesInfo(seriesId);
    } catch (e) {
      return {};
    }
  }

  /// Get players list
  Future<List<Map<String, dynamic>>> getPlayersList({int offset = 0, String? search}) async {
    try {
      return await _api.getPlayersList(offset: offset, search: search);
    } catch (e) {
      return [];
    }
  }

  /// Get player info
  Future<Map<String, dynamic>> getPlayerInfo(String playerId) async {
    try {
      return await _api.getPlayerInfo(playerId);
    } catch (e) {
      return {};
    }
  }

  /// Get fantasy points for a match
  Future<Map<String, dynamic>> getMatchPoints(String matchId) async {
    try {
      return await _api.getMatchPoints(matchId);
    } catch (e) {
      return {};
    }
  }
}
