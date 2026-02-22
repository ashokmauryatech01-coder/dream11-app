class ContestModel {
  final String id;
  final String name;
  final String matchId;
  final double entryFee;
  final double prizePool;
  final int maxTeams;
  final int currentTeams;
  final bool multipleTeams;

  ContestModel({
    required this.id,
    required this.name,
    required this.matchId,
    required this.entryFee,
    required this.prizePool,
    required this.maxTeams,
    required this.currentTeams,
    required this.multipleTeams,
  });

  factory ContestModel.fromJson(Map<String, dynamic> json) {
    return ContestModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      matchId: json['match_id']?.toString() ?? '',
      entryFee: (json['entry_fee'] ?? 0).toDouble(),
      prizePool: (json['prize_pool'] ?? 0).toDouble(),
      maxTeams: json['max_teams'] ?? 0,
      currentTeams: json['current_teams'] ?? 0,
      multipleTeams: json['multiple_teams'] ?? false,
    );
  }
}
