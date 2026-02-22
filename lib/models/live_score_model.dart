/// ============================================================================
/// CRICAPI LIVE SCORE MODELS
/// ============================================================================
/// 
/// Models for CricAPI (cricapi.com) - Your API Key: 2d7407ac-645c-4c1a-96bb-15647ad63f71
/// 
/// API Response Structure:
/// -----------------------
/// 1. **status**: "success" or "failure"
/// 2. **data**: Array of match objects
/// 3. **info**: API usage info (hitsToday, hitsLimit, etc.)
/// 
/// Match Object Structure:
/// -----------------------
/// - id: Unique match GUID
/// - name: Match name (e.g., "India vs Australia, 1st T20I")
/// - matchType: "t20" / "odi" / "test"
/// - status: Current match status text
/// - venue: Stadium name
/// - date: Match date (YYYY-MM-DD)
/// - dateTimeGMT: ISO datetime string
/// - teams: Array of team names [Team1, Team2]
/// - teamInfo: Array of team details with images
/// - score: Array of innings scores
/// - series_id: Series GUID
/// - fantasyEnabled: Boolean
/// - matchStarted: Boolean
/// - matchEnded: Boolean
/// 
/// ============================================================================

class CricApiResponse {
  final String status;
  final List<CricMatch> data;
  final ApiInfo info;

  CricApiResponse({
    required this.status,
    required this.data,
    required this.info,
  });

  factory CricApiResponse.fromJson(Map<String, dynamic> json) {
    final dataList = json['data'] as List<dynamic>? ?? [];
    return CricApiResponse(
      status: json['status'] as String? ?? 'unknown',
      data: dataList.map((m) => CricMatch.fromJson(m as Map<String, dynamic>)).toList(),
      info: ApiInfo.fromJson(json['info'] as Map<String, dynamic>? ?? {}),
    );
  }

  bool get isSuccess => status == 'success';
}

/// API Usage Information
class ApiInfo {
  final int hitsToday;
  final int hitsLimit;
  final int credits;
  final int totalRows;
  final double queryTime;

  ApiInfo({
    required this.hitsToday,
    required this.hitsLimit,
    required this.credits,
    required this.totalRows,
    required this.queryTime,
  });

  factory ApiInfo.fromJson(Map<String, dynamic> json) {
    return ApiInfo(
      hitsToday: json['hitsToday'] as int? ?? 0,
      hitsLimit: json['hitsLimit'] as int? ?? 100,
      credits: json['credits'] as int? ?? 0,
      totalRows: json['totalRows'] as int? ?? 0,
      queryTime: (json['queryTime'] as num?)?.toDouble() ?? 0.0,
    );
  }

  int get hitsRemaining => hitsLimit - hitsToday;
}

/// ============================================================================
/// CRIC SCORE MATCH - Simplified format from /cricScore endpoint
/// ============================================================================
/// 
/// Response format:
/// - id: Match ID
/// - dateTimeGMT: Date time in GMT
/// - matchType: t20/odi/test
/// - status: Match status text
/// - ms: Match state ("live", "result", "fixture")
/// - t1: Team 1 name with short code (e.g., "India [IND]")
/// - t2: Team 2 name with short code
/// - t1s: Team 1 score (e.g., "161/9 (20)")
/// - t2s: Team 2 score
/// - t1img: Team 1 image URL
/// - t2img: Team 2 image URL
/// - series: Series name
/// 
/// ============================================================================

class CricScoreMatch {
  final String id;
  final String dateTimeGMT;
  final String matchType;
  final String status;
  final String matchState; // "live", "result", "fixture"
  final String team1Name;
  final String team2Name;
  final String team1ShortName;
  final String team2ShortName;
  final String team1Score;
  final String team2Score;
  final String team1Img;
  final String team2Img;
  final String seriesName;

  CricScoreMatch({
    required this.id,
    required this.dateTimeGMT,
    required this.matchType,
    required this.status,
    required this.matchState,
    required this.team1Name,
    required this.team2Name,
    required this.team1ShortName,
    required this.team2ShortName,
    required this.team1Score,
    required this.team2Score,
    required this.team1Img,
    required this.team2Img,
    required this.seriesName,
  });

