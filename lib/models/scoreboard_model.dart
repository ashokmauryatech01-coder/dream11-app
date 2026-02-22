/// Model for match scoreboard data from /cricket-match-scoreboard API
class ScoreboardModel {
  final InningsData? firstInnings;
  final InningsData? secondInnings;

  ScoreboardModel({this.firstInnings, this.secondInnings});

  factory ScoreboardModel.fromJson(Map<String, dynamic> json) {
    return ScoreboardModel(
      firstInnings: json['firstInnings'] != null
          ? InningsData.fromJson(json['firstInnings'] as Map<String, dynamic>)
          : null,
      secondInnings: json['secondInnings'] != null
          ? InningsData.fromJson(json['secondInnings'] as Map<String, dynamic>)
          : null,
    );
  }

  bool get hasData =>
      (firstInnings?.batters.isNotEmpty ?? false) ||
      (secondInnings?.batters.isNotEmpty ?? false);
}

class InningsData {
  final List<BatterData> batters;
  final List<BowlerData> bowlers;
  final ExtrasData? extras;
  final TotalData? total;
  final PowerplayData? powerplays;
  final FallOfWicketsData? fallOfWickets;
  final DidNotBatData? didNotBat;

  InningsData({
    required this.batters,
    required this.bowlers,
    this.extras,
    this.total,
    this.powerplays,
    this.fallOfWickets,
    this.didNotBat,
  });

  factory InningsData.fromJson(Map<String, dynamic> json) {
    return InningsData(
      batters: (json['batters'] as List<dynamic>? ?? [])
          .map((b) => BatterData.fromJson(b as Map<String, dynamic>))
          .toList(),
      bowlers: (json['bowlers'] as List<dynamic>? ?? [])
          .map((b) => BowlerData.fromJson(b as Map<String, dynamic>))
          .toList(),
      extras: json['extras'] != null && (json['extras'] as Map).isNotEmpty
          ? ExtrasData.fromJson(json['extras'] as Map<String, dynamic>)
          : null,
      total: json['total'] != null && (json['total'] as Map).isNotEmpty
          ? TotalData.fromJson(json['total'] as Map<String, dynamic>)
          : null,
      powerplays: json['powerplays'] != null
          ? PowerplayData.fromJson(json['powerplays'] as Map<String, dynamic>)
          : null,
      fallOfWickets: json['fallOfWickets'] != null
          ? FallOfWicketsData.fromJson(json['fallOfWickets'] as Map<String, dynamic>)
          : null,
      didNotBat: json['didNotBat'] != null && (json['didNotBat'] as Map).isNotEmpty
          ? DidNotBatData.fromJson(json['didNotBat'] as Map<String, dynamic>)
          : null,
    );
  }
}

class BatterData {
  final String name;
  final String runs;
  final String balls;
  final String fours;
  final String sixes;
  final String strikeRate;
  final String dismissal;

  BatterData({
    required this.name,
    required this.runs,
    required this.balls,
    required this.fours,
    required this.sixes,
    required this.strikeRate,
    required this.dismissal,
  });

  factory BatterData.fromJson(Map<String, dynamic> json) {
    return BatterData(
      name: json['name'] as String? ?? '',
      runs: json['runs'] as String? ?? '0',
      balls: json['balls'] as String? ?? '0',
      fours: json['fours'] as String? ?? '0',
      sixes: json['sixes'] as String? ?? '0',
      strikeRate: json['strikeRate'] as String? ?? '0.00',
      dismissal: json['dismissal'] as String? ?? '',
    );
  }
}

class BowlerData {
  final String name;
  final String overs;
  final String maidens;
  final String runs;
  final String wickets;
  final String economy;

  BowlerData({
    required this.name,
    required this.overs,
    required this.maidens,
    required this.runs,
    required this.wickets,
    required this.economy,
  });

  factory BowlerData.fromJson(Map<String, dynamic> json) {
    return BowlerData(
      name: json['name'] as String? ?? '',
      overs: json['overs'] as String? ?? '0',
      maidens: json['maidens'] as String? ?? '0',
      runs: json['runs'] as String? ?? '0',
      wickets: json['wickets'] as String? ?? '0',
      economy: json['economy'] as String? ?? '0.00',
    );
  }
}

class ExtrasData {
  final String total;
  final String detail;

  ExtrasData({required this.total, required this.detail});

  factory ExtrasData.fromJson(Map<String, dynamic> json) {
    return ExtrasData(
      total: json['total'] as String? ?? '0',
      detail: json['detail'] as String? ?? '',
    );
  }
}

class TotalData {
  final String runs;
  final String wickets;
  final String overs;

  TotalData({required this.runs, required this.wickets, required this.overs});

  factory TotalData.fromJson(Map<String, dynamic> json) {
    return TotalData(
      runs: json['runs'] as String? ?? '0',
      wickets: json['wickets'] as String? ?? '0',
      overs: json['overs'] as String? ?? '0',
    );
  }

  String get formatted => '$runs/$wickets ($overs ov)';
}

class PowerplayData {
  final String label;
  final String overs;
  final String runs;

  PowerplayData({required this.label, required this.overs, required this.runs});

  factory PowerplayData.fromJson(Map<String, dynamic> json) {
    return PowerplayData(
      label: json['label'] as String? ?? '',
      overs: json['overs'] as String? ?? '',
      runs: json['runs'] as String? ?? '',
    );
  }
}

class FallOfWicketsData {
  final String label;
  final List<String> detail;

  FallOfWicketsData({required this.label, required this.detail});

  factory FallOfWicketsData.fromJson(Map<String, dynamic> json) {
    return FallOfWicketsData(
      label: json['label'] as String? ?? 'Fall Of Wickets',
      detail: (json['detail'] as List<dynamic>? ?? [])
          .map((d) => d.toString())
          .toList(),
    );
  }
}

class DidNotBatData {
  final List<String> players;

  DidNotBatData({required this.players});

  factory DidNotBatData.fromJson(Map<String, dynamic> json) {
    final label = json['label'] as String? ?? '';
    final detail = json['detail'] as String? ?? '';
    final players = <String>[];
    if (label.isNotEmpty) players.add(label);
    if (detail.isNotEmpty) players.addAll(detail.split(',').map((e) => e.trim()));
    return DidNotBatData(players: players);
  }
}

/// Model for match info from /cricket-match-info API
class MatchInfoModel {
  final Map<String, dynamic> raw;

  MatchInfoModel({required this.raw});

  factory MatchInfoModel.fromJson(Map<String, dynamic> json) {
    return MatchInfoModel(raw: json['matchInfo'] as Map<String, dynamic>? ?? {});
  }

  bool get hasData => raw.isNotEmpty;
  
  String get status => raw['status'] as String? ?? '';
  String get result => raw['result'] as String? ?? '';
  String get toss => raw['toss'] as String? ?? '';
  String get umpires => raw['umpires'] as String? ?? '';
  String get referee => raw['referee'] as String? ?? '';
  String get manOfMatch => raw['manOfMatch'] as String? ?? '';
}
