import 'package:flutter/material.dart';
import 'package:fantasy_crick/core/constants/app_colors.dart';
import 'package:fantasy_crick/core/services/entity_sport_service.dart';
import 'package:fantasy_crick/features/matches/screens/es_match_detail_screen.dart';
import 'package:fantasy_crick/features/contest/screens/es_contest_screen.dart';
import 'package:fantasy_crick/features/contest/screens/es_create_team_screen.dart';
import 'package:fantasy_crick/features/home/screens/es_series_screen.dart';
import 'package:fantasy_crick/features/profile/screens/es_profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;

  // ── data ──────────────────────────────────────────────────────────────
  bool _loading = true;
  String? _error;

  List<Map<String, dynamic>> _liveMatches = [];
  List<Map<String, dynamic>> _upcomingMatches = [];
  List<Map<String, dynamic>> _finishedMatches = [];
  List<Map<String, dynamic>> _liveSeries = [];

  late TabController _matchesTabController;

  @override
  void initState() {
    super.initState();
    _matchesTabController = TabController(length: 3, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _matchesTabController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        EntitySportService.getLiveMatches(),
        EntitySportService.getUpcomingMatches(),
        EntitySportService.getFinishedMatches(),
        EntitySportService.getLiveSeries(),
      ]);
      if (!mounted) return;
      setState(() {
        _liveMatches    = results[0];
        _upcomingMatches= results[1];
        _finishedMatches= results[2];
        _liveSeries     = results[3];
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = 'Failed to load data.'; });
    }
  }

  // ── navigation ────────────────────────────────────────────────────────
  static const List<_NavItem> _navItems = [
    _NavItem(Icons.home_rounded,         'Home'),
    _NavItem(Icons.sports_cricket,       'Matches'),
    _NavItem(Icons.emoji_events_rounded, 'Series'),
    _NavItem(Icons.groups_rounded,       'Contest'),
    _NavItem(Icons.person_rounded,       'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
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
      title: Text(
        titles[_selectedIndex.clamp(0, 4)],
        style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 20),
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, -2))],
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
                          color: selected ? AppColors.primary : AppColors.unselectedIcon,
                          size: 24,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _navItems[i].label,
                          style: TextStyle(
                            fontSize: 11,
                            color: selected ? AppColors.primary : AppColors.unselectedIcon,
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
      case 0: return _buildHomeTab();
      case 1: return _buildMatchesTab();
      case 2: return _buildSeriesTab();
      case 3: return _buildContestTab();
      case 4: return const EsProfileScreen();
      default: return _buildHomeTab();
    }
  }

  // ── HOME TAB ─────────────────────────────────────────────────────────
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

            // ── Live Matches ──────────────────────────────────────────
            _SectionHeader(
              title: 'Live Matches',
              count: _liveMatches.length,
              badgeColor: Colors.red,
              onSeeAll: () => setState(() { _selectedIndex = 1; _matchesTabController.index = 0; }),
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

            // ── Upcoming Matches ──────────────────────────────────────
            _SectionHeader(
              title: 'Upcoming Matches',
              count: _upcomingMatches.length,
              badgeColor: AppColors.primary,
              onSeeAll: () => setState(() { _selectedIndex = 1; _matchesTabController.index = 1; }),
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

            // ── Live Series ───────────────────────────────────────────
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

            // ── Quick Actions ─────────────────────────────────────────
            _buildQuickActions(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
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
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.circle, color: Colors.white, size: 8),
                const SizedBox(width: 5),
                Text(
                  liveCount > 0 ? '$liveCount LIVE' : 'CRICKET',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ]),
            ),
          ]),
          const SizedBox(height: 12),
          const Text('11 Dreamer', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(
            '${_upcomingMatches.length} upcoming · ${_finishedMatches.length} finished · ${_liveSeries.length} series',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Row(children: [
            _HeroPill(
              icon: Icons.add_circle_outline,
              label: 'Create Team',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EsCreateTeamScreen())),
            ),
            const SizedBox(width: 12),
            _HeroPill(
              icon: Icons.emoji_events_outlined,
              label: 'Contests',
              onTap: () => setState(() => _selectedIndex = 3),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Quick Actions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.text)),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _QuickActionCard(
              icon: Icons.sports_cricket,
              label: 'Finished\nMatches',
              color: AppColors.success,
              onTap: () => setState(() { _selectedIndex = 1; _matchesTabController.index = 2; }),
            )),
            const SizedBox(width: 10),
            Expanded(child: _QuickActionCard(
              icon: Icons.group_add,
              label: 'Create\nTeam',
              color: AppColors.blue,
              onTap: () {
                if (_upcomingMatches.isNotEmpty) {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => EsCreateTeamScreen(matchData: _upcomingMatches.first),
                  ));
                } else {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const EsCreateTeamScreen()));
                }
              },
            )),
            const SizedBox(width: 10),
            Expanded(child: _QuickActionCard(
              icon: Icons.leaderboard,
              label: 'View\nContest',
              color: AppColors.primary,
              onTap: () => setState(() => _selectedIndex = 3),
            )),
          ]),
        ],
      ),
    );
  }

  // ── MATCHES TAB ───────────────────────────────────────────────────────
  Widget _buildMatchesTab() {
    return Column(children: [
      Container(
        color: AppColors.primary,
        child: TabBar(
          controller: _matchesTabController,
          indicatorColor: AppColors.white,
          indicatorWeight: 3,
          labelColor: AppColors.white,
          unselectedLabelColor: Colors.white54,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
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
            _MatchListView(
              matches: _liveMatches,
              isLive: true,
              onRefresh: _loadAll,
              onTap: _openMatch,
            ),
            _MatchListView(
              matches: _upcomingMatches,
              isLive: false,
              onRefresh: _loadAll,
              onTap: _openMatch,
            ),
            _MatchListView(
              matches: _finishedMatches,
              isLive: false,
              isFinished: true,
              onRefresh: _loadAll,
              onTap: _openMatch,
            ),
          ],
        ),
      ),
    ]);
  }

  // ── SERIES TAB ────────────────────────────────────────────────────────
  Widget _buildSeriesTab() {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadAll,
      child: _liveSeries.isEmpty
          ? ListView(children: [
              const SizedBox(height: 200),
              Center(child: Column(children: [
                const Icon(Icons.sports_cricket, size: 60, color: AppColors.textLight),
                const SizedBox(height: 16),
                const Text('No series available', style: TextStyle(color: AppColors.textLight, fontSize: 16)),
              ])),
            ])
          : ListView.builder(
              padding: const EdgeInsets.all(14),
              itemCount: _liveSeries.length,
              itemBuilder: (_, i) => _SeriesCard(data: _liveSeries[i], expanded: true, onTap: () => _openSeries(_liveSeries[i])),
            ),
    );
  }

  // ── CONTEST TAB ───────────────────────────────────────────────────────
  Widget _buildContestTab() {
    return EsContestScreen(
      matches: _upcomingMatches.isNotEmpty ? _upcomingMatches : _liveMatches,
    );
  }

  // ── helpers ───────────────────────────────────────────────────────────
  void _openMatch(Map<String, dynamic> match) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => EsMatchDetailScreen(matchData: match),
    ));
  }

  void _openSeries(Map<String, dynamic> series) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => EsSeriesScreen(seriesData: series),
    ));
  }

  Widget _buildError() {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.cloud_off_rounded, size: 60, color: AppColors.textLight),
      const SizedBox(height: 16),
      const Text('Unable to load data', style: TextStyle(color: AppColors.text, fontSize: 17, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      Text(_error ?? '', style: const TextStyle(color: AppColors.textLight)),
      const SizedBox(height: 24),
      ElevatedButton.icon(
        onPressed: _loadAll,
        icon: const Icon(Icons.refresh),
        label: const Text('Retry'),
        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
      ),
    ]));
  }

  Widget _buildEmptyInline(String msg) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withOpacity(0.4)),
      ),
      child: Row(children: [
        const Icon(Icons.info_outline, color: AppColors.textLight, size: 18),
        const SizedBox(width: 10),
        Text(msg, style: const TextStyle(color: AppColors.textLight, fontSize: 13)),
      ]),
    );
  }
}