  factory CricScoreMatch.fromJson(Map<String, dynamic> json) {
    // Parse team name and short name from format "India [IND]"
    final t1 = json['t1'] as String? ?? '';
    final t2 = json['t2'] as String? ?? '';
    
    final team1Parts = _parseTeamName(t1);
    final team2Parts = _parseTeamName(t2);

    return CricScoreMatch(
      id: json['id'] as String? ?? '',
      dateTimeGMT: json['dateTimeGMT'] as String? ?? '',
      matchType: json['matchType'] as String? ?? 't20',
      status: json['status'] as String? ?? '',
      matchState: json['ms'] as String? ?? 'fixture',
      team1Name: team1Parts['name']!,
      team2Name: team2Parts['name']!,
      team1ShortName: team1Parts['short']!,
      team2ShortName: team2Parts['short']!,
      team1Score: json['t1s'] as String? ?? '',
      team2Score: json['t2s'] as String? ?? '',
      team1Img: json['t1img'] as String? ?? '',
      team2Img: json['t2img'] as String? ?? '',
      seriesName: json['series'] as String? ?? '',
    );
  }

  /// Parse "India [IND]" into {name: "India", short: "IND"}
  static Map<String, String> _parseTeamName(String fullName) {
    final bracketIndex = fullName.lastIndexOf('[');
    if (bracketIndex > 0) {
      final name = fullName.substring(0, bracketIndex).trim();
      final short = fullName.substring(bracketIndex + 1).replaceAll(']', '').trim();
      return {'name': name, 'short': short};
    }
    // No bracket format, generate short name
    final name = fullName.trim();
    final short = name.length > 3 ? name.substring(0, 3).toUpperCase() : name.toUpperCase();
    return {'name': name, 'short': short};
  }

  /// Check if match is live
  bool get isLive => matchState == 'live';

  /// Check if match is upcoming
  bool get isUpcoming => matchState == 'fixture';

  /// Check if match is completed
  bool get isCompleted => matchState == 'result';

  /// Get match format display (T20 / ODI / TEST)
  String get formatDisplay => matchType.toUpperCase();

  /// Get parsed DateTime
  DateTime get dateTime {
    try {
      return DateTime.parse(dateTimeGMT);
    } catch (e) {
      return DateTime.now();
    }
  }

  /// Get match title (e.g., "IND vs AUS")
  String get matchTitle => '$team1ShortName vs $team2ShortName';
}
class CricMatch {
  final String id;
  final String name;
  final String matchType;
  final String status;
  final String venue;
  final String date;
  final String dateTimeGMT;
  final List<String> teams;
  final List<TeamInfo> teamInfo;
  final List<InningsScore> score;
  final String seriesId;
  final bool fantasyEnabled;
  final bool bbbEnabled;
  final bool hasSquad;
  final bool matchStarted;
  final bool matchEnded;

  CricMatch({
    required this.id,
    required this.name,
    required this.matchType,
    required this.status,
    required this.venue,
    required this.date,
    required this.dateTimeGMT,
    required this.teams,
    required this.teamInfo,
    required this.score,
    required this.seriesId,
    required this.fantasyEnabled,
    required this.bbbEnabled,
    required this.hasSquad,
    required this.matchStarted,
    required this.matchEnded,
  });

  factory CricMatch.fromJson(Map<String, dynamic> json) {
    // Parse teams array
    final teamsList = (json['teams'] as List<dynamic>? ?? [])
        .map((t) => t.toString())
        .toList();

    // Parse team info
    final teamInfoList = (json['teamInfo'] as List<dynamic>? ?? [])
        .map((t) => TeamInfo.fromJson(t as Map<String, dynamic>))
        .toList();

    // Parse scores
    final scoreList = (json['score'] as List<dynamic>? ?? [])
        .map((s) => InningsScore.fromJson(s as Map<String, dynamic>))
        .toList();

    return CricMatch(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      matchType: json['matchType'] as String? ?? 't20',
      status: json['status'] as String? ?? '',
      venue: json['venue'] as String? ?? '',
      date: json['date'] as String? ?? '',
      dateTimeGMT: json['dateTimeGMT'] as String? ?? '',
      teams: teamsList,
      teamInfo: teamInfoList,
      score: scoreList,
      seriesId: json['series_id'] as String? ?? '',
      fantasyEnabled: json['fantasyEnabled'] as bool? ?? false,
      bbbEnabled: json['bbbEnabled'] as bool? ?? false,
      hasSquad: json['hasSquad'] as bool? ?? false,
      matchStarted: json['matchStarted'] as bool? ?? false,
      matchEnded: json['matchEnded'] as bool? ?? false,
    );
  }

