import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fantasy_crick/core/constants/app_colors.dart';
import 'package:fantasy_crick/models/match_model.dart';
import 'package:fantasy_crick/features/home/utils/app_utils.dart';

class MatchCard extends StatelessWidget {
  final MatchModel match;
  final VoidCallback onTap;

  const MatchCard({
    super.key,
    required this.match,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 280,
        height: 160,
        margin: const EdgeInsets.only(right: 12, bottom: 4, top: 4, left: 4),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              offset: const Offset(0, 2),
              blurRadius: 4,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Column(
            children: [
              // Header - Series Name & Status
              _buildHeader(),
              // Teams Section
              Expanded(child: _buildTeamsSection()),
              // Footer - Date & Action
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final isLive = match.isLive;
    final displayText = match.seriesName ?? match.matchDesc ?? 'Cricket Match';
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      color: AppColors.background,
      child: Row(
        children: [
          if (isLive) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'LIVE',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 6),
          ],
          Expanded(
            child: Text(
              displayText,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: _getFormatColor(match.format).withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              match.format,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: _getFormatColor(match.format),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        children: [
          // Team 1
          Expanded(
            child: _buildTeamColumn(match.team1, true),
          ),
          // VS & Time
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'VS',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textLight,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getMatchTimeText(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: match.isLive ? Colors.green : AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          // Team 2
          Expanded(
            child: _buildTeamColumn(match.team2, false),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamColumn(Team team, bool isTeam1) {
    final score = isTeam1 ? match.team1Score : match.team2Score;
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Team logo
        _buildTeamLogo(team),
        const SizedBox(height: 4),
        // Team name
        Text(
          team.shortName,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppColors.text,
          ),
        ),
        // Score if available
        if (score != null)
          Text(
            score.scoreString,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textLight,
            ),
          )
        else
          Text(
            team.name.length > 12 ? '${team.name.substring(0, 10)}...' : team.name,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textLight,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );
  }

  Widget _buildTeamLogo(Team team) {
    if (team.imageUrl != null && team.imageUrl!.isNotEmpty) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: team.imageUrl!,
          width: 36,
          height: 36,
          fit: BoxFit.cover,
          placeholder: (context, url) => _buildDefaultLogo(team.shortName),
          errorWidget: (context, url, error) => _buildDefaultLogo(team.shortName),
        ),
      );
    }
    return _buildDefaultLogo(team.shortName);
  }

  Widget _buildDefaultLogo(String shortName) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        shortName.isNotEmpty
            ? shortName.substring(0, shortName.length.clamp(0, 2))
            : '?',
        style: const TextStyle(
          color: AppColors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      color: AppColors.background.withOpacity(0.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                match.isLive ? Icons.sports_cricket : Icons.calendar_today,
                size: 11,
                color: AppColors.textLight,
              ),
              const SizedBox(width: 4),
              Text(
                match.isLive ? match.status : AppUtils.formatMatchDate(match.dateTime),
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textLight,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              match.isLive ? 'View' : 'Play',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AppColors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getMatchTimeText() {
    if (match.isLive) {
      return 'Started';
    } else if (match.isCompleted) {
      return 'Completed';
    } else {
      return AppUtils.getTimeUntilMatch(match.dateTime);
    }
  }

  Color _getFormatColor(String format) {
    switch (format.toUpperCase()) {
      case 'T20':
        return Colors.purple;
      case 'ODI':
        return Colors.blue;
      case 'TEST':
        return Colors.red;
      default:
        return AppColors.primary;
    }
  }
}
