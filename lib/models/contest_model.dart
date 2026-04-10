class ContestModel {
  final String id;
  final String name;
  final String matchId;
  final double entryFee;
  final double prizePool;
  final int maxTeams;
  final int currentTeams;
  final bool multipleTeams;

  final int winnerPercentage;
  final bool isGuaranteed;

  ContestModel({
    required this.id,
    required this.name,
    required this.matchId,
    required this.entryFee,
    required this.prizePool,
    required this.maxTeams,
    required this.currentTeams,
    required this.multipleTeams,
    this.winnerPercentage = 50,
    this.isGuaranteed = false,
  });

  factory ContestModel.fromJson(Map<String, dynamic> json) {
    return ContestModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      matchId: json['match_id']?.toString() ?? '',
      entryFee: double.tryParse(json['entry_fee']?.toString() ?? '0') ?? 0.0,
      prizePool: double.tryParse(json['prize_pool']?.toString() ?? '0') ?? 0.0,
      maxTeams: int.tryParse(json['max_participants']?.toString() ?? 
                            json['max_teams']?.toString() ?? 
                            json['total_spots']?.toString() ?? '0') ?? 0,
      currentTeams: int.tryParse(json['current_participants']?.toString() ?? 
                                json['current_teams']?.toString() ?? 
                                json['filled_spots']?.toString() ?? '0') ?? 0,
      multipleTeams: json['multiple_entries'] == true || 
                     json['multiple_teams'] == true || 
                     json['multiple_entries']?.toString() == '1',
      winnerPercentage: int.tryParse(json['winner_percentage']?.toString() ?? '50') ?? 50,
      isGuaranteed: json['is_guaranteed'] == true || 
                    json['guaranteed'] == true || 
                    json['is_guaranteed']?.toString() == '1',
    );
  }
}
