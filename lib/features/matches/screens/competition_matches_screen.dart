import 'package:flutter/material.dart';
import 'package:fantasy_crick/core/constants/app_colors.dart';
import 'package:fantasy_crick/core/services/competition_service.dart';
import 'package:fantasy_crick/models/competition_match_model.dart';
import 'package:fantasy_crick/features/matches/screens/es_match_detail_screen.dart';

class CompetitionMatchesScreen extends StatefulWidget {
  final int competitionId;
  final String competitionName;
  final String competitionAbbr;
  final String season;

  const CompetitionMatchesScreen({
    super.key,
    required this.competitionId,
    required this.competitionName,
    required this.competitionAbbr,
    required this.season,
  });

  @override
  State<CompetitionMatchesScreen> createState() =>
      _CompetitionMatchesScreenState();
}

class _CompetitionMatchesScreenState extends State<CompetitionMatchesScreen> {
  final _service = CompetitionService();
  bool _isLoading = true;
  List<CompetitionMatchModel> _matches = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await _service.getAllCompetitionMatches(
      cid: widget.competitionId,
    );
    if (mounted) {
      setState(() {
        _matches = data;
        _isLoading = false;
      });
    }
  }

  Map<String, dynamic> _matchToMap(CompetitionMatchModel m) {
    return {
      'match_id': m.matchId,
      'title': m.title,
      'short_title': m.shortTitle,
      'subtitle': m.subtitle,
      'format_str': m.formatStr,
      'status': m.status,
      'status_str': m.statusStr,
      'status_note': m.statusNote,
      'winning_team_id': m.winningTeamId,
      'date_start_ist': m.dateStartIst,
      'umpires': m.umpires,
      'referee': m.referee,
      'teama': {
        'team_id': m.teama.teamId,
        'name': m.teama.name,
        'short_name': m.teama.shortName,
        'logo_url': m.teama.logoUrl,
        'scores_full': m.teama.scoresFull,
      },
      'teamb': {
        'team_id': m.teamb.teamId,
        'name': m.teamb.name,
        'short_name': m.teamb.shortName,
        'logo_url': m.teamb.logoUrl,
        'scores_full': m.teamb.scoresFull,
      },
      'competition': {
        'title': m.competition.title,
        'season': m.competition.season,
        'category': m.competition.category,
      },
      'venue': {
        'name': m.venue.name,
        'location': m.venue.location,
        'country': m.venue.country,
      },
      'toss': m.toss != null ? {'text': m.toss!.text} : null,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          '${widget.competitionAbbr} ${widget.season}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _matches.isEmpty
          ? const Center(
              child: Text(
                'No matches found.',
                style: TextStyle(color: Colors.white70),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _matches.length,
              itemBuilder: (_, i) {
                final match = _matches[i];
                return _buildMatchCard(match);
              },
            ),
    );
  }

  Widget _buildMatchCard(CompetitionMatchModel match) {
    return Card(
      color: const Color(0xFF243052),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  EsMatchDetailScreen(matchData: _matchToMap(match)),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      match.shortTitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: match.isLive
                          ? Colors.red
                          : (match.isCompleted
                                ? AppColors.success
                                : AppColors.primary),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      match.statusBadge,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                match.subtitle,
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _teamCol(match.teama, true),
                  _vsBadge(match),
                  _teamCol(match.teamb, false),
                ],
              ),
              if (match.statusNote.isNotEmpty) ...[
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    match.statusNote,
                    style: const TextStyle(
                      color: Colors.amber,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _teamCol(TeamInfo team, bool isA) {
    return Expanded(
      child: Column(
        crossAxisAlignment: isA
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isA) _logo(team.logoUrl),
              if (isA) const SizedBox(width: 8),
              Flexible(
                child: Text(
                  team.shortName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              if (!isA) const SizedBox(width: 8),
              if (!isA) _logo(team.logoUrl),
            ],
          ),
          if (team.scoresFull.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              team.scoresFull,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
              textAlign: isA ? TextAlign.left : TextAlign.right,
            ),
          ],
        ],
      ),
    );
  }

  Widget _logo(String url) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: BorderRadius.circular(6),
      ),
      child: url.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.network(
                url,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.shield, color: Colors.white54, size: 18),
              ),
            )
          : const Icon(Icons.shield, color: Colors.white54, size: 18),
    );
  }

  Widget _vsBadge(CompetitionMatchModel match) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Text(
        'VS',
        style: TextStyle(
          color: Colors.white54,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}
