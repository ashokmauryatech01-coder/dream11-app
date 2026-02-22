class SeriesModel {
  final String id;
  final String name;
  final String? startDate;
  final String? endDate;

  SeriesModel({
    required this.id,
    required this.name,
    this.startDate,
    this.endDate,
  });

  factory SeriesModel.fromJson(Map<String, dynamic> json) {
    return SeriesModel(
      id: (json['id'] ?? json['seriesId'] ?? '').toString(),
      name: json['name'] as String? ?? json['seriesName'] as String? ?? 'Unknown Series',
      startDate: (json['startDt'] ?? json['startDate'] ?? '').toString(),
      endDate: (json['endDt'] ?? json['endDate'] ?? '').toString(),
    );
  }

  /// Format date range for display (e.g. "Jan 2026 - Mar 2026")
  String get dateRange {
    final start = _parseEpoch(startDate);
    final end = _parseEpoch(endDate);

    if (start == null && end == null) return '';

    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];

    String format(DateTime dt) => '${months[dt.month - 1]} ${dt.day}, ${dt.year}';

    if (start != null && end != null) {
      return '${format(start)} - ${format(end)}';
    } else if (start != null) {
      return format(start);
    } else {
      return format(end!);
    }
  }

  DateTime? _parseEpoch(String? value) {
    if (value == null || value.isEmpty) return null;
    final ms = int.tryParse(value);
    if (ms == null || ms == 0) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }
}
