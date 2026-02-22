import 'package:fantasy_crick/models/series_model.dart';
import 'package:fantasy_crick/core/services/cricket_api_service.dart';

/// ============================================================================
/// SERIES SERVICE - Updated for CricAPI
/// ============================================================================
/// 
/// Service layer for fetching series data from CricAPI.
/// Note: CricAPI doesn't have separate endpoints for international/league/etc.
/// Use search parameter to filter series by name.
/// 
/// ============================================================================

class SeriesService {
  final CricketApiService _api = CricketApiService();

  /// Fetch all cricket series
  Future<List<SeriesModel>> getAllSeries({int offset = 0}) async {
    try {
      final data = await _api.getSeriesList(offset: offset);
      return data.map((s) => SeriesModel.fromJson(s)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Search series by name
  Future<List<SeriesModel>> searchSeries(String query, {int offset = 0}) async {
    try {
      final data = await _api.getSeriesList(offset: offset, search: query);
      return data.map((s) => SeriesModel.fromJson(s)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Fetch international cricket series (searches for keywords)
  Future<List<SeriesModel>> getInternationalSeries() async {
    try {
      // CricAPI doesn't have separate endpoints, so we get all series
      final data = await _api.getSeriesList();
      return data.map((s) => SeriesModel.fromJson(s)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Fetch league cricket series (searches for IPL, BBL, PSL, etc.)
  Future<List<SeriesModel>> getLeagueSeries() async {
    try {
      // Search for common league keywords
      final data = await _api.getSeriesList(search: 'League');
      return data.map((s) => SeriesModel.fromJson(s)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Fetch domestic cricket series
  Future<List<SeriesModel>> getDomesticSeries() async {
    try {
      final data = await _api.getSeriesList(search: 'Domestic');
      return data.map((s) => SeriesModel.fromJson(s)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Fetch women's cricket series
  Future<List<SeriesModel>> getWomenSeries() async {
    try {
      final data = await _api.getSeriesList(search: 'Women');
      return data.map((s) => SeriesModel.fromJson(s)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get series info by ID
  Future<Map<String, dynamic>> getSeriesInfo(String seriesId) async {
    try {
      return await _api.getSeriesInfo(seriesId);
    } catch (e) {
      return {};
    }
  }
}
