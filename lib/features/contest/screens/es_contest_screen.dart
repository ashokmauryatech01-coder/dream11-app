import 'package:flutter/material.dart';
import 'package:fantasy_crick/core/constants/app_colors.dart';
import 'package:fantasy_crick/features/contest/screens/es_create_team_screen.dart';
import 'package:fantasy_crick/core/services/location_service.dart';
import 'package:fantasy_crick/core/services/teams_service.dart';
import 'package:fantasy_crick/core/services/contest_service.dart';
import 'package:fantasy_crick/models/contest_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  CONTEST SCREEN — white background, real contests from API
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

  int _mainTab = 0; // 0 = Contests, 1 = My Teams
  List<Map<String, dynamic>> _myTeams = [];
  bool _loadingTeams = false;

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

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadContests() async {
    if (_selectedMatch == null) return;
    setState(() {
      _loading = true;
      _loadingTeams = true;
    });
    final matchId = int.tryParse(_selectedMatch!['match_id']?.toString() ?? '0') ?? 0;
    try {
      final contestService = ContestService();
      // Fetch all contests across all matches as per user request
      final contests = await contestService.getAllContests();
      final teams = await TeamsService().getMyTeams(matchId);

      if (!mounted) return;

      setState(() {
        _contests = contests;
        _myTeams = teams;
        _loading = false;
        _loadingTeams = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _contests = []; // Mock contests are already returned by ContestService on error
        _loading = false;
        _loadingTeams = false;
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

          // Main Tabs (Contests | My Teams)
          Container(
            color: Colors.white,
            child: Row(
              children: [
                Expanded(child: _mainTabBtn('Contests', 0)),
                Expanded(
                  child: _mainTabBtn('My Teams (${_myTeams.length})', 1),
                ),
              ],
            ),
          ),

          if (_mainTab == 0) ...[
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
          ] else ...[
            Expanded(
              child: _loadingTeams
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    )
                  : _myTeamsList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _mainTabBtn(String label, int index) {
    bool sel = _mainTab == index;
    return GestureDetector(
      onTap: () => setState(() => _mainTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: sel ? AppColors.primary : Colors.transparent,
              width: 2.5,
            ),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: sel ? AppColors.primary : Colors.grey[500],
            fontWeight: sel ? FontWeight.bold : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  // ── MATCH SELECTOR ────────────────────────────────────────────────────────

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

  // ── MY TEAMS LIST ─────────────────────────────────────────────────────────
  Widget _myTeamsList() {
    if (_myTeams.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shield_outlined, size: 56, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text(
              'No teams created yet',
              style: TextStyle(color: Colors.grey[500], fontSize: 15),
            ),
            const SizedBox(height: 16),
            /* ElevatedButton.icon(
          onPressed: () {
            if (_selectedMatch != null) {
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => EsCreateTeamScreen(matchData: _selectedMatch!),
              )).then((_) => _loadContests());
            }
          },
          icon: const Icon(Icons.add), label: const Text('Create Team'),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, foregroundColor: Colors.white),
        ), */
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadContests,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 80),
        itemCount: _myTeams.length,
        itemBuilder: (_, i) => _teamCard(_myTeams[i]),
      ),
    );
  }

  Widget _teamCard(Map<String, dynamic> team) {
    final name = team['name']?.toString() ?? 'My Team';
    final pts = team['points']?.toString() ?? '0.0';
    final players = team['players'] as List<dynamic>? ?? [];

    // Find Cap and VC
    String capName = '-', vcName = '-';
    for (var p in players) {
      final pivot = p['pivot'] as Map<String, dynamic>? ?? {};
      if (pivot['is_captain'] == 1 || pivot['is_captain'] == true)
        capName = p['name'] ?? '-';
      if (pivot['is_vice_captain'] == 1 || pivot['is_vice_captain'] == true)
        vcName = p['name'] ?? '-';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${players.length} Players Selected',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$pts pts',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 1,
            color: Colors.grey.withOpacity(0.08),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 12,
                      backgroundColor: AppColors.primary,
                      child: Text(
                        'C',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'CAPTAIN',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            capName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: AppColors.text,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 12,
                      backgroundColor: AppColors.secondary,
                      child: Text(
                        'VC',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'VICE CAPTAIN',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            vcName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: AppColors.text,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
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
                        const SizedBox(height: 2),
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
                          color: spotsLeft < 5 ? Colors.red : Colors.grey[600],
                          fontSize: 11,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '$winners% winners',
                        style: const TextStyle(
                          color: Colors.green,
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

  void _join(ContestModel contest) {
    if (_selectedMatch == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EsCreateTeamScreen(matchData: _selectedMatch),
      ),
    );
  }

  void _showContestDetails(BuildContext ctx, ContestModel c) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Contest Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const Divider(height: 24),
            _detailRow(
              'Total Spots',
              c.maxTeams.toString(),
            ),
            _detailRow(
              'Spots Filled',
              c.currentTeams.toString(),
            ),
            _detailRow(
              'Entry Fee',
              LocationService.formatAmount(c.entryFee.toInt(), _location),
            ),
            _detailRow(
              'Prize Pool',
              LocationService.formatAmount(c.prizePool.toInt(), _location),
            ),
            _detailRow(
              'Winners',
              '${c.winnerPercentage}%',
            ),
            _detailRow(
              'Multiple Entries',
              (c.multipleTeams) ? 'Allowed' : 'Not Allowed',
            ),
            _detailRow(
              'Guaranteed',
              (c.isGuaranteed)
                  ? 'Yes'
                  : 'No',
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _join(c);
                },
                icon: const Icon(Icons.group_add_rounded),
                label: const Text(
                  'Join Contest',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[700], fontSize: 13)),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ],
    ),
  );
}
