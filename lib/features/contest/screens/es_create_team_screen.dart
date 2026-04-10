import 'package:flutter/material.dart';
import 'package:fantasy_crick/core/constants/app_colors.dart';
import 'package:fantasy_crick/core/services/entity_sport_service.dart';
import 'package:fantasy_crick/core/services/location_service.dart';
import 'package:fantasy_crick/core/services/teams_service.dart';
import 'package:fantasy_crick/core/services/player_service.dart';
import 'package:fantasy_crick/core/services/contest_service.dart';
import 'package:fantasy_crick/core/services/user_profile_service.dart';
import 'package:fantasy_crick/models/contest_model.dart';
import 'package:fantasy_crick/main.dart';
import 'package:cached_network_image/cached_network_image.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  MODEL
// ─────────────────────────────────────────────────────────────────────────────
class _Player {
  final String id;
  final String name;
  final String shortName;
  final String role; // WK | BAT | AR | BOWL
  final double credits;
  final String imageUrl;
  final String teamShort;
  final double rating;
  final String battingStyle;
  final String bowlingStyle;
  String runs = '', balls = '', strikeRate = '', wickets = '', economy = '';
  final bool isPlaying;

  _Player({
    required this.id,
    required this.name,
    required this.shortName,
    required this.role,
    required this.credits,
    required this.imageUrl,
    required this.teamShort,
    required this.rating,
    required this.battingStyle,
    required this.bowlingStyle,
    this.isPlaying = false,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
//  SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class EsCreateTeamScreen extends StatefulWidget {
  final Map<String, dynamic>? matchData;
  final ContestModel? contest;
  final Map<String, dynamic>? existingTeam; // For edit mode
  const EsCreateTeamScreen({super.key, this.matchData, this.contest, this.existingTeam});

  @override
  State<EsCreateTeamScreen> createState() => _EsCreateTeamScreenState();
}

class _EsCreateTeamScreenState extends State<EsCreateTeamScreen>
    with SingleTickerProviderStateMixin {
  // ── state ──────────────────────────────────────────────────────────────────
  bool _loading = true;
  bool _submitting = false;
  String? _error;
  int? _matchRequestId; 
  Map<String, dynamic>? _matchInfo; 
  List<_Player> _players = [];
  final Set<String> _selected = {};
  String? _captainId;
  String? _vcId;
  bool _showCaptainScreen = false;
  int _tabIndex = 0; // 0=WK 1=BAT 2=AR 3=BOWL
  late TabController _tabCtrl;
  final TextEditingController _teamNameCtrl = TextEditingController(
    text: 'Team 1',
  );
  String _currencySymbol = '₹';
  String _currencyCode = 'INR';
  bool get _isEditMode => widget.existingTeam != null;
  int? _editTeamId;

  static const double _totalCredits = 100.0;
  static const List<String> _roles = ['WK', 'BAT', 'AR', 'BOWL'];
  static const Map<String, String> _roleLabels = {
    'WK': 'Keeper',
    'BAT': 'Batsman',
    'AR': 'All-Rounder',
    'BOWL': 'Bowler',
  };
  static const Map<String, int> _maxRole = {
    'WK': 4,
    'BAT': 6,
    'AR': 4,
    'BOWL': 6,
  };
  static const Map<String, int> _minRole = {
    'WK': 1,
    'BAT': 3,
    'AR': 1,
    'BOWL': 3,
  };

  // ── derived ────────────────────────────────────────────────────────────────
  List<_Player> get _selectedPlayers =>
      _players.where((p) => _selected.contains(p.id)).toList();

  double get _usedCredits =>
      _selectedPlayers.fold(0.0, (s, p) => s + p.credits);
  double get _remaining => _totalCredits - _usedCredits;
  int get _count => _selected.length;
  int _rc(String r) => _selectedPlayers.where((p) => p.role == r).length;

  String get _filterRole => _roles[_tabIndex];

  List<_Player> get _playingFiltered {
    final playing = _players.where((p) => p.isPlaying).toList();
    final pool = playing.isEmpty ? _players : playing;
    return pool.where((p) => p.role == _filterRole).toList();
  }

  List<_Player> get _filtered => _playingFiltered;

  bool _canAdd(_Player p) {
    if (_selected.contains(p.id)) return false;
    if (_count >= 11) return false;
    if (_remaining < p.credits - 0.001) return false;
    return _rc(p.role) < (_maxRole[p.role] ?? 6);
  }

  bool get _canProceed =>
      _count == 11 && _minRole.entries.every((e) => _rc(e.key) >= e.value);

  // ── init ───────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _roles.length, vsync: this)
      ..addListener(() {
        if (!_tabCtrl.indexIsChanging)
          setState(() => _tabIndex = _tabCtrl.index);
      });
    // Pre-fill if editing
    if (widget.existingTeam != null) {
      final et = widget.existingTeam!;
      _editTeamId = int.tryParse(et['id']?.toString() ?? '0') ?? 0;
      _teamNameCtrl.text = et['name']?.toString() ?? 'Team 1';
      // Pre-select players
      final existingPlayers = et['players'] as List? ?? [];
      for (final p in existingPlayers) {
        final pid = (p is Map ? p['id'] : p)?.toString();
        if (pid != null) _selected.add(pid);
      }
      _captainId = et['captain_id']?.toString();
      _vcId = et['vice_captain_id']?.toString();
      print('DEBUG: EsCreateTeamScreen EDIT MODE - teamId=$_editTeamId, name=${_teamNameCtrl.text}, players=${_selected.length}');
    }
    _loadUserCurrency();
    _loadSquad();
  }

  Future<void> _loadUserCurrency() async {
    final data = await LocationService.getLocationData();
    if (mounted) {
      setState(() {
        _currencyCode = data['currency'] ?? 'INR';
        _currencySymbol = data['currency_symbol'] ?? '₹';
      });
    }
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _teamNameCtrl.dispose();
    super.dispose();
  }

  // ── load ───────────────────────────────────────────────────────────────────
  Future<void> _loadSquad() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    _matchInfo = widget.matchData;
    print('DEBUG: EsCreateTeamScreen - matchData from widget: $_matchInfo');
    print('DEBUG: EsCreateTeamScreen - contest from widget: ${widget.contest?.id}, matchId: ${widget.contest?.matchId}');

    final rawMid = _matchInfo?['match_id'] ?? _matchInfo?['additional_match_id'] ?? _matchInfo?['id'] ?? widget.contest?.matchId;
    _matchRequestId = int.tryParse(rawMid?.toString() ?? '') ?? 0;
    
    // If we have match_id: 1, try to find a real ID in teama/teamb or external info
    if (_matchRequestId == 1 || _matchRequestId == 0) {
      if (_matchInfo?.containsKey('raw') == true) {
         final rawMatch = _matchInfo!['raw'] as Map<String, dynamic>?;
         final realId = rawMatch?['match_id'] ?? rawMatch?['id'];
         if (realId != null) _matchRequestId = int.tryParse(realId.toString()) ?? _matchRequestId;
      }
    }

    final matchId = _matchRequestId!;
    print('DEBUG: EsCreateTeamScreen - Resolved matchId for request: $matchId');

    if (matchId > 0 && (_matchInfo == null || !_matchInfo!.containsKey('teama') || !_matchInfo!.containsKey('teamb'))) {
      try {
        final info = await EntitySportService.getMatchInfo(matchId);
        if (info.isNotEmpty) _matchInfo = info;
      } catch (e) { print('Error fetching missing match info for $matchId: $e'); }
    }

    final teamaRaw = _matchInfo?['teama'] as Map<String, dynamic>?;
    final teambRaw = _matchInfo?['teamb'] as Map<String, dynamic>?;

    final tidA = int.tryParse(teamaRaw?['team_id']?.toString() ?? '');
    final tidB = int.tryParse(teambRaw?['team_id']?.toString() ?? '');

    final shortA = teamaRaw?['short_name']?.toString() ?? 'TM A';
    final shortB = teambRaw?['short_name']?.toString() ?? 'TM B';

    try {
      final isEntitySport = widget.matchData?.containsKey('match_id') ?? false;

      if (!isEntitySport) {
        final customPlayers = await PlayerService.getPlayersByMatch(matchId);
        if (customPlayers.isNotEmpty) {
          final List<_Player> players = [];
          for (final p in customPlayers) {
            String tShort = p['team_code']?.toString() ?? p['team_short']?.toString() ?? '';
            if (tShort.isEmpty) {
              final pTid = p['team_id']?.toString();
              if (pTid != null && tidA != null && pTid == tidA.toString()) tShort = shortA;
              else if (pTid != null && tidB != null && pTid == tidB.toString()) tShort = shortB;
              else tShort = shortA;
            }
            players.add(_fromRaw(p, tShort, {}));
          }
          if (players.isNotEmpty && mounted) {
            setState(() { _players = players; _loading = false; });
            return;
          }
        }
      }

      print('DEBUG: EsCreateTeamScreen - Fetching squad and scorecard for match: $matchId');
      Map<String, dynamic> squadData = {};
      Map<String, dynamic> scorecardData = {};
      
      try {
        squadData = await EntitySportService.getFantasySquad(matchId);
      } catch (e) {
        print('DEBUG: EsCreateTeamScreen - Fantasy Squad failed, likely 403 or 400. Trying match players instead.');
      }

      try {
        scorecardData = await EntitySportService.getScorecard(matchId);
      } catch (_) {}

      final statsMap = <String, Map<String, String>>{};
      _parseScorecard(scorecardData, statsMap);
      List<_Player> players = _parseSquad(squadData, shortA, shortB, statsMap);

      print('DEBUG: EsCreateTeamScreen - parseSquad resulted in ${players.length} players');

      if (players.isEmpty) {
        final matchPlayers = await EntitySportService.getPlayersByMatch(matchId);
        for (int i = 0; i < matchPlayers.length; i++) players.add(_fromRaw(matchPlayers[i], (i % 2 == 0) ? shortA : shortB, statsMap));
      }

      if (!mounted) return;
      if (players.isEmpty) {
        setState(() { _error = 'No squad announced yet. Try again later.'; _loading = false; });
        return;
      }
      setState(() { _players = players; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = 'Failed to load squad data.'; _loading = false; });
    }
  }

