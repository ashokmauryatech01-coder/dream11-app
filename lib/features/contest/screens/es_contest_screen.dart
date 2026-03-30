import 'package:flutter/material.dart';
import 'package:fantasy_crick/core/constants/app_colors.dart';
import 'package:fantasy_crick/features/contest/screens/es_create_team_screen.dart';
import 'package:fantasy_crick/core/services/location_service.dart';
import 'package:fantasy_crick/core/services/teams_service.dart';
import 'package:fantasy_crick/core/services/contest_service.dart';
import 'package:fantasy_crick/core/services/user_profile_service.dart';
import 'package:fantasy_crick/models/contest_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  CONTEST SCREEN — white background, real contests from API
//  Simplified: My Teams tab removed.
// ─────────────────────────────────────────────────────────────────────────────
class EsContestScreen extends StatefulWidget {
  final List<Map<String, dynamic>> matches;
  const EsContestScreen({super.key, required this.matches});

  @override
  State<EsContestScreen> createState() => _EsContestScreenState();
}

class _EsContestScreenState extends State<EsContestScreen> {
  Map<String, dynamic>? _selectedMatch;
  List<ContestModel> _contests = [];
  bool _loading = false;
  Map<String, dynamic>? _location;

  @override
  void initState() {
    super.initState();
    _initLocation();
    if (widget.matches.isNotEmpty) {
      _selectedMatch = widget.matches.first;
      _loadContests();
    }
  }

  Future<void> _initLocation() async {
    final data = await LocationService.getLocationData();
    if (mounted) {
      setState(() {
        _location = data;
      });
    }
  }

