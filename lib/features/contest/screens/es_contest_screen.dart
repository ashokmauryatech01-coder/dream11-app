import 'package:flutter/material.dart';
import 'package:fantasy_crick/core/constants/app_colors.dart';
import 'package:fantasy_crick/features/contest/screens/es_create_team_screen.dart';
import 'package:fantasy_crick/core/services/location_service.dart';
import 'package:fantasy_crick/core/services/teams_service.dart';
import 'package:fantasy_crick/core/services/contest_service.dart';
import 'package:fantasy_crick/core/services/user_profile_service.dart';
import 'package:fantasy_crick/models/contest_model.dart';
import 'package:fantasy_crick/features/contest/widgets/contest_card.dart';

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
    final midStr = matchId.toString();
    try {
      final contestService = ContestService();
      final contests = await contestService.getContestsForMatch(midStr);

      if (!mounted) return;

      setState(() {
        _contests = contests.where((c) => c.matchId == midStr).toList();
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
            ContestCard(
              contest: _contests[i],
              onTap: () => _join(_contests[i]),
            ),
      ),
    );
  }

  Future<void> _join(ContestModel contest) async {
    final matchId = int.tryParse(contest.matchId) ?? 0;
    print('DEBUG: EsContestScreen._join - JOIN clicked, contest=${contest.name}, matchId=$matchId');

    if (matchId <= 0) {
      _navigateToCreateTeam(contest, {'match_id': contest.matchId});
      return;
    }

    setState(() => _loading = true);
    
    try {
      // Hit GET /api/v1/teams?match_id={{match_id}}&page=1&limit=10
      final teams = await TeamsService().getMyTeams(matchId);
      setState(() => _loading = false);
      if (!mounted) return;

      print('DEBUG: EsContestScreen._join - Got ${teams.length} teams');

      if (teams.isNotEmpty) {
        _showTeamSelector(contest, teams);
      } else {
        Map<String, dynamic>? matchData;
        try {
          matchData = widget.matches.firstWhere(
            (m) => m['match_id']?.toString() == contest.matchId || m['id']?.toString() == contest.matchId,
          );
        } catch (_) {
          matchData = {'match_id': contest.matchId};
        }
        _navigateToCreateTeam(contest, matchData);
      }
    } catch (e) {
      print('DEBUG: EsContestScreen._join - ERROR: $e');
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
    int? selectedTeamIdx;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          padding: const EdgeInsets.only(top: 12, bottom: 24),
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
              const SizedBox(height: 24),
              const Text(
                'Select Your Team',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  color: Color(0xFF1B2430),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Choose a team to join this contest',
                style: TextStyle(color: Colors.grey[500], fontSize: 13),
              ),
              const Divider(height: 32, thickness: 1),
              
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: teams.length,
                  itemBuilder: (ctx, idx) {
                    final team = teams[idx];
                    final name = team['name']?.toString() ?? 'Team ${idx + 1}';
                    final isSelected = selectedTeamIdx == idx;
                    
                    return GestureDetector(
                      onTap: () => setSheetState(() => selectedTeamIdx = idx),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF007A8A).withOpacity(0.05) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? const Color(0xFF007A8A) : Colors.grey.shade200,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFF007A8A) : Colors.grey.shade100,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.group_rounded,
                                color: isSelected ? Colors.white : Colors.grey.shade400,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: isSelected ? const Color(0xFF007A8A) : const Color(0xFF1B2430),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${(team['players'] as List? ?? []).length} Players Selected',
                                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              const Icon(Icons.check_circle, color: Color(0xFF007A8A))
                            else
                              Icon(Icons.circle_outlined, color: Colors.grey.shade300),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: selectedTeamIdx == null 
                      ? null 
                      : () {
                          Navigator.pop(ctx);
                          _confirmJoin(contest, teams[selectedTeamIdx!]);
                        },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B2430),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                      disabledBackgroundColor: Colors.grey.shade200,
                    ),
                    child: const Text(
                      'JOIN CONTEST 🏆',
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Map<String, dynamic>? matchData;
                      try {
                        matchData = widget.matches.firstWhere(
                          (m) => m['match_id']?.toString() == contest.matchId || m['id']?.toString() == contest.matchId,
                        );
                      } catch (_) {
                        matchData = {'match_id': contest.matchId};
                      }
                      _navigateToCreateTeam(contest, matchData);
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: Colors.grey.shade200, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(
                      'CREATE ANOTHER TEAM',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
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
}
