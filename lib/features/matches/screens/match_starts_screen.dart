import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fantasy_crick/core/constants/app_colors.dart';
import 'package:fantasy_crick/models/match_model.dart';
import 'package:fantasy_crick/features/home/utils/app_utils.dart';
import 'package:fantasy_crick/features/contest/screens/create_new_team_screen.dart';
import 'package:fantasy_crick/features/contest/screens/contest_screen.dart';

class MatchStartsScreen extends StatelessWidget {
  final MatchModel? match;

  const MatchStartsScreen({super.key, this.match});

  @override
  Widget build(BuildContext context) {
    final team1 = match?.teams.isNotEmpty == true ? match!.teams[0] : null;
    final team2 = match != null && match!.teams.length > 1 ? match!.teams[1] : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Match Starts', style: TextStyle(color: AppColors.text, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.text),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                if (match?.matchDesc != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(match!.matchDesc!, style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
                    ),
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildTeamCol(team1),
                    Column(
                      children: [
                        const Text('VS', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textLight, fontSize: 16)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(4)),
                          child: Text(match?.format ?? 'T20', style: const TextStyle(color: AppColors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    _buildTeamCol(team2),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.timer, size: 18, color: AppColors.warning),
                    const SizedBox(width: 6),
                    Text(
                      match != null ? 'Starts in ${AppUtils.getTimeUntilMatch(match!.dateTime)}' : 'Starting soon',
                      style: const TextStyle(color: AppColors.warning, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.location_on, size: 14, color: AppColors.textLight),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        match != null
                            ? '${match!.venue.name} • ${AppUtils.formatMatchDate(match!.dateTime)}'
                            : 'TBD',
                        style: const TextStyle(color: AppColors.textLight, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateNewTeamScreen()));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Create Team', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const ContestScreen()));
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Join Contest', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTeamCol(Team? team) {
    return Column(
      children: [
        if (team?.imageUrl != null)
          CachedNetworkImage(
            imageUrl: team!.imageUrl!,
            width: 44,
            height: 44,
            placeholder: (context, url) => _buildPlaceholder(team.shortName),
            errorWidget: (context, url, error) => _buildPlaceholder(team.shortName),
          )
        else
          _buildPlaceholder(team?.shortName ?? '?'),
        const SizedBox(height: 6),
        Text(team?.shortName ?? 'TBD', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        SizedBox(
          width: 90,
          child: Text(
            team?.name ?? 'TBD',
            style: const TextStyle(fontSize: 10, color: AppColors.textLight),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholder(String text) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
      child: Center(
        child: Text(text.isNotEmpty ? text[0] : '?', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 18)),
      ),
    );
  }
}