  Future<void> _loadContests() async {
    if (_selectedMatch == null) return;
    setState(() {
      _loading = true;
    });
    final matchId = int.tryParse(_selectedMatch!['match_id']?.toString() ?? '0') ?? 0;
    try {
      final contestService = ContestService();
      final contests = await contestService.getAllContests();

      if (!mounted) return;

      setState(() {
        _contests = contests;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _contests = [];
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[50],
      child: Column(
        children: [
          // Match selector removed as per user request

          // Contest list
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                    ),
                  )
                : _contestList(),
          ),
        ],
      ),
    );
  }

  // ── CONTEST LIST ──────────────────────────────────────────────────────────
  Widget _contestList() {
    if (_contests.isEmpty)
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.emoji_events_outlined,
              size: 56,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 12),
            Text(
              'No contests available',
              style: TextStyle(color: Colors.grey[500], fontSize: 15),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadContests,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    return RefreshIndicator(
      onRefresh: _loadContests,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 80),
        itemCount: _contests.length,
        itemBuilder: (_, i) =>
            _contestCard(_contests[i]),
      ),
    );
  }

  // ── CONTEST CARD ──────────────────────────────────────────────────────────
  Widget _contestCard(ContestModel c) {
    final totalSpots = c.maxTeams;
    final filledSpots = c.currentTeams;
    final fee = c.entryFee.toInt();
    final isFree = fee == 0;
    final prize = LocationService.formatAmount(c.prizePool, _location);
    final winners = c.winnerPercentage;
    final spotsLeft = totalSpots - filledSpots;
    final progress = totalSpots > 0
        ? (filledSpots / totalSpots).clamp(0.0, 1.0)
        : 0.0;
    final name = c.name;
    final matchId = c.matchId; // Show match ID
    final isGuaranteed = c.isGuaranteed;

    Color progressColor = progress >= 0.9
        ? Colors.red
        : progress >= 0.6
        ? Colors.orange
        : Colors.green;

    return GestureDetector(
      onTap: () => _showContestDetails(context, c),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(color: Colors.grey.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isGuaranteed)
                              Container(
                                margin: const EdgeInsets.only(left: 6),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'G',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              'Match ID: $matchId',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              'Prize Pool  ',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              prize,
                              style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isFree
                          ? AppColors.secondary
                          : AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: (isFree ? AppColors.secondary : AppColors.primary).withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      isFree
                          ? 'FREE'
                          : LocationService.formatAmount(fee, _location),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Divider(height: 1, color: Colors.grey[100]),

            // Progress + stats
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress.toDouble(),
                      minHeight: 4,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        spotsLeft > 0
                            ? '$spotsLeft spots left'
                            : 'Contest full',
                        style: TextStyle(
                          color: spotsLeft < 10 ? Colors.red : Colors.green[700],
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '$winners% winners',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Bottom Action (Join Button)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: spotsLeft > 0 
                      ? (isFree ? AppColors.secondary : AppColors.primary)
                      : Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: spotsLeft > 0 ? [
                      BoxShadow(
                        color: (isFree ? AppColors.secondary : AppColors.primary).withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ] : [],
                  ),
                  child: ElevatedButton(
                    onPressed: spotsLeft > 0 ? () => _join(c) : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.group_add_rounded, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          spotsLeft > 0
                              ? (isFree ? 'JOIN FREE' : 'JOIN CONTEST')
                              : 'CONTEST FULL',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _join(ContestModel contest) async {
    setState(() => _loading = true);
    final matchId = int.tryParse(contest.matchId) ?? 0;
    
    try {
      final teams = await TeamsService().getMyTeams(matchId);
      setState(() => _loading = false);

      if (!mounted) return;

      if (teams.isNotEmpty) {
        _showTeamSelector(contest, teams);
      } else {
        // Find the match data for this contest
        final matchData = widget.matches.firstWhere(
          (m) => m['match_id']?.toString() == contest.matchId || m['id']?.toString() == contest.matchId,
          orElse: () => {'match_id': contest.matchId},
        );
        _navigateToCreateTeam(contest, matchData);
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
      _navigateToCreateTeam(contest, {'match_id': contest.matchId});
    }
  }

  void _navigateToCreateTeam(ContestModel contest, Map<String, dynamic> matchData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            EsCreateTeamScreen(matchData: matchData, contest: contest),
      ),
    ).then((_) => _loadContests());
  }

  void _showTeamSelector(ContestModel contest, List<Map<String, dynamic>> teams) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Select Team to Join',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              contest.name,
              style: TextStyle(color: Colors.grey[500], fontSize: 13),
            ),
            const Divider(height: 32),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: teams.length,
                itemBuilder: (ctx, idx) {
                  final team = teams[idx];
                  final name = team['name'] ?? 'Team ${idx + 1}';
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: ListTile(
                      onTap: () async {
                        Navigator.pop(ctx);
                        _confirmJoin(contest, team);
                      },
                      title: Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '${(team['players'] as List? ?? []).length} Players',
                        style: TextStyle(fontSize: 12),
                      ),
                      trailing: const Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.grey,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            if (teams.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      // Find match data
                      final matchData = widget.matches.firstWhere(
                        (m) => m['match_id']?.toString() == contest.matchId || m['id']?.toString() == contest.matchId,
                        orElse: () => {'match_id': contest.matchId},
                      );
                      _navigateToCreateTeam(contest, matchData);
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Create New Team'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmJoin(
    ContestModel contest,
    Map<String, dynamic> team,
  ) async {
    final userId = await UserProfileService.getSavedUserId();
    if (userId <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to join contests')),
      );
      return;
    }

    try {
      final teamId = team['id']?.toString() ?? '0';
      final teamName = team['name']?.toString() ?? 'My Team';

      await ContestService().joinContest(
        contestId: contest.id,
        teamId: teamId,
        teamName: teamName,
        userId: userId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Joined contest successfully! 🏆'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _loadContests();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Join failed: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showContestDetails(BuildContext context, ContestModel c) {
    // Basic bottom sheet for details if needed
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 10),
            Text('Prize Pool: ${LocationService.formatAmount(c.prizePool, _location)}'),
            const SizedBox(height: 5),
            Text('Entry Fee: ${LocationService.formatAmount(c.entryFee, _location)}'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _join(c);
              },
              child: const Text('Join Now'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            )
          ],
        ),
      )
    );
  }
}
