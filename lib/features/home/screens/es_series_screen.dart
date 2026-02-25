import 'package:flutter/material.dart';
import 'package:fantasy_crick/core/constants/app_colors.dart';
import 'package:fantasy_crick/core/services/entity_sport_service.dart';
import 'package:fantasy_crick/features/matches/screens/competition_matches_screen.dart';

class EsSeriesScreen extends StatelessWidget {
  final Map<String, dynamic> seriesData;
  const EsSeriesScreen({super.key, required this.seriesData});

  @override
  Widget build(BuildContext context) {
    final title = seriesData['title']?.toString() ?? '';
    final abbr = seriesData['abbr']?.toString() ?? '';
    final season = seriesData['season']?.toString() ?? '';
    final status = seriesData['status']?.toString() ?? '';
    final category = seriesData['category']?.toString() ?? '';
    final type = seriesData['type']?.toString() ?? '';
    final format = seriesData['match_format']?.toString() ?? '';
    final total = seriesData['total_matches']?.toString() ?? '0';
    final country = seriesData['country']?.toString() ?? '';
    final dateStart = seriesData['datestart']?.toString() ?? '';
    final dateEnd = seriesData['dateend']?.toString() ?? '';
    final cid = seriesData['cid'] as int?;

    Color statusColor;
    switch (status) {
      case 'live': statusColor = Colors.red; break;
      case 'fixture': statusColor = AppColors.primary; break;
      default: statusColor = AppColors.success;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Header
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            backgroundColor: AppColors.primary,
            iconTheme: const IconThemeData(color: Colors.white),
            title: Text(abbr.isNotEmpty ? abbr : title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [AppColors.primary, AppColors.secondary], begin: Alignment.topLeft, end: Alignment.bottomRight),
                ),
                padding: const EdgeInsets.fromLTRB(20, 85, 20, 16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.end, children: [
                  Row(children: [
                    Container(width: 48, height: 48,
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.sports_cricket, color: Colors.white, size: 26)),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold), maxLines: 2),
                      const SizedBox(height: 4),
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: statusColor.withOpacity(0.8), borderRadius: BorderRadius.circular(8)),
                          child: Text(status.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 8),
                        Text('$total matches · $format'.toUpperCase(), style: const TextStyle(color: Colors.white70, fontSize: 11)),
                      ]),
                    ])),
                  ]),
                ]),
              ),
            ),
          ),

          // Info grid
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(children: [
              // Stats grid
              Row(children: [
                _StatBox(label: 'Category', value: category, icon: Icons.category),
                const SizedBox(width: 10),
                _StatBox(label: 'Type', value: type, icon: Icons.emoji_events),
                const SizedBox(width: 10),
                _StatBox(label: 'Format', value: format.toUpperCase(), icon: Icons.sports_cricket),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                _StatBox(label: 'Country', value: country.toUpperCase(), icon: Icons.flag),
                const SizedBox(width: 10),
                _StatBox(label: 'Season', value: season, icon: Icons.calendar_today),
                const SizedBox(width: 10),
                _StatBox(label: 'Matches', value: total, icon: Icons.format_list_numbered),
              ]),

              const SizedBox(height: 14),

              // Date range
              if (dateStart.isNotEmpty || dateEnd.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)],
                  ),
                  child: Row(children: [
                    const Icon(Icons.date_range, color: AppColors.primary, size: 20),
                    const SizedBox(width: 12),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Tournament Period', style: TextStyle(color: AppColors.textLight, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text('$dateStart → $dateEnd', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.text, fontSize: 14)),
                    ]),
                  ]),
                ),

              const SizedBox(height: 14),

              // View Matches button
              if (cid != null)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => CompetitionMatchesScreen(
                        competitionId: cid,
                        competitionName: title,
                        competitionAbbr: abbr,
                        season: season,
                      ),
                    )),
                    icon: const Icon(Icons.list_alt),
                    label: Text('View $total Matches'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                ),
            ]),
          )),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label, value;
  final IconData icon;
  const _StatBox({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)],
      ),
      child: Column(children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(height: 6),
        Text(value.isEmpty ? '-' : value, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.text, fontSize: 13), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
        Text(label, style: const TextStyle(color: AppColors.textLight, fontSize: 10), textAlign: TextAlign.center),
      ]),
    ),
  );
}