  List<_Player> _parseSquad(
    Map<String, dynamic> squadData,
    String shortA,
    String shortB,
    Map<String, Map<String, String>> statsMap,
  ) {
    final out = <_Player>[];
    final detailsMap = <String, Map<String, dynamic>>{};
    final playersList = squadData['players'] as List<dynamic>? ?? [];
    for (final p in playersList) {
      if (p is Map<String, dynamic>) {
        final pid = p['pid']?.toString();
        if (pid != null) detailsMap[pid] = p;
      }
    }

    for (final entry in [['teama', shortA], ['teamb', shortB]]) {
      final teamKey = entry[0] as String;
      final tShort = entry[1] as String;
      final team = squadData[teamKey] as Map<String, dynamic>?;
      if (team == null) continue;

      final squad = (team['squads'] ?? team['squad']) as List<dynamic>? ?? [];
      for (final pRaw in squad) {
        if (pRaw is! Map<String, dynamic>) continue;
        final pid = (pRaw['player_id'] ?? pRaw['pid'])?.toString();
        Map<String, dynamic> merged = Map.from(pRaw);
        if (pid != null && detailsMap.containsKey(pid)) merged.addAll(detailsMap[pid]!);
        else merged['pid'] = pid;
        out.add(_fromRaw(merged, tShort, statsMap));
      }
    }
    return out;
  }

