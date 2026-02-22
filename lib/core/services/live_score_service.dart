import 'dart:async';
import 'package:fantasy_crick/models/live_score_model.dart';
import 'package:fantasy_crick/core/services/api_client.dart';

class ApiResult<T> {
  final T? data;
  final String? error;
  final bool isSuccess;
  final int? statusCode;
  final DateTime timestamp;
  final ApiInfo? info;

  ApiResult.success(this.data, {this.info})
      : error = null,
        isSuccess = true,
        statusCode = 200,
        timestamp = DateTime.now();

  ApiResult.failure(this.error, {this.statusCode})
      : data = null,
        isSuccess = false,
        info = null,
        timestamp = DateTime.now();
}

class LiveScoreService {
  static final LiveScoreService _instance = LiveScoreService._internal();
  factory LiveScoreService() => _instance;
  LiveScoreService._internal();

  int get remainingApiCalls => 1000;

  final Map<String, _CacheEntry> _cache = {};

  Future<ApiResult<List<CricScoreMatch>>> getLiveScores({bool forceRefresh = false}) async {
    const cacheKey = 'cric_score';
    if (!forceRefresh && _isCacheValid(cacheKey)) {
      return ApiResult.success(_cache[cacheKey]!.data as List<CricScoreMatch>);
    }

    try {
      final response = await ApiClient.get('/cricket/live-matches');
      final dataList = response['data'] as List<dynamic>? ?? [];
      final matches = dataList.map((m) => CricScoreMatch.fromJson(m as Map<String, dynamic>)).toList();
      _cache[cacheKey] = _CacheEntry(matches);
      return ApiResult.success(matches);
    } catch (e) {
      return ApiResult.failure('Failed to fetch live scores: ${e.toString()}');
    }
  }

  Future<ApiResult<List<CricMatch>>> getCurrentMatches({bool forceRefresh = false, int offset = 0}) async {
    final cacheKey = 'current_matches_$offset';
    if (!forceRefresh && _isCacheValid(cacheKey)) {
      return ApiResult.success(_cache[cacheKey]!.data as List<CricMatch>);
    }

    try {
      final response = await ApiClient.get('/cricket/matches');
      final dataList = response['data'] as List<dynamic>? ?? [];
      final matches = dataList.map((m) => CricMatch.fromJson(m as Map<String, dynamic>)).toList();
      _cache[cacheKey] = _CacheEntry(matches);
      return ApiResult.success(matches);
    } catch (e) {
      return ApiResult.failure('Failed to fetch matches: ${e.toString()}');
    }
  }

  Future<ApiResult<List<CricMatch>>> getAllMatches({bool forceRefresh = false, int offset = 0}) async {
    final cacheKey = 'all_matches_$offset';
    if (!forceRefresh && _isCacheValid(cacheKey)) {
      return ApiResult.success(_cache[cacheKey]!.data as List<CricMatch>);
    }

    try {
      final response = await ApiClient.get('/cricket/matches');
      final dataList = response['data'] as List<dynamic>? ?? [];
      final matches = dataList.map((m) => CricMatch.fromJson(m as Map<String, dynamic>)).toList();
      _cache[cacheKey] = _CacheEntry(matches);
      return ApiResult.success(matches);
    } catch (e) {
      return ApiResult.failure('Failed to fetch matches: ${e.toString()}');
    }
  }

  Future<ApiResult<List<CricSeries>>> getSeriesList({bool forceRefresh = false, int offset = 0, String? search}) async {
    final cacheKey = 'series_list_${offset}_$search';
    if (!forceRefresh && _isCacheValid(cacheKey)) {
      return ApiResult.success(_cache[cacheKey]!.data as List<CricSeries>);
    }

    try {
      final response = await ApiClient.get('/cricket/live-series');
      final dataList = response['data'] as List<dynamic>? ?? [];
      final series = dataList.map((s) => CricSeries.fromJson(s as Map<String, dynamic>)).toList();
      _cache[cacheKey] = _CacheEntry(series);
      return ApiResult.success(series);
    } catch (e) {
      return ApiResult.failure('Failed to fetch series: ${e.toString()}');
    }
  }

  Future<ApiResult<Map<String, dynamic>>> getSeriesInfo(String seriesId) async {
    final cacheKey = 'series_info_$seriesId';
    if (_isCacheValid(cacheKey)) {
      return ApiResult.success(_cache[cacheKey]!.data as Map<String, dynamic>);
    }

    try {
      final response = await ApiClient.get('/cricket/series/$seriesId');
      final data = response['data'] as Map<String, dynamic>? ?? {};
      _cache[cacheKey] = _CacheEntry(data);
      return ApiResult.success(data);
    } catch (e) {
      return ApiResult.failure('Failed to fetch series info: ${e.toString()}');
    }
  }

  Future<ApiResult<CricMatch>> getMatchInfo(String matchId) async {
    final cacheKey = 'match_info_$matchId';
    if (_isCacheValid(cacheKey, duration: const Duration(seconds: 30))) {
      return ApiResult.success(_cache[cacheKey]!.data as CricMatch);
    }

    try {
      final response = await ApiClient.get('/cricket/matches/$matchId');
      final data = response['data'] as Map<String, dynamic>? ?? {};
      final match = CricMatch.fromJson(data);
      _cache[cacheKey] = _CacheEntry(match);
      return ApiResult.success(match);
    } catch (e) {
      return ApiResult.failure('Failed to fetch match info: ${e.toString()}');
    }
  }

