import 'package:flutter/material.dart';
import 'package:fantasy_crick/core/constants/app_colors.dart';
import 'package:fantasy_crick/core/services/entity_sport_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  MODEL
// ─────────────────────────────────────────────────────────────────────────────
class _Player {
  final String id;
  final String name;
  final String shortName;
  final String role;        // WK | BAT | AR | BOWL
  final double credits;
  final String imageUrl;
  final String teamShort;
  final double rating;
  final String battingStyle;
  final String bowlingStyle;
  // filled from scorecard
  String runs = '', balls = '', strikeRate = '', wickets = '', economy = '';

  _Player({
    required this.id, required this.name, required this.shortName,
    required this.role, required this.credits, required this.imageUrl,
    required this.teamShort, required this.rating,
    required this.battingStyle, required this.bowlingStyle,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
//  SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class EsCreateTeamScreen extends StatefulWidget {
  final Map<String, dynamic>? matchData;
  const EsCreateTeamScreen({super.key, this.matchData});

  @override
  State<EsCreateTeamScreen> createState() => _EsCreateTeamScreenState();
}

class _EsCreateTeamScreenState extends State<EsCreateTeamScreen>
    with SingleTickerProviderStateMixin {

  // ── state ──────────────────────────────────────────────────────────────────
  bool _loading = true;
  String? _error;
  List<_Player> _players = [];
  final Set<String> _selected = {};
  String? _captainId;
  String? _vcId;
  bool _showCaptainScreen = false;
  int _tabIndex = 0;          // 0=ALL 1=WK 2=BAT 3=AR 4=BOWL
  late TabController _tabCtrl;

  static const double _totalCredits = 100.0;
  static const List<String> _roles = ['ALL', 'WK', 'BAT', 'AR', 'BOWL'];
  static const Map<String, String> _roleLabels = {
    'ALL': 'All', 'WK': 'Keeper', 'BAT': 'Batsman', 'AR': 'All-Rounder', 'BOWL': 'Bowler'
  };
  static const Map<String, int> _maxRole = {'WK': 4, 'BAT': 6, 'AR': 4, 'BOWL': 6};
  static const Map<String, int> _minRole = {'WK': 1, 'BAT': 3, 'AR': 1, 'BOWL': 3};
  static const Map<String, Color> _roleClr = {
    'WK':   Color(0xFF8E24AA),
    'BAT':  Color(0xFF1976D2),
    'AR':   Color(0xFF388E3C),
    'BOWL': Color(0xFFD32F2F),
  };

  // ── derived ────────────────────────────────────────────────────────────────
  List<_Player> get _selectedPlayers =>
      _players.where((p) => _selected.contains(p.id)).toList();

  double get _usedCredits => _selectedPlayers.fold(0.0, (s, p) => s + p.credits);
  double get _remaining   => _totalCredits - _usedCredits;
  int    get _count       => _selected.length;
  int    _rc(String r)    => _selectedPlayers.where((p) => p.role == r).length;

  String get _filterRole => _roles[_tabIndex];

  List<_Player> get _filtered =>
      _filterRole == 'ALL' ? _players : _players.where((p) => p.role == _filterRole).toList();

  bool _canAdd(_Player p) {
    if (_selected.contains(p.id)) return false;
    if (_count >= 11) return false;
    if (_remaining < p.credits - 0.001) return false;
    return _rc(p.role) < (_maxRole[p.role] ?? 6);
  }

  bool get _canProceed =>
      _count == 11 &&
      _minRole.entries.every((e) => _rc(e.key) >= e.value);

  // ── init ───────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _roles.length, vsync: this)
      ..addListener(() { if (!_tabCtrl.indexIsChanging) setState(() => _tabIndex = _tabCtrl.index); });
    _loadSquad();
  }

  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  // ── load ───────────────────────────────────────────────────────────────────
  Future<void> _loadSquad() async {
    setState(() { _loading = true; _error = null; });
    final matchId  = widget.matchData?['match_id'] as int?;
    final teamaRaw = widget.matchData?['teama'] as Map<String, dynamic>?;
    final teambRaw = widget.matchData?['teamb'] as Map<String, dynamic>?;
    final tidA = teamaRaw?['team_id'] as int?;
    final tidB = teambRaw?['team_id'] as int?;
    final shortA = teamaRaw?['short_name']?.toString() ?? 'TM A';
    final shortB = teambRaw?['short_name']?.toString() ?? 'TM B';

    if (matchId == null && tidA == null && tidB == null) {
      _buildDemo(shortA, shortB);
      return;
    }

    try {
      // 1. Try squad API (has match-specific data)
      final Map<String, dynamic> squadData =
          matchId != null ? await EntitySportService.getFantasySquad(matchId) : {};

      // 2. Scorecard for stats
      final Map<String, dynamic> scorecardData =
          matchId != null ? await EntitySportService.getScorecard(matchId) : {};
      final statsMap = <String, Map<String, String>>{};
      _parseScorecard(scorecardData, statsMap);

      List<_Player> players = _parseSquad(squadData, shortA, shortB, statsMap);

      // 3. If squad is empty, fall back to Teams Player API
      if (players.isEmpty) {
        final futures = <Future<List<Map<String, dynamic>>>>[];
        if (tidA != null) futures.add(EntitySportService.getTeamPlayers(tidA));
        if (tidB != null) futures.add(EntitySportService.getTeamPlayers(tidB));
        final results = await Future.wait(futures);
        int idx = 0;
        for (final tShort in [shortA, shortB].take(results.length)) {
          for (final p in results[idx]) {
            players.add(_fromRaw(p, tShort, statsMap));
          }
          idx++;
        }
      }

      if (!mounted) return;
      if (players.isEmpty) { _buildDemo(shortA, shortB); return; }
      setState(() { _players = players; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      _buildDemo(shortA, shortB);
    }
  }

  List<_Player> _parseSquad(
    Map<String, dynamic> squadData, String shortA, String shortB,
    Map<String, Map<String, String>> statsMap,
  ) {
    final out = <_Player>[];
    for (final entry in [
      ['teama', shortA],
      ['teamb', shortB],
    ]) {
      final team  = squadData[entry[0]] as Map<String, dynamic>?;
      final tShort = entry[1];
      if (team == null) continue;
      final squad = team['squad'] as List<dynamic>? ?? [];
      for (final p in squad) {
        out.add(_fromRaw(p as Map<String, dynamic>, tShort, statsMap));
      }
    }
    return out;
  }

  _Player _fromRaw(
    Map<String, dynamic> p, String teamShort,
    Map<String, Map<String, String>> statsMap,
  ) {
    final pid   = p['pid']?.toString() ?? UniqueKey().toString();
    final name  = p['title']?.toString() ?? p['name']?.toString() ?? 'Unknown';
    final role  = _mapRole(p['role']?.toString() ?? p['playing_role']?.toString() ?? '');
    final cred  = (p['fantasy_player_rating'] as num?)?.toDouble() ?? 8.0;
    final pl = _Player(
      id: pid, name: name, shortName: _short(name), role: role,
      credits: cred.clamp(6.0, 12.0),
      imageUrl: p['thumb_url']?.toString() ?? p['logo_url']?.toString() ?? '',
      teamShort: teamShort,
      rating:  cred,
      battingStyle:  p['batting_style']?.toString()  ?? '',
      bowlingStyle:  p['bowling_style']?.toString()  ?? '',
    );
    final st = statsMap[pid] ?? statsMap[name];
    if (st != null) {
      pl.runs       = st['runs']  ?? '';
      pl.balls      = st['balls'] ?? '';
      pl.strikeRate = st['sr']    ?? '';
      pl.wickets    = st['wkts']  ?? '';
      pl.economy    = st['econ']  ?? '';
    }
    return pl;
  }

  void _parseScorecard(Map<String, dynamic> sc, Map<String, Map<String, String>> out) {
    try {
      final innings = sc['innings'] as List<dynamic>? ?? [];
      for (final inn in innings) {
        final im = inn as Map<String, dynamic>;
        for (final b in (im['batting'] as List<dynamic>? ?? [])) {
          final bm = b as Map<String, dynamic>;
          final k = bm['pid']?.toString() ?? bm['name']?.toString() ?? '';
          if (k.isEmpty) continue;
          out[k] = {
            ...(out[k] ?? {}),
            'runs': bm['runs']?.toString() ?? '',
            'balls': bm['balls_played']?.toString() ?? '',
            'sr': bm['strike_rate']?.toString() ?? '',
          };
        }
        for (final bw in (im['bowling'] as List<dynamic>? ?? [])) {
          final bm = bw as Map<String, dynamic>;
          final k = bm['pid']?.toString() ?? bm['name']?.toString() ?? '';
          if (k.isEmpty) continue;
          out[k] = {
            ...(out[k] ?? {}),
            'wkts': bm['wickets']?.toString() ?? '',
            'econ': bm['econ']?.toString() ?? '',
          };
        }
      }
    } catch (_) {}
  }

  void _buildDemo(String shortA, String shortB) {
    if (!mounted) return;
    final roleSeq = ['WK','BAT','BAT','BAT','BAT','AR','AR','BOWL','BOWL','BOWL','BOWL'];
    final ps = <_Player>[];
    for (int i = 0; i < roleSeq.length; i++) {
      ps.add(_Player(id: 'a$i', name: '$shortA Player ${i+1}', shortName: '${shortA[0]}. Player${i+1}',
          role: roleSeq[i], credits: (8.0 + i * 0.2).clamp(8.0, 10.0), imageUrl: '', teamShort: shortA,
          rating: 8.0, battingStyle: 'Right Hand Bat', bowlingStyle: ''));
      ps.add(_Player(id: 'b$i', name: '$shortB Player ${i+1}', shortName: '${shortB[0]}. Player${i+1}',
          role: roleSeq[i], credits: (8.0 + i * 0.2).clamp(8.0, 10.0), imageUrl: '', teamShort: shortB,
          rating: 8.0, battingStyle: 'Right Hand Bat', bowlingStyle: ''));
    }
    setState(() { _players = ps; _loading = false; _error = null; });
  }

  // ── helpers ────────────────────────────────────────────────────────────────
  String _mapRole(String r) {
    switch (r.toLowerCase()) {
      case 'wk': case 'keeper': case 'wicket-keeper': case 'wicketkeeper': return 'WK';
      case 'bat': case 'batsman': case 'batter': return 'BAT';
      case 'ar': case 'all': case 'all-rounder': case 'allrounder': return 'AR';
      case 'bowl': case 'bowler': return 'BOWL';
      default: return 'BAT';
    }
  }

  String _short(String name) {
    final p = name.trim().split(' ');
    return p.length == 1 ? name : '${p.first[0]}. ${p.last}';
  }

  void _toggle(_Player p) {
    if (_selected.contains(p.id)) {
      setState(() {
        _selected.remove(p.id);
        if (_captainId == p.id) _captainId = null;
        if (_vcId == p.id) _vcId = null;
      });
      return;
    }
    if (_count >= 11)             { _snack('Max 11 players'); return; }
    if (_remaining < p.credits - 0.001) { _snack('Not enough credits'); return; }
    if (!_canAdd(p))              { _snack('Role limit reached (${_roleLabels[p.role]})'); return; }
    setState(() => _selected.add(p.id));
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg), backgroundColor: AppColors.primary,
      duration: const Duration(seconds: 2), behavior: SnackBarBehavior.floating,
    ));
  }

