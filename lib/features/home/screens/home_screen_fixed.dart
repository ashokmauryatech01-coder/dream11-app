import 'package:flutter/material.dart';
import 'package:fantasy_crick/common/widgets/cricket_animation.dart';
import 'package:fantasy_crick/core/constants/app_colors.dart';
import 'package:fantasy_crick/core/services/entity_sport_service.dart';
import 'package:fantasy_crick/features/matches/screens/es_match_detail_screen.dart';
import 'package:fantasy_crick/features/contest/screens/es_contest_screen.dart';
import 'package:fantasy_crick/features/contest/screens/es_create_team_screen.dart';
import 'package:fantasy_crick/core/services/match_service.dart';
import 'package:fantasy_crick/features/home/screens/es_series_screen.dart';
import 'package:fantasy_crick/features/profile/screens/es_profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // ── data ──────────────────────────────────────────────────────
  bool _loading = true;
  String? _error;

  List<Map<String, dynamic>> _liveMatches = [];
  List<Map<String, dynamic>> _upcomingMatches = [];
  List<Map<String, dynamic>> _finishedMatches = [];
  List<Map<String, dynamic>> _liveSeries = [];
  List<Map<String, dynamic>> _leaderboardData = [
    {'rank': 1, 'name': 'You', 'winnings': '₹5,000', 'matches': 45},
    {'rank': 2, 'name': 'Player 2', 'winnings': '₹4,200', 'matches': 38},
    {'rank': 3, 'name': 'Player 3', 'winnings': '₹3,800', 'matches': 32},
    {'rank': 4, 'name': 'Player 4', 'winnings': '₹2,500', 'matches': 28},
    {'rank': 5, 'name': 'Player 5', 'winnings': '₹1,200', 'matches': 22},
  ];

  late TabController _matchesTabController;
  late TabController _mainTabController;

  @override
  void initState() {
    super.initState();
    _matchesTabController = TabController(length: 3, vsync: this);
    _mainTabController = TabController(length: 6, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _matchesTabController.dispose();
    _mainTabController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final matchesTask = MatchService.getMatches('all');
      final seriesTask = EntitySportService.getLiveSeries();

      final results = await Future.wait([matchesTask, seriesTask]);

      final List<Map<String, dynamic>> allMatches = results[0];
      final List<Map<String, dynamic>> liveSeries = results[1];

      if (!mounted) return;

      setState(() {
        _liveMatches = allMatches.where((m) => m['status'] == 3).toList();
        _upcomingMatches = allMatches.where((m) => m['status'] == 1).toList();
        _finishedMatches = allMatches.where((m) => m['status'] == 2).toList();
        _liveSeries = liveSeries;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Failed to load data.';
      });
    }
  }

  // ── navigation ────────────────────────────────────────────────
  static const List<_NavItem> _navItems = [
    _NavItem(Icons.home_rounded, 'Home'),
    _NavItem(Icons.sports_cricket, 'Matches'),
    _NavItem(Icons.emoji_events_rounded, 'Series'),
    _NavItem(Icons.groups_rounded, 'Contest'),
    _NavItem(Icons.leaderboard, 'Leaderboard'),
    _NavItem(Icons.person_rounded, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _selectedIndex == 5 ? null : _buildAppBar(),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _error != null && _liveMatches.isEmpty && _upcomingMatches.isEmpty
          ? _buildError()
          : _buildCurrentTab(),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    const titles = ['Home', 'Matches', 'Series', 'Contests', 'Leaderboard', 'Profile'];
    return AppBar(
      backgroundColor: AppColors.primary,
      elevation: 0,
      title: Text(
        titles[_selectedIndex],
        style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: AppColors.white),
          onPressed: _loadAll,
        ),
      ],
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(_navItems.length, (i) {
              final selected = i == _selectedIndex;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedIndex = i),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: selected ? AppColors.primary : Colors.transparent,
                          width: 2.5,
                        ),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _navItems[i].icon,
                          color: selected ? AppColors.primary : Colors.grey.shade400,
                          size: 24,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _navItems[i].label,
                          style: TextStyle(
                            fontSize: 11,
                            color: selected ? AppColors.primary : Colors.grey.shade400,
                            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
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
        return _buildSeriesTab();
      case 3:
        return _buildContestTab();
      case 4:
        return _buildLeaderboardTab();
      case 5:
        return const EsProfileScreen();
      default:
        return _buildHomeTab();
    }
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.grey, size: 64),
          const SizedBox(height: 16),
          Text(
            _error ?? 'Something went wrong',
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadAll,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  // ── HOME TAB ─────────────────────────────────────────────────
  Widget _buildHomeTab() {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadAll,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeroBanner(),
            const SizedBox(height: 20),

            // ── Live Matches ──────────────────────────────────
            _SectionHeader(
              title: 'Live Matches',
              count: _liveMatches.length,
              badgeColor: Colors.red,
              onSeeAll: () => setState(() {
                _selectedIndex = 1;
                _matchesTabController.index = 0;
              }),
            ),
            if (_liveMatches.isEmpty)
              _buildEmptyInline('No live matches right now')
            else
              SizedBox(
                height: 185,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  scrollDirection: Axis.horizontal,
                  itemCount: _liveMatches.length.clamp(0, 10),
                  itemBuilder: (_, i) => _MatchCard(
                    data: _liveMatches[i],
                    isLive: true,
                    onTap: () => _openMatch(_liveMatches[i]),
                  ),
                ),
              ),

            const SizedBox(height: 20),

            // ── Upcoming Matches ──────────────────────────────
            _SectionHeader(
              title: 'Upcoming Matches',
              count: _upcomingMatches.length,
              badgeColor: AppColors.primary,
              onSeeAll: () => setState(() {
                _selectedIndex = 1;
                _matchesTabController.index = 1;
              }),
            ),
            if (_upcomingMatches.isEmpty)
              _buildEmptyInline('No upcoming matches')
            else
              SizedBox(
                height: 185,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  scrollDirection: Axis.horizontal,
                  itemCount: _upcomingMatches.length.clamp(0, 10),
                  itemBuilder: (_, i) => _MatchCard(
                    data: _upcomingMatches[i],
                    isLive: false,
                    onTap: () => _openMatch(_upcomingMatches[i]),
                  ),
                ),
              ),

            const SizedBox(height: 20),

            // ── Live Series ───────────────────────────────────
            _SectionHeader(
              title: 'Live Series',
              count: _liveSeries.length,
              badgeColor: AppColors.accent,
              onSeeAll: () => setState(() => _selectedIndex = 2),
            ),
            if (_liveSeries.isNotEmpty)
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                itemCount: _liveSeries.length.clamp(0, 5),
                itemBuilder: (_, i) => _SeriesCard(
                  data: _liveSeries[i],
                  onTap: () => _openSeries(_liveSeries[i]),
                ),
              )
            else
              _buildEmptyInline('No active series'),

            const SizedBox(height: 24),

            // ── Quick Actions ────────────────────────────────────
            _buildQuickActions(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ── LEADERBOARD TAB ───────────────────────────────────────
  Widget _buildLeaderboardTab() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.purple,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CricketAnimation(
                  type: AnimationType.trophy,
                  size: 30,
                  color: Colors.amber,
                  duration: const Duration(seconds: 2),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Leaderboard',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Leaderboard List
          Expanded(
            child: ListView.builder(
              itemCount: _leaderboardData.length,
              itemBuilder: (context, index) {
                final player = _leaderboardData[index];
                final rank = index + 1;
                final isCurrentUser = player['rank'].toString() == '1';
                
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isCurrentUser 
                        ? Colors.amber.withOpacity(0.2)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isCurrentUser 
                          ? Colors.amber
                          : Colors.grey.shade300,
                      width: isCurrentUser ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Rank
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _getRankColor(rank),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '$rank',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: 12),
                      
                      // Player Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              player['name']?.toString() ?? 'Player',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isCurrentUser ? Colors.amber.shade800 : Colors.black87,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                CricketAnimation(
                                  type: AnimationType.coin,
                                  size: 16,
                                  color: Colors.green,
                                  duration: const Duration(seconds: 3),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  player['winnings']?.toString() ?? '₹0',
                                  style: TextStyle(
                                    color: Colors.green.shade700,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      // Trophy for top 3
                      if (rank <= 3) ...[
                        const SizedBox(width: 8),
                        CricketAnimation(
                          type: AnimationType.trophy,
                          size: 24,
                          color: _getRankColor(rank),
                          duration: const Duration(seconds: 2),
                        ),
                      ],
                      
                      // Current User Badge
                      if (isCurrentUser) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'YOU',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber;
      case 2:
        return Colors.grey.shade400;
      case 3:
        return Colors.brown.shade400;
      default:
        return Colors.grey;
    }
  }

  Widget _buildHeroBanner() {
    final liveCount = _liveMatches.length;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Welcome to',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'Segga Sportzz',
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      '$liveCount',
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'Live',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Create your dream team and win exciting prizes!',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.add_circle_outline,
                  label: 'Create\nTeam',
                  color: AppColors.primary,
                  onTap: () {
                    // Get first live or upcoming match
                    final target = _liveMatches.isNotEmpty
                        ? _liveMatches.first
                        : (_upcomingMatches.isNotEmpty ? _upcomingMatches.first : null);
                    if (target != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EsCreateTeamScreen(matchData: target),
                        ),
                      );
                    }
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.leaderboard,
                  label: 'View\nContest',
                  color: AppColors.primary,
                  onTap: () => setState(() => _selectedIndex = 3),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── MATCHES TAB ───────────────────────────────────────────────
  Widget _buildMatchesTab() {
    return Column(
      children: [
        Container(
          color: AppColors.primary,
          child: TabBar(
            controller: _matchesTabController,
            indicatorColor: AppColors.white,
            indicatorWeight: 3,
            labelColor: AppColors.white,
            unselectedLabelColor: Colors.white54,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
            tabs: [
              _TabLabel('Live', _liveMatches.length, Colors.red),
              _TabLabel('Upcoming', _upcomingMatches.length, AppColors.accent),
              _TabLabel('Finished', _finishedMatches.length, AppColors.success),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _matchesTabController,
            children: [
              _buildLiveMatchesList(),
              _buildUpcomingMatchesList(),
              _buildFinishedMatchesList(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLiveMatchesList() {
    if (_liveMatches.isEmpty) {
      return _buildEmpty('No live matches right now');
    }
    return ListView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: _liveMatches.length,
      itemBuilder: (context, index) {
        final match = _liveMatches[index];
        return _MatchCard(
          data: match,
          isLive: true,
          onTap: () => _openMatch(match),
        );
      },
    );
  }

  Widget _buildUpcomingMatchesList() {
    if (_upcomingMatches.isEmpty) {
      return _buildEmpty('No upcoming matches');
    }
    return ListView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: _upcomingMatches.length,
      itemBuilder: (context, index) {
        final match = _upcomingMatches[index];
        return _MatchCard(
          data: match,
          isLive: false,
          onTap: () => _openMatch(match),
        );
      },
    );
  }

  Widget _buildFinishedMatchesList() {
    if (_finishedMatches.isEmpty) {
      return _buildEmpty('No finished matches');
    }
    return ListView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: _finishedMatches.length,
      itemBuilder: (context, index) {
        final match = _finishedMatches[index];
        return _MatchCard(
          data: match,
          isLive: false,
          onTap: () => _openMatch(match),
        );
      },
    );
  }

  Widget _buildEmpty(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 100),
          Icon(Icons.sports_cricket, color: Colors.grey.shade400, size: 64),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyInline(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          Icon(Icons.sports_cricket, color: Colors.grey.shade400, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeriesTab() {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadAll,
      child: const EsSeriesScreen(),
    );
  }

  Widget _buildContestTab() {
    return const EsContestScreen(
      matches: _upcomingMatches.isNotEmpty ? _upcomingMatches : _liveMatches,
    );
  }

  void _openMatch(Map<String, dynamic> match) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EsMatchDetailScreen(matchData: match),
      ),
    );
  }

  void _openSeries(Map<String, dynamic> series) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EsSeriesScreen(seriesData: series),
      ),
    );
  }
}

// ── NAV ITEM ────────────────────────────────────────────────────────
class _NavItem {
  final IconData icon;
  final String label;

  const _NavItem(this.icon, this.label);
}

// ── TAB LABEL ───────────────────────────────────────────────────────
Tab _TabLabel(String text, int count, Color badgeColor) {
  return Tab(
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(text),
        const SizedBox(width: 6),
        if (count > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    ),
  );
}

// ── MATCH CARD ───────────────────────────────────────────────────────
class _MatchCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isLive;
  final VoidCallback onTap;

  const _MatchCard({
    super.key,
    required this.data,
    required this.isLive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final teamA = data['teama'] ?? 'Team A';
    final teamB = data['teamb'] ?? 'Team B';
    final status = data['status'] ?? 1;
    final startTime = data['date_start'] ?? '';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 280,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Live indicator
            if (isLive)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'LIVE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            
            const SizedBox(height: 8),
            
            // Teams
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        teamA,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'vs',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        teamB,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.right,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        startTime,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ],
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

// ── SERIES CARD ───────────────────────────────────────────────────────
class _SeriesCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onTap;

  const _SeriesCard({
    super.key,
    required this.data,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final name = data['name'] ?? 'Unknown Series';
    final matches = data['total_matches'] ?? 0;
    final startDate = data['date_start'] ?? 'Unknown';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '$matches matches',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Starts: $startDate',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── QUICK ACTION CARD ───────────────────────────────────────────────
class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── SECTION HEADER ───────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final Color badgeColor;
  final VoidCallback onSeeAll;

  const _SectionHeader({
    super.key,
    required this.title,
    required this.count,
    required this.badgeColor,
    required this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
          GestureDetector(
            onTap: onSeeAll,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: badgeColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'See all ($count)',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