  /// Get match display title (e.g., "IND vs AUS")
  String get matchTitle {
    if (teamInfo.length >= 2) {
      return '${teamInfo[0].shortName} vs ${teamInfo[1].shortName}';
    }
    if (teams.length >= 2) {
      return '${_getShortName(teams[0])} vs ${_getShortName(teams[1])}';
    }
    return name;
  }

  /// Get team 1 info
  TeamInfo? get team1Info => teamInfo.isNotEmpty ? teamInfo[0] : null;

  /// Get team 2 info
  TeamInfo? get team2Info => teamInfo.length > 1 ? teamInfo[1] : null;

  /// Get team 1 name
  String get team1Name => teams.isNotEmpty ? teams[0] : 'TBD';

  /// Get team 2 name
  String get team2Name => teams.length > 1 ? teams[1] : 'TBD';

  /// Get team 1 score (first innings of team 1)
  InningsScore? get team1Score {
    for (final s in score) {
      if (s.inning.toLowerCase().contains(team1Name.toLowerCase())) {
        return s;
      }
    }
    return score.isNotEmpty ? score[0] : null;
  }

  /// Get team 2 score
  InningsScore? get team2Score {
    for (final s in score) {
      if (s.inning.toLowerCase().contains(team2Name.toLowerCase())) {
        return s;
      }
    }
    return score.length > 1 ? score[1] : null;
  }

  /// Check if match is live (started but not ended)
  bool get isLive => matchStarted && !matchEnded;

  /// Check if match is upcoming
  bool get isUpcoming => !matchStarted && !matchEnded;

  /// Check if match is completed
  bool get isCompleted => matchEnded;

  /// Get parsed DateTime
  DateTime get dateTime {
    try {
      return DateTime.parse(dateTimeGMT);
    } catch (e) {
      return DateTime.now();
    }
  }

  /// Get match format display (T20 / ODI / TEST)
  String get formatDisplay => matchType.toUpperCase();

  /// Helper to get short name from full team name
  String _getShortName(String name) {
    final parts = name.split(' ');
    if (parts.length == 1) {
      return name.length > 3 ? name.substring(0, 3).toUpperCase() : name.toUpperCase();
    }
    // Take first letter of each word
    return parts.map((p) => p.isNotEmpty ? p[0] : '').join().toUpperCase();
  }
}

/// Team Information with Image
class TeamInfo {
  final String name;
  final String shortName;
  final String imageUrl;

  TeamInfo({
    required this.name,
    required this.shortName,
    required this.imageUrl,
  });

  factory TeamInfo.fromJson(Map<String, dynamic> json) {
    return TeamInfo(
      name: json['name'] as String? ?? '',
      shortName: json['shortname'] as String? ?? '',
      imageUrl: json['img'] as String? ?? '',
    );
  }

  /// Get fallback short name if not provided
  String get displayShortName {
    if (shortName.isNotEmpty) return shortName;
    if (name.length > 3) return name.substring(0, 3).toUpperCase();
    return name.toUpperCase();
  }
}

/// Innings Score
class InningsScore {
  final int runs;
  final int wickets;
  final double overs;
  final String inning;

  InningsScore({
    required this.runs,
    required this.wickets,
    required this.overs,
    required this.inning,
  });

  factory InningsScore.fromJson(Map<String, dynamic> json) {
    return InningsScore(
      runs: json['r'] as int? ?? 0,
      wickets: json['w'] as int? ?? 0,
      overs: (json['o'] as num?)?.toDouble() ?? 0.0,
      inning: json['inning'] as String? ?? '',
    );
  }

  /// Get score string (e.g., "185/4")
  String get scoreString => '$runs/$wickets';

  /// Get overs string (e.g., "(18.2 ov)")
  String get oversString => '(${overs.toStringAsFixed(1)} ov)';

  /// Get full score display (e.g., "185/4 (18.2 ov)")
  String get fullScoreDisplay => '$scoreString $oversString';

  /// Get innings description (Team name + Inning number)
  String get inningsDescription => inning;
}

/// Series Model
class CricSeries {
  final String id;
  final String name;
  final String startDate;
  final String endDate;
  final int odi;
  final int t20;
  final int test;
  final int squads;
  final int matches;

  CricSeries({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.odi,
    required this.t20,
    required this.test,
    required this.squads,
    required this.matches,
  });

