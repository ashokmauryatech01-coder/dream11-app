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
      entryFee: double.tryParse(json['entry_fee']?.toString() ?? '0') ?? 0.0,
      prizePool: double.tryParse(json['prize_pool']?.toString() ?? '0') ?? 0.0,
      maxTeams: json['max_participants'] ?? json['max_teams'] ?? 0,
      currentTeams: json['current_participants'] ?? json['current_teams'] ?? 0,
      multipleTeams: json['multiple_entries'] ?? json['multiple_teams'] ?? false,
    );
  }
}
