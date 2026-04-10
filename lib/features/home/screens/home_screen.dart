import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fantasy_crick/common/widgets/cricket_animation.dart';
import 'package:fantasy_crick/core/constants/app_colors.dart';
import 'package:fantasy_crick/core/services/entity_sport_service.dart';
import 'package:fantasy_crick/features/matches/screens/es_match_detail_screen.dart';
import 'package:fantasy_crick/core/services/match_service.dart';
import 'package:fantasy_crick/core/services/contest_service.dart';
import 'package:fantasy_crick/models/contest_model.dart';
import 'package:fantasy_crick/features/home/screens/es_series_screen.dart';
import 'package:fantasy_crick/features/profile/screens/es_profile_screen.dart';
import 'package:fantasy_crick/features/contest/screens/es_create_team_screen.dart';
import 'package:fantasy_crick/core/services/teams_service.dart';
import 'package:fantasy_crick/core/services/user_profile_service.dart';
import 'package:cached_network_image/cached_network_image.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0;

  // ── data ──────────────────────────────────────────────────────
  bool _loading = true;
  String? _error;

  List<Map<String, dynamic>> _liveMatches = [];
  List<Map<String, dynamic>> _upcomingMatches = [];
  List<Map<String, dynamic>> _finishedMatches = [];
  List<Map<String, dynamic>> _liveSeries = [];
  List<ContestModel> _featuredContests = [];

  late TabController _matchesTabController; // PLAY & WIN, All Matches, Series
  late TabController _subMatchesTabController; // Upcoming, Live, Completed
  final PageController _carouselCtrl = PageController(viewportFraction: 0.88);
  int _carouselPage = 0;
  Timer? _carouselTimer;

  @override
  void initState() {
    super.initState();
    _matchesTabController = TabController(length: 3, vsync: this);
    _matchesTabController.addListener(
      () => setState(() {}),
    ); // Rebuild to change sub-tabs
    _subMatchesTabController = TabController(length: 3, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _matchesTabController.dispose();
    _subMatchesTabController.dispose();
    _carouselTimer?.cancel();
    _carouselCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    final bool hasData =
        _liveMatches.isNotEmpty ||
        _upcomingMatches.isNotEmpty ||
        _liveSeries.isNotEmpty;
    setState(() {
      _loading = !hasData;
      _error = null;
    });
    try {
      final matchesTask = MatchService.getMatches('all');
      final seriesTask = EntitySportService.getLiveSeries();
      final contestsTask = ContestService().getFeaturedContests();

      final results = await Future.wait([
        matchesTask,
        seriesTask,
        contestsTask,
      ]);

      final allMatches = results[0] as List<Map<String, dynamic>>;
      final liveSeries = results[1] as List<Map<String, dynamic>>;
      final featuredContests = results[2] as List<ContestModel>;

      if (!mounted) return;

      setState(() {
        _liveMatches = allMatches.where((m) => m['status']?.toString() == '3').toList();
        _upcomingMatches = allMatches.where((m) => m['status']?.toString() == '1').toList();
        _finishedMatches = allMatches.where((m) => m['status']?.toString() == '2').toList();
        _liveSeries = liveSeries;
        _featuredContests = featuredContests;
        _loading = false;
        print('DEBUG: HomeScreen loaded ${_upcomingMatches.length} upcoming matches and ${_featuredContests.length} contests');
      });
      _startCarouselTimer();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Failed to load data.';
      });
    }
  }

  // ── carousel auto-slide ──────────────────────────────────────
  void _startCarouselTimer() {
    _carouselTimer?.cancel();
    final total = (_liveMatches.length + _upcomingMatches.length).clamp(0, 10);
    if (total <= 1) return;
    _carouselTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      final next = (_carouselPage + 1) % total;
      _carouselCtrl.animateToPage(next,
          duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
    });
  }

  // ── navigation ────────────────────────────────────────────────
  static const List<_NavItem> _navItems = [
    _NavItem(Icons.home_outlined, 'Home'),
    _NavItem(Icons.sports_cricket_outlined, 'Matches'),
    _NavItem(Icons.person_outline, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _selectedIndex == 4 ? null : _buildAppBar(),
      body: _loading
          ? const Center(
              child: CricketAnimation(
                type: AnimationType.cricketBall,
                size: 60,
                color: AppColors.primary,
              ),
            )
          : _error != null && _liveMatches.isEmpty && _upcomingMatches.isEmpty
          ? _buildError()
          : _buildCurrentTab(),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF1B2430),
      elevation: 0,
      centerTitle: true,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white54, width: 1),
            ),
            child: CircleAvatar(
              radius: 12,
              backgroundColor: Colors.transparent,
              child: Image.asset(
                'assets/images/segga_logo.png',
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.sports_cricket,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'SEGGA SPORTZ',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 18,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: 75,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_navItems.length, (index) {
              final item = _navItems[index];
              final isSelected = _selectedIndex == index;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedIndex = index),
                  child: Container(
                    color: Colors.transparent,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          item.icon,
                          color: isSelected
                              ? const Color(0xFF007A8A)
                              : AppColors.textLight,
                          size: 26,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 11,
                            color: isSelected
                                ? const Color(0xFF007A8A)
                                : AppColors.textLight,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentTab() {
    switch (_selectedIndex) {
      case 0:
        return _buildHomeTab();
      case 1:
        return _buildMatchesTab();
      case 2:
        return const EsProfileScreen();
      default:
        return _buildHomeTab();
    }
  }

  Widget _buildHomeTab() {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadAll,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_upcomingMatches.isNotEmpty || _liveMatches.isNotEmpty) ...[
              const SizedBox(height: 16),
              SizedBox(
                height: 200,
                child: PageView.builder(
                  controller: _carouselCtrl,
                  onPageChanged: (i) => setState(() => _carouselPage = i),
                  itemCount: (_liveMatches.length + _upcomingMatches.length).clamp(0, 10),
                  itemBuilder: (context, index) {
                    final isLive = index < _liveMatches.length;
                    final match = isLive
                        ? _liveMatches[index]
                        : _upcomingMatches[index - _liveMatches.length];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: _MatchCarouselCard(
                        data: match,
                        isLive: isLive,
                        onTap: () => _openMatch(match),
                        onJoin: () => _joinByMatchId(match),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    (_liveMatches.length + _upcomingMatches.length).clamp(0, 10),
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: i == _carouselPage ? 20 : 6,
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3),
                        color: i == _carouselPage
                            ? const Color(0xFF007A8A)
                            : Colors.black12,
                      ),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            _buildPlayWinBanner(),
            const SizedBox(height: 24),
            _buildSeriesListSection(),
            const SizedBox(height: 24),
            _buildPromoBanner(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSeriesListSection() {
    if (_liveSeries.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'TOP SERIES',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B2430),
                ),
              ),
              TextButton(
                onPressed: () => setState(() => _selectedIndex = 1),
                child: const Text(
                  'View All',
                  style: TextStyle(
                    color: Color(0xFF007A8A),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _liveSeries.length.clamp(0, 5),
          itemBuilder: (context, index) {
            final serie = _liveSeries[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black.withOpacity(0.05)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF0F7F8),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.emoji_events,
                    color: Color(0xFF007A8A),
                    size: 20,
                  ),
                ),
                title: Text(
                  serie['title']?.toString() ?? 'Series',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                  color: Colors.black26,
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EsSeriesScreen(seriesData: serie),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPlayWinBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      child: Row(
        children: [
          const Text(
            'PLAY ',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1B2430),
              letterSpacing: -0.5,
            ),
          ),
          const Text(
            '& WIN',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: Color(0xFF007A8A),
              letterSpacing: -0.5,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1B2430), Color(0xFF007A8A)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF007A8A).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Row(
              children: [
                Icon(Icons.arrow_forward, color: Colors.white, size: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromoBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [Color(0xFF1B2430), Color(0xFF007A8A)],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: 16,
              bottom: 0,
              top: 0,
              child: Center(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Join Now',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 120, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'TATA IPL 2026',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'MANAGER MODE',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchesTab() {
    return Column(
      children: [
        Container(
          color: const Color(0xFF1B2430),
          width: double.infinity,
          child: TabBar(
            controller: _matchesTabController,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white54,
            tabs: const [
              Tab(text: 'PLAY & WIN'),
              Tab(text: 'All Matches'),
              Tab(text: 'Series'),
            ],
          ),
        ),
        Expanded(
          child: _matchesTabController.index == 2
              ? EsSeriesScreen(seriesList: _liveSeries)
              : _matchesTabController.index == 0
              ? _buildPlayWinTabContent()
              : _buildAllMatchesContent(),
        ),
      ],
    );
  }

  Widget _buildPlayWinTabContent() {
    if (_featuredContests.isEmpty) {
      return _buildEmpty('No contests available right now');
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _featuredContests.length,
      itemBuilder: (context, index) {
        final contest = _featuredContests[index];
        return _ContestCard(
          contest: contest,
          onJoin: () => _join(contest),
        );
      },
    );
  }

  Widget _buildAllMatchesContent() {
    return Column(
      children: [
        Container(
          color: Colors.white,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: TabBar(
            controller: _subMatchesTabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorColor: const Color(0xFF007A8A),
            labelColor: const Color(0xFF007A8A),
            unselectedLabelColor: Colors.black54,
            tabs: const [
              Tab(text: 'Upcoming'),
              Tab(text: 'Live'),
              Tab(text: 'Completed'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _subMatchesTabController,
            children: [
              _buildMatchesList(_upcomingMatches, false),
              _buildMatchesList(_liveMatches, true),
              _buildMatchesList(_finishedMatches, false),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMatchesList(List<Map<String, dynamic>> matches, bool isLive) {
    if (matches.isEmpty) return _buildEmpty('No matches available');
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: matches.length,
      itemBuilder: (context, index) => _MatchListCard(
        data: matches[index],
        isLive: isLive,
        onTap: () => _openMatch(matches[index]),
      ),
    );
  }

  Widget _buildEmpty(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.sports_cricket, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(_error ?? 'Error loading data'),
          ElevatedButton(onPressed: _loadAll, child: const Text('Retry')),
        ],
      ),
    );
  }

  void _openMatch(Map<String, dynamic> match) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EsMatchDetailScreen(matchData: match)),
    );
  }

  Future<void> _joinByMatchId(Map<String, dynamic> match) async {
    final matchId = match['match_id']?.toString() ?? match['id']?.toString() ?? '0';
    if (matchId == '0') return;

    setState(() => _loading = true);
    try {
      final contests = await ContestService().getContestsForMatch(matchId);
      setState(() => _loading = false);
      
      if (contests.isNotEmpty) {
        _join(contests.first);
      } else {
        // Fallback to creating team if no contests found via specific match ID
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => EsCreateTeamScreen(matchData: match)),
          ).then((_) => _loadAll());
        }
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
      // Fallback
      if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => EsCreateTeamScreen(matchData: match)),
          ).then((_) => _loadAll());
        }
    }
  }

  /// When user clicks "JOIN NOW" on a contest card:
  /// 1. Take the match_id from the contest
  /// 2. Hit GET /api/v1/teams?match_id={{match_id}}&page=1&limit=10
  /// 3. If teams found → show team selector popup
  /// 4. If no teams (empty) → redirect to create team page
  Future<void> _join(ContestModel contest) async {
    final matchId = int.tryParse(contest.matchId) ?? 0;
    print('DEBUG: HomeScreen._join - JOIN NOW clicked for contest: ${contest.name}');
    print('DEBUG: HomeScreen._join - contest.matchId = ${contest.matchId}, parsed matchId = $matchId');

    if (matchId <= 0) {
      print('DEBUG: HomeScreen._join - Invalid matchId, going to create team');
      _navigateToCreateTeam(contest, {'match_id': contest.matchId});
      return;
    }

    setState(() => _loading = true);

    try {
      // Step 1: Fetch user's teams for THIS match
      print('DEBUG: HomeScreen._join - Fetching teams for match_id=$matchId...');
      final teams = await TeamsService().getMyTeams(matchId);
      print('DEBUG: HomeScreen._join - Got ${teams.length} teams back');

      if (!mounted) return;
      setState(() => _loading = false);

      if (teams.isNotEmpty) {
        // Step 2a: Teams exist → show selector popup
        print('DEBUG: HomeScreen._join - Showing team selector with ${teams.length} teams');
        _showTeamSelector(contest, teams);
      } else {
        // Step 2b: No teams → go to create team page
        print('DEBUG: HomeScreen._join - No teams found, redirecting to create team');
        final all = [..._liveMatches, ..._upcomingMatches, ..._finishedMatches];
        Map<String, dynamic> matchData;
        try {
          matchData = all.firstWhere(
            (m) => m['match_id']?.toString() == contest.matchId || m['id']?.toString() == contest.matchId,
          );
        } catch (_) {
          matchData = {'match_id': contest.matchId};
        }
        _navigateToCreateTeam(contest, matchData);
      }
    } catch (e) {
      print('DEBUG: HomeScreen._join - ERROR: $e');
      if (mounted) setState(() => _loading = false);
      _navigateToCreateTeam(contest, {'match_id': contest.matchId});
    }
  }

  void _navigateToCreateTeam(ContestModel contest, Map<String, dynamic> matchData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EsCreateTeamScreen(matchData: matchData, contest: contest),
      ),
    ).then((_) => _loadAll());
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
                      // Find match data to pass to team creation
                      final all = [..._liveMatches, ..._upcomingMatches, ..._finishedMatches];
                      final matchIdStr = contest.matchId.toString();
                      final matchData = all.firstWhere(
                        (m) => m['match_id']?.toString() == matchIdStr || m['id']?.toString() == matchIdStr,
                        orElse: () => {'match_id': contest.matchId},
                      );
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

  Future<void> _confirmJoin(ContestModel contest, Map<String, dynamic> team) async {
    final userId = await UserProfileService.getSavedUserId();
    if (userId <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to join contests')),
        );
      }
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
        _loadAll();
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

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem(this.icon, this.label);
}

class _MatchCarouselCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isLive;
  final VoidCallback onTap;
  final VoidCallback onJoin;
  const _MatchCarouselCard({
    required this.data,
    required this.isLive,
    required this.onTap,
    required this.onJoin,
  });

  @override
  Widget build(BuildContext context) {
    final teamA = data['teama']?['short_name'] ?? 'T1';
    final teamB = data['teamb']?['short_name'] ?? 'T2';
    final teamALogo = data['teama']?['logo_url']?.toString();
    final teamBLogo = data['teamb']?['logo_url']?.toString();
    final matchHeader = data['competition']?['title'] ?? 'Tournament';
    final venue = data['venue']?['name']?.toString() ?? data['venue']?.toString() ?? '';
    final format = data['format_str']?.toString() ?? data['format']?.toString() ?? '';
    var timeStr = (data['date_start'] ?? '').toString();
    String time = '';
    String dateStr = '';
    if (timeStr.isNotEmpty) {
      try {
        final dt = DateTime.tryParse(timeStr);
        if (dt != null) {
          final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
          dateStr = '${dt.day} ${months[dt.month - 1]}';
          time = '${dt.hour > 12 ? dt.hour - 12 : dt.hour}:${dt.minute.toString().padLeft(2, '0')} ${dt.hour >= 12 ? 'PM' : 'AM'}';
        } else {
          if (timeStr.contains('T')) {
            time = timeStr.split('T').last.substring(0, 5);
          } else if (timeStr.contains(' ')) {
            time = timeStr.split(' ').last.substring(0, 5);
          }
        }
      } catch (_) {}
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black.withOpacity(0.05)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header: competition name + format
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    matchHeader,
                    style: const TextStyle(fontSize: 11, color: Colors.black45, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (format.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF007A8A).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(format.toUpperCase(), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF007A8A))),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            // Teams row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: 100,
                  child: Row(
                    children: [
                      _cardTeamLogo(teamALogo, teamA),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(teamA.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF1B2430)), overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ),
                // Center: live badge or time
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isLive)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.circle, size: 6, color: Colors.white),
                            SizedBox(width: 4),
                            Text('LIVE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
                          ],
                        ),
                      )
                    else ...[
                      if (dateStr.isNotEmpty)
                        Text(dateStr, style: const TextStyle(fontSize: 10, color: Colors.black45, fontWeight: FontWeight.w500)),
                      Text(time.isNotEmpty ? time : 'TBD', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1B2430))),
                    ],
                  ],
                ),
                SizedBox(
                  width: 100,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Text(teamB.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF1B2430)), textAlign: TextAlign.right, overflow: TextOverflow.ellipsis),
                      ),
                      const SizedBox(width: 8),
                      _cardTeamLogo(teamBLogo, teamB),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Bottom: venue + view button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 14, color: Colors.black38),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      venue.isNotEmpty ? venue : 'Venue TBA',
                      style: const TextStyle(fontSize: 10, color: Colors.black45, fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  GestureDetector(
                    onTap: onTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF007A8A),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('View', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cardTeamLogo(String? url, String short) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black.withOpacity(0.08)),
      ),
      child: ClipOval(
        child: (url != null && url.isNotEmpty)
            ? CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                placeholder: (context, url) => Center(
                  child: Text(
                    short.isNotEmpty ? short[0].toUpperCase() : '?',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 13),
                  ),
                ),
                errorWidget: (context, url, error) => Center(
                  child: Text(
                    short.isNotEmpty ? short[0].toUpperCase() : '?',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 13),
                  ),
                ),
              )
            : Center(
                child: Text(
                  short.isNotEmpty ? short[0].toUpperCase() : '?',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 13),
                ),
              ),
      ),
    );
  }
}

