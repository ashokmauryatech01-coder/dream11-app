/// ============================================================================
/// CRICKET TEAM MODEL - Updated for CricAPI
/// ============================================================================

class CricketTeamModel {
  final String id;
  final String name;
  final String shortName;
  final int? imageId;
  final String? imageUrl;
  final String? category;

  CricketTeamModel({
    required this.id,
    required this.name,
    required this.shortName,
    this.imageId,
    this.imageUrl,
    this.category,
  });

  /// Create from CricAPI response (teamInfo from matches)
  factory CricketTeamModel.fromJson(Map<String, dynamic> json) {
    final id = (json['teamId'] ?? json['id'] ?? '').toString();
    final imgId = json['imageId'] as int?;
    
    // Try to get image URL from CricAPI format first, then fallback to cricbuzz
    String? imgUrl = json['img'] as String?;
    if (imgUrl == null && imgId != null) {
      imgUrl = 'https://static.cricbuzz.com/a/img/v1/72x54/i1/c$imgId/team.jpg';
    }

    return CricketTeamModel(
      id: id.isNotEmpty ? id : (json['name']?.hashCode.toString() ?? ''),
      name: json['teamName'] as String? ?? json['name'] as String? ?? 'Unknown',
      shortName: json['teamSName'] as String? ?? json['shortname'] as String? ?? json['shortName'] as String? ?? '',
      imageId: imgId,
      imageUrl: imgUrl,
      category: json['_category'] as String?,
    );
  }

  /// Create from minimal data (for TeamsService)
  factory CricketTeamModel.simple({
    required String id,
    required String name,
    required String shortName,
    String? imageUrl,
  }) {
    return CricketTeamModel(
      id: id,
      name: name,
      shortName: shortName,
      imageUrl: imageUrl,
    );
  }

  // Legacy getters for backward compatibility
  String get teamId => id;
  String get teamName => name;
}
