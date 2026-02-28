import 'package:flutter/material.dart';
import 'package:fantasy_crick/core/constants/app_colors.dart';
import 'package:fantasy_crick/core/services/entity_sport_service.dart';
import 'package:fantasy_crick/features/contest/screens/es_create_team_screen.dart';

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
  Map<String, dynamic>? _fantasyPoints;
  bool _loadingScorecard = false;
  bool _loadingPoints = false;
  // auto-refresh for live matches
  bool _autoRefresh = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      if (_tabController.index == 1 && _scorecard == null && !_loadingScorecard) _loadScorecard();
      if (_tabController.index == 2 && _fantasyPoints == null && !_loadingPoints) _loadPoints();
    });
    final status = widget.matchData['status'] as int? ?? 0;
    if (status == 3) {
      _loadScorecard(); // auto-load live scorecard
      _autoRefresh = true;
    }
  }

  @override
  void dispose() { _tabController.dispose(); super.dispose(); }

  int get _matchId => widget.matchData['match_id'] as int? ?? 0;

  Future<void> _loadScorecard() async {
    if (_matchId == 0) return;
    setState(() => _loadingScorecard = true);
    try {
      final res = await Future.wait([
        EntitySportService.getScorecard(_matchId),
        if (_isLive || _isFinished) EntitySportService.getLiveScore(_matchId),
      ]);
      if (!mounted) return;
      setState(() {
        _scorecard = res[0];
        if (res.length > 1) _liveScore = res[1];
        _loadingScorecard = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingScorecard = false);
    }
  }

  Future<void> _loadPoints() async {
    if (_matchId == 0) return;
    setState(() => _loadingPoints = true);
    final data = await EntitySportService.getFantasyPoints(_matchId);
    if (!mounted) return;
    setState(() { _fantasyPoints = data; _loadingPoints = false; });
  }

  Map<String, dynamic> get _teamA => widget.matchData['teama'] as Map<String, dynamic>? ?? {};
  Map<String, dynamic> get _teamB => widget.matchData['teamb'] as Map<String, dynamic>? ?? {};
  int get _status => widget.matchData['status'] as int? ?? 0;
  bool get _isLive => _status == 3;
  bool get _isFinished => _status == 2;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B2033),
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            backgroundColor: AppColors.primary,
            iconTheme: const IconThemeData(color: Colors.white),
            title: Text(
              widget.matchData['short_title']?.toString() ?? 'Match Detail',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
            ),
            actions: [
              if (_isLive)
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                  onPressed: _loadScorecard,
                  tooltip: 'Refresh scorecard',
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: ClipRect(child: _buildHeroHeader()),
            ),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              indicatorWeight: 2.5,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white54,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              tabs: const [Tab(text: 'Match Info'), Tab(text: 'Scorecard'), Tab(text: 'Fantasy Pts')],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _matchInfoTab(),
            _scorecardTab(),
            _fantasyPointsTab(),
          ],
        ),
      ),
      /* floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => EsCreateTeamScreen(matchData: widget.matchData),
        )),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.group_add_rounded, color: Colors.white),
        label: const Text('Create Team', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ), */
    );
  }

  // ── HERO HEADER (OVERFLOW FIXED) ──────────────────────────────────────────
  Widget _buildHeroHeader() {
    final winId = widget.matchData['winning_team_id'];
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFCE404D), Color(0xFF7E0A13)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: 58, bottom: 52, left: 12, right: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: _teamBlock(_teamA, winId, false)),
            _centerBadge(),
            Expanded(child: _teamBlock(_teamB, winId, true)),
          ],
        ),
      ),
    );
  }

  Widget _teamBlock(Map<String, dynamic> team, dynamic winId, bool alignRight) {
    final logo   = team['logo_url']?.toString() ?? '';
    final short  = team['short_name']?.toString() ?? '';
    final scores = team['scores_full']?.toString() ?? '';
    final isWinner = winId != null && winId == team['team_id'];
    final alignment = alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: alignment,
      children: [
        // Logo
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 44, height: 44,
            color: Colors.white.withOpacity(0.15),
            child: logo.isNotEmpty
                ? Image.network(logo, fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(Icons.sports_cricket, color: Colors.white70, size: 24))
                : const Icon(Icons.sports_cricket, color: Colors.white70, size: 24),
          ),
        ),
        const SizedBox(height: 6),
        Text(short,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
          maxLines: 1, overflow: TextOverflow.ellipsis),
        if (scores.isNotEmpty)
          Text(scores,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
            maxLines: 1, overflow: TextOverflow.ellipsis),
        if (isWinner)
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: Colors.amber.shade700, borderRadius: BorderRadius.circular(10)),
            child: const Text('🏆 Won', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
      ],
    );
  }

  Widget _centerBadge() {
    String label = _isLive ? '● LIVE' : _isFinished ? 'FT' : 'VS';
    Color bg = _isLive ? Colors.red : Colors.white24;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(label,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: _isLive ? 12 : 15,
          )),
        if (widget.matchData['format_str'] != null)
          Text(widget.matchData['format_str'].toString(),
            style: const TextStyle(color: Colors.white60, fontSize: 9)),
      ]),
    );
  }

  // ── MATCH INFO TAB ────────────────────────────────────────────────────────
  Widget _matchInfoTab() {
    final comp    = widget.matchData['competition'] as Map<String, dynamic>? ?? {};
    final venue   = widget.matchData['venue'] as Map<String, dynamic>? ?? {};
    final toss    = widget.matchData['toss'] as Map<String, dynamic>? ?? {};
    final note    = widget.matchData['status_note']?.toString() ?? '';
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 100),
      child: Column(children: [
        if (note.isNotEmpty) _infoNote(note),
        _infoCard('Match Details', [
          _infoRow(Icons.tag, 'Match', widget.matchData['subtitle']?.toString() ?? ''),
          _infoRow(Icons.sports_cricket, 'Format', widget.matchData['format_str']?.toString() ?? ''),
          _infoRow(Icons.info_outline, 'Status', widget.matchData['status_str']?.toString() ?? ''),
          _infoRow(Icons.calendar_today, 'Date Start', widget.matchData['date_start_ist']?.toString() ?? ''),
        ]),
        const SizedBox(height: 12),
        _infoCard('Competition', [
          _infoRow(Icons.emoji_events, 'Tournament', comp['title']?.toString() ?? ''),
          _infoRow(Icons.calendar_month, 'Season', comp['season']?.toString() ?? ''),
          _infoRow(Icons.category, 'Category', comp['category']?.toString() ?? ''),
        ]),
        const SizedBox(height: 12),
        _infoCard('Venue', [
          _infoRow(Icons.stadium, 'Ground', venue['name']?.toString() ?? ''),
          _infoRow(Icons.location_city, 'City', venue['location']?.toString() ?? ''),
          _infoRow(Icons.flag, 'Country', venue['country']?.toString() ?? ''),
        ]),
        if (toss.isNotEmpty) ...[
          const SizedBox(height: 12),
          _infoCard('Toss', [_infoRow(Icons.flip, 'Result', toss['text']?.toString() ?? '')]),
        ],
        if ((widget.matchData['umpires'] ?? '').toString().isNotEmpty) ...[
          const SizedBox(height: 12),
          _infoCard('Officials', [
            _infoRow(Icons.person, 'Umpires', widget.matchData['umpires'].toString()),
            if ((widget.matchData['referee'] ?? '').toString().isNotEmpty)
              _infoRow(Icons.person_outline, 'Referee', widget.matchData['referee'].toString()),
          ]),
        ],
      ]),
    );
  }

  Widget _infoNote(String text) => Container(
    width: double.infinity, margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.amber.withOpacity(0.15),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: Colors.amber.withOpacity(0.4)),
    ),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Icon(Icons.info, color: Colors.amber, size: 16),
      const SizedBox(width: 8),
      Expanded(child: Text(text, style: const TextStyle(color: Colors.amber, fontSize: 12))),
    ]),
  );

  Widget _infoCard(String title, List<Widget> items) => Container(
    decoration: BoxDecoration(
      color: const Color(0xFF243052),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
        child: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))),
      Divider(height: 1, color: Colors.white.withOpacity(0.08)),
      ...items,
    ]),
  );

  Widget _infoRow(IconData icon, String label, String val) {
    if (val.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 15, color: AppColors.primary),
        const SizedBox(width: 10),
        SizedBox(width: 80, child: Text(label, style: const TextStyle(color: Colors.white38, fontSize: 12))),
        Expanded(child: Text(val, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13))),
      ]),
    );
  }

  // ── SCORECARD TAB ─────────────────────────────────────────────────────────
  Widget _scorecardTab() {
    if (_loadingScorecard) return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    if (_scorecard == null) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.sports_cricket, size: 60, color: Colors.white12),
        const SizedBox(height: 16),
        const Text('Scorecard', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 8),
        const Text('Load the live scorecard', style: TextStyle(color: Colors.white38)),
        const SizedBox(height: 20),
        ElevatedButton.icon(onPressed: _loadScorecard,
          icon: const Icon(Icons.download_rounded), label: const Text('Load Scorecard'),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white)),
      ]));
    }

    final innings = _scorecard!['innings'] as List<dynamic>? ?? [];
    final hasLive = _liveScore != null && _liveScore!.isNotEmpty;

    if (innings.isEmpty && !hasLive) {
      return const Center(child: Text('No scorecard data yet', style: TextStyle(color: Colors.white38)));
    }

    return RefreshIndicator(
      onRefresh: _loadScorecard,
      color: AppColors.primary,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
        child: Column(children: [
          // Live indicators
          if (_isLive) _liveIndicator(),
          if (_liveScore != null && _liveScore!.isNotEmpty) _liveScoreBlock(_liveScore!),
          ...innings.map((inn) => _inningsBlock(inn as Map<String, dynamic>)),
        ]),
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
      decoration: BoxDecoration(color: const Color(0xFF243052), borderRadius: BorderRadius.circular(14)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        // Live Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [(data['status'] == 3 ? Colors.redAccent : AppColors.primary), AppColors.secondary.withOpacity(0.8)]),
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(14), topRight: Radius.circular(14)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(teamBat, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15))),
              Text('${live['runs'] ?? '0'}/${live['wickets'] ?? '0'}  (${live['overs'] ?? '0'} Ov)',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ]),
            const SizedBox(height: 6),
            Row(children: [
              Text('CRR: ${live['runrate'] ?? '0.00'}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
              if (live['required_runrate'] != null) ...[
                const Spacer(),
                Text('RRR: ${live['required_runrate']}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ]),
            if (statusNote.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(statusNote, style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ]),
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
            child: const Text('RECENT BALLS', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
          ),
          ...comms.take(6).map((c) => _commentaryCard(c as Map<String, dynamic>)),
        ],
      ]),
    );
  }

  Widget _battingRowLive(Map<String, dynamic> b) {
    return Container(
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05)))),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(children: [
        Expanded(child: Text(b['name']?.toString() ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
        _scoreCell(b['runs']?.toString() ?? '0', Colors.white, bold: true),
        _scoreCell(b['balls_faced']?.toString() ?? '0', Colors.white60),
        _scoreCell(b['fours']?.toString() ?? '0', Colors.white60),
        _scoreCell(b['sixes']?.toString() ?? '0', Colors.white60),
        SizedBox(width: 45, child: Text(b['strike_rate']?.toString() ?? '-', style: const TextStyle(color: Colors.white, fontSize: 12), textAlign: TextAlign.right)),
      ]),
    );
  }

  Widget _bowlingRowLive(Map<String, dynamic> b) {
    return Container(
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05)))),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(children: [
        Expanded(child: Text(b['name']?.toString() ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
        _scoreCell(b['overs']?.toString() ?? '0', Colors.white),
        _scoreCell(b['maidens']?.toString() ?? '0', Colors.white60),
        _scoreCell(b['runs_conceded']?.toString() ?? '0', Colors.white),
        _scoreCell(b['wickets']?.toString() ?? '0', AppColors.primary, bold: true),
        SizedBox(width: 45, child: Text(b['econ']?.toString() ?? '-', style: const TextStyle(color: Colors.white, fontSize: 12), textAlign: TextAlign.right)),
      ]),
    );
  }

  Widget _commentaryCard(Map<String, dynamic> c) {
    if (c['event'] == 'overend') {
      return Container(
        padding: const EdgeInsets.all(12),
        width: double.infinity,
        decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.1), border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05)))),
        child: Text(c['commentary']?.toString() ?? 'Over End', style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 12)),
      );
    }
    
    final isWicket = c['event'] == 'wicket';
    final isBoundary = c['score'] == 4 || c['score'] == 6;
    Color ballColor = Colors.grey.shade800;
    Color textColor = Colors.white;

    if (isWicket) {
      ballColor = Colors.redAccent;
    } else if (c['score'] == 6) {
      ballColor = Colors.green;
    } else if (c['score'] == 4) {
      ballColor = Colors.lightBlue;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05)))),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(width: 30, child: Text('${c['over']}.${c['ball']}', style: const TextStyle(color: Colors.white60, fontSize: 11))),
            Container(
              width: 24, height: 24,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(color: ballColor, shape: BoxShape.circle),
              child: Center(child: Text(isWicket ? 'W' : c['score']?.toString() ?? '0', style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 11))),
            ),
          ],
        ),
        Expanded(
          child: Text(c['commentary']?.toString() ?? '', style: TextStyle(color: Colors.grey.shade300, fontSize: 12, height: 1.4)),
        ),
      ]),
    );
  }

  Widget _liveIndicator() => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.red.withOpacity(0.15),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: Colors.red.withOpacity(0.4)),
    ),
    child: Row(children: [
      Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
      const SizedBox(width: 8),
      const Text('LIVE • Pull down to refresh', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 12)),
      const Spacer(),
      GestureDetector(onTap: _loadScorecard,
        child: const Icon(Icons.refresh_rounded, color: Colors.redAccent, size: 18)),
    ]),
  );

  Widget _inningsBlock(Map<String, dynamic> inn) {
    final name   = inn['name']?.toString() ?? '';
    final scores = inn['scores']?.toString() ?? '';
    final overs  = inn['overs']?.toString() ?? '';
    final batters = inn['batting'] as List<dynamic>? ?? [];
    final bowlers = inn['bowling'] as List<dynamic>? ?? [];
    final extras  = inn['extras'] as Map<String, dynamic>? ?? {};

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(color: const Color(0xFF243052), borderRadius: BorderRadius.circular(14)),
      child: Column(children: [
        // Innings header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [AppColors.primary.withOpacity(0.8), AppColors.secondary.withOpacity(0.8)]),
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(14), topRight: Radius.circular(14)),
          ),
          child: Row(children: [
            Expanded(child: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              maxLines: 1, overflow: TextOverflow.ellipsis)),
            Text('$scores${overs.isNotEmpty ? "  ($overs Ov)" : ""}',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          ]),
        ),
        // Batting
        if (batters.isNotEmpty) ...[
          _sectionHeader('BATTING'),
          _battingHeader(),
          ...batters.map((b) => _battingRow(b as Map<String, dynamic>)),
          if (extras.isNotEmpty) _extrasRow(extras),
        ],
        if (bowlers.isNotEmpty) ...[
          _sectionHeader('BOWLING'),
          _bowlingHeader(),
          ...bowlers.map((b) => _bowlingRow(b as Map<String, dynamic>)),
        ],
      ]),
    );
  }

  Widget _sectionHeader(String t) => Container(
    color: const Color(0xFF1B2033),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
    width: double.infinity,
    child: Text(t, style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
  );

  Widget _battingHeader() => Container(
    color: const Color(0xFF1F2845),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
    child: const Row(children: [
      Expanded(child: Text('BATTER', style: TextStyle(color: Colors.white38, fontSize: 10))),
      SizedBox(width: 34, child: Text('R', style: TextStyle(color: Colors.white38, fontSize: 10), textAlign: TextAlign.center)),
      SizedBox(width: 34, child: Text('B', style: TextStyle(color: Colors.white38, fontSize: 10), textAlign: TextAlign.center)),
      SizedBox(width: 30, child: Text('4s', style: TextStyle(color: Colors.white38, fontSize: 10), textAlign: TextAlign.center)),
      SizedBox(width: 30, child: Text('6s', style: TextStyle(color: Colors.white38, fontSize: 10), textAlign: TextAlign.center)),
      SizedBox(width: 40, child: Text('SR', style: TextStyle(color: Colors.white38, fontSize: 10), textAlign: TextAlign.center)),
    ]),
  );

  Widget _battingRow(Map<String, dynamic> b) {
    final name   = b['name']?.toString() ?? b['title']?.toString() ?? '';
    final how    = b['how_out']?.toString() ?? '';
    final notOut = how.isEmpty || how == 'not out' || how == 'playing';
    final runs   = b['runs']?.toString() ?? '0';
    final balls  = b['balls_played']?.toString() ?? '0';
    final fours  = b['fours']?.toString() ?? '0';
    final sixes  = b['sixes']?.toString() ?? '0';
    final sr     = b['strike_rate']?.toString() ?? '-';
    final srVal  = double.tryParse(sr.replaceAll(',', '.')) ?? 0;

    return Container(
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05)))),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Flexible(child: Text(name, style: TextStyle(
              color: notOut ? Colors.white : Colors.white70,
              fontWeight: notOut ? FontWeight.bold : FontWeight.normal,
              fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis)),
            if (notOut) Container(
              margin: const EdgeInsets.only(left: 4),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(color: AppColors.success.withOpacity(0.3), borderRadius: BorderRadius.circular(3)),
              child: const Text('*', style: TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.bold))),
          ]),
          if (how.isNotEmpty && how != 'not out' && how != 'playing')
            Text(how, style: const TextStyle(color: Colors.white24, fontSize: 10),
              maxLines: 1, overflow: TextOverflow.ellipsis),
        ])),
        _scoreCell(runs, notOut ? Colors.white : Colors.white60, bold: true),
        _scoreCell(balls, Colors.white38),
        _scoreCell(fours, Colors.white60),
        _scoreCell(sixes, Colors.white60),
        SizedBox(width: 40, child: Text(sr,
          style: TextStyle(
            color: srVal >= 150 ? Colors.greenAccent : srVal >= 100 ? Colors.white60 : Colors.redAccent,
            fontSize: 11, fontWeight: FontWeight.w600),
          textAlign: TextAlign.center)),
      ]),
    );
  }

  Widget _scoreCell(String val, Color color, {bool bold = false}) =>
      SizedBox(width: val.length > 2 ? 38 : 34,
        child: Text(val, style: TextStyle(color: color, fontSize: 12,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal), textAlign: TextAlign.center));

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
      child: Row(children: [
        Expanded(child: Text('Extras${detail.isNotEmpty ? " ($detail)" : ""}',
          style: const TextStyle(color: Colors.white54, fontSize: 11))),
        Text(total, style: const TextStyle(color: Colors.white54, fontWeight: FontWeight.bold, fontSize: 12)),
      ]),
    );
  }

  Widget _bowlingHeader() => Container(
    color: const Color(0xFF1F2845),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
    child: const Row(children: [
      Expanded(child: Text('BOWLER', style: TextStyle(color: Colors.white38, fontSize: 10))),
      SizedBox(width: 32, child: Text('O', style: TextStyle(color: Colors.white38, fontSize: 10), textAlign: TextAlign.center)),
      SizedBox(width: 32, child: Text('M', style: TextStyle(color: Colors.white38, fontSize: 10), textAlign: TextAlign.center)),
      SizedBox(width: 32, child: Text('R', style: TextStyle(color: Colors.white38, fontSize: 10), textAlign: TextAlign.center)),
      SizedBox(width: 32, child: Text('W', style: TextStyle(color: Colors.white38, fontSize: 10), textAlign: TextAlign.center)),
      SizedBox(width: 40, child: Text('Eco', style: TextStyle(color: Colors.white38, fontSize: 10), textAlign: TextAlign.center)),
    ]),
  );

  Widget _bowlingRow(Map<String, dynamic> b) {
    final name   = b['name']?.toString() ?? b['title']?.toString() ?? '';
    final overs  = b['overs']?.toString() ?? '0';
    final maiden = b['maidens']?.toString() ?? '0';
    final runs   = b['runs_conceded']?.toString() ?? b['runs']?.toString() ?? '0';
    final wkts   = b['wickets']?.toString() ?? '0';
    final econ   = b['econ']?.toString() ?? '-';
    final econVal = double.tryParse(econ.replaceAll(',', '.')) ?? 10.0;
    final hasWkt = (int.tryParse(wkts) ?? 0) > 0;

    return Container(
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05)))),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      child: Row(children: [
        Expanded(child: Text(name, style: TextStyle(
          color: hasWkt ? Colors.white : Colors.white70,
          fontWeight: hasWkt ? FontWeight.bold : FontWeight.normal,
          fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis)),
        _scoreCell(overs, Colors.white54),
        _scoreCell(maiden, Colors.white54),
        _scoreCell(runs, Colors.white60),
        _scoreCell(wkts, hasWkt ? AppColors.success : Colors.white54, bold: hasWkt),
        SizedBox(width: 40, child: Text(econ,
          style: TextStyle(
            color: econVal <= 6 ? Colors.greenAccent : econVal <= 9 ? Colors.white60 : Colors.redAccent,
            fontSize: 11, fontWeight: FontWeight.w600),
          textAlign: TextAlign.center)),
      ]),
    );
  }

  // ── FANTASY POINTS TAB ───────────────────────────────────────────────────
  Widget _fantasyPointsTab() {
    if (_loadingPoints) return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    if (_fantasyPoints == null) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.star_border_rounded, size: 60, color: Colors.white12),
        const SizedBox(height: 16),
        const Text('Fantasy Points', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 8),
        const Text('View fantasy points for each player', style: TextStyle(color: Colors.white38)),
        const SizedBox(height: 20),
        ElevatedButton.icon(onPressed: _loadPoints,
          icon: const Icon(Icons.download_rounded), label: const Text('Load Points'),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white)),
      ]));
    }

    final players = (_fantasyPoints!['players'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
    if (players.isEmpty) {
      return const Center(child: Text('No fantasy data yet', style: TextStyle(color: Colors.white38)));
    }

    // Sort by points desc
    final sorted = [...players]..sort((a, b) {
      final pa = (a['fantasy_player_rating'] as num?)?.toDouble() ?? 0;
      final pb = (b['fantasy_player_rating'] as num?)?.toDouble() ?? 0;
      return pb.compareTo(pa);
    });

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
      itemCount: sorted.length,
      itemBuilder: (_, i) {
        final p = sorted[i];
        final pts = (p['fantasy_player_rating'] as num?)?.toDouble() ?? 0;
        final name = p['name']?.toString() ?? p['title']?.toString() ?? '';
        final role = p['role']?.toString() ?? '';
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: const Color(0xFF243052),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: i == 0 ? AppColors.accent.withOpacity(0.5) : Colors.transparent),
          ),
          child: Row(children: [
            Container(width: 24, child: Text('${i+1}', style: TextStyle(
              color: i < 3 ? AppColors.accent : Colors.white38,
              fontWeight: i < 3 ? FontWeight.bold : FontWeight.normal, fontSize: 12))),
            const SizedBox(width: 10),
            CircleAvatar(backgroundColor: AppColors.primary.withOpacity(0.2), radius: 18,
              child: Text(name.isNotEmpty ? name[0] : '?',
                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold))),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              Text(role.toUpperCase(), style: const TextStyle(color: Colors.white38, fontSize: 10)),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: pts >= 50 ? AppColors.success.withOpacity(0.2) : AppColors.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('${pts.toStringAsFixed(1)} pts',
                style: TextStyle(
                  color: pts >= 50 ? AppColors.success : AppColors.primary,
                  fontWeight: FontWeight.bold, fontSize: 13))),
          ]),
        );
      },
    );
  }
}