// ── TAB LABEL ─────────────────────────────────────────────────────────────
Tab _TabLabel(String text, int count, Color badgeColor) {
  return Tab(
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Text(text),
      const SizedBox(width: 5),
      if (count > 0)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(10)),
          child: Text('$count', style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
        ),
    ]),
  );
}

// ── SECTION HEADER ────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final Color badgeColor;
  final VoidCallback onSeeAll;

  const _SectionHeader({required this.title, required this.count, required this.badgeColor, required this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(children: [
        if (count > 0) ...[
          Container(
            width: 6, height: 6,
            decoration: BoxDecoration(color: badgeColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
        ],
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.text)),
        if (count > 0) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: badgeColor.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
            child: Text('$count', style: TextStyle(color: badgeColor, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
        const Spacer(),
        TextButton(
          onPressed: onSeeAll,
          style: TextButton.styleFrom(padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
          child: const Row(children: [
            Text('See All', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13)),
            Icon(Icons.chevron_right, color: AppColors.primary, size: 16),
          ]),
        ),
      ]),
    );
  }
}

// ── MATCH CARD ────────────────────────────────────────────────────────────
class _MatchCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isLive;
  final VoidCallback onTap;

  const _MatchCard({required this.data, required this.isLive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final teamA = data['teama'] as Map<String, dynamic>? ?? {};
    final teamB = data['teamb'] as Map<String, dynamic>? ?? {};
    final comp = data['competition'] as Map<String, dynamic>? ?? {};

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: 12, bottom: 4),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: isLive ? Border.all(color: Colors.red.withOpacity(0.4), width: 1.5) : null,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isLive ? Colors.red.withOpacity(0.06) : AppColors.background,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              ),
              child: Row(children: [
                if (isLive) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(8)),
                    child: const Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 6),
                ],
                Expanded(
                  child: Text(
                    comp['abbr']?.toString() ?? comp['title']?.toString() ?? '',
                    style: const TextStyle(color: AppColors.textLight, fontSize: 10),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                ),
              ]),
            ),
            // Teams
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TeamRow(team: teamA, isWinner: data['winning_team_id'] == teamA['team_id']),
                  const SizedBox(height: 6),
                  const Center(child: Text('vs', style: TextStyle(color: AppColors.textLight, fontSize: 11, fontWeight: FontWeight.w500))),
                  const SizedBox(height: 6),
                  _TeamRow(team: teamB, isWinner: data['winning_team_id'] == teamB['team_id']),
                ],
              ),
            ),
            const Divider(height: 1),
            // Status note
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(
                data['status_note']?.toString() ?? data['subtitle']?.toString() ?? '',
                style: TextStyle(
                  fontSize: 11,
                  color: isLive ? Colors.red : AppColors.textLight,
                  fontWeight: isLive ? FontWeight.w600 : FontWeight.normal,
                ),
                maxLines: 1, overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TeamRow extends StatelessWidget {
  final Map<String, dynamic> team;
  final bool isWinner;
  const _TeamRow({required this.team, required this.isWinner});

  @override
  Widget build(BuildContext context) {
    final name = team['short_name']?.toString() ?? team['name']?.toString() ?? '?';
    final scores = team['scores']?.toString() ?? '';
    final logoUrl = team['logo_url']?.toString() ?? '';

    return Row(children: [
      Container(
        width: 28, height: 28,
        decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(4)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: logoUrl.isNotEmpty
              ? Image.network(logoUrl, fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(Icons.sports_cricket, size: 16, color: AppColors.primary))
              : const Icon(Icons.sports_cricket, size: 16, color: AppColors.primary),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(child: Text(name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isWinner ? AppColors.success : AppColors.text))),
      if (scores.isNotEmpty)
        Text(scores, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isWinner ? AppColors.success : AppColors.textLight)),
    ]);
  }
}

