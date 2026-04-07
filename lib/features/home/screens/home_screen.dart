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
import 'package:fantasy_crick/common/widgets/dashboard_animation.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  int _selectedIndex = 0;

  // ── data ──────────────────────────────────────────────────────
  bool _loading = true;
  String? _error;

  List<Map<String, dynamic>> _liveMatches = [];
  List<Map<String, dynamic>> _upcomingMatches = [];
  List<Map<String, dynamic>> _finishedMatches = [];
  List<Map<String, dynamic>> _liveSeries = [];


  late TabController _matchesTabController;
  late TabController _mainTabController;

  @override
  void initState() {
    super.initState();
    _matchesTabController = TabController(length: 3, vsync: this);
    _mainTabController = TabController(length: 5, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _matchesTabController.dispose();
    _mainTabController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    final bool hasData = _liveMatches.isNotEmpty || _upcomingMatches.isNotEmpty || _liveSeries.isNotEmpty;
    setState(() {
      _loading = !hasData;
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
    _NavItem(Icons.person_rounded, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
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
    const titles = ['Home', 'Matches', 'Series', 'Contests', 'Profile'];
    return AppBar(
      backgroundColor: AppColors.primary,
      elevation: 0,
      centerTitle: false,
      title: Text(
        titles[_selectedIndex].toUpperCase(),
        style: const TextStyle(
          color: AppColors.white, 
          fontWeight: FontWeight.w900,
          fontSize: 18,
          letterSpacing: 1.2,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_none_rounded, color: AppColors.white),
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.account_balance_wallet_outlined, color: AppColors.white),
          onPressed: () => Navigator.pushNamed(context, '/add-cash'),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 65,
          child: Row(
            children: List.generate(_navItems.length, (i) {
              final selected = i == _selectedIndex;
              return Expanded(
                child: InkWell(
                  onTap: () => setState(() => _selectedIndex = i),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: EdgeInsets.all(selected ? 8 : 4),
                        decoration: BoxDecoration(
                          color: selected ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _navItems[i].icon,
                          color: selected ? AppColors.primary : AppColors.unselectedIcon,
                          size: selected ? 24 : 22,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _navItems[i].label,
                        style: TextStyle(
                          fontSize: 10,
                          color: selected ? AppColors.primary : AppColors.unselectedIcon,
                          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
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
          const Icon(Icons.error_outline, color: AppColors.textLight, size: 64),
          const SizedBox(height: 16),
          Text(
            _error ?? 'Something went wrong',
            style: const TextStyle(fontSize: 16, color: AppColors.textLight),
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
      child: DashboardAnimation(
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
                  height: 180, 
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    clipBehavior: Clip.none,
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
                  height: 180, 
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    clipBehavior: Clip.none,
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
  
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroBanner() {
    final liveCount = _liveMatches.length;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background Animation
          Positioned(
            right: -20,
            top: -20,
            child: Opacity(
              opacity: 0.05,
              child: CricketAnimation(
                type: AnimationType.trophy,
                size: 150,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome back,',
                            style: TextStyle(
                              color: AppColors.textLight,
                              fontSize: 14,
                            ),
                          ),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: const Text(
                              'Segga Sportzz',
                              style: TextStyle(
                                color: AppColors.text,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _HeaderBadge(count: liveCount, label: 'Live'),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.flash_on, color: AppColors.primary, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Create your dream team and win prizes!',
                          style: TextStyle(
                            color: AppColors.text,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
          width: double.infinity,
          child: TabBar(
            controller: _matchesTabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
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
          Icon(Icons.sports_cricket, color: AppColors.textLight, size: 64),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(fontSize: 16, color: AppColors.textLight),
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
          Icon(Icons.sports_cricket, color: AppColors.textLight, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 14, color: AppColors.textLight),
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
      child: EsSeriesScreen(seriesList: _liveSeries),
    );
  }

  Widget _buildContestTab() {
    return EsContestScreen(
      matches: _upcomingMatches.isNotEmpty ? _upcomingMatches : (_liveMatches.isNotEmpty ? _liveMatches : []),
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
        const SizedBox(width: 4),
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

class _HeaderBadge extends StatelessWidget {
  final int count;
  final String label;

  const _HeaderBadge({required this.count, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.white.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.accent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$count $label',
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
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

  Widget _resolveLogo(String? url, String code) {
    if (url != null && url.isNotEmpty) {
      String finalUrl = url;
      final codeMap = {
        'IND': 'https://flagcdn.com/w160/in.png',
        'AUS': 'https://flagcdn.com/w160/au.png',
        'SRL': 'https://flagcdn.com/w160/lk.png',
        'SL': 'https://flagcdn.com/w160/lk.png',
        'NZ': 'https://flagcdn.com/w160/nz.png',
        'PAK': 'https://flagcdn.com/w160/pk.png',
        'SA': 'https://flagcdn.com/w160/za.png',
        'ENG': 'https://flagcdn.com/w160/gb.png',
        'WI': 'https://flagcdn.com/w160/jm.png',
        'AFG': 'https://flagcdn.com/w160/af.png',
        'ADL': 'https://flagcdn.com/w160/au.png',
        'PRS': 'https://flagcdn.com/w160/au.png',
      };
      
      String? mapped = codeMap[url.toUpperCase()] ?? codeMap[code.toUpperCase()];
      if (mapped != null) finalUrl = mapped;

      if (finalUrl.startsWith('http')) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(45),
          child: Image.network(
            finalUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _shortName(code),
          ),
        );
      }
    }
    return _shortName(code);
  }

  Widget _shortName(String code) {
    return Text(
      code,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 13,
        color: AppColors.secondary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Extract team names properly from JSON data
    final teamA = (data['teama']?['name'] ?? data['teama']?.toString() ?? 'Team A').toString();
    final teamB = (data['teamb']?['name'] ?? data['teamb']?.toString() ?? 'Team B').toString();
    final status = (data['status'] ?? 1).toString();
    final startTime = (data['date_start'] ?? '').toString();
    
    // Extract team short codes for display
    final teamAFull = (data['teama']?['name'] ?? data['teama']?.toString() ?? 'Team A').toString();
    final teamBFull = (data['teamb']?['name'] ?? data['teamb']?.toString() ?? 'Team B').toString();
    final matchType = (data['subtitle'] ?? 'T20 Match').toString();
    final seriesName = (data['competition']?['title'] ?? 'Cricket Match').toString();
    final teamAShort = teamAFull.length > 3 ? teamAFull.substring(0, 3).toUpperCase() : teamAFull.toUpperCase();
    final teamBShort = teamBFull.length > 3 ? teamBFull.substring(0, 3).toUpperCase() : teamBFull.toUpperCase();
    final teamALogo = data['teama']?['logo_url']?.toString();
    final teamBLogo = data['teamb']?['logo_url']?.toString();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 300,
        margin: const EdgeInsets.only(right: 16, bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
            ),
          ],
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    matchType.toUpperCase(),
                    style: TextStyle(
                      color: AppColors.textLight,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (isLive)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'LIVE',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Text(
                      startTime.split('T').first,
                      style: TextStyle(
                        color: AppColors.textLight,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
            
            // Middle Section (Teams) - Row layout for efficiency
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Team A
                  Expanded(
                    child: Column(
                      children: [
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Center(
                            child: _resolveLogo(teamALogo, teamAShort),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          teamAFull,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            color: AppColors.text,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  
                  // Center Info
                  SizedBox(
                    width: 60,
                    child: Column(
                      children: [
                        const Text(
                          'VS',
                          style: TextStyle(
                            color: AppColors.textLight,
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          seriesName,
                          style: const TextStyle(
                            color: AppColors.textLight,
                            fontSize: 8,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  
                  // Team B
                  Expanded(
                    child: Column(
                      children: [
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Center(
                            child: _resolveLogo(teamBLogo, teamBShort),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          teamBFull,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            color: AppColors.text,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Bottom Action Removed as per user request
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

  _SeriesCard({
    super.key,
    required this.data,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final title = data['title']?.toString() ?? data['name']?.toString() ?? 'Unknown Series';
    final matches = data['total_matches']?.toString() ?? '0';
    final format = (data['match_format'] ?? data['game_format'] ?? 'mixed').toString();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.emoji_events_outlined,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$matches Matches · $format',
                    style: const TextStyle(color: AppColors.textLight, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textLight),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 28,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                height: 1.2,
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