  factory CricSeries.fromJson(Map<String, dynamic> json) {
    return CricSeries(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      startDate: json['startDate'] as String? ?? '',
      endDate: json['endDate'] as String? ?? '',
      odi: json['odi'] as int? ?? 0,
      t20: json['t20'] as int? ?? 0,
      test: json['test'] as int? ?? 0,
      squads: json['squads'] as int? ?? 0,
      matches: json['matches'] as int? ?? 0,
    );
  }

  /// Get total matches count
  int get totalMatches => odi + t20 + test;

  /// Get date range display
  String get dateRange => '$startDate - $endDate';
}

/// Player Model
class CricPlayer {
  final String id;
  final String name;
  final String country;
  final String? dateOfBirth;
  final String? role;
  final String? battingStyle;
  final String? bowlingStyle;
  final String? placeOfBirth;
  final String? playerImg;

  CricPlayer({
    required this.id,
    required this.name,
    required this.country,
    this.dateOfBirth,
    this.role,
    this.battingStyle,
    this.bowlingStyle,
    this.placeOfBirth,
    this.playerImg,
  });

  factory CricPlayer.fromJson(Map<String, dynamic> json) {
    return CricPlayer(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      country: json['country'] as String? ?? '',
      dateOfBirth: json['dateOfBirth'] as String?,
      role: json['role'] as String?,
      battingStyle: json['battingStyle'] as String?,
      bowlingStyle: json['bowlingStyle'] as String?,
      placeOfBirth: json['placeOfBirth'] as String?,
      playerImg: json['playerImg'] as String?,
    );
  }
}

/// Scorecard Model
class MatchScorecard {
  final String id;
  final String name;
  final String matchType;
  final String status;
  final String venue;
  final String date;
  final String dateTimeGMT;
  final List<String> teams;
  final List<InningsScore> score;
  final String? tossWinner;
  final String? tossChoice;
  final String? matchWinner;
  final String seriesId;
  final List<ScorecardInning> scorecard;

  MatchScorecard({
    required this.id,
    required this.name,
    required this.matchType,
    required this.status,
    required this.venue,
    required this.date,
    required this.dateTimeGMT,
    required this.teams,
    required this.score,
    this.tossWinner,
    this.tossChoice,
    this.matchWinner,
    required this.seriesId,
    required this.scorecard,
  });

  factory MatchScorecard.fromJson(Map<String, dynamic> json) {
    final teamsList = (json['teams'] as List<dynamic>? ?? [])
        .map((t) => t.toString())
        .toList();

    final scoreList = (json['score'] as List<dynamic>? ?? [])
        .map((s) => InningsScore.fromJson(s as Map<String, dynamic>))
        .toList();

    final scorecardList = (json['scorecard'] as List<dynamic>? ?? [])
        .map((s) => ScorecardInning.fromJson(s as Map<String, dynamic>))
        .toList();

    return MatchScorecard(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      matchType: json['matchType'] as String? ?? '',
      status: json['status'] as String? ?? '',
      venue: json['venue'] as String? ?? '',
      date: json['date'] as String? ?? '',
      dateTimeGMT: json['dateTimeGMT'] as String? ?? '',
      teams: teamsList,
      score: scoreList,
      tossWinner: json['tossWinner'] as String?,
      tossChoice: json['tossChoice'] as String?,
      matchWinner: json['matchWinner'] as String?,
      seriesId: json['series_id'] as String? ?? '',
      scorecard: scorecardList,
    );
  }
}

/// Scorecard Inning
class ScorecardInning {
  final String inning;
  final List<BattingEntry> batting;
  final List<BowlingEntry> bowling;
  final ExtrasInfo extras;
  final TotalsInfo totals;

  ScorecardInning({
    required this.inning,
    required this.batting,
    required this.bowling,
    required this.extras,
    required this.totals,
  });

  factory ScorecardInning.fromJson(Map<String, dynamic> json) {
    final battingList = (json['batting'] as List<dynamic>? ?? [])
        .map((b) => BattingEntry.fromJson(b as Map<String, dynamic>))
        .toList();

    final bowlingList = (json['bowling'] as List<dynamic>? ?? [])
        .map((b) => BowlingEntry.fromJson(b as Map<String, dynamic>))
        .toList();

    return ScorecardInning(
      inning: json['inning'] as String? ?? '',
      batting: battingList,
      bowling: bowlingList,
      extras: ExtrasInfo.fromJson(json['extras'] as Map<String, dynamic>? ?? {}),
      totals: TotalsInfo.fromJson(json['totals'] as Map<String, dynamic>? ?? {}),
    );
  }
}