// ── SERIES CARD ───────────────────────────────────────────────────────────
class _SeriesCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool expanded;
  final VoidCallback onTap;
  const _SeriesCard({required this.data, this.expanded = false, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final status = data['status']?.toString() ?? '';
    final category = data['category']?.toString() ?? '';
    final total = data['total_matches']?.toString() ?? '0';

    Color statusColor;
    switch (status) {
      case 'live': statusColor = Colors.red; break;
      case 'fixture': statusColor = AppColors.primary; break;
      default: statusColor = AppColors.success;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.sports_cricket, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(data['title']?.toString() ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.text), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(color: statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                child: Text(status.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 8),
              Text('$total matches · $category', style: const TextStyle(color: AppColors.textLight, fontSize: 11)),
            ]),
          ])),
          const Icon(Icons.chevron_right, color: AppColors.textLight, size: 20),
        ]),
      ),
    );
  }
}

// ── MATCH LIST VIEW ───────────────────────────────────────────────────────
class _MatchListView extends StatelessWidget {
  final List<Map<String, dynamic>> matches;
  final bool isLive;
  final bool isFinished;
  final Future<void> Function() onRefresh;
  final void Function(Map<String, dynamic>) onTap;

  const _MatchListView({
    required this.matches,
    required this.isLive,
    this.isFinished = false,
    required this.onRefresh,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (matches.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(isLive ? Icons.live_tv : Icons.sports_cricket, size: 60, color: AppColors.textLight),
        const SizedBox(height: 16),
        Text(
          isLive ? 'No live matches right now' : isFinished ? 'No finished matches' : 'No upcoming matches',
          style: const TextStyle(color: AppColors.textLight, fontSize: 15),
        ),
      ]));
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(14),
        itemCount: matches.length,
        itemBuilder: (_, i) => _FullMatchCard(data: matches[i], isLive: isLive, isFinished: isFinished, onTap: () => onTap(matches[i])),
      ),
    );
  }
}

