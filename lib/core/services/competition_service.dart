import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:fantasy_crick/models/competition_match_model.dart';

class CompetitionService {
  static const String _baseUrl = 'https://restapi.entitysport.com/v2';
  static const String _token = '44b16e8558165c3b9fed0b6ad7814377';

  /// Fetch matches for a given competition ID with pagination.
  /// [cid] - Competition ID (e.g. 121143 for Big Bash League 2021)
  /// [perPage] - Number of matches per page (default 50)
  /// [page] - Page number (default 1)
  Future<List<CompetitionMatchModel>> getCompetitionMatches({
    required int cid,
    int perPage = 50,
    int page = 1,
  }) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/competitions/$cid/matches/?token=$_token&per_page=$perPage&paged=$page',
      );

      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        if (decoded['status'] == 'ok') {
          final items = decoded['response']?['items'] as List<dynamic>? ?? [];
          return items
              .map((item) => CompetitionMatchModel.fromJson(item as Map<String, dynamic>))
              .toList();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Fetch all pages of competition matches (up to maxPages).
  Future<List<CompetitionMatchModel>> getAllCompetitionMatches({
    required int cid,
    int perPage = 50,
    int maxPages = 5,
  }) async {
    final List<CompetitionMatchModel> allMatches = [];
    for (int page = 1; page <= maxPages; page++) {
      final matches = await getCompetitionMatches(cid: cid, perPage: perPage, page: page);
      if (matches.isEmpty) break;
      allMatches.addAll(matches);
      if (matches.length < perPage) break;
    }
    return allMatches;
  }
}
