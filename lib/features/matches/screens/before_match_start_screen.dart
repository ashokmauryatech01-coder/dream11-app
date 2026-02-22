import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fantasy_crick/core/constants/app_colors.dart';
import 'package:fantasy_crick/models/match_model.dart';
import 'package:fantasy_crick/features/home/utils/app_utils.dart';
import 'package:fantasy_crick/features/contest/screens/create_new_team_screen.dart';
import 'package:fantasy_crick/features/contest/screens/contest_screen.dart';
import 'package:fantasy_crick/features/matches/screens/match_detail_screen.dart';

class BeforeMatchStartScreen extends StatelessWidget {
  final MatchModel? match;

  const BeforeMatchStartScreen({super.key, this.match});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Match Preview', style: TextStyle(color: AppColors.text, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.text),
        actions: [
          if (match != null)
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MatchDetailScreen(match: match!)),
                );
              },
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildMatchHeader(),
          const SizedBox(height: 16),
          if (match?.seriesName != null) ...[
            _buildSeriesInfo(),
            const SizedBox(height: 16),
          ],
          _buildTeamComparison(),
          const SizedBox(height: 16),
          _buildVenueInfo(),
          const SizedBox(height: 16),
          _buildChecklist(),
          const SizedBox(height: 16),
          _buildActionButtons(context),
        ],
      ),
    );
  }

  Widget _buildMatchHeader() {
    final team1 = match?.teams.isNotEmpty == true ? match!.teams[0] : null;
    final team2 = match != null && match!.teams.length > 1 ? match!.teams[1] : null;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          if (match?.matchDesc != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  match!.matchDesc!,
                  style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600),
                ),
              ),
            ),

          // Teams row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Team 1
              _buildTeamColumn(team1),
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('VS', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textLight)),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      match?.format ?? 'T20',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.white),
                    ),
                  ),
                ],
              ),
              // Team 2
              _buildTeamColumn(team2),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Countdown
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.access_time, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                match != null ? AppUtils.getTimeUntilMatch(match!.dateTime) : 'TBD',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            match != null ? AppUtils.formatMatchDate(match!.dateTime) : '',
            style: const TextStyle(fontSize: 12, color: AppColors.textLight),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamColumn(Team? team) {
    return Column(
      children: [
        if (team?.imageUrl != null)
          CachedNetworkImage(
            imageUrl: team!.imageUrl!,
            width: 48,
            height: 48,
            placeholder: (context, url) => _buildTeamPlaceholder(team.shortName),
            errorWidget: (context, url, error) => _buildTeamPlaceholder(team.shortName),
          )
        else
          _buildTeamPlaceholder(team?.shortName ?? '?'),
        const SizedBox(height: 8),
        Text(
          team?.shortName ?? 'TBD',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text),
        ),
        const SizedBox(height: 2),
        SizedBox(
          width: 100,
          child: Text(
            team?.name ?? 'TBD',
            style: const TextStyle(fontSize: 11, color: AppColors.textLight),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildTeamPlaceholder(String shortName) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          shortName.isNotEmpty ? shortName[0] : '?',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary),
        ),
      ),
    );
  }

  Widget _buildSeriesInfo() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          const Icon(Icons.emoji_events, color: AppColors.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  match!.seriesName!,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text),
                  maxLines: 2,
                ),
                if (match?.seriesCategory != null)
                  Text(
                    match!.seriesCategory!,
                    style: const TextStyle(fontSize: 11, color: AppColors.textLight),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamComparison() {
    final team1 = match?.teams.isNotEmpty == true ? match!.teams[0] : null;
    final team2 = match != null && match!.teams.length > 1 ? match!.teams[1] : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Quick Info', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 12),
          _buildInfoRow('Team 1', team1?.name ?? 'TBD'),
          _buildInfoRow('Team 2', team2?.name ?? 'TBD'),
          _buildInfoRow('Format', match?.format ?? 'TBD'),
          if (match?.venue.country != null)
            _buildInfoRow('Country', match!.venue.country!),
          if (match?.dateHeader != null)
            _buildInfoRow('Date', match!.dateHeader!),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textLight)),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVenueInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.location_on, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  match?.venue.name ?? 'TBD',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.text),
                ),
                const SizedBox(height: 2),
                Text(
                  '${match?.venue.city ?? 'TBD'}${match?.venue.country != null ? ', ${match!.venue.country}' : ''}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textLight),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChecklist() {
    final items = [
      'Finalize your team',
      'Select Captain & Vice Captain',
      'Join contests',
      'Set match reminders',
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Checklist', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: AppColors.success, size: 18),
                    const SizedBox(width: 8),
                    Text(item, style: const TextStyle(color: AppColors.textLight)),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CreateNewTeamScreen()),
              );
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
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ContestScreen()),
              );
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
    );
  }
}
