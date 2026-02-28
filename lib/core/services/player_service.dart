import 'package:fantasy_crick/core/services/api_client.dart';

class PlayerService {
  static Future<List<Map<String, dynamic>>> getPlayersByMatch(
    dynamic matchId,
  ) async {
    try {
      final response = await ApiClient.get(
        '/players?match_id=$matchId&page=1&limit=12',
      );
      // Handle different levels of nesting for "players"
      dynamic data = response?['data'];
      List<dynamic> list = [];

      if (data is Map) {
        list = data['players'] as List<dynamic>? ?? [];
      } else if (data is List) {
        list = data;
      }

      return list.map((p) => p as Map<String, dynamic>).toList();
    } catch (e) {
      print('Error fetching players: $e');
      return [];
    }
  }
}