  Future<ApiResult<MatchScorecard>> getMatchScorecard(String matchId) async {
    final cacheKey = 'scorecard_$matchId';
    if (_isCacheValid(cacheKey, duration: const Duration(seconds: 30))) {
      return ApiResult.success(_cache[cacheKey]!.data as MatchScorecard);
    }

    try {
      final response = await ApiClient.get('/cricket/matches/$matchId/scorecard');
      final data = response['data'] as Map<String, dynamic>? ?? {};
      final scorecard = MatchScorecard.fromJson(data);
      _cache[cacheKey] = _CacheEntry(scorecard);
      return ApiResult.success(scorecard);
    } catch (e) {
      return ApiResult.failure('Failed to fetch scorecard: ${e.toString()}');
    }
  }

  Future<ApiResult<List<MatchSquad>>> getMatchSquad(String matchId) async {
    final cacheKey = 'squad_$matchId';
    if (_isCacheValid(cacheKey)) {
      return ApiResult.success(_cache[cacheKey]!.data as List<MatchSquad>);
    }

    try {
      final response = await ApiClient.get('/cricket/matches/$matchId/squad');
      final dataList = response['data'] as List<dynamic>? ?? [];
      final squads = dataList.map((s) => MatchSquad.fromJson(s as Map<String, dynamic>)).toList();
      _cache[cacheKey] = _CacheEntry(squads);
      return ApiResult.success(squads);
    } catch (e) {
      return ApiResult.failure('Failed to fetch squad: ${e.toString()}');
    }
  }

  Future<ApiResult<List<CricPlayer>>> getPlayers({bool forceRefresh = false, int offset = 0, String? search}) async {
    final cacheKey = 'players_${offset}_$search';
    if (!forceRefresh && _isCacheValid(cacheKey)) {
      return ApiResult.success(_cache[cacheKey]!.data as List<CricPlayer>);
    }

    try {
      final response = await ApiClient.get('/players?page=1&limit=20');
      final dataList = response['data'] as List<dynamic>? ?? [];
      final players = dataList.map((p) => CricPlayer.fromJson(p as Map<String, dynamic>)).toList();
      _cache[cacheKey] = _CacheEntry(players);
      return ApiResult.success(players);
    } catch (e) {
      return ApiResult.failure('Failed to fetch players: ${e.toString()}');
    }
  }

  Future<ApiResult<CricPlayer>> getPlayerInfo(String playerId) async {
    final cacheKey = 'player_info_$playerId';
    if (_isCacheValid(cacheKey)) {
      return ApiResult.success(_cache[cacheKey]!.data as CricPlayer);
    }

    try {
      final response = await ApiClient.get('/players/$playerId');
      final data = response['data'] as Map<String, dynamic>? ?? {};
      final player = CricPlayer.fromJson(data);
      _cache[cacheKey] = _CacheEntry(player);
      return ApiResult.success(player);
    } catch (e) {
      return ApiResult.failure('Failed to fetch player info: ${e.toString()}');
    }
  }

  Future<ApiResult<List<CricMatch>>> getLiveMatches({bool forceRefresh = false}) async {
    try {
      final response = await ApiClient.get('/cricket/live-matches');
      final dataList = response['data'] as List<dynamic>? ?? [];
      final matches = dataList.map((m) => CricMatch.fromJson(m as Map<String, dynamic>)).toList();
      return ApiResult.success(matches);
    } catch (e) {
      return ApiResult.failure('Failed: $e');
    }
  }

  Future<ApiResult<List<CricMatch>>> getUpcomingMatches({bool forceRefresh = false}) async {
    try {
      final response = await ApiClient.get('/cricket/upcoming-matches');
      final dataList = response['data'] as List<dynamic>? ?? [];
      final matches = dataList.map((m) => CricMatch.fromJson(m as Map<String, dynamic>)).toList();
      return ApiResult.success(matches);
    } catch (e) {
      return ApiResult.failure('Failed: $e');
    }
  }

  Future<ApiResult<List<CricMatch>>> getRecentMatches({bool forceRefresh = false}) async {
    try {
      final response = await ApiClient.get('/cricket/finished-matches');
      final dataList = response['data'] as List<dynamic>? ?? [];
      final matches = dataList.map((m) => CricMatch.fromJson(m as Map<String, dynamic>)).toList();
      return ApiResult.success(matches);
    } catch (e) {
      return ApiResult.failure('Failed: $e');
    }
  }

  bool _isCacheValid(String key, {Duration? duration}) {
    final entry = _cache[key];
    if (entry == null) return false;
    final expiry = duration ?? const Duration(minutes: 5);
    return DateTime.now().difference(entry.timestamp) < expiry;
  }

  void clearCache() {
    _cache.clear();
  }

  void dispose() {
    _cache.clear();
  }
}

class _CacheEntry {
  final dynamic data;
  final DateTime timestamp;

  _CacheEntry(this.data) : timestamp = DateTime.now();
}

class LiveScoreStream {
  final LiveScoreService _service = LiveScoreService();
  StreamController<ApiResult<List<CricMatch>>>? _controller;
  Timer? _timer;
  bool _isActive = false;

  Stream<ApiResult<List<CricMatch>>> startLiveScoreStream({Duration interval = const Duration(seconds: 30)}) {
    _controller?.close();
    _controller = StreamController<ApiResult<List<CricMatch>>>.broadcast();
    _isActive = true;
    _fetchAndEmit();
    _timer = Timer.periodic(interval, (_) {
      if (_isActive) _fetchAndEmit();
    });
    return _controller!.stream;
  }

  void _fetchAndEmit() async {
    if (_controller?.isClosed ?? true) return;
    final result = await _service.getLiveMatches(forceRefresh: true);
    if (!(_controller?.isClosed ?? true)) {
      _controller!.add(result);
    }
  }

  void pause() => _isActive = false;
  void resume() { _isActive = true; _fetchAndEmit(); }
  void dispose() {
    _isActive = false;
    _timer?.cancel();
    _controller?.close();
    _controller = null;
    _timer = null;
  }
}