class _FullMatchCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isLive;
  final bool isFinished;
  final VoidCallback onTap;
  const _FullMatchCard({required this.data, required this.isLive, required this.isFinished, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final teamA = data['teama'] as Map<String, dynamic>? ?? {};
    final teamB = data['teamb'] as Map<String, dynamic>? ?? {};
    final comp = data['competition'] as Map<String, dynamic>? ?? {};
    final venue = data['venue'] as Map<String, dynamic>? ?? {};
    final statusNote = data['status_note']?.toString() ?? '';
    final subtitle = data['subtitle']?.toString() ?? '';
    final dateIst = data['date_start_ist']?.toString() ?? data['date_start']?.toString() ?? '';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: isLive ? Border.all(color: Colors.red.withOpacity(0.35), width: 1.5) : null,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isLive ? Colors.red.withOpacity(0.05) : AppColors.background.withOpacity(0.5),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
                if (comp['title'] != null)
                  Text(comp['title'].toString(), style: const TextStyle(fontSize: 11, color: AppColors.textLight), maxLines: 1, overflow: TextOverflow.ellipsis),
              ])),
              _StatusBadge(isLive: isLive, isFinished: isFinished),
            ]),
          ),
          // Teams
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(children: [
              Expanded(child: _TeamCol(team: teamA, isWinner: data['winning_team_id'] == teamA['team_id'])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
                child: const Text('VS', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 13)),
              ),
              Expanded(child: _TeamCol(team: teamB, isWinner: data['winning_team_id'] == teamB['team_id'], alignRight: true)),
            ]),
          ),
          if (statusNote.isNotEmpty) ...[
            Divider(height: 1, color: AppColors.border.withOpacity(0.4)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              child: Text(statusNote, style: TextStyle(fontSize: 12, color: isFinished ? AppColors.success : isLive ? Colors.red : AppColors.textLight, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ],
          // Footer
          Divider(height: 1, color: AppColors.border.withOpacity(0.4)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            child: Row(children: [
              const Icon(Icons.location_on_outlined, size: 13, color: AppColors.textLight),
              const SizedBox(width: 4),
              Expanded(child: Text(
                '${venue['name'] ?? ''} ${venue['location'] != null ? "· ${venue['location']}" : ""}'.trim(),
                style: const TextStyle(fontSize: 11, color: AppColors.textLight), maxLines: 1, overflow: TextOverflow.ellipsis,
              )),
              if (dateIst.isNotEmpty) ...[
                const SizedBox(width: 8),
                const Icon(Icons.access_time, size: 13, color: AppColors.textLight),
                const SizedBox(width: 4),
                Text(_fmtDate(dateIst), style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
              ],
            ]),
          ),
        ]),
      ),
    );
  }

  String _fmtDate(String d) {
    try {
      final dt = DateTime.parse(d);
      const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final min = dt.minute.toString().padLeft(2,'0');
      final ap = dt.hour < 12 ? 'AM' : 'PM';
      return '${dt.day} ${m[dt.month-1]}, $h:$min $ap';
    } catch (_) { return d; }
  }
}

