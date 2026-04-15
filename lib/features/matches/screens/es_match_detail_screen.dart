import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fantasy_crick/core/constants/app_colors.dart';
import 'package:fantasy_crick/core/services/entity_sport_service.dart';
import 'package:fantasy_crick/core/services/contest_service.dart';
import 'package:fantasy_crick/models/contest_model.dart';
import 'package:fantasy_crick/features/contest/screens/es_create_team_screen.dart';
import 'package:fantasy_crick/core/services/teams_service.dart';
import 'package:fantasy_crick/core/services/user_profile_service.dart';
import 'package:cached_network_image/cached_network_image.dart';

class EsMatchDetailScreen extends StatefulWidget {
  final Map<String, dynamic> matchData;
  const EsMatchDetailScreen({super.key, required this.matchData});

  @override
  State<EsMatchDetailScreen> createState() => _EsMatchDetailScreenState();
}

class _EsMatchDetailScreenState extends State<EsMatchDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _scorecard;
  Map<String, dynamic>? _liveScore;
  Map<String, dynamic>? _squad;
  Map<String, dynamic>? _points;
  bool _loadingScorecard = false;
  bool _loadingSquad = false;
  bool _loadingPoints = false;
  // auto-refresh for live matches
  bool _autoRefresh = false;
  Timer? _pollingTimer;
  String? _lastBallId;
  int? _boundaryScore;
  bool _showingAnimation = false;

  List<ContestModel> _matchContests = [];
  bool _loadingContests = false;

  Future<void> _refreshAll() async {
    if (!mounted) return;
    setState(() {
      _loadingContests = true;
      _loadingScorecard = true;
      _loadingPoints = true;
    });

    await Future.wait([
      _loadContests(),
      _loadScorecard(),
      _loadPoints(),
    ]).catchError((e) => print('Error refreshing all: $e'));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Match data updated'), duration: Duration(seconds: 1)),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index == 0 &&
          _matchContests.isEmpty &&
          !_loadingContests)
        _loadContests();
      if (_tabController.index == 1 && _scorecard == null && !_loadingScorecard)
        _loadScorecard();
      if (_tabController.index == 2 && _scorecard == null && !_loadingScorecard)
        _loadScorecard();
    });

    _loadContests();

    final status = widget.matchData['status'] as int? ?? 0;
    if (status == 3) {
      _loadScorecard();
      _autoRefresh = true;
      _startPolling();
    }
  }

  Future<void> _loadContests() async {
    setState(() => _loadingContests = true);
    try {
      final contests = await ContestService().getContestsForMatch(
        _matchId.toString(),
      );
      if (mounted) {
        setState(() {
          // Frontend safety filter: ensure contest.matchId matches current _matchId
          _matchContests = contests
              .where((c) => c.matchId == _matchId.toString())
              .toList();
          _loadingContests = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingContests = false);
    }
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted && _isLive) {
        _loadScorecard(isPolling: true);
      }
    });
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _stopPolling();
    super.dispose();
  }

  int get _matchId {
    final rawId = widget.matchData['match_id'] ?? widget.matchData['id'];
    if (rawId == null) return 0;
    if (rawId is int) return rawId;
    return int.tryParse(rawId.toString()) ?? 0;
  }

  Future<void> _loadScorecard({bool isPolling = false}) async {
    if (_matchId == 0) return;
    if (!isPolling) setState(() => _loadingScorecard = true);
    try {
      final res = await Future.wait([
        EntitySportService.getScorecard(_matchId),
        if (_isLive || _isFinished) EntitySportService.getLiveScore(_matchId),
      ]);
      if (!mounted) return;

      final liveData = res.length > 1 ? res[1] as Map<String, dynamic>? : null;
      if (liveData != null && liveData.isNotEmpty) {
        final comms = liveData['commentaries'] as List<dynamic>? ?? [];
        if (comms.isNotEmpty) {
          final first = comms.first as Map<String, dynamic>?;
          if (first != null) {
            final ballId = "${first['over']}.${first['ball']}";
            final score = first['score'] as int? ?? 0;

            // Trigger animation if it's a new 4 or 6
            if (ballId != _lastBallId && (score == 4 || score == 6)) {
              _triggerBoundaryAnimation(score);
            }
            _lastBallId = ballId;
          }
        }
      }

      setState(() {
        _scorecard = res[0];
        if (liveData != null) _liveScore = liveData;
        _loadingScorecard = false;
      });
      print(
        'DEBUG: EsMatchDetailScreen - Scorecard loaded for match: $_matchId',
      );
      print('DEBUG: EsMatchDetailScreen - Match Data: ${widget.matchData}');
    } catch (_) {
      if (mounted) setState(() => _loadingScorecard = false);
    }
  }

  void _triggerBoundaryAnimation(int score) {
    if (_showingAnimation) return;
    setState(() {
      _boundaryScore = score;
      _showingAnimation = true;
    });
    // Hide after 3 seconds
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _showingAnimation = false;
        });
      }
    });
  }

  Future<void> _loadPoints() async {
    if (_matchId == 0) return;
    setState(() => _loadingPoints = true);
    final data = await EntitySportService.getMatchPoints(_matchId);
    if (!mounted) return;
    setState(() {
      _points = data;
      _loadingPoints = false;
    });
  }

  Future<void> _loadSquad() async {
    // Removed per user request
    return;
  }

  Future<void> _join(ContestModel contest) async {
    // Check login first
    final userId = await UserProfileService.getSavedUserId();
    if (userId <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to join contests')),
        );
      }
      return;
    }

    int matchId = int.tryParse(contest.matchId) ?? 0;
    if (matchId == 0) matchId = _matchId;
    
    print('DEBUG: EsMatchDetailScreen._join - JOIN clicked, matchId=$matchId');

    if (matchId <= 0) {
      _navigateToCreateTeam(contest, widget.matchData);
      return;
    }

    setState(() => _loadingContests = true);

    try {
      // Hit GET /api/v1/teams?match_id={{match_id}}&page=1&limit=10
      final teams = await TeamsService().getMyTeams(matchId);
      setState(() => _loadingContests = false);
      if (!mounted) return;
      
      print('DEBUG: EsMatchDetailScreen._join - Opening selector with ${teams.length} teams');
      _showTeamSelector(contest, teams);
    } catch (e) {
      print('DEBUG: EsMatchDetailScreen._join - ERROR: $e');
      if (mounted) setState(() => _loadingContests = false);
      // Fallback: show selector anyway, it will show "Create Team" option
      _showTeamSelector(contest, []);
    }
  }

  void _navigateToCreateTeam(
    ContestModel contest,
    Map<String, dynamic> matchData,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            EsCreateTeamScreen(matchData: matchData, contest: contest),
      ),
    ).then((_) => _loadContests());
  }

  void _showTeamSelector(
    ContestModel contest,
    List<Map<String, dynamic>> teams,
  ) {
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
               Text(
                'Choose a team to join this contest',
                style: TextStyle(color: Colors.grey[500], fontSize: 13),
              ),
              const Divider(height: 32, thickness: 1),

              if (teams.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.group_add_rounded, 
                          size: 40, 
                          color: Colors.grey.shade400
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No teams created for this match yet',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.bold,
                          fontSize: 15
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Create your first team to join the contest',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 12
                        ),
                      ),
                    ],
                  ),
                ),

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
                          color: isSelected
                              ? const Color(0xFF007A8A).withOpacity(0.05)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF007A8A)
                                : Colors.grey.shade200,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF007A8A)
                                    : Colors.blueGrey.shade50,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: isSelected ? [
                                  BoxShadow(
                                    color: const Color(0xFF007A8A).withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  )
                                ] : [],
                              ),
                              child: Icon(
                                Icons.shield_rounded,
                                color: isSelected
                                    ? Colors.white
                                    : Colors.blueGrey.shade200,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: isSelected
                                        ? const Color(0xFF007A8A)
                                        : const Color(0xFF1B2430),
                                  ),
                                ),
                              ],
                            ),),
                            if (isSelected)
                              const Icon(
                                Icons.check_circle,
                                color: Color(0xFF007A8A),
                              )
                            else
                              Icon(
                                Icons.circle_outlined,
                                color: Colors.grey.shade300,
                              ),
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
                    onPressed: teams.isEmpty
                        ? () {
                            Navigator.pop(ctx);
                            _navigateToCreateTeam(contest, widget.matchData);
                          }
                        : (selectedTeamIdx == null
                            ? null
                            : () {
                                Navigator.pop(ctx);
                                _confirmJoin(contest, teams[selectedTeamIdx!]);
                              }),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B2430),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                      disabledBackgroundColor: Colors.grey.shade200,
                    ),
                    child: Text(
                      teams.isEmpty ? 'CREATE FIRST TEAM 🚀' : 'JOIN CONTEST 🏆',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
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
                      _navigateToCreateTeam(contest, widget.matchData);
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: Colors.grey.shade200, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      teams.isEmpty ? 'BACK' : 'CREATE ANOTHER TEAM',
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
      if (mounted)
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
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Join failed: ${e.toString().replaceAll('Exception: ', '')}',
            ),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  Map<String, dynamic> get _teamA =>
      widget.matchData['teama'] as Map<String, dynamic>? ?? {};
  Map<String, dynamic> get _teamB =>
      widget.matchData['teamb'] as Map<String, dynamic>? ?? {};
  int get _status => widget.matchData['status'] as int? ?? 0;
  bool get _isLive => _status == 3;
  bool get _isFinished => _status == 2;
  bool get _isUpcoming => _status == 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          NestedScrollView(
            headerSliverBuilder: (_, __) => [
              SliverAppBar(
                expandedHeight: 240,
                pinned: true,
                backgroundColor: AppColors.primary,
                iconTheme: const IconThemeData(color: Colors.white),
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.matchData['short_title']?.toString() ??
                          'Match Detail',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (widget.matchData['competition']?['title'] != null)
                      Text(
                        widget.matchData['competition']['title'].toString(),
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
                actions: [
                  IconButton(
                    icon: const Icon(
                      Icons.refresh_rounded,
                      color: Colors.white,
                    ),
                    onPressed: _refreshAll,
                    tooltip: 'Refresh all data',
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: ClipRect(child: _buildHeroHeader()),
                ),
                bottom: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabAlignment: TabAlignment.center,
                  indicatorColor: Colors.white,
                  indicatorWeight: 2.5,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white54,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.normal,
                    fontSize: 11,
                  ),
                  tabs: const [
                    Tab(text: 'PLAY & WIN'),
                    Tab(text: 'Info'),
                    Tab(text: 'Scorecard'),
                  ],
                ),
              ),
            ],
            body: TabBarView(
              controller: _tabController,
              children: [_playWinTab(), _matchInfoTab(), _scorecardTab()],
            ),
          ),
          if (_showingAnimation) _buildBoundaryOverlay(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EsCreateTeamScreen(matchData: widget.matchData),
          ),
        ),
        backgroundColor: AppColors.secondary,
        label: const Text(
          'CREATE TEAM',
          style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white),
        ),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }

  Widget _buildBoundaryOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black45,
        child: Center(
          child: _BoundaryTextAnimation(score: _boundaryScore ?? 4),
        ),
      ),
    );
  }

  Widget _playWinTab() {
    if (_loadingContests)
      return const Center(
        child: CircularProgressIndicator(color: AppColors.secondary),
      );

    if (_matchContests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.emoji_events_outlined,
              size: 64,
              color: Colors.amber,
            ),
            const SizedBox(height: 16),
            const Text(
              'No Contests Available Yet',
              style: TextStyle(color: AppColors.textLight),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      EsCreateTeamScreen(matchData: widget.matchData),
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: Colors.white,
              ),
              child: const Text('CREATE YOUR TEAM NOW'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      itemCount: _matchContests.length,
      itemBuilder: (context, index) => _ContestCardWidget(
        contest: _matchContests[index],
        matchData: widget.matchData,
        onTap: () => _join(_matchContests[index]),
      ),
    );
  }

  Widget _matchInfoTab() {
    final comp = widget.matchData['competition'] as Map<String, dynamic>? ?? {};
    final venue = widget.matchData['venue'] as Map<String, dynamic>? ?? {};
    final note = widget.matchData['status_note']?.toString() ?? '';
    final title = comp['title']?.toString() ?? 'Tournament Info';
    final subtitle = widget.matchData['subtitle']?.toString() ?? '';
    final istRaw = widget.matchData['date_start_ist']?.toString() ?? '';
    String time = '07:30 PM';
    String dateStr = 'Today';

    if (istRaw.isNotEmpty) {
      try {
        final dt = DateTime.parse(istRaw.replaceFirst(' ', 'T'));
        dateStr =
            '${_getDayName(dt.weekday)}, ${dt.day}/${dt.month}/${dt.year}';
        final hour = dt.hour > 12
            ? dt.hour - 12
            : (dt.hour == 0 ? 12 : dt.hour);
        final min = dt.minute.toString().padLeft(2, '0');
        final amPm = dt.hour >= 12 ? 'PM' : 'AM';
        time = '$hour:$min $amPm, IST';
      } catch (e) {
        dateStr = istRaw.split(' ').first;
        time = istRaw.split(' ').last;
      }
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (note.isNotEmpty) _infoNote(note),

          // Tournament Info Card with Illustration
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$subtitle • ${widget.matchData['format_str'] ?? 'T20'}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                      const SizedBox(height: 16),
                      _miniInfo('Date', dateStr),
                      const SizedBox(height: 12),
                      _miniInfo('Time', time),
                      const SizedBox(height: 12),
                      _miniInfo(
                        'Toss',
                        widget.matchData['toss']?['text']?.toString() ??
                            'Yet to happen',
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 100,
                  height: 100,
                  child: Image.asset(
                    'assets/images/cricket_info_art.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.sports_cricket,
                      size: 64,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ),

          _divider(),

          // Links Row Removed per user request
          const SizedBox(height: 12),

          Container(height: 8, color: Colors.grey[50]),

          // Venue Details
          _sectionTitle('Venue & Conditions'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade100),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.stadium_outlined,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Stadium',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              venue['name']?.toString() ?? 'TBD Stadium',
                              style: const TextStyle(
                                color: Color(0xFF1B2430),
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Divider(height: 1),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Icon(
                              Icons.grass,
                              size: 18,
                              color: Colors.green[400],
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Pitch',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 10,
                                  ),
                                ),
                                Text(
                                  widget.matchData['pitch_condition'] ??
                                      'Batting',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(width: 1, height: 30, color: Colors.grey[200]),
                      Expanded(
                        child: Row(
                          children: [
                            const SizedBox(width: 16),
                            Icon(
                              Icons.bolt,
                              size: 18,
                              color: Colors.amber[600],
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Supports',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 10,
                                  ),
                                ),
                                Text(
                                  widget.matchData['supports'] ?? 'Pacers',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildIplTabContent() {
    // Method moved or deleted in last edit
    return const SizedBox();
  }

  Widget _miniInfo(String label, String val) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
      Text(
        val,
        style: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
      ),
    ],
  );

  Widget _miniLogo(dynamic url, String short) {
    final String logoUrl = url?.toString() ?? '';
    print('DEBUG: EsMatchDetailScreen - miniLogo URL for $short: $logoUrl');
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey[100],
      ),
      child: logoUrl.isNotEmpty
          ? ClipOval(
              child: CachedNetworkImage(
                imageUrl: logoUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Center(
                  child: Text(
                    short.isNotEmpty ? short[0].toUpperCase() : '?',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Center(
                  child: Text(
                    short.isNotEmpty ? short[0].toUpperCase() : '?',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
            )
          : Center(
              child: Text(
                short.isNotEmpty ? short[0].toUpperCase() : '?',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
    );
  }

  Widget _winIndicator(String label, String pct, Color bg, Color clr) => Column(
    children: [
      Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 50,
            height: 50,
            child: CircularProgressIndicator(
              value: double.parse(pct.replaceAll('%', '')) / 100,
              strokeWidth: 4,
              backgroundColor: bg,
              valueColor: AlwaysStoppedAnimation<Color>(clr),
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
      Text(
        pct,
        style: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
    ],
  );

  Widget _sectionTitle(String t) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
    child: Text(
      t,
      style: const TextStyle(
        color: Colors.black,
        fontWeight: FontWeight.bold,
        fontSize: 16,
      ),
    ),
  );
  Widget _divider() => Divider(height: 1, color: Colors.grey[200]);
  Widget _squadPlaceholder(String name) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
    child: Text(
      name,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        color: Colors.black54,
      ),
    ),
  );

  Widget _infoNote(String text) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.amber.withOpacity(0.15),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: Colors.amber.withOpacity(0.4)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.info, color: Colors.amber, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Colors.amber, fontSize: 12),
          ),
        ),
      ],
    ),
  );

  Widget _infoCard(String title, List<Widget> items) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.grey.withOpacity(0.1)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
          child: Text(
            title,
            style: const TextStyle(
              color: AppColors.text,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        Divider(height: 1, color: Colors.white.withOpacity(0.08)),
        ...items,
      ],
    ),
  );

  Widget _pointsTab() {
    if (_loadingPoints)
      return const Center(
        child: CircularProgressIndicator(color: AppColors.secondary),
      );
    if (_points == null || _points!['players'] == null)
      return _buildEmpty('Points data not available yet');

    final players = ((_points!['players'] as List? ?? []))
        .cast<Map<String, dynamic>>();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: players.length,
      itemBuilder: (ctx, i) {
        final p = players[i];
        final name = p['name'] ?? 'Player';
        final points = p['point']?.toString() ?? '0';
        final role = p['role'] ?? '';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primary.withOpacity(0.1),
                child: Text(
                  name[0],
                  style: const TextStyle(color: AppColors.primary),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      role.toUpperCase(),
                      style: const TextStyle(color: Colors.grey, fontSize: 10),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    points,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: Color(0xFF007A8A),
                    ),
                  ),
                  const Text(
                    'POINTS',
                    style: TextStyle(color: Colors.grey, fontSize: 9),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmpty(String msg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.info_outline, size: 48, color: Colors.grey),
          const SizedBox(height: 16),
          Text(msg, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String val) {
    if (val.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: AppColors.primary),
          const SizedBox(width: 10),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textLight, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              val,
              style: const TextStyle(
                color: AppColors.text,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── SCORECARD TAB ─────────────────────────────────────────────────────────
  Widget _scorecardTab() {
    if (_isUpcoming) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.timer_outlined,
              size: 64,
              color: Colors.grey.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'Match Not Started Yet',
              style: TextStyle(
                color: AppColors.text,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'The scorecard will be available once the match begins.',
              style: TextStyle(color: AppColors.textLight, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_loadingScorecard)
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    if (_scorecard == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.sports_cricket, size: 60, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Scorecard',
              style: TextStyle(
                color: AppColors.text,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Load the live scorecard',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadScorecard,
              icon: const Icon(Icons.download_rounded),
              label: const Text('Load Scorecard'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    final inningsRaw = _scorecard?['innings'];
    final List<dynamic> innings = (inningsRaw is List) ? inningsRaw : [];
    final hasLive = _liveScore != null && _liveScore!.isNotEmpty;

    if (innings.isEmpty && !hasLive) {
      return const Center(
        child: Text(
          'No scorecard data yet',
          style: TextStyle(color: AppColors.textLight),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadScorecard,
      color: AppColors.primary,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
        child: Column(
          children: [
            // Live indicators
            if (_isLive) _liveIndicator(),
            if (_liveScore != null && _liveScore!.isNotEmpty)
              _liveScoreBlock(_liveScore!),
            ...innings.map(
              (inn) => _inningsBlock(inn is Map<String, dynamic> ? inn : {}),
            ),
          ],
        ),
      ),
    );
  }

  Widget _liveScoreBlock(Map<String, dynamic> data) {
    final live = data['live_score'] as Map<String, dynamic>? ?? {};
    final batsmen = data['batsmen'] as List<dynamic>? ?? [];
    final bowlers = data['bowlers'] as List<dynamic>? ?? [];
    final comms = data['commentaries'] as List<dynamic>? ?? [];

    final statusNote = data['status_note']?.toString() ?? '';
    final teamBat = data['team_batting']?.toString() ?? 'Batting';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF243052),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Live Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  (data['status'] == 3
                      ? const Color(0xFF4CAF50)
                      : AppColors.primary),
                  AppColors.secondary.withOpacity(0.8),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        teamBat,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    Text(
                      '${live['runs'] ?? '0'}/${live['wickets'] ?? '0'}  (${live['overs'] ?? '0'} Ov)',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'CRR: ${live['runrate'] ?? '0.00'}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (live['required_runrate'] != null) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'RRR: ${live['required_runrate']}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ],
                ),
                if (statusNote.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    statusNote,
                    style: const TextStyle(
                      color: Colors.amber,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Batsmen Live
          if (batsmen.isNotEmpty) ...[
            _sectionHeader('BATTER'),
            ...batsmen.map((b) => _battingRowLive(b as Map<String, dynamic>)),
          ],

          // Bowlers Live
          if (bowlers.isNotEmpty) ...[
            _sectionHeader('BOWLER'),
            ...bowlers.map((b) => _bowlingRowLive(b as Map<String, dynamic>)),
          ],

          // Recent Commentary
          if (comms.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              color: const Color(0xFF1B2033),
              child: const Text(
                'RECENT BALLS',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
            ...comms
                .take(6)
                .map((c) => _commentaryCard(c as Map<String, dynamic>)),
          ],
        ],
      ),
    );
  }

  Widget _battingRowLive(Map<String, dynamic> b) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              b['name']?.toString() ?? '',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          _scoreCell(b['runs']?.toString() ?? '0', Colors.white, bold: true),
          _scoreCell(b['balls_faced']?.toString() ?? '0', Colors.white60),
          _scoreCell(b['fours']?.toString() ?? '0', Colors.white60),
          _scoreCell(b['sixes']?.toString() ?? '0', Colors.white60),
          SizedBox(
            width: 45,
            child: Text(
              b['strike_rate']?.toString() ?? '-',
              style: const TextStyle(color: Colors.white, fontSize: 12),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _bowlingRowLive(Map<String, dynamic> b) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              b['name']?.toString() ?? '',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          _scoreCell(b['overs']?.toString() ?? '0', Colors.white),
          _scoreCell(b['maidens']?.toString() ?? '0', Colors.white60),
          _scoreCell(b['runs_conceded']?.toString() ?? '0', Colors.white),
          _scoreCell(
            b['wickets']?.toString() ?? '0',
            AppColors.primary,
            bold: true,
          ),
          SizedBox(
            width: 45,
            child: Text(
              b['econ']?.toString() ?? '-',
              style: const TextStyle(color: Colors.white, fontSize: 12),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _commentaryCard(Map<String, dynamic> c) {
    if (c['event'] == 'overend') {
      return Container(
        padding: const EdgeInsets.all(12),
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFF007A8A).withOpacity(0.1),
          border: Border(
            bottom: BorderSide(color: Colors.white.withOpacity(0.05)),
          ),
        ),
        child: Text(
          c['commentary']?.toString() ?? 'Over End',
          style: const TextStyle(
            color: Color(0xFF007A8A),
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      );
    }

    final isWicket = c['event'] == 'wicket';
    final isBoundary = c['score'] == 4 || c['score'] == 6;
    Color ballColor = Colors.grey.shade800;
    Color textColor = Colors.white;

    if (isWicket) {
      ballColor = const Color(0xFF1B2430); // Navy for wicket
    } else if (c['score'] == 6) {
      ballColor = const Color(0xFF4CAF50); // Green for 6
    } else if (c['score'] == 4) {
      ballColor = const Color(0xFF007A8A); // Teal for 4
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 30,
                child: Text(
                  '${c['over']}.${c['ball']}',
                  style: const TextStyle(color: Colors.white60, fontSize: 11),
                ),
              ),
              Container(
                width: 24,
                height: 24,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: ballColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    isWicket ? 'W' : c['score']?.toString() ?? '0',
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: Text(
              c['commentary']?.toString() ?? '',
              style: TextStyle(
                color: Colors.grey.shade300,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _liveIndicator() => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    decoration: BoxDecoration(
      color: const Color(0xFF4CAF50).withOpacity(0.15),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.4)),
    ),
    child: Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: Color(0xFF4CAF50),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        const Text(
          'LIVE • Pull down to refresh',
          style: TextStyle(
            color: Color(0xFF4CAF50),
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: _loadScorecard,
          child: const Icon(
            Icons.refresh_rounded,
            color: Color(0xFF007A8A),
            size: 18,
          ),
        ),
      ],
    ),
  );

  Widget _inningsBlock(Map<String, dynamic> inn) {
    final name = inn['name']?.toString() ?? '';
    final scores = inn['scores']?.toString() ?? '';
    final overs = inn['overs']?.toString() ?? '';
    final batters = inn['batting'] as List<dynamic>? ?? [];
    final bowlers = inn['bowling'] as List<dynamic>? ?? [];
    final extras = inn['extras'] as Map<String, dynamic>? ?? {};

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF243052),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          // Innings header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: AppColors.primaryGradient),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    '$scores${overs.isNotEmpty ? "  ($overs Ov)" : ""}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          // Batting
          if (batters.isNotEmpty) ...[
            _sectionHeader('BATTING'),
            _battingHeader(),
            ...batters.map(
              (b) => _battingRow(b is Map<String, dynamic> ? b : {}),
            ),
            if (extras.isNotEmpty) _extrasRow(extras),
          ],
          if (bowlers.isNotEmpty) ...[
            _sectionHeader('BOWLING'),
            _bowlingHeader(),
            ...bowlers.map(
              (b) => _bowlingRow(b is Map<String, dynamic> ? b : {}),
            ),
          ],
        ],
      ),
    );
  }

  Widget _sectionHeader(String t) => Container(
    color: const Color(0xFF1B2033),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
    width: double.infinity,
    child: Text(
      t,
      style: const TextStyle(
        color: Colors.white38,
        fontSize: 10,
        fontWeight: FontWeight.bold,
        letterSpacing: 1,
      ),
    ),
  );

  Widget _battingHeader() => Container(
    color: const Color(0xFF1F2845),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
    child: const Row(
      children: [
        Expanded(
          child: Text(
            'BATTER',
            style: TextStyle(color: Colors.white38, fontSize: 10),
          ),
        ),
        SizedBox(
          width: 34,
          child: Text(
            'R',
            style: TextStyle(color: Colors.white38, fontSize: 10),
            textAlign: TextAlign.center,
          ),
        ),
        SizedBox(
          width: 34,
          child: Text(
            'B',
            style: TextStyle(color: Colors.white38, fontSize: 10),
            textAlign: TextAlign.center,
          ),
        ),
        SizedBox(
          width: 30,
          child: Text(
            '4s',
            style: TextStyle(color: Colors.white38, fontSize: 10),
            textAlign: TextAlign.center,
          ),
        ),
        SizedBox(
          width: 30,
          child: Text(
            '6s',
            style: TextStyle(color: Colors.white38, fontSize: 10),
            textAlign: TextAlign.center,
          ),
        ),
        SizedBox(
          width: 40,
          child: Text(
            'SR',
            style: TextStyle(color: Colors.white38, fontSize: 10),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    ),
  );

  Widget _battingRow(Map<String, dynamic> b) {
    final name = b['name']?.toString() ?? b['title']?.toString() ?? '';
    final how = b['how_out']?.toString() ?? '';
    final notOut = how.isEmpty || how == 'not out' || how == 'playing';
    final runs = b['runs']?.toString() ?? '0';
    final balls = b['balls_played']?.toString() ?? '0';
    final fours = b['fours']?.toString() ?? '0';
    final sixes = b['sixes']?.toString() ?? '0';
    final sr = b['strike_rate']?.toString() ?? '-';
    final srVal = double.tryParse(sr.replaceAll(',', '.')) ?? 0;

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
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
                        style: TextStyle(
                          color: notOut ? Colors.white : Colors.white70,
                          fontWeight: notOut
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (notOut)
                      Container(
                        margin: const EdgeInsets.only(left: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: const Text(
                          '*',
                          style: TextStyle(
                            color: AppColors.success,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                if (how.isNotEmpty && how != 'not out' && how != 'playing')
                  Text(
                    how,
                    style: const TextStyle(color: Colors.white24, fontSize: 10),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          _scoreCell(runs, notOut ? Colors.white : Colors.white60, bold: true),
          _scoreCell(balls, Colors.white38),
          _scoreCell(fours, Colors.white60),
          _scoreCell(sixes, Colors.white60),
          SizedBox(
            width: 40,
            child: Text(
              sr,
              style: TextStyle(
                color: srVal >= 150
                    ? const Color(0xFF4CAF50)
                    : srVal >= 100
                    ? Colors.white60
                    : Colors.orangeAccent,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _scoreCell(String val, Color color, {bool bold = false}) => SizedBox(
    width: val.length > 2 ? 38 : 34,
    child: Text(
      val,
      style: TextStyle(
        color: color,
        fontSize: 12,
        fontWeight: bold ? FontWeight.bold : FontWeight.normal,
      ),
      textAlign: TextAlign.center,
    ),
  );

  Widget _extrasRow(Map<String, dynamic> extras) {
    final total = extras['total']?.toString() ?? '';
    final detail = [
      if ((extras['b'] ?? 0) != 0) 'b ${extras['b']}',
      if ((extras['lb'] ?? 0) != 0) 'lb ${extras['lb']}',
      if ((extras['wd'] ?? 0) != 0) 'wd ${extras['wd']}',
      if ((extras['nb'] ?? 0) != 0) 'nb ${extras['nb']}',
    ].join(', ');
    return Container(
      color: const Color(0xFF1F2845),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Extras${detail.isNotEmpty ? " ($detail)" : ""}',
              style: const TextStyle(color: Colors.white54, fontSize: 11),
            ),
          ),
          Text(
            total,
            style: const TextStyle(
              color: Colors.white54,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _bowlingHeader() => Container(
    color: const Color(0xFF1F2845),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
    child: const Row(
      children: [
        Expanded(
          child: Text(
            'BOWLER',
            style: TextStyle(color: Colors.white38, fontSize: 10),
          ),
        ),
        SizedBox(
          width: 32,
          child: Text(
            'O',
            style: TextStyle(color: Colors.white38, fontSize: 10),
            textAlign: TextAlign.center,
          ),
        ),
        SizedBox(
          width: 32,
          child: Text(
            'M',
            style: TextStyle(color: Colors.white38, fontSize: 10),
            textAlign: TextAlign.center,
          ),
        ),
        SizedBox(
          width: 32,
          child: Text(
            'R',
            style: TextStyle(color: Colors.white38, fontSize: 10),
            textAlign: TextAlign.center,
          ),
        ),
        SizedBox(
          width: 32,
          child: Text(
            'W',
            style: TextStyle(color: Colors.white38, fontSize: 10),
            textAlign: TextAlign.center,
          ),
        ),
        SizedBox(
          width: 40,
          child: Text(
            'Eco',
            style: TextStyle(color: Colors.white38, fontSize: 10),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    ),
  );

  Widget _bowlingRow(Map<String, dynamic> b) {
    final name = b['name']?.toString() ?? b['title']?.toString() ?? '';
    final overs = b['overs']?.toString() ?? '0';
    final maiden = b['maidens']?.toString() ?? '0';
    final runs = b['runs_conceded']?.toString() ?? b['runs']?.toString() ?? '0';
    final wkts = b['wickets']?.toString() ?? '0';
    final econ = b['econ']?.toString() ?? '-';
    final econVal = double.tryParse(econ.replaceAll(',', '.')) ?? 10.0;
    final hasWkt = (int.tryParse(wkts) ?? 0) > 0;

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      child: Row(
        children: [
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                color: hasWkt ? Colors.white : Colors.white70,
                fontWeight: hasWkt ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          _scoreCell(overs, Colors.white54),
          _scoreCell(maiden, Colors.white54),
          _scoreCell(runs, Colors.white60),
          _scoreCell(
            wkts,
            hasWkt ? AppColors.success : Colors.white54,
            bold: hasWkt,
          ),
          SizedBox(
            width: 40,
            child: Text(
              econ,
              style: TextStyle(
                color: econVal <= 6
                    ? const Color(0xFF4CAF50)
                    : econVal <= 9
                    ? Colors.white60
                    : Colors.orangeAccent,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroHeader() {
    var timeStr = (widget.matchData['date_start'] ?? '').toString();
    String countdown = widget.matchData['status_str'] ?? 'Starts Soon';
    if (timeStr.isNotEmpty) {
      try {
        final dt = DateTime.parse(timeStr);
        final now = DateTime.now();
        final diff = dt.difference(now);

        if (_isLive) {
          countdown = 'LIVE';
        } else if (_isFinished) {
          countdown = 'COMPLETED';
        } else if (diff.isNegative) {
          // It's passed time but not live yet
          countdown = 'Starts Soon';
        } else if (diff.inHours > 24) {
          countdown = '${diff.inDays}d ${diff.inHours % 24}h';
        } else {
          countdown = '${diff.inHours}h ${diff.inMinutes % 60}m';
        }
      } catch (_) {}
    }

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1B2430), Color(0xFF243555)],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.1,
              child: Image.asset(
                'assets/images/cricket_login_bg.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 100, 16, 12),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _teamDetailBlock(_teamA, false),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Text(
                            _isLive ? 'LIVE' : 'STARTS IN',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          countdown,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _teamDetailBlock(_teamB, true),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                    ),
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Text(
                    'MEGA CONTEST',
                    style: TextStyle(
                      color: Color(0xFF1B2430),
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _teamDetailBlock(Map<String, dynamic> team, bool alignRight) {
    final logo = team['logo_url']?.toString() ?? '';
    final short = team['short_name']?.toString() ?? '';
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56,
          height: 56,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white24, width: 2),
          ),
          child: logo.isNotEmpty
              ? ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: logo,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Center(
                      child: Text(
                        short.isNotEmpty ? short[0] : '?',
                        style: const TextStyle(
                          color: Colors.black54,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Center(
                      child: Text(
                        short.isNotEmpty ? short[0] : '?',
                        style: const TextStyle(
                          color: Colors.black54,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                )
              : Center(
                  child: Text(
                    short.isNotEmpty ? short[0] : '?',
                    style: const TextStyle(
                      color: Colors.black54,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
        ),
        const SizedBox(height: 8),
        Text(
          short,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  String _getDayName(int day) {
    switch (day) {
      case 1:
        return 'Monday';
      case 2:
        return 'Tuesday';
      case 3:
        return 'Wednesday';
      case 4:
        return 'Thursday';
      case 5:
        return 'Friday';
      case 6:
        return 'Saturday';
      case 7:
        return 'Sunday';
      default:
        return '';
    }
  }
}

class _ContestCardWidget extends StatelessWidget {
  final ContestModel contest;
  final Map<String, dynamic> matchData;
  final VoidCallback onTap;
  const _ContestCardWidget({
    required this.contest,
    required this.matchData,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final spotsLeft = contest.maxTeams - contest.currentTeams;
    final progress = (contest.maxTeams > 0)
        ? (contest.currentTeams.toDouble() / contest.maxTeams.toDouble())
        : 0.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF243052),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    contest.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '₹${contest.prizePool}',
                  style: const TextStyle(
                    color: Colors.amber,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$spotsLeft spots left',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                Text(
                  '${contest.maxTeams} spots',
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress.toDouble(),
                backgroundColor: Colors.white12,
                color: AppColors.secondary,
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'ENTRY ₹${contest.entryFee}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: onTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'JOIN',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BoundaryTextAnimation extends StatelessWidget {
  final int score;
  const _BoundaryTextAnimation({required this.score});

  @override
  Widget build(BuildContext context) {
    final String text = score == 6 ? "SIX!" : "FOUR!";
    final List<Color> colors = score == 6
        ? [Colors.greenAccent, Colors.green.shade800]
        : [Colors.lightBlueAccent, Colors.blue.shade800];

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value * 1.5,
          child: Opacity(opacity: value.clamp(0.0, 1.0), child: child),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: colors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: colors[0].withOpacity(0.5),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 60,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                letterSpacing: 4,
                shadows: [
                  Shadow(
                    color: Colors.black45,
                    offset: Offset(4, 4),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          _BlinkingText(text: "SPECTACULAR HIT!", color: colors[0]),
        ],
      ),
    );
  }
}

class _BlinkingText extends StatefulWidget {
  final String text;
  final Color color;
  const _BlinkingText({required this.text, required this.color});

  @override
  State<_BlinkingText> createState() => _BlinkingTextState();
}

class _BlinkingTextState extends State<_BlinkingText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.2, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Text(
        widget.text,
        style: TextStyle(
          color: widget.color,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
        ),
      ),
    );
  }
}