  String _getTitle() {
    final a = (widget.matchData?['teama'] as Map?)?.tryString('short_name') ?? 'Team A';
    final b = (widget.matchData?['teamb'] as Map?)?.tryString('short_name') ?? 'Team B';
    return '$a vs $b';
  }

  // ── build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_loading) return _loader();
    if (_error != null && _players.isEmpty) return _errView();
    if (_showCaptainScreen) return _captainScreen();
    return _selectScreen();
  }

  // ── LOADER ─────────────────────────────────────────────────────────────────
  Widget _loader() => Scaffold(
    backgroundColor: Colors.white,
    body: SafeArea(child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      const CircularProgressIndicator(color: AppColors.primary, strokeWidth: 3),
      const SizedBox(height: 20),
      Text('Loading Squad…', style: TextStyle(color: Colors.grey.shade600, fontSize: 15)),
    ]))),
  );

  Widget _errView() => Scaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(backgroundColor: Colors.white, iconTheme: const IconThemeData(color: Colors.black),
      title: const Text('Create Team', style: TextStyle(color: Colors.black))),
    body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.error_outline, size: 60, color: Colors.grey),
      const SizedBox(height: 16),
      Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600)),
      const SizedBox(height: 20),
      ElevatedButton.icon(onPressed: _loadSquad, icon: const Icon(Icons.refresh), label: const Text('Retry'),
        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white)),
    ])),
  );

  // ─────────────────────────────────────────────────────────────────────────
  //  SELECT SCREEN
  // ─────────────────────────────────────────────────────────────────────────
  Widget _selectScreen() {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        bottom: false,
        child: Column(children: [
          _selectHeader(),
          _infoBar(),
          _roleTabs(),
          Expanded(child: _playerList()),
          _bottomBar(),
        ]),
      ),
    );
  }

  Widget _selectHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFFCE404D), Color(0xFF7E0A13)],
          begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      child: Column(children: [
        // Title Row
        Row(children: [
          GestureDetector(onTap: () => Navigator.pop(context),
            child: Container(padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.arrow_back, color: Colors.white, size: 20))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_getTitle(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
            const Text('Select 11 Players', style: TextStyle(color: Colors.white60, fontSize: 11)),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(_remaining.toStringAsFixed(1),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22)),
            const Text('Credits Left', style: TextStyle(color: Colors.white60, fontSize: 10)),
          ]),
        ]),
        const SizedBox(height: 12),
        // Credits progress bar — use LayoutBuilder to avoid overflow
        LayoutBuilder(builder: (ctx, constraints) {
          final fraction = (_usedCredits / _totalCredits).clamp(0.0, 1.0);
          return Stack(children: [
            Container(height: 4, width: double.infinity,
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
            Container(height: 4, width: constraints.maxWidth * fraction,
              decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(2))),
          ]);
        }),
        const SizedBox(height: 12),
        // Role badges
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: ['WK','BAT','AR','BOWL'].map((r) => _roleBadge(r)).toList()),
      ]),
    );
  }

  Widget _roleBadge(String role) {
    final count = _rc(role);
    final color = _roleClr[role]!;
    final full  = count >= (_maxRole[role] ?? 6);
    return Column(children: [
      AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: count > 0 ? color : Colors.white12,
          shape: BoxShape.circle,
          border: Border.all(color: full ? AppColors.accent : color.withOpacity(0.3), width: 1.5),
        ),
        child: Center(child: Text('$count',
          style: TextStyle(color: count > 0 ? Colors.white : Colors.white38,
            fontWeight: FontWeight.bold, fontSize: 15))),
      ),
      const SizedBox(height: 4),
      Text(role, style: const TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.bold)),
      Text('${_minRole[role]}-${_maxRole[role]}', style: const TextStyle(color: Colors.white30, fontSize: 8)),
    ]);
  }

  Widget _infoBar() => Container(
    color: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
    child: Row(children: [
      Icon(Icons.info_outline, color: Colors.grey.shade500, size: 14),
      const SizedBox(width: 6),
      Expanded(child: Text('Max 7 players from one team  •  $_count/11',
        style: TextStyle(color: Colors.grey.shade600, fontSize: 12))),
      Text('${_usedCredits.toStringAsFixed(1)}/$_totalCredits CR',
        style: const TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.bold)),
    ]),
  );

  Widget _roleTabs() => Container(
    color: Colors.white,
    child: TabBar(
      controller: _tabCtrl,
      isScrollable: false,
      indicatorColor: AppColors.primary,
      indicatorWeight: 2.5,
      labelColor: AppColors.primary,
      unselectedLabelColor: Colors.grey.shade600,
      labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 12),
      tabs: _roles.map((r) {
        final cnt = r == 'ALL' ? _players.length : _players.where((p) => p.role == r).length;
        return Tab(child: Text('${_roleLabels[r]}\n($cnt)', textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 10)));
      }).toList(),
    ),
  );

  Widget _playerList() {
    final list  = _filtered;
    final teams = list.map((p) => p.teamShort).toSet().toList();

    return Container(
      color: Colors.white,
      child: list.isEmpty
          ? _emptyState()
          : ListView(children: [
              _colHeader(),
              for (final team in teams) ...[
                _teamDivider(team),
                ...list.where((p) => p.teamShort == team).map(_playerTile),
              ],
              const SizedBox(height: 80),
            ]),
    );
  }

  Widget _emptyState() => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Icon(Icons.sports_cricket, size: 48, color: Colors.grey.shade300),
    const SizedBox(height: 12),
    Text('No players found', style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
  ]));

  Widget _colHeader() => Container(
    color: Colors.grey.shade100,
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
    child: Row(children: [
      const SizedBox(width: 50),
      Expanded(child: Text('PLAYER', style: TextStyle(color: Colors.grey.shade600, fontSize: 11, fontWeight: FontWeight.bold))),
      SizedBox(width: 90, child: Text('STATS', style: TextStyle(color: Colors.grey.shade600, fontSize: 11, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
      SizedBox(width: 50, child: Text('CREDITS', style: TextStyle(color: Colors.grey.shade600, fontSize: 11, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
      const SizedBox(width: 36),
    ]),
  );

  Widget _teamDivider(String team) => Container(
    color: Colors.grey.shade200,
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
    child: Text(team, style: TextStyle(color: Colors.grey.shade800, fontWeight: FontWeight.bold, fontSize: 13)),
  );

  Widget _playerTile(_Player p) {
    final sel   = _selected.contains(p.id);
    final isC   = _captainId == p.id;
    final isVC  = _vcId == p.id;
    final canAdd = _canAdd(p) || sel;
    final clr   = _roleClr[p.role] ?? AppColors.primary;

    return GestureDetector(
      onTap: () => _toggle(p),
      child: Container(
        decoration: BoxDecoration(
          color: sel ? Colors.green.shade50 : Colors.white,
          border: Border(
            left: BorderSide(color: sel ? Colors.green : Colors.transparent, width: 3),
            bottom: BorderSide(color: Colors.grey.shade200),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(children: [
          // Avatar
          Stack(clipBehavior: Clip.none, children: [
            _avatar(p.imageUrl, p.name, clr, 44),
            // Role badge
            Positioned(bottom: -5, left: 0, right: 0,
              child: Center(child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(color: clr, borderRadius: BorderRadius.circular(3)),
                child: Text(p.role, style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
              ))),
            if (isC) Positioned(top: -4, right: -4, child: _badge('C', Colors.redAccent)),
            if (isVC) Positioned(top: -4, right: -4, child: _badge('VC', Colors.blue)),
          ]),
          const SizedBox(width: 14),
          // Name + style
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(p.shortName,
              style: TextStyle(color: canAdd ? Colors.black : Colors.grey.shade400,
                fontWeight: FontWeight.bold, fontSize: 14),
              maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(p.teamShort, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            if (p.battingStyle.isNotEmpty)
              Text(p.battingStyle, style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ])),
          // Stats
          SizedBox(width: 90, child: _statsSection(p)),
          // Credits
          SizedBox(width: 50, child: Text(p.credits.toStringAsFixed(1),
            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14),
            textAlign: TextAlign.center)),
          // Toggle
          SizedBox(width: 36, child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 28, height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: sel ? Colors.green : canAdd ? AppColors.primary : Colors.grey.shade300,
              ),
              child: Icon(sel ? Icons.check : Icons.add, color: Colors.white, size: 16),
            ),
          )),
        ]),
      ),
    );
  }

  Widget _statsSection(_Player p) {
    if (p.role == 'BOWL' && p.wickets.isNotEmpty) {
      return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.center, children: [
        _stat('${p.wickets}W', Colors.orange.shade800),
        if (p.economy.isNotEmpty) _stat('Eco ${p.economy}', Colors.orange.shade700),
      ]);
    }
    if (p.runs.isNotEmpty) {
      return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.center, children: [
        _stat('${p.runs}${p.balls.isNotEmpty ? " (${p.balls})" : ""}', Colors.blue.shade800),
        if (p.strikeRate.isNotEmpty) _stat('SR ${p.strikeRate}', Colors.green.shade800),
      ]);
    }
    return Text('${p.rating.toStringAsFixed(1)} pts',
      style: TextStyle(color: Colors.grey.shade500, fontSize: 12), textAlign: TextAlign.center);
  }

  Widget _stat(String text, Color color) => Text(text,
    style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
    textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis);

  Widget _bottomBar() => Container(
    padding: EdgeInsets.only(left: 16, right: 16, top: 12,
      bottom: MediaQuery.of(context).padding.bottom + 12),
    decoration: BoxDecoration(color: Colors.white,
      border: Border(top: BorderSide(color: Colors.grey.shade200)),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, -4))]),
    child: Row(children: [
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('$_count / 11', style: const TextStyle(color: Colors.black,
          fontWeight: FontWeight.bold, fontSize: 18)),
        Text('Players', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
      ]),
      const SizedBox(width: 16),
      // Mini role breakdown
      Expanded(child: Row(mainAxisAlignment: MainAxisAlignment.center,
        children: ['WK','BAT','AR','BOWL'].map((r) {
          final c = _rc(r);
          final clr = _roleClr[r]!;
          return Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: Column(children: [
            Text('$c', style: TextStyle(color: c > 0 ? clr : Colors.grey.shade400, fontWeight: FontWeight.bold, fontSize: 15)),
            Text(r, style: TextStyle(color: Colors.grey.shade500, fontSize: 10)),
          ]));
        }).toList())),
      GestureDetector(
        onTap: _canProceed ? () => setState(() => _showCaptainScreen = true) : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          decoration: BoxDecoration(
            gradient: _canProceed
                ? const LinearGradient(colors: [AppColors.primary, AppColors.secondary])
                : LinearGradient(colors: [Colors.grey.shade400, Colors.grey.shade300]),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Text(
            _canProceed ? 'Next →' : 'Select ${11 - _count} more',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
        ),
      ),
    ]),
  );

  // ─────────────────────────────────────────────────────────────────────────
  //  CAPTAIN / VC SCREEN
  // ─────────────────────────────────────────────────────────────────────────
  Widget _captainScreen() => Scaffold(
    backgroundColor: Colors.grey[50],
    body: SafeArea(bottom: false, child: Column(children: [
      _captainHeader(),
      Container(padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Row(children: [
          Icon(Icons.info_outline, color: Colors.grey.shade600, size: 15),
          const SizedBox(width: 6),
          Text('C gets 2x pts  •  VC gets 1.5x pts',
            style: TextStyle(color: Colors.grey.shade700, fontSize: 13, fontWeight: FontWeight.w600)),
        ])),
      Expanded(child: ListView(children: [
        ..._selectedPlayers.map(_captainTile),
        const SizedBox(height: 100),
      ])),
      _captainBottomBar(),
    ])),
  );

  Widget _captainHeader() => Container(
    padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
    decoration: const BoxDecoration(gradient: LinearGradient(
      colors: [Color(0xFF1B5E20), Color(0xFF388E3C)],
      begin: Alignment.topLeft, end: Alignment.bottomRight)),
    child: Row(children: [
      GestureDetector(onTap: () => setState(() => _showCaptainScreen = false),
        child: Container(padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.arrow_back, color: Colors.white, size: 20))),
      const SizedBox(width: 12),
      const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Choose Captain & VC', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        Text('Select from your 11 players', style: TextStyle(color: Colors.white60, fontSize: 11)),
      ])),
      Row(children: [_badge('C', Colors.redAccent), const SizedBox(width: 8), _badge('VC', Colors.blue)]),
    ]),
  );

  Widget _captainTile(_Player p) {
    final isC   = _captainId == p.id;
    final isVC  = _vcId == p.id;
    final clr   = _roleClr[p.role] ?? AppColors.primary;

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 6, 14, 4),
      decoration: BoxDecoration(
        color: isC ? Colors.red.shade50 : isVC ? Colors.blue.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isC ? Colors.redAccent : isVC ? Colors.blue : Colors.grey.shade200,
          width: isC || isVC ? 1.5 : 1,
        ),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Padding(padding: const EdgeInsets.all(12), child: Row(children: [
        // Avatar
        Stack(clipBehavior: Clip.none, children: [
          _avatar(p.imageUrl, p.name, clr, 48),
          if (isC)  Positioned(top: -5, right: -5, child: _badge('C',  Colors.redAccent)),
          if (isVC) Positioned(top: -5, right: -5, child: _badge('VC', Colors.blue)),
        ]),
        const SizedBox(width: 14),
        // Info
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(p.name, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15),
            maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Wrap(spacing: 8, children: [
            _pill(p.role, clr),
            _pill(p.teamShort, Colors.grey.shade600),
            _pill('${p.credits.toStringAsFixed(1)} CR', Colors.black87),
          ]),
          if (p.runs.isNotEmpty || p.wickets.isNotEmpty)
            Padding(padding: const EdgeInsets.only(top: 6), child: Wrap(spacing: 12, children: [
              if (p.runs.isNotEmpty) Text('${p.runs} runs${p.balls.isNotEmpty ? " (${p.balls}b)" : ""}  SR:${p.strikeRate}',
                style: TextStyle(color: Colors.blue.shade800, fontSize: 11, fontWeight: FontWeight.bold)),
              if (p.wickets.isNotEmpty) Text('${p.wickets}W  Eco:${p.economy}',
                style: TextStyle(color: Colors.orange.shade800, fontSize: 11, fontWeight: FontWeight.bold)),
            ])),
        ])),
        const SizedBox(width: 12),
        // C / VC buttons
        Column(children: [
          _cvBtn('C', isC, Colors.redAccent, () => setState(() {
            if (isC) { _captainId = null; }
            else { if (_vcId == p.id) _vcId = null; _captainId = p.id; }
          })),
          const SizedBox(height: 8),
          _cvBtn('VC', isVC, Colors.blue, () => setState(() {
            if (isVC) { _vcId = null; }
            else { if (_captainId == p.id) _captainId = null; _vcId = p.id; }
          })),
        ]),
      ])),
    );
  }

  Widget _pill(String text, Color bg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(color: bg.withOpacity(0.12), borderRadius: BorderRadius.circular(5)),
    child: Text(text, style: TextStyle(color: bg == Colors.grey.shade600 ? Colors.grey.shade800 : bg, fontSize: 10, fontWeight: FontWeight.bold)),
  );

  Widget _cvBtn(String label, bool active, Color color, VoidCallback fn) => GestureDetector(
    onTap: fn,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 44, height: 32,
      decoration: BoxDecoration(
        color:  active ? color : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: active ? color : Colors.grey.shade300, width: 1.5),
      ),
      child: Center(child: Text(label,
        style: TextStyle(color: active ? Colors.white : Colors.grey.shade600, fontWeight: FontWeight.bold, fontSize: 13))),
    ),
  );

  Widget _captainBottomBar() {
    final ready = _captainId != null && _vcId != null;
    String cName = _captainId != null
        ? _short(_players.firstWhere((p) => p.id == _captainId, orElse: () => _players.first).name)
        : 'Not selected';
    String vName = _vcId != null
        ? _short(_players.firstWhere((p) => p.id == _vcId, orElse: () => _players.first).name)
        : 'Not selected';

    return Container(
      padding: EdgeInsets.only(left: 16, right: 16, top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, -4))]),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            _badge('C', Colors.redAccent), const SizedBox(width: 8),
            Text(cName, style: TextStyle(color: _captainId != null ? Colors.redAccent : Colors.grey.shade400,
              fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
          ]),
          const SizedBox(height: 6),
          Row(children: [
            _badge('VC', Colors.blue), const SizedBox(width: 8),
            Text(vName, style: TextStyle(color: _vcId != null ? Colors.blue : Colors.grey.shade400,
              fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
          ]),
        ])),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: ready ? _submit : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            decoration: BoxDecoration(
              gradient: ready
                  ? const LinearGradient(colors: [Color(0xFF1B5E20), Color(0xFF43A047)])
                  : LinearGradient(colors: [Colors.grey.shade400, Colors.grey.shade300]),
              borderRadius: BorderRadius.circular(28),
            ),
            child: const Text('Create Team 🏏',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
          ),
        ),
      ]),
    );
  }

  void _submit() {
    final cap = _players.firstWhere((p) => p.id == _captainId);
    final vc  = _players.firstWhere((p) => p.id == _vcId);
    showDialog(
      context: context, barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.emoji_events_rounded, size: 64, color: Colors.orange),
          const SizedBox(height: 16),
          const Text('Team Created! 🎉',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 22)),
          const SizedBox(height: 16),
          Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(
            color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200)),
            child: Column(children: [
              _row('Players',       '$_count/11'),
              _row('Credits Used',  '${_usedCredits.toStringAsFixed(1)} / ${_totalCredits.toStringAsFixed(0)}'),
              _row('Captain (2x)',  cap.name),
              _row('Vice-Capt (1.5x)', vc.name),
            ]),
          ),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: () { Navigator.pop(context); Navigator.pop(context); },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('Awesome!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          )),
        ])),
      ),
    );
  }

  Widget _row(String l, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(children: [
      Text(l, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
      const Spacer(),
      Text(v, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13)),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  SHARED HELPERS
// ─────────────────────────────────────────────────────────────────────────────
Widget _avatar(String url, String name, Color clr, double size) => Container(
  width: size, height: size,
  decoration: BoxDecoration(
    shape: BoxShape.circle,
    color: clr.withOpacity(0.15),
    border: Border.all(color: clr.withOpacity(0.4), width: 1.5),
  ),
  child: ClipOval(
    child: url.isNotEmpty
        ? Image.network(url, fit: BoxFit.cover, width: size, height: size,
            errorBuilder: (_, __, ___) => _initial(name, clr, size))
        : _initial(name, clr, size),
  ),
);

Widget _initial(String name, Color clr, double size) => Center(child: Text(
  name.isNotEmpty ? name[0].toUpperCase() : '?',
  style: TextStyle(color: clr, fontWeight: FontWeight.bold, fontSize: size * 0.38),
));

Widget _badge(String label, Color color) => Container(
  padding: EdgeInsets.symmetric(horizontal: label.length == 1 ? 6 : 5, vertical: 2),
  decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
  child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
);

extension _MapExt on Map {
  String? tryString(String key) => this[key]?.toString();
}
