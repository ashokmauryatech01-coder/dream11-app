/// ============================================================================
/// MATCH MODEL - Updated for CricAPI
/// ============================================================================
/// 
/// Supports both old RapidAPI format and new CricAPI format.
/// Use `fromCricApi` factory for CricAPI responses.
/// 
/// CricAPI Response Structure:
/// {
///   "id": "guid",
///   "name": "Match Name",
///   "matchType": "t20/odi/test",
///   "status": "Status text",
///   "venue": "Stadium name",
///   "date": "2026-02-07",
///   "dateTimeGMT": "2026-02-07T13:30:00",
///   "teams": ["Team1", "Team2"],
///   "teamInfo": [{ "name": "", "shortname": "", "img": "" }],
///   "score": [{ "r": 185, "w": 4, "o": 18.2, "inning": "..." }],
///   "fantasyEnabled": true,
///   "matchStarted": true,
///   "matchEnded": false
/// }
/// 
/// ============================================================================

class MatchModel {
  final String id;
  final List<Team> teams;
  final Venue venue;
  final DateTime dateTime;
  final String format;
  final String status;
  final String? seriesName;
  final String? seriesCategory;
  final String? matchDesc;
  final String? dateHeader;
  final List<ScoreInfo> score;
  final bool fantasyEnabled;
  final bool matchStarted;
  final bool matchEnded;

  MatchModel({
    required this.id,
    required this.teams,
    required this.venue,
    required this.dateTime,
    required this.format,
    required this.status,
    this.seriesName,
    this.seriesCategory,
    this.matchDesc,
    this.dateHeader,
    this.score = const [],
    this.fantasyEnabled = false,
    this.matchStarted = false,
    this.matchEnded = false,
  });

  /// Create a MatchModel from CricAPI response (currentMatches, matches)
  factory MatchModel.fromCricApi(Map<String, dynamic> json) {
    // Parse teams from teams array and teamInfo
    final teamsArray = json['teams'] as List<dynamic>? ?? [];
    final teamInfoArray = json['teamInfo'] as List<dynamic>? ?? [];
    
    final List<Team> teams = [];
    for (int i = 0; i < teamsArray.length && i < 2; i++) {
      final teamName = teamsArray[i].toString();
      // Find matching teamInfo
      Map<String, dynamic>? teamInfo;
      for (final info in teamInfoArray) {
        final infoMap = info as Map<String, dynamic>;
        if (infoMap['name'] == teamName) {
          teamInfo = infoMap;
          break;
        }
      }
      // If not found by exact match, use by index
      if (teamInfo == null && i < teamInfoArray.length) {
        teamInfo = teamInfoArray[i] as Map<String, dynamic>;
      }
      teams.add(Team.fromCricApi(teamName, teamInfo));
    }

    // Parse score array
    final scoreArray = json['score'] as List<dynamic>? ?? [];
    final scores = scoreArray.map((s) => ScoreInfo.fromJson(s as Map<String, dynamic>)).toList();

    // Parse date
    DateTime dateTime;
    try {
      final dateTimeGMT = json['dateTimeGMT'] as String?;
      if (dateTimeGMT != null && dateTimeGMT.isNotEmpty) {
        dateTime = DateTime.parse(dateTimeGMT);
      } else {
        final dateStr = json['date'] as String?;
        dateTime = dateStr != null ? DateTime.parse(dateStr) : DateTime.now();
      }
    } catch (e) {
      dateTime = DateTime.now();
    }

    // Get series name (use 'series' field if available)
    String? seriesName = json['series'] as String?;
    if (seriesName == null || seriesName.isEmpty) {
      seriesName = json['series_id'] as String?;
    }

    // Generate a proper match description
    String matchDesc;
    final name = json['name'] as String?;
    if (name != null && name.isNotEmpty && !_looksLikeId(name)) {
      matchDesc = name;
    } else if (teams.length >= 2) {
      matchDesc = '${teams[0].shortName} vs ${teams[1].shortName}';
    } else {
      matchDesc = 'Cricket Match';
    }

    return MatchModel(
      id: json['id'] as String? ?? '',
      teams: teams,
      venue: Venue(
        name: json['venue'] as String? ?? 'TBD',
        city: '',
        country: null,
      ),
      dateTime: dateTime,
      format: (json['matchType'] as String? ?? 'T20').toUpperCase(),
      status: json['status'] as String? ?? '',
      seriesName: seriesName,
      matchDesc: matchDesc,
      score: scores,
      fantasyEnabled: json['fantasyEnabled'] as bool? ?? false,
      matchStarted: json['matchStarted'] as bool? ?? false,
      matchEnded: json['matchEnded'] as bool? ?? false,
    );
  }

  /// Check if a string looks like a GUID/UUID
  static bool _looksLikeId(String s) {
    // GUIDs are typically 36 chars with hyphens
    if (s.length >= 30 && s.contains('-')) {
      final parts = s.split('-');
      if (parts.length >= 4) return true;
    }
    return false;
  }

  /// Create a MatchModel from the old RapidAPI schedule response (legacy)
  factory MatchModel.fromApiJson(Map<String, dynamic> json) {
    final team1Data = json['team1'] as Map<String, dynamic>? ?? {};
    final team2Data = json['team2'] as Map<String, dynamic>? ?? {};
    final venueData = json['venueInfo'] as Map<String, dynamic>? ?? {};

    // Parse startDate (epoch millis as string)
    final startDateStr = json['startDate'] as String? ?? '0';
    final startDateMs = int.tryParse(startDateStr) ?? 0;
    final dateTime = DateTime.fromMillisecondsSinceEpoch(startDateMs);

    return MatchModel(
      id: (json['matchId'] ?? '').toString(),
      teams: [
        Team.fromApiJson(team1Data),
        Team.fromApiJson(team2Data),
      ],
      venue: Venue.fromApiJson(venueData),
      dateTime: dateTime,
      format: json['matchFormat'] as String? ?? 'T20',
      status: 'upcoming',
      seriesName: json['_seriesName'] as String?,
      seriesCategory: json['_seriesCategory'] as String?,
      matchDesc: json['matchDesc'] as String?,
      dateHeader: json['_dateHeader'] as String?,
    );
  }

  /// Create a MatchModel from /cricket-matches-* endpoints (legacy)
  factory MatchModel.fromMatchesApi(Map<String, dynamic> json, {String status = 'upcoming'}) {
    final team1Data = json['team1'] as Map<String, dynamic>? ?? {};
    final team2Data = json['team2'] as Map<String, dynamic>? ?? {};
    final venueData = json['venueInfo'] as Map<String, dynamic>? ?? {};

    final startDateStr = (json['startDate'] ?? '0').toString();
    final startDateMs = int.tryParse(startDateStr) ?? 0;
    final dateTime = startDateMs > 0 
        ? DateTime.fromMillisecondsSinceEpoch(startDateMs)
        : DateTime.now();

    return MatchModel(
      id: (json['matchId'] ?? json['id'] ?? '').toString(),
      teams: [
        Team.fromApiJson(team1Data),
        Team.fromApiJson(team2Data),
      ],
      venue: Venue.fromApiJson(venueData),
      dateTime: dateTime,
      format: json['matchFormat'] as String? ?? json['format'] as String? ?? 'T20',
      status: json['state'] as String? ?? status,
      seriesName: json['seriesName'] as String? ?? json['_seriesName'] as String?,
      seriesCategory: json['seriesCategory'] as String? ?? json['_seriesCategory'] as String?,
      matchDesc: json['matchDesc'] as String? ?? json['title'] as String?,
      dateHeader: json['_dateHeader'] as String?,
    );
  }

  /// Check if match is live
  bool get isLive => matchStarted && !matchEnded;

  /// Check if match is upcoming
  bool get isUpcoming => !matchStarted && !matchEnded;

  /// Check if match is completed
  bool get isCompleted => matchEnded;

