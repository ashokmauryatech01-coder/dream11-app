class CompetitionMatchModel {
  final int matchId;
  final String title;
  final String shortTitle;
  final String subtitle;
  final String matchNumber;
  final int format;
  final String formatStr;
  final int status;
  final String statusStr;
  final String statusNote;
  final String verified;
  final String preSquad;
  final int gameState;
  final String gameStateStr;
  final CompetitionInfo competition;
  final TeamInfo teama;
  final TeamInfo teamb;
  final String dateStart;
  final String dateEnd;
  final int timestampStart;
  final int timestampEnd;
  final String dateStartIst;
  final String dateEndIst;
  final VenueInfo venue;
  final String umpires;
  final String referee;
  final String equation;
  final String live;
  final String result;
  final int resultType;
  final String winMargin;
  final int winningTeamId;
  final int commentary;
  final int wagon;
  final int latestInningNumber;
  final TossInfo? toss;

  CompetitionMatchModel({
    required this.matchId,
    required this.title,
    required this.shortTitle,
    required this.subtitle,
    required this.matchNumber,
    required this.format,
    required this.formatStr,
    required this.status,
    required this.statusStr,
    required this.statusNote,
    required this.verified,
    required this.preSquad,
    required this.gameState,
    required this.gameStateStr,
    required this.competition,
    required this.teama,
    required this.teamb,
    required this.dateStart,
    required this.dateEnd,
    required this.timestampStart,
    required this.timestampEnd,
    required this.dateStartIst,
    required this.dateEndIst,
    required this.venue,
    required this.umpires,
    required this.referee,
    required this.equation,
    required this.live,
    required this.result,
    required this.resultType,
    required this.winMargin,
    required this.winningTeamId,
    required this.commentary,
    required this.wagon,
    required this.latestInningNumber,
    this.toss,
  });

  factory CompetitionMatchModel.fromJson(Map<String, dynamic> json) {
    return CompetitionMatchModel(
      matchId: json['match_id'] ?? 0,
      title: json['title'] ?? '',
      shortTitle: json['short_title'] ?? '',
      subtitle: json['subtitle'] ?? '',
      matchNumber: json['match_number']?.toString() ?? '',
      format: json['format'] ?? 0,
      formatStr: json['format_str'] ?? '',
      status: json['status'] ?? 0,
      statusStr: json['status_str'] ?? '',
      statusNote: json['status_note'] ?? '',
      verified: json['verified']?.toString() ?? 'false',
      preSquad: json['pre_squad']?.toString() ?? 'false',
      gameState: json['game_state'] ?? 0,
      gameStateStr: json['game_state_str'] ?? '',
      competition: CompetitionInfo.fromJson(json['competition'] ?? {}),
      teama: TeamInfo.fromJson(json['teama'] ?? {}),
      teamb: TeamInfo.fromJson(json['teamb'] ?? {}),
      dateStart: json['date_start'] ?? '',
      dateEnd: json['date_end'] ?? '',
      timestampStart: json['timestamp_start'] ?? 0,
      timestampEnd: json['timestamp_end'] ?? 0,
      dateStartIst: json['date_start_ist'] ?? '',
      dateEndIst: json['date_end_ist'] ?? '',
      venue: VenueInfo.fromJson(json['venue'] ?? {}),
      umpires: json['umpires'] ?? '',
      referee: json['referee'] ?? '',
      equation: json['equation'] ?? '',
      live: json['live'] ?? '',
      result: json['result'] ?? '',
      resultType: json['result_type'] ?? 0,
      winMargin: json['win_margin'] ?? '',
      winningTeamId: json['winning_team_id'] ?? 0,
      commentary: json['commentary'] ?? 0,
      wagon: json['wagon'] ?? 0,
      latestInningNumber: json['latest_inning_number'] ?? 0,
      toss: json['toss'] != null ? TossInfo.fromJson(json['toss']) : null,
    );
  }

  bool get isLive => status == 3;
  bool get isCompleted => status == 2;
  bool get isUpcoming => status == 1;

  String get statusBadge {
    if (isLive) return 'LIVE';
    if (isCompleted) return 'Completed';
    return 'Upcoming';
  }
}

class CompetitionInfo {
  final int cid;
  final String title;
  final String abbr;
  final String type;
  final String category;
  final String matchFormat;
  final String season;
  final String status;
  final String datestart;
  final String dateend;
  final String country;
  final String totalMatches;
  final String totalRounds;
  final String totalTeams;

  CompetitionInfo({
    required this.cid,
    required this.title,
    required this.abbr,
    required this.type,
    required this.category,
    required this.matchFormat,
    required this.season,
    required this.status,
    required this.datestart,
    required this.dateend,
    required this.country,
    required this.totalMatches,
    required this.totalRounds,
    required this.totalTeams,
  });

  factory CompetitionInfo.fromJson(Map<String, dynamic> json) {
    return CompetitionInfo(
      cid: json['cid'] ?? 0,
      title: json['title'] ?? '',
      abbr: json['abbr'] ?? '',
      type: json['type'] ?? '',
      category: json['category'] ?? '',
      matchFormat: json['match_format'] ?? '',
      season: json['season'] ?? '',
      status: json['status'] ?? '',
      datestart: json['datestart'] ?? '',
      dateend: json['dateend'] ?? '',
      country: json['country'] ?? '',
      totalMatches: json['total_matches']?.toString() ?? '0',
      totalRounds: json['total_rounds']?.toString() ?? '0',
      totalTeams: json['total_teams']?.toString() ?? '0',
    );
  }
}

class TeamInfo {
  final int teamId;
  final String name;
  final String shortName;
  final String logoUrl;
  final String thumbUrl;
  final String scoresFull;
  final String scores;
  final String overs;

  TeamInfo({
    required this.teamId,
    required this.name,
    required this.shortName,
    required this.logoUrl,
    required this.thumbUrl,
    required this.scoresFull,
    required this.scores,
    required this.overs,
  });

  factory TeamInfo.fromJson(Map<String, dynamic> json) {
    return TeamInfo(
      teamId: json['team_id'] ?? 0,
      name: json['name'] ?? '',
      shortName: json['short_name'] ?? '',
      logoUrl: json['logo_url'] ?? '',
      thumbUrl: json['thumb_url'] ?? '',
      scoresFull: json['scores_full'] ?? '',
      scores: json['scores'] ?? '',
      overs: json['overs'] ?? '',
    );
  }
}

class VenueInfo {
  final String venueId;
  final String name;
  final String location;
  final String country;
  final String timezone;

  VenueInfo({
    required this.venueId,
    required this.name,
    required this.location,
    required this.country,
    required this.timezone,
  });

  factory VenueInfo.fromJson(Map<String, dynamic> json) {
    return VenueInfo(
      venueId: json['venue_id']?.toString() ?? '',
      name: json['name'] ?? '',
      location: json['location'] ?? '',
      country: json['country'] ?? '',
      timezone: json['timezone']?.toString() ?? '',
    );
  }
}

class TossInfo {
  final String text;
  final int winner;
  final int decision;

  TossInfo({
    required this.text,
    required this.winner,
    required this.decision,
  });

  factory TossInfo.fromJson(Map<String, dynamic> json) {
    return TossInfo(
      text: json['text'] ?? '',
      winner: json['winner'] ?? 0,
      decision: json['decision'] ?? 0,
    );
  }
}