/// Batting Entry
class BattingEntry {
  final String batsmanId;
  final String batsmanName;
  final String dismissal;
  final String dismissalText;
  final int runs;
  final int balls;
  final int fours;
  final int sixes;
  final double strikeRate;

  BattingEntry({
    required this.batsmanId,
    required this.batsmanName,
    required this.dismissal,
    required this.dismissalText,
    required this.runs,
    required this.balls,
    required this.fours,
    required this.sixes,
    required this.strikeRate,
  });

  factory BattingEntry.fromJson(Map<String, dynamic> json) {
    final batsman = json['batsman'] as Map<String, dynamic>? ?? {};
    return BattingEntry(
      batsmanId: batsman['id'] as String? ?? '',
      batsmanName: batsman['name'] as String? ?? '',
      dismissal: json['dismissal'] as String? ?? '',
      dismissalText: json['dismissal-text'] as String? ?? '',
      runs: json['r'] as int? ?? 0,
      balls: json['b'] as int? ?? 0,
      fours: json['4s'] as int? ?? 0,
      sixes: json['6s'] as int? ?? 0,
      strikeRate: (json['sr'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// Bowling Entry
class BowlingEntry {
  final String bowlerId;
  final String bowlerName;
  final double overs;
  final int maidens;
  final int runs;
  final int wickets;
  final int noBalls;
  final int wides;
  final double economy;

  BowlingEntry({
    required this.bowlerId,
    required this.bowlerName,
    required this.overs,
    required this.maidens,
    required this.runs,
    required this.wickets,
    required this.noBalls,
    required this.wides,
    required this.economy,
  });

  factory BowlingEntry.fromJson(Map<String, dynamic> json) {
    final bowler = json['bowler'] as Map<String, dynamic>? ?? {};
    return BowlingEntry(
      bowlerId: bowler['id'] as String? ?? '',
      bowlerName: bowler['name'] as String? ?? '',
      overs: (json['o'] as num?)?.toDouble() ?? 0.0,
      maidens: json['m'] as int? ?? 0,
      runs: json['r'] as int? ?? 0,
      wickets: json['w'] as int? ?? 0,
      noBalls: json['nb'] as int? ?? 0,
      wides: json['wd'] as int? ?? 0,
      economy: (json['eco'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// Extras Info
class ExtrasInfo {
  final int total;
  final int byes;
  final int legByes;
  final int wides;
  final int noBalls;
  final int penalty;

  ExtrasInfo({
    required this.total,
    required this.byes,
    required this.legByes,
    required this.wides,
    required this.noBalls,
    required this.penalty,
  });

  factory ExtrasInfo.fromJson(Map<String, dynamic> json) {
    return ExtrasInfo(
      total: json['r'] as int? ?? 0,
      byes: json['b'] as int? ?? 0,
      legByes: json['lb'] as int? ?? 0,
      wides: json['w'] as int? ?? 0,
      noBalls: json['nb'] as int? ?? 0,
      penalty: json['p'] as int? ?? 0,
    );
  }
}

/// Totals Info
class TotalsInfo {
  final int runs;
  final double overs;
  final int wickets;
  final double runRate;

  TotalsInfo({
    required this.runs,
    required this.overs,
    required this.wickets,
    required this.runRate,
  });

  factory TotalsInfo.fromJson(Map<String, dynamic> json) {
    return TotalsInfo(
      runs: json['R'] as int? ?? 0,
      overs: (json['O'] as num?)?.toDouble() ?? 0.0,
      wickets: json['W'] as int? ?? 0,
      runRate: (json['RR'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// Squad Model
class MatchSquad {
  final String teamName;
  final List<CricPlayer> players;

  MatchSquad({
    required this.teamName,
    required this.players,
  });

  factory MatchSquad.fromJson(Map<String, dynamic> json) {
    final playersList = (json['players'] as List<dynamic>? ?? [])
        .map((p) => CricPlayer.fromJson(p as Map<String, dynamic>))
        .toList();

    return MatchSquad(
      teamName: json['teamName'] as String? ?? '',
      players: playersList,
    );
  }
}