  /// Get team 1
  Team get team1 => teams.isNotEmpty ? teams[0] : Team(name: 'TBD', shortName: 'TBD');

  /// Get team 2
  Team get team2 => teams.length > 1 ? teams[1] : Team(name: 'TBD', shortName: 'TBD');

  /// Get team 1 score
  ScoreInfo? get team1Score {
    for (final s in score) {
      if (s.inning.toLowerCase().contains(team1.name.toLowerCase())) {
        return s;
      }
    }
    return score.isNotEmpty ? score[0] : null;
  }

  /// Get team 2 score
  ScoreInfo? get team2Score {
    for (final s in score) {
      if (s.inning.toLowerCase().contains(team2.name.toLowerCase())) {
        return s;
      }
    }
    return score.length > 1 ? score[1] : null;
  }

  /// Get match title
  String get matchTitle => '${team1.shortName} vs ${team2.shortName}';
}

/// Score info for an innings
class ScoreInfo {
  final int runs;
  final int wickets;
  final double overs;
  final String inning;

  ScoreInfo({
    required this.runs,
    required this.wickets,
    required this.overs,
    required this.inning,
  });

  factory ScoreInfo.fromJson(Map<String, dynamic> json) {
    return ScoreInfo(
      runs: json['r'] as int? ?? 0,
      wickets: json['w'] as int? ?? 0,
      overs: (json['o'] as num?)?.toDouble() ?? 0.0,
      inning: json['inning'] as String? ?? '',
    );
  }

  String get scoreString => '$runs/$wickets';
  String get oversString => '(${overs.toStringAsFixed(1)} ov)';
  String get fullDisplay => '$scoreString $oversString';
}

class Team {
  final String name;
  final String shortName;
  final String? teamId;
  final int? imageId;
  final String? imageUrl;

  Team({
    required this.name,
    required this.shortName,
    this.teamId,
    this.imageId,
    this.imageUrl,
  });

  /// Create from CricAPI teamInfo
  factory Team.fromCricApi(String teamName, Map<String, dynamic>? teamInfo) {
    String shortName = teamName;
    String? imageUrl;
    
    if (teamInfo != null) {
      shortName = teamInfo['shortname'] as String? ?? teamName;
      imageUrl = teamInfo['img'] as String?;
    }
    
    // Generate short name if not provided
    if (shortName == teamName && teamName.length > 3) {
      // Take first 3 characters or first letters of each word
      final words = teamName.split(' ');
      if (words.length > 1) {
        shortName = words.map((w) => w.isNotEmpty ? w[0] : '').join().toUpperCase();
      } else {
        shortName = teamName.substring(0, 3).toUpperCase();
      }
    }

    return Team(
      name: teamName,
      shortName: shortName,
      imageUrl: imageUrl,
    );
  }

  /// Create from old RapidAPI format
  factory Team.fromApiJson(Map<String, dynamic> json) {
    final teamId = (json['teamId'] ?? '').toString();
    final imageId = json['imageId'] as int?;
    // Build image URL from imageId
    String? imageUrl;
    if (imageId != null) {
      imageUrl = 'https://static.cricbuzz.com/a/img/v1/72x54/i1/c$imageId/team.jpg';
    }

    return Team(
      name: json['teamName'] as String? ?? 'TBD',
      shortName: json['teamSName'] as String? ?? 'TBD',
      teamId: teamId.isNotEmpty ? teamId : null,
      imageId: imageId,
      imageUrl: imageUrl,
    );
  }
}

class Venue {
  final String name;
  final String city;
  final String? country;

  Venue({
    required this.name,
    required this.city,
    this.country,
  });

  factory Venue.fromApiJson(Map<String, dynamic> json) {
    return Venue(
      name: json['ground'] as String? ?? 'TBD',
      city: json['city'] as String? ?? 'TBD',
      country: json['country'] as String?,
    );
  }

  String get fullName => city.isNotEmpty ? '$name, $city' : name;
}