class _TeamCol extends StatelessWidget {
  final Map<String, dynamic> team;
  final bool isWinner;
  final bool alignRight;
  const _TeamCol({required this.team, required this.isWinner, this.alignRight = false});

  @override
  Widget build(BuildContext context) {
    final name = team['short_name']?.toString() ?? team['name']?.toString() ?? '';
    final score = team['scores_full']?.toString() ?? '';
    final logo = team['logo_url']?.toString() ?? '';

    return Column(crossAxisAlignment: alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start, children: [
      Container(
        width: 36, height: 36,
        decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(6)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: logo.isNotEmpty
              ? Image.network(logo, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Icon(Icons.sports_cricket, size: 18, color: AppColors.primary))
              : const Icon(Icons.sports_cricket, size: 18, color: AppColors.primary),
        ),
      ),
      const SizedBox(height: 6),
      Text(name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: isWinner ? AppColors.success : AppColors.text), textAlign: alignRight ? TextAlign.right : TextAlign.left),
      if (score.isNotEmpty)
        Text(score, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isWinner ? AppColors.success : AppColors.textLight), textAlign: alignRight ? TextAlign.right : TextAlign.left),
      if (isWinner) ...[
        const SizedBox(height: 3),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (alignRight) ...[
              const Text('Won', style: TextStyle(fontSize: 10, color: AppColors.warning, fontWeight: FontWeight.w600)),
              const SizedBox(width: 3),
              const Icon(Icons.emoji_events, size: 13, color: AppColors.warning),
            ] else ...[
              const Icon(Icons.emoji_events, size: 13, color: AppColors.warning),
              const SizedBox(width: 3),
              const Text('Won', style: TextStyle(fontSize: 10, color: AppColors.warning, fontWeight: FontWeight.w600)),
            ],
          ],
        ),
      ],
    ]);
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isLive;
  final bool isFinished;
  const _StatusBadge({required this.isLive, required this.isFinished});

  @override
  Widget build(BuildContext context) {
    Color bg; String label;
    if (isLive) { bg = Colors.red; label = 'LIVE'; }
    else if (isFinished) { bg = AppColors.success.withOpacity(0.15); label = 'Finished'; }
    else { bg = AppColors.primary.withOpacity(0.12); label = 'Upcoming'; }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(label, style: TextStyle(color: isLive ? Colors.white : isFinished ? AppColors.success : AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
}

// ── HERO PILL ─────────────────────────────────────────────────────────────
class _HeroPill extends StatelessWidget {
  final IconData icon; final String label; final VoidCallback onTap;
  const _HeroPill({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), borderRadius: BorderRadius.circular(25)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: Colors.white, size: 16),
        const SizedBox(width: 7),
        Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
      ]),
    ),
  );
}

// ── QUICK ACTION CARD ─────────────────────────────────────────────────────
class _QuickActionCard extends StatelessWidget {
  final IconData icon; final String label; final Color color; final VoidCallback onTap;
  const _QuickActionCard({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.text), textAlign: TextAlign.center),
      ]),
    ),
  );
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem(this.icon, this.label);
}