class _MatchListCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isLive;
  final VoidCallback onTap;
  const _MatchListCard({
    required this.data,
    required this.isLive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final teamA = data['teama']?['short_name'] ?? 'T1';
    final teamB = data['teamb']?['short_name'] ?? 'T2';
    final teamALogo = data['teama']?['logo_url']?.toString();
    final teamBLogo = data['teamb']?['logo_url']?.toString();
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black12),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _teamIcon(teamALogo, teamA),
                Column(
                  children: [
                    Text(
                      isLive ? 'LIVE' : _formatTime(data['date_start']),
                      style: TextStyle(
                        color: isLive
                            ? const Color(0xFF4CAF50)
                            : const Color(0xFF007A8A),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'VS',
                      style: TextStyle(color: Colors.grey, fontSize: 10),
                    ),
                  ],
                ),
                _teamIcon(teamBLogo, teamB),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              data['competition']?['title'] ?? 'Series',
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _teamIcon(String? url, String short) {
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.black.withOpacity(0.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipOval(
            child: (url != null && url.isNotEmpty)
                ? CachedNetworkImage(
                    imageUrl: url,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Center(
                      child: Text(
                        short.isNotEmpty ? short[0].toUpperCase() : '?',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 16),
                      ),
                    ),
                    errorWidget: (context, url, error) => Center(
                      child: Text(
                        short.isNotEmpty ? short[0].toUpperCase() : '?',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 16),
                      ),
                    ),
                  )
                : Center(
                    child: Text(
                      short.isNotEmpty ? short[0].toUpperCase() : '?',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 16),
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          short,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: Color(0xFF1B2430),
          ),
        ),
      ],
    );
  }
  String _formatTime(dynamic dateStart) {
    if (dateStart == null) return 'TBD';
    String str = dateStart.toString();
    if (str.isEmpty) return 'TBD';
    try {
      if (str.contains(' ')) {
        final timePart = str.split(' ').last;
        if (timePart.length >= 5) return timePart.substring(0, 5);
      } else if (str.contains('T')) {
        final timePart = str.split('T').last;
        if (timePart.length >= 5) return timePart.substring(0, 5);
      }
    } catch (_) {}
    return str.length > 10 ? str.substring(11, 16) : '07:30 PM';
  }
}

class _ContestCard extends StatelessWidget {
  final ContestModel contest;
  final VoidCallback onJoin;
  const _ContestCard({required this.contest, required this.onJoin});

  @override
  Widget build(BuildContext context) {
    final spotsLeft = contest.maxTeams - contest.currentTeams;
    final progress = (contest.maxTeams > 0)
        ? (contest.currentTeams.toDouble() / contest.maxTeams.toDouble())
        : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: AppColors.primaryGradient),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  contest.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                Text(
                  '₹${contest.prizePool}',
                  style: const TextStyle(
                    color: Colors.amber,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$spotsLeft spots left',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${contest.maxTeams} spots',
                      style: TextStyle(color: Colors.grey[400], fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress.toDouble(),
                    backgroundColor: Colors.grey[200],
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
                        color: AppColors.primary.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'ENTRY ₹${contest.entryFee}',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: onJoin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'JOIN NOW',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