  _Player _fromRaw(Map<String, dynamic> p, String teamShort, Map<String, Map<String, String>> statsMap) {
    final rawId = p['pid'] ?? p['player_id'] ?? p['id'] ?? p['player_id_api'];
    final pid = rawId?.toString() ?? UniqueKey().toString();
    final name = p['title']?.toString() ?? p['name']?.toString() ?? 'Unknown';
    final roleStr = p['playing_role']?.toString() ?? p['role']?.toString() ?? '';
    final role = _mapRole(roleStr);
    final rawCred = p['fantasy_player_rating'] ?? p['credits'];
    double cred = 8.5;
    if (rawCred is num) cred = rawCred.toDouble();
    else if (rawCred is String) cred = double.tryParse(rawCred) ?? 8.5;

    final pl = _Player(
      id: pid, name: name, shortName: _short(name), role: role, credits: cred.clamp(5.0, 15.0),
      imageUrl: p['photo_url']?.toString() ?? p['thumb_url']?.toString() ?? p['logo_url']?.toString() ?? p['image']?.toString() ?? '',
      teamShort: teamShort, rating: cred,
      battingStyle: p['batting_style']?.toString() ?? p['batting_type']?.toString() ?? '',
      bowlingStyle: p['bowling_style']?.toString() ?? p['bowling_type']?.toString() ?? '',
      isPlaying: p['playing_status']?.toString() == '1' || p['is_playing'] == true || p['playing_11'] == true,
    );

    final st = statsMap[pid] ?? statsMap[name];
    if (st != null) {
      pl.runs = st['runs'] ?? ''; pl.balls = st['balls'] ?? ''; pl.strikeRate = st['sr'] ?? '';
      pl.wickets = st['wkts'] ?? ''; pl.economy = st['econ'] ?? '';
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
          out[k] = { ...(out[k] ?? {}), 'runs': bm['runs']?.toString() ?? '', 'balls': bm['balls_played']?.toString() ?? '', 'sr': bm['strike_rate']?.toString() ?? '', };
        }
        for (final bw in (im['bowling'] as List<dynamic>? ?? [])) {
          final bm = bw as Map<String, dynamic>;
          final k = bm['pid']?.toString() ?? bm['name']?.toString() ?? '';
          if (k.isEmpty) continue;
          out[k] = { ...(out[k] ?? {}), 'wkts': bm['wickets']?.toString() ?? '', 'econ': bm['econ']?.toString() ?? '', };
        }
      }
    } catch (_) {}
  }

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
    if (_count >= 11) { _snack('Max 11 players'); return; }
    if (_remaining < p.credits - 0.001) { _snack('Not enough credits'); return; }
    if (!_canAdd(p)) { _snack('Role limit reached (${_roleLabels[p.role]})'); return; }
    setState(() => _selected.add(p.id));
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppColors.primary, duration: const Duration(seconds: 2), behavior: SnackBarBehavior.floating));
  }

  int _teamCount(String short) {
    return _selectedPlayers.where((p) => p.teamShort == short).length;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return _loader();
    if (_error != null && _players.isEmpty) return _errView();
    if (_showCaptainScreen) return _captainScreen();
    return _selectScreen();
  }

  Widget _loader() => Scaffold(backgroundColor: Colors.white, body: SafeArea(child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [const CircularProgressIndicator(color: AppColors.primary, strokeWidth: 3), const SizedBox(height: 20), Text('Loading Squad…', style: TextStyle(color: Colors.grey.shade600, fontSize: 15))]))));

  Widget _errView() => Scaffold(backgroundColor: Colors.white, appBar: AppBar(backgroundColor: Colors.white, iconTheme: const IconThemeData(color: Colors.black), title: Text(_isEditMode ? 'Edit Team' : 'Create Team', style: const TextStyle(color: Colors.black))), body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.error_outline, size: 60, color: Colors.grey), const SizedBox(height: 16), Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600)), const SizedBox(height: 20), ElevatedButton.icon(onPressed: _loadSquad, icon: const Icon(Icons.refresh), label: const Text('Retry'), style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white))])));

  // ── NEW LAYOUT MATCHING SCREENSHOT ──────────────────────────────────────────
  Widget _selectScreen() => Scaffold(
    backgroundColor: Colors.grey[50],
    body: SafeArea(
      bottom: false,
      child: Column(
        children: [
          _buildTopHeader(),
          _buildTabBar(),
          _buildSubHeader(),
          Expanded(child: _playerList()),
          _buildBottomNav(),
        ],
      ),
    ),
  );

  Widget _buildTopHeader() {
    final t1 = (_matchInfo?['teama'] as Map<String, dynamic>?)?.tryString('short_name') ?? 'TM A';
    final t2 = (_matchInfo?['teamb'] as Map<String, dynamic>?)?.tryString('short_name') ?? 'TM B';
    final t1Count = _teamCount(t1);
    final t2Count = _teamCount(t2);

    return Container(
      color: AppColors.primary,
      child: Column(
        children: [
          // Row 1: App bar area
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_isEditMode ? 'Edit Team' : 'Create Team', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                      const Row(
                        children: [
                          Icon(Icons.schedule, color: Colors.white70, size: 10),
                          SizedBox(width: 4),
                          Text('Match Started', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Row 2: Selected stats
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Players', style: TextStyle(color: Colors.white70, fontSize: 11)),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('$_count', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        const Padding(padding: EdgeInsets.only(bottom: 2), child: Text('/11', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold))),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    _headerTeamLogo((_matchInfo?['teama'] as Map<String, dynamic>?)?.tryString('logo_url'), t1),
                    const SizedBox(width: 6),
                    Column(
                      children: [
                        Text(t1, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                        Text('$t1Count', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Column(
                      children: [
                        Text(t2, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                        Text('$t2Count', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(width: 6),
                    _headerTeamLogo((_matchInfo?['teamb'] as Map<String, dynamic>?)?.tryString('logo_url'), t2),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Credits Left', style: TextStyle(color: Colors.white70, fontSize: 11)),
                    Text(_remaining.toStringAsFixed(1), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Row 3: Progress Bar 11 Segments
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: List.generate(11, (index) {
                final isSelected = index < _count;
                return Expanded(
                  child: Container(
                    height: 6,
                    margin: EdgeInsets.only(right: index == 10 ? 0 : 2),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.green : Colors.white24,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 6),
          const Center(
            child: Text('Cricket Match', style: TextStyle(color: Colors.white60, fontSize: 10)),
          ),
          const SizedBox(height: 12),

          // Row 4: Pitch Info
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            color: Colors.black26,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Pitch : ', style: TextStyle(color: Colors.white70, fontSize: 10)),
                Icon(Icons.sports_cricket, color: Colors.white, size: 10),
                Text(' Batting', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                Text('   Supports : ', style: TextStyle(color: Colors.white70, fontSize: 10)),
                Icon(Icons.sports_baseball, color: Colors.white, size: 10),
                Text(' Pacers', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                Text('   Avg Score', style: TextStyle(color: Colors.white70, fontSize: 10)),
                Text(' 150', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerTeamLogo(String? url, String short) {
    final logoUrl = url?.toString() ?? '';
    return Container(
      width: 24, height: 24,
      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
      child: ClipOval(
        child: logoUrl.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: logoUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => _initial(short, AppColors.primary, 24),
                errorWidget: (context, url, error) => _initial(short, AppColors.primary, 24),
              )
            : _initial(short, AppColors.primary, 24),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabCtrl,
        indicatorColor: AppColors.secondary,
        labelColor: AppColors.secondary,
        unselectedLabelColor: Colors.grey[600],
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        tabs: _roles.map((r) => Tab(text: '$r (${_rc(r)})')).toList(),
      ),
    );
  }

  Widget _buildSubHeader() {
    final min = _minRole[_filterRole] ?? 1;
    final max = _maxRole[_filterRole] ?? 6;
    return Container(
      color: Colors.grey[50],
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Pick $min-$max $_filterRole', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black87)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(16)),
                child: Row(
                  children: [
                    Icon(Icons.people_outline, color: Colors.grey[400], size: 14),
                    const SizedBox(width: 4),
                    Text('Lineups', style: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.bold, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const SizedBox(width: 8),
              const Expanded(flex: 3, child: Text('Team ↑↓', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.w500))),
              const Expanded(flex: 2, child: Text('Points ↑↓', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.w500), textAlign: TextAlign.center)),
              const Expanded(flex: 2, child: Text('Sel by ↑↓', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.w500), textAlign: TextAlign.center)),
              Expanded(flex: 2, child: Container(alignment: Alignment.centerRight, child: const Text('Credits ↑↓', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.w500)))),
              const SizedBox(width: 44), // Space for add button
            ],
          ),
        ],
      ),
    );
  }

  Widget _emptyState() => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.sports_cricket, size: 48, color: Colors.grey.shade300), const SizedBox(height: 12), Text('No players found', style: TextStyle(color: Colors.grey.shade500, fontSize: 14))]));

  Widget _playerList() {
    final list = _filtered;
    if (list.isEmpty) return _emptyState();

    return Container(
      color: Colors.white,
      child: ListView.separated(
        physics: const BouncingScrollPhysics(),
        itemCount: list.length,
        separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade200),
        itemBuilder: (context, index) => _playerTile(list[index]),
      ),
    );
  }

  Widget _playerTile(_Player p) {
    final sel = _selected.contains(p.id);
    final canAdd = _canAdd(p) || sel;

    return GestureDetector(
      onTap: () => _toggle(p),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        color: sel ? Colors.green.shade50 : Colors.white,
        child: Row(
          children: [
            // Avatar and Team
            SizedBox(
              width: 56,
              height: 56,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 46, height: 46,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.grey[100]),
                    child: ClipOval(
                      child: (p.imageUrl.isNotEmpty)
                        ? CachedNetworkImage(
                            imageUrl: p.imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Center(child: Icon(Icons.person, color: Colors.grey[400], size: 24)),
                            errorWidget: (context, url, error) => _initial(p.shortName, AppColors.primary, 36),
                          )
                        : _initial(p.shortName, AppColors.primary, 36),
                    ),
                  ),
                  Positioned(
                    top: 0, left: 0,
                    child: Icon(Icons.info_outline, color: Colors.grey[500], size: 14),
                  ),
                  Positioned(
                    bottom: -4, left: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(4)),
                      child: Text(p.teamShort, style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Name and Details
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.shortName, style: TextStyle(color: canAdd ? Colors.black : Colors.grey.shade500, fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  if (p.rating > 0) Text('${p.rating} pts', style: TextStyle(color: Colors.grey[600], fontSize: 10)),
                  const SizedBox(height: 2),
                  if (p.isPlaying) Row(children: [Container(width: 4, height: 4, decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle)), const SizedBox(width: 4), const Text('Played last match', style: TextStyle(color: Colors.blue, fontSize: 9))]),
                ],
              ),
            ),

            // Sel by
            Expanded(
              flex: 2,
              child: Center(
                child: Text('—', style: TextStyle(color: Colors.grey[600], fontSize: 11)), // Would be dynamic %
              ),
            ),

            // Credits
            Expanded(
              flex: 2,
              child: Container(
                alignment: Alignment.centerRight,
                child: Text(p.credits.toStringAsFixed(1), style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ),
            const SizedBox(width: 12),

            // Add/Remove Button
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 24, height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: sel ? Colors.green : (canAdd ? Colors.green : Colors.grey), width: 1.5),
                color: Colors.white,
              ),
              child: Icon(sel ? Icons.remove : Icons.add, color: sel ? Colors.green : (canAdd ? Colors.green : Colors.grey), size: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey.shade200))),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _canProceed ? () => setState(() => _showCaptainScreen = true) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _canProceed ? Colors.green : Colors.grey[300],
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                child: Text('Next', style: TextStyle(color: _canProceed ? Colors.white : Colors.grey[500], fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── CAPTAIN SCREEN ────────────────────────────────────────────────────────
  Widget _captainScreen() => Scaffold(
    backgroundColor: Colors.white,
    body: SafeArea(
      bottom: false,
      child: Column(
        children: [
          _captainHeader(),
          _teamNameInput(),
          _captainSubHeader(),
          _captainSortHeader(),
          Expanded(child: ListView.separated(
            physics: const BouncingScrollPhysics(),
            itemCount: _selectedPlayers.length,
            separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade200),
            itemBuilder: (context, index) => _captainTile(_selectedPlayers[index]),
          )),
          _captainBottomBar(),
        ],
      ),
    ),
  );

  Widget _teamNameInput() => Container(
    margin: const EdgeInsets.fromLTRB(14, 8, 14, 8),
    padding: const EdgeInsets.symmetric(horizontal: 4),
    decoration: BoxDecoration(
      color: Colors.white, 
      borderRadius: BorderRadius.circular(12), 
      border: Border.all(color: Colors.grey.shade300),
    ),
    child: TextField(
      controller: _teamNameCtrl,
      onChanged: (val) {
        print('DEBUG: Team Name typing: $val');
      },
      decoration: const InputDecoration(
        labelText: 'TEAM NAME', 
        labelStyle: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.2), 
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8), 
        border: InputBorder.none, 
      ),
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black),
    ),
  );

  Widget _captainHeader() {
    return Container(
      color: AppColors.primary,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Row(
        children: [
          GestureDetector(onTap: () => setState(() => _showCaptainScreen = false), child: const Icon(Icons.arrow_back, color: Colors.white, size: 24)),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Create Team', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    Icon(Icons.schedule, color: Colors.white70, size: 10),
                    SizedBox(width: 4),
                    Text('Match Started', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w500)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _captainSubHeader() {
    String cName = _captainId != null ? _short(_players.firstWhere((p) => p.id == _captainId).name) : 'Hammad Mir...';
    String vName = _vcId != null ? _short(_players.firstWhere((p) => p.id == _vcId).name) : 'Charlie Tea...';

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      child: Column(
        children: [
          const Text('Select Captain and Vice Captain', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(20)),
                    child: Text('C : $cName', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                  ),
                  const SizedBox(height: 4),
                  const Text('Gets 2x Points', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(20)),
                    child: Text('VC : $vName', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                  ),
                  const SizedBox(height: 4),
                  const Text('Gets 1.5x Points', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _captainSortHeader() {
    return Container(
      color: Colors.grey[50],
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: const Row(
        children: [
          SizedBox(width: 8),
          Expanded(flex: 3, child: Text('Team ↑↓', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.w500))),
          Expanded(flex: 2, child: Text('Points ↑↓', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.w500), textAlign: TextAlign.center)),
          Expanded(flex: 2, child: Text('% C ↑↓', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.w500), textAlign: TextAlign.center)),
          Expanded(flex: 2, child: Text('% VC ↑↓', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.w500), textAlign: TextAlign.center)),
        ],
      ),
    );
  }

  Widget _captainTile(_Player p) {
    final isC = _captainId == p.id;
    final isVC = _vcId == p.id;

    return Container(
      color: (isC || isVC) ? Colors.orange.shade50 : Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          // Avatar and Team
          SizedBox(
            width: 56,
            height: 56,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 46, height: 46,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.grey[100]),
                  child: ClipOval(
                    child: (p.imageUrl.isNotEmpty)
                      ? CachedNetworkImage(
                          imageUrl: p.imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Image.asset('assets/images/player_placeholder.png', fit: BoxFit.cover),
                          errorWidget: (context, url, error) => Image.asset('assets/images/player_placeholder.png', fit: BoxFit.cover),
                        )
                      : Image.asset('assets/images/player_placeholder.png', fit: BoxFit.cover),
                  ),
                ),
                Positioned(
                  bottom: -4, left: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.white, width: 1)),
                    child: Text(p.teamShort, style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Name and Details
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(p.teamShort, style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900, fontSize: 10)),
                    const SizedBox(width: 6),
                    Expanded(child: Text(p.shortName, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  ],
                ),
                const SizedBox(height: 4),
                Text('${p.role} | ${p.rating > 0 ? '${p.rating} pts' : '0 pts'}', style: TextStyle(color: Colors.grey[600], fontSize: 10)),
                const SizedBox(height: 2),
                if (p.isPlaying) Row(children: [Container(width: 4, height: 4, decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle)), const SizedBox(width: 4), const Text('Played last match', style: TextStyle(color: Colors.blue, fontSize: 9))]),
              ],
            ),
          ),

          // % C (Captain Button)
          Expanded(
            flex: 2,
            child: Column(
              children: [
                _cvBtn('C', '2x', isC, () { setState(() { if (isC) _captainId = null; else { _captainId = p.id; if (isVC) _vcId = null; } }); }),
                const SizedBox(height: 4),
                Text('1.3%', style: TextStyle(color: Colors.grey[600], fontSize: 9)),
              ],
            ),
          ),

          // % VC (Vice Captain Button)
          Expanded(
            flex: 2,
            child: Column(
              children: [
                _cvBtn('VC', '1.5x', isVC, () { setState(() { if (isVC) _vcId = null; else { _vcId = p.id; if (isC) _captainId = null; } }); }),
                const SizedBox(height: 4),
                Text('0.7%', style: TextStyle(color: Colors.grey[600], fontSize: 9)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _cvBtn(String label, String activeLabel, bool active, VoidCallback fn) => GestureDetector(
    onTap: fn,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 38, height: 38,
      decoration: BoxDecoration(
        color: active ? Colors.green : Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: active ? Colors.green : Colors.grey.shade400, width: 1.0),
      ),
      child: Center(
        child: Text(active ? activeLabel : label, style: TextStyle(color: active ? Colors.white : Colors.grey.shade500, fontWeight: FontWeight.bold, fontSize: 12)),
      ),
    ),
  );

  Widget _captainBottomBar() {
    final ready = _captainId != null && _vcId != null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey.shade200)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, -2))]),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: (ready && !_submitting) ? () => _submit() : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: (ready && !_submitting) ? Colors.green : Colors.grey[300],
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                child: _submitting 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                  : Text('Save Team', style: TextStyle(color: (ready && !_submitting) ? Colors.white : Colors.grey[500], fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_captainId == null || _vcId == null) { _snack('Please select Captain and Vice-Captain'); return; }
    setState(() => _submitting = true);
    try {
      final matchId = widget.contest != null ? (int.tryParse(widget.contest!.matchId) ?? _matchRequestId ?? 1) : (_matchRequestId ?? 1);
      final playerIds = _selected.map((id) => int.tryParse(id) ?? 0).where((id) => id != 0).toList();
      
      print('DEBUG: EsCreateTeamScreen - ${_isEditMode ? "UPDATING" : "SUBMITTING"} TEAM:');
      print('  - Team Name: ${_teamNameCtrl.text}');
      print('  - Match ID: $matchId');
      print('  - Players: $playerIds');
      print('  - Captain: $_captainId');
      print('  - Vice-Captain: $_vcId');

      if (_isEditMode && _editTeamId != null && _editTeamId! > 0) {
        // UPDATE existing team
        final updateRes = await TeamsService().updateTeam(
          teamId: _editTeamId!,
          name: _teamNameCtrl.text.isEmpty ? "My Team" : _teamNameCtrl.text,
          playerIds: playerIds,
          captainId: int.parse(_captainId!),
          viceCaptainId: int.parse(_vcId!),
        );
        if (!mounted) return;
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Team updated successfully! ✅'), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating),
        );
        Navigator.pop(context, true);
      } else {
        // CREATE new team
        final teamRes = await TeamsService().saveTeam(
          name: _teamNameCtrl.text.isEmpty ? "My Team" : _teamNameCtrl.text, 
          matchId: matchId, 
          playerIds: playerIds, 
          captainId: int.parse(_captainId!), 
          viceCaptainId: int.parse(_vcId!)
        );
        final dynamic rawTeamId = teamRes['data']?['team']?['id'] ?? 
                                teamRes['data']?['id'] ?? 
                                teamRes['id'] ?? 
                                teamRes['team_id'];
        final teamId = rawTeamId?.toString() ?? '0';
        if (!mounted) return;
        setState(() => _submitting = false);
        _showSuccessDialog(teamId);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      _snack('Error ${_isEditMode ? "updating" : "saving"} team: $e');
    }
  }

  void _showSuccessDialog(String teamId) {
    bool joining = false;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: Colors.white,
          elevation: 24,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated-like checkmark icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(Icons.check_circle_rounded, size: 64, color: Colors.green),
                  ),
                ),
                const SizedBox(height: 24),
                
                const Text(
                  'Team Created! 🎉',
                  style: TextStyle(
                    color: Color(0xFF1B2430),
                    fontWeight: FontWeight.w900,
                    fontSize: 24,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _teamNameCtrl.text.isEmpty ? 'Team 1' : _teamNameCtrl.text,
                  style: TextStyle(color: Colors.grey[500], fontSize: 15, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 32),
                
                if (widget.contest != null)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: joining ? null : () async {
                        setDialogState(() => joining = true);
                        try {
                          final savedData = await UserProfileService.getSavedUserData();
                          final int userId = int.tryParse(savedData['id']?.toString() ?? '56') ?? 56;
                          
                          // Use the newly created teamId!
                          await ContestService().joinContest(
                            contestId: widget.contest!.id, 
                            teamId: teamId, 
                            teamName: _teamNameCtrl.text.isEmpty ? "Team 1" : _teamNameCtrl.text, 
                            userId: userId
                          );
                          
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Joined contest successfully! 🏆'), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating)
                            );
                            Navigator.pop(dialogContext);
                            navigatorKey.currentState?.pop();
                          }
                        } catch (e) {
                          setDialogState(() => joining = false);
                          _snack('Join failed: ${e.toString().replaceAll('Exception: ', '')}');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1B2430),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: joining 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.emoji_events_rounded, size: 20),
                              SizedBox(width: 10),
                              Text(
                                'Join Contest 🏆',
                                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                              ),
                            ],
                          ),
                    ),
                  ),
                
                if (widget.contest != null) const SizedBox(height: 12),
                
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: joining ? null : () {
                      Navigator.pop(dialogContext);
                      navigatorKey.currentState?.pop();
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: Colors.grey.shade200, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      backgroundColor: Colors.white,
                    ),
                    child: const Text(
                      'Done',
                      style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  SHARED HELPERS
// ─────────────────────────────────────────────────────────────────────────────
Widget _initial(String name, Color clr, double size) => Center(child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: TextStyle(color: clr, fontWeight: FontWeight.bold, fontSize: size * 0.38)));

extension _MapExt on Map<String, dynamic> {
  String? tryString(String key) => this[key]?.toString();
}