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
  const EsCreateTeamScreen({super.key, this.matchData, this.contest});

  @override
  State<EsCreateTeamScreen> createState() => _EsCreateTeamScreenState();
}

class _EsCreateTeamScreenState extends State<EsCreateTeamScreen>
    with SingleTickerProviderStateMixin {
  // ── state ──────────────────────────────────────────────────────────────────
  bool _loading = true;
  bool _submitting = false;
  String? _error;
  int? _matchRequestId; // The match ID we were asked to use from the contest
  Map<String, dynamic>? _matchInfo; // Full match details from API
  List<_Player> _players = [];
  final Set<String> _selected = {};
  String? _captainId;
  String? _vcId;
  bool _showCaptainScreen = false;
  int _tabIndex = 0; // 0=ALL 1=WK 2=BAT 3=AR 4=BOWL
  late TabController _tabCtrl;
  final TextEditingController _teamNameCtrl = TextEditingController(
    text: 'Team 1',
  );
  String _currencySymbol = '₹';
  String _currencyCode = 'INR';

  static const double _totalCredits = 100.0;
  static const List<String> _roles = ['ALL', 'WK', 'BAT', 'AR', 'BOWL'];
  static const Map<String, String> _roleLabels = {
    'ALL': 'All',
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
  static const Map<String, Color> _roleClr = {
    'WK': Color(0xFFFF187C),
    'BAT': Color(0xFF63DAB9),
    'AR': Color(0xFFFF187C),
    'BOWL': Color(0xFF63DAB9),
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
    // Stale objects in memory after hot reload might have null for the new isPlaying field
    final playing = _players.where((p) {
      try { return (p as dynamic).isPlaying == true; } catch(_) { return false; }
    }).toList();
    
    // If no one is marked as playing yet (lineup not out), show everyone
    final pool = playing.isEmpty ? _players : playing;
    
    if (_filterRole == 'ALL') return pool;
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
    final rawMid = _matchInfo?['match_id'] ?? _matchInfo?['id'];
    _matchRequestId = int.tryParse(rawMid?.toString() ?? '') ?? 1;
    final matchId = _matchRequestId!;
    print('Loading squad for match: $matchId');

    // If match data is incomplete, fetch full info first
    if (_matchInfo == null || !_matchInfo!.containsKey('teama') || !_matchInfo!.containsKey('teamb')) {
      try {
        final info = await EntitySportService.getMatchInfo(matchId);
        if (info.isNotEmpty) {
          _matchInfo = info;
        }
      } catch (e) {
        print('Error fetching missing match info: $e');
      }
    }

    final teamaRaw = _matchInfo?['teama'] as Map<String, dynamic>?;
    final teambRaw = _matchInfo?['teamb'] as Map<String, dynamic>?;

    // Safety parse for team IDs
    final tidA = int.tryParse(teamaRaw?['team_id']?.toString() ?? '');
    final tidB = int.tryParse(teambRaw?['team_id']?.toString() ?? '');

    final shortA = teamaRaw?['short_name']?.toString() ?? 'TM A';
    final shortB = teambRaw?['short_name']?.toString() ?? 'TM B';

    try {
      final isEntitySport = widget.matchData?.containsKey('match_id') ?? false;

      // 1. Try NEW API ONLY for internal matches
      if (!isEntitySport) {
        final customPlayers = await PlayerService.getPlayersByMatch(matchId);
        if (customPlayers.isNotEmpty) {
        final List<_Player> players = [];
        for (final p in customPlayers) {
          // Map team code or fallback to A/B
          String tShort =
              p['team_code']?.toString() ?? p['team_short']?.toString() ?? '';
          if (tShort.isEmpty) {
            final pTid = p['team_id']?.toString();
            if (pTid != null && tidA != null && pTid == tidA.toString())
              tShort = shortA;
            else if (pTid != null && tidB != null && pTid == tidB.toString())
              tShort = shortB;
            else
              tShort = shortA; // Fallback
          }
          players.add(_fromRaw(p, tShort, {}));
        }
          if (players.isNotEmpty && mounted) {
            setState(() {
              _players = players;
              _loading = false;
            });
            return;
          }
        }
      }

      // 2. Fallback to EntitySport squad API
      final Map<String, dynamic> squadData =
          await EntitySportService.getFantasySquad(matchId);
      final Map<String, dynamic> scorecardData =
          await EntitySportService.getScorecard(matchId);

      final statsMap = <String, Map<String, String>>{};
      _parseScorecard(scorecardData, statsMap);
      List<_Player> players = _parseSquad(squadData, shortA, shortB, statsMap);

      if (players.isEmpty) {
        final matchPlayers = await EntitySportService.getPlayersByMatch(
          matchId,
        );
        for (int i = 0; i < matchPlayers.length; i++) {
          players.add(
            _fromRaw(matchPlayers[i], (i % 2 == 0) ? shortA : shortB, statsMap),
          );
        }
      }

      if (!mounted) return;
      if (players.isEmpty) {
        setState(() {
          _error = 'No squad announced yet. Try again later.';
          _loading = false;
        });
        return;
      }
      setState(() {
        _players = players;
        _loading = false;
      });
    } catch (e) {
      print('Squad load error: $e');
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load squad data.';
        _loading = false;
      });
    }
  }

  List<_Player> _parseSquad(
    Map<String, dynamic> squadData,
    String shortA,
    String shortB,
    Map<String, Map<String, String>> statsMap,
  ) {
    final out = <_Player>[];

    // 1. Build a map of detailed player info from the root 'players' list
    final detailsMap = <String, Map<String, dynamic>>{};
    final playersList = squadData['players'] as List<dynamic>? ?? [];
    for (final p in playersList) {
      if (p is Map<String, dynamic>) {
        final pid = p['pid']?.toString();
        if (pid != null) detailsMap[pid] = p;
      }
    }

    // 2. Process teama and teamb squads
    for (final entry in [
      ['teama', shortA],
      ['teamb', shortB],
    ]) {
      final teamKey = entry[0] as String;
      final tShort = entry[1] as String;
      final team = squadData[teamKey] as Map<String, dynamic>?;
      if (team == null) continue;

      // EntitySport sometimes uses 'squad' and sometimes 'squads'
      final squad = (team['squads'] ?? team['squad']) as List<dynamic>? ?? [];

      for (final pRaw in squad) {
        if (pRaw is! Map<String, dynamic>) continue;

        final pid = (pRaw['player_id'] ?? pRaw['pid'])?.toString();
        Map<String, dynamic> merged = Map.from(pRaw);

        // If we have detailed info for this player, merge it
        if (pid != null && detailsMap.containsKey(pid)) {
          merged.addAll(detailsMap[pid]!);
        } else {
          // Ensure pid is set correctly for _fromRaw
          merged['pid'] = pid;
        }

        out.add(_fromRaw(merged, tShort, statsMap));
      }
    }
    return out;
  }

  _Player _fromRaw(
    Map<String, dynamic> p,
    String teamShort,
    Map<String, Map<String, String>> statsMap,
  ) {
    // Standardize ID: pid or player_id or id
    final rawId = p['pid'] ?? p['player_id'] ?? p['id'] ?? p['player_id_api'];
    final pid = rawId?.toString() ?? UniqueKey().toString();

    // Standardize Name: title or name
    final name = p['title']?.toString() ?? p['name']?.toString() ?? 'Unknown';

    // Standardize Role: playing_role or role
    final roleStr =
        p['playing_role']?.toString() ?? p['role']?.toString() ?? '';
    final role = _mapRole(roleStr);

    // Standardize Credits: fantasy_player_rating or credits
    final rawCred = p['fantasy_player_rating'] ?? p['credits'];
    double cred = 8.5;
    if (rawCred is num) {
      cred = rawCred.toDouble();
    } else if (rawCred is String) {
      cred = double.tryParse(rawCred) ?? 8.5;
    }

    final pl = _Player(
      id: pid,
      name: name,
      shortName: _short(name),
      role: role,
      credits: cred.clamp(5.0, 15.0),
      imageUrl:
          p['photo_url']?.toString() ??
          p['thumb_url']?.toString() ??
          p['logo_url']?.toString() ??
          p['image']?.toString() ??
          '',
      teamShort: teamShort,
      rating: cred,
      battingStyle:
          p['batting_style']?.toString() ?? p['batting_type']?.toString() ?? '',
      bowlingStyle:
          p['bowling_style']?.toString() ?? p['bowling_type']?.toString() ?? '',
      isPlaying: p['playing_status']?.toString() == '1' || 
                 p['is_playing'] == true || 
                 p['playing_11'] == true,
    );

    // Attach scorecard stats if available
    final st = statsMap[pid] ?? statsMap[name];
    if (st != null) {
      pl.runs = st['runs'] ?? '';
      pl.balls = st['balls'] ?? '';
      pl.strikeRate = st['sr'] ?? '';
      pl.wickets = st['wkts'] ?? '';
      pl.economy = st['econ'] ?? '';
    }

    // Fallback to 'points' field from custom API
    final apiPts = p['points'];
    if (pl.runs.isEmpty && pl.wickets.isEmpty && apiPts != null) {
      final val = double.tryParse(apiPts.toString()) ?? 0;
      if (val > 0) pl.runs = '${val.toStringAsFixed(1)} pts';
    }

    return pl;
  }

  void _parseScorecard(
    Map<String, dynamic> sc,
    Map<String, Map<String, String>> out,
  ) {
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

  // ── helpers ────────────────────────────────────────────────────────────────
  String _mapRole(String r) {
    switch (r.toLowerCase()) {
      case 'wk':
      case 'keeper':
      case 'wicket-keeper':
      case 'wicketkeeper':
        return 'WK';
      case 'bat':
      case 'batsman':
      case 'batter':
        return 'BAT';
      case 'ar':
      case 'all':
      case 'all-rounder':
      case 'allrounder':
        return 'AR';
      case 'bowl':
      case 'bowler':
        return 'BOWL';
      default:
        return 'BAT';
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
    if (_count >= 11) {
      _snack('Max 11 players');
      return;
    }
    if (_remaining < p.credits - 0.001) {
      _snack('Not enough credits');
      return;
    }
    if (!_canAdd(p)) {
      _snack('Role limit reached (${_roleLabels[p.role]})');
      return;
    }
    setState(() => _selected.add(p.id));
  }

  void _showRulesPopup() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Selection Rules',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            _ruleRow('11 Players', 'Total to be selected'),
            _ruleRow('Max 7 Players', 'From a single team'),
            const Divider(height: 32),
            const Text(
              'Role Constraints:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 12),
            _ruleRow('WK (Keeper)', '1 - 4'),
            _ruleRow('BAT (Batsman)', '3 - 6'),
            _ruleRow('AR (All-rounder)', '1 - 4'),
            _ruleRow('BOWL (Bowler)', '3 - 6'),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _ruleRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 14, color: Colors.black87)),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black)),
        ],
      ),
    );
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _getTitle() {
    final a =
        (_matchInfo?['teama'] as Map<String, dynamic>?)?.tryString('short_name') ??
        'Team A';
    final b =
        (_matchInfo?['teamb'] as Map<String, dynamic>?)?.tryString('short_name') ??
        'Team B';
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
    body: SafeArea(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 3,
            ),
            const SizedBox(height: 20),
            Text(
              'Loading Squad…',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _errView() => Scaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(
      backgroundColor: Colors.white,
      iconTheme: const IconThemeData(color: Colors.black),
      title: const Text('Create Team', style: TextStyle(color: Colors.black)),
    ),
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 60, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _loadSquad,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    ),
  );

  // ─────────────────────────────────────────────────────────────────────────
  //  SELECT SCREEN
  // ─────────────────────────────────────────────────────────────────────────
  Widget _selectScreen() {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _selectHeader(),
            Expanded(child: _playerList()),
            _bottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _selectHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
      decoration: const BoxDecoration(
        color: AppColors.primary,
      ),
      child: Column(
        children: [
          // Title Row
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getTitle(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Row(
                      children: [
                        const Text(
                          'Select 11 Players',
                          style: TextStyle(color: Colors.white60, fontSize: 11),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: _showRulesPopup,
                          child: const Icon(
                            Icons.help_outline,
                            color: Colors.white60,
                            size: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _remaining.toStringAsFixed(1),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  ),
                  const Text(
                    'Credits Left',
                    style: TextStyle(color: Colors.white60, fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Credits progress bar — use LayoutBuilder to avoid overflow
          LayoutBuilder(
            builder: (ctx, constraints) {
              final fraction = (_usedCredits / _totalCredits).clamp(0.0, 1.0);
              return Stack(
                children: [
                  Container(
                    height: 4,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Container(
                    height: 4,
                    width: constraints.maxWidth * fraction,
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          // Role badges
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              'WK',
              'BAT',
              'AR',
              'BOWL',
            ].map((r) => _roleBadge(r)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _roleBadge(String role) {
    final count = _rc(role);
    final color = _roleClr[role]!;
    final min = _minRole[role] ?? 1;
    final max = _maxRole[role] ?? 6;
    final full = count >= max;
    final isInvalid = _count == 11 && (count < min || count > max);

    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isInvalid ? Colors.red : (count > 0 ? color : Colors.white12),
            shape: BoxShape.circle,
            border: Border.all(
              color: isInvalid ? Colors.redAccent : (full ? AppColors.secondary : color.withOpacity(0.3)),
              width: 1.5,
            ),
          ),
          child: Center(
            child: Text(
              '$count',
              style: TextStyle(
                color: (count > 0 || isInvalid) ? Colors.white : Colors.white38,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          role,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          '${_minRole[role]}-${_maxRole[role]}',
          style: const TextStyle(color: Colors.white30, fontSize: 8),
        ),
      ],
    );
  }


  Widget _playerList() {
    final list = _filtered;
    final teamAPlayers = list.where((p) => p.teamShort == ((_matchInfo?['teama'] as Map<String, dynamic>?)?.tryString('short_name') ?? 'TM A')).toList();
    final teamBPlayers = list.where((p) => p.teamShort == ((_matchInfo?['teamb'] as Map<String, dynamic>?)?.tryString('short_name') ?? 'TM B')).toList();

    if (list.isEmpty) {
      return Container(color: Colors.white, child: _emptyState());
    }

    return Container(
      color: Colors.white,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Team A Players Column
                  Expanded(
                    child: Column(
                      children: [
                        _teamColumnHeader('TEAM A', AppColors.primary, teamAPlayers.length),
                        ...teamAPlayers.map(_playerTile).toList(),
                      ],
                    ),
                  ),
                  // Vertical Divider
                  Container(
                    width: 0.8,
                    color: Colors.grey.shade200,
                  ),
                  // Team B Players Column
                  Expanded(
                    child: Column(
                      children: [
                        _teamColumnHeader('TEAM B', AppColors.primary, teamBPlayers.length),
                        ...teamBPlayers.map(_playerTile).toList(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Minimal padding for scroll space
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _teamColumnHeader(String teamName, Color color, int playerCount) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    decoration: BoxDecoration(
      color: color.withOpacity(0.06),
      border: Border(
        bottom: BorderSide(color: color.withOpacity(0.1)),
        top: BorderSide(color: color.withOpacity(0.05)),
      ),
    ),
    child: Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            teamName,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$playerCount',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _emptyState() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.sports_cricket, size: 48, color: Colors.grey.shade300),
        const SizedBox(height: 12),
        Text(
          'No players found',
          style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
        ),
      ],
    ),
  );

  Widget _colHeader() => Container(
    color: Colors.grey.shade100,
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
    child: Row(
      children: [
        const SizedBox(width: 50),
        Expanded(
          child: Text(
            'PLAYER',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(
          width: 90,
          child: Text(
            'STATS',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        SizedBox(
          width: 50,
          child: Text(
            'CREDITS',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(width: 36),
      ],
    ),
  );

  Widget _teamDivider(String team) => Container(
    color: Colors.grey.shade200,
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
    child: Text(
      team,
      style: TextStyle(
        color: Colors.grey.shade800,
        fontWeight: FontWeight.bold,
        fontSize: 13,
      ),
    ),
  );

  Widget _playerTile(_Player p) {
    final sel = _selected.contains(p.id);
    final isC = _captainId == p.id;
    final isVC = _vcId == p.id;
    final canAdd = _canAdd(p) || sel;
    final clr = _roleClr[p.role] ?? AppColors.primary;

    return GestureDetector(
      onTap: () => _toggle(p),
      child: Container(
        decoration: BoxDecoration(
          color: sel ? Colors.green.shade50 : Colors.white,
          border: Border(
            left: BorderSide(
              color: sel ? Colors.green : Colors.transparent,
              width: 2,
            ),
            bottom: BorderSide(color: Colors.grey.shade100),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Row(
          children: [
            // Avatar
            Stack(
              clipBehavior: Clip.none,
              children: [
                _avatar(p.imageUrl, p.name, clr, 28),
                // Role badge
                Positioned(
                  bottom: -3,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 2.5,
                        vertical: 0.5,
                      ),
                      decoration: BoxDecoration(
                        color: clr,
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Text(
                        p.role,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 6,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                if (isC)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: _badge('C', Colors.redAccent),
                  ),
                if (isVC)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: _badge('VC', Colors.blue),
                  ),
              ],
            ),
            const SizedBox(width: 4),
            // Name + team
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.shortName,
                    style: TextStyle(
                      color: canAdd ? Colors.black : Colors.grey.shade400,
                      fontWeight: FontWeight.bold,
                      fontSize: 10.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    p.teamShort,
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 8),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 2),
            // Stats
            SizedBox(width: 38, child: _statsSection(p)),
            // Credits
            SizedBox(
              width: 28,
              child: Text(
                p.credits.toStringAsFixed(1),
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            // Toggle
            SizedBox(
              width: 24,
              child: Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: sel
                        ? Colors.green
                        : canAdd
                        ? AppColors.primary
                        : Colors.grey.shade300,
                  ),
                  child: Icon(
                    sel ? Icons.check : Icons.add,
                    color: Colors.white,
                    size: 13,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statsSection(_Player p) {
    if (p.role == 'BOWL' && p.wickets.isNotEmpty) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _stat('${p.wickets}W', Colors.orange.shade800),
          if (p.economy.isNotEmpty)
            _stat('Ec ${p.economy}', Colors.orange.shade700),
        ],
      );
    }
    if (p.runs.isNotEmpty) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _stat(
            '${p.runs}${p.balls.isNotEmpty ? " (${p.balls})" : ""}',
            Colors.blue.shade800,
          ),
          if (p.strikeRate.isNotEmpty)
            _stat('S ${p.strikeRate}', Colors.green.shade800),
        ],
      );
    }
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        '${p.rating.toStringAsFixed(1)} pts',
        style: TextStyle(color: Colors.grey.shade500, fontSize: 9.5),
        textAlign: TextAlign.center,
        maxLines: 1,
      ),
    );
  }

  Widget _stat(String text, Color color) => FittedBox(
    fit: BoxFit.scaleDown,
    child: Text(
      text,
      style: TextStyle(color: color, fontSize: 8.5, fontWeight: FontWeight.bold),
      textAlign: TextAlign.center,
      maxLines: 1,
    ),
  );

  Widget _bottomBar() => Container(
    padding: EdgeInsets.only(
      left: 16,
      right: 16,
      top: 12,
      bottom: MediaQuery.of(context).padding.bottom + 12,
    ),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border(top: BorderSide(color: Colors.grey.shade200)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 10,
          offset: const Offset(0, -4),
        ),
      ],
    ),
    child: Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$_count / 11',
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              'Players',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(width: 16),
        // Mini role breakdown
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: ['WK', 'BAT', 'AR', 'BOWL'].map((r) {
              final c = _rc(r);
              final clr = _roleClr[r]!;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$c',
                      style: TextStyle(
                        color: c > 0 ? clr : Colors.grey.shade400,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      r,
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        GestureDetector(
          onTap: _canProceed
              ? () => setState(() => _showCaptainScreen = true)
              : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: _canProceed
                  ? AppColors.primary
                  : Colors.grey.shade400,
              borderRadius: BorderRadius.circular(20),
              boxShadow: _canProceed ? [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              ] : null,
            ),
            child: Text(
              _canProceed 
                  ? 'Next →' 
                  : (_count == 11 ? 'Check Roles' : 'Add ${11 - _count}'),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ],
    ),
  );

  // ─────────────────────────────────────────────────────────────────────────
  //  CAPTAIN / VC SCREEN
  // ─────────────────────────────────────────────────────────────────────────
  Widget _captainScreen() => Scaffold(
    backgroundColor: Colors.grey[50],
    body: SafeArea(
      bottom: false,
      child: Column(
        children: [
          _captainHeader(),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.grey.shade600, size: 15),
                const SizedBox(width: 6),
                Text(
                  'C gets 2x pts  •  VC gets 1.5x pts',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          _teamNameInput(),
          Expanded(
            child: ListView(
              children: [
                ..._selectedPlayers.map(_captainTile),
                const SizedBox(height: 100),
              ],
            ),
          ),
          _captainBottomBar(),
        ],
      ),
    ),
  );

  Widget _captainHeader() => Container(
    padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
    decoration: const BoxDecoration(
      color: AppColors.primary,
    ),
    child: Row(
      children: [
        GestureDetector(
          onTap: () => setState(() => _showCaptainScreen = false),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white12,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choose Captain & VC',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                'Select from your 11 players',
                style: TextStyle(color: Colors.white60, fontSize: 11),
              ),
            ],
          ),
        ),
        Row(
          children: [
            _badge('C', AppColors.primary),
            const SizedBox(width: 8),
            _badge('VC', AppColors.secondary),
          ],
        ),
      ],
    ),
  );

  Widget _captainTile(_Player p) {
    final isC = _captainId == p.id;
    final isVC = _vcId == p.id;
    final clr = _roleClr[p.role] ?? AppColors.primary;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (isC || isVC) ? AppColors.primary.withOpacity(0.3) : Colors.grey.shade100,
          width: (isC || isVC) ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          _avatar(p.imageUrl, p.name, clr, 42),
          const SizedBox(width: 12),
          // Name + role
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                _captainRoleBadge(p.role, clr),
              ],
            ),
          ),
          // C/VC Buttons
          Row(
            children: [
              _cvBtn('C', isC, AppColors.primary, () {
                setState(() {
                  if (isC) {
                    _captainId = null;
                  } else {
                    _captainId = p.id;
                    if (isVC) _vcId = null;
                  }
                });
              }),
              const SizedBox(width: 10),
              _cvBtn('VC', isVC, AppColors.primary.withOpacity(0.8), () {
                setState(() {
                  if (isVC) {
                    _vcId = null;
                  } else {
                    _vcId = p.id;
                    if (isC) _captainId = null;
                  }
                });
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _captainRoleBadge(String role, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text(
      _roleLabels[role] ?? role,
      style: TextStyle(
        color: color,
        fontSize: 9,
        fontWeight: FontWeight.bold,
      ),
    ),
  );

  Widget _cvBtn(String label, bool active, Color color, VoidCallback fn) =>
      GestureDetector(
        onTap: fn,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: active ? color : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: active ? color : Colors.grey.shade300,
              width: 1.5,
            ),
            boxShadow: active ? [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              )
            ] : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: active ? Colors.white : Colors.grey.shade600,
                fontWeight: FontWeight.w900,
                fontSize: 14,
              ),
            ),
          ),
        ),
      );

  Widget _teamNameInput() => Container(
    margin: const EdgeInsets.fromLTRB(14, 8, 14, 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.03),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
      border: Border.all(color: AppColors.primary.withOpacity(0.2)),
    ),
    child: Theme(
      data: Theme.of(context).copyWith(primaryColor: AppColors.primary),
      child: TextField(
        controller: _teamNameCtrl,
        decoration: InputDecoration(
          labelText: 'Team Name',
          floatingLabelBehavior: FloatingLabelBehavior.always,
          labelStyle: const TextStyle(
            color: AppColors.primary,
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: InputBorder.none,
          hintText: 'e.g. Dream 11 Pro',
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
        ),
        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Colors.black),
      ),
    ),
  );

  Widget _captainBottomBar() {
    final ready = _captainId != null && _vcId != null;
    String cName = _captainId != null
        ? _short(
            _players
                .firstWhere(
                  (p) => p.id == _captainId,
                  orElse: () => _players.first,
                )
                .name,
          )
        : 'Not selected';
    String vName = _vcId != null
        ? _short(
            _players
                .firstWhere((p) => p.id == _vcId, orElse: () => _players.first)
                .name,
          )
        : 'Not selected';

    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _badge('C', AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      cName,
                      style: TextStyle(
                        color: _captainId != null
                            ? AppColors.primary
                            : Colors.grey.shade400,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _badge('VC', AppColors.secondary),
                    const SizedBox(width: 8),
                    Text(
                      vName,
                      style: TextStyle(
                        color: _vcId != null
                            ? AppColors.secondary
                            : Colors.grey.shade400,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: (ready && !_submitting) ? () => _submit() : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                color: (ready && !_submitting)
                    ? AppColors.primary
                    : Colors.grey.shade400,
                borderRadius: BorderRadius.circular(28),
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Create Team 🏏',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (_captainId == null || _vcId == null) {
      _snack('Please select Captain and Vice-Captain');
      return;
    }

    setState(() => _submitting = true);

    try {
      // Use the ID from the contest if it was passed, otherwise use whatever matchId we resolved
      final matchId = widget.contest != null 
          ? (int.tryParse(widget.contest!.matchId) ?? _matchRequestId ?? 1)
          : (_matchRequestId ?? 1);
      
      print('DEBUG: Saving team for matchId: $matchId');
      final playerIds = _selected
          .map((id) => int.tryParse(id) ?? 0)
          .where((id) => id != 0)
          .toList();
      final captId = int.tryParse(_captainId!) ?? 0;
      final viceCaptId = int.tryParse(_vcId!) ?? 0;

      final service = TeamsService();
      final teamRes = await service.saveTeam(
        name: _teamNameCtrl.text.isEmpty ? "My Team" : _teamNameCtrl.text,
        matchId: matchId,
        playerIds: playerIds,
        captainId: captId,
        viceCaptainId: viceCaptId,
      );

      final dynamic rawTeamId = teamRes['data']?['id'] ?? teamRes['id'] ?? teamRes['team_id'] ?? (teamRes['data'] is Map ? teamRes['data']['team_id'] : null);
      final teamId = rawTeamId?.toString() ?? '0';
      print('DEBUG: Team saved successfully. Final Team ID: $teamId');

      if (!mounted) return;
      setState(() => _submitting = false);

      _showSuccessDialog(teamId);
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      _snack('Error saving team: $e');
    }
  }

  void _showSuccessDialog(String teamId) {
    bool joiningForDialog = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_circle_outline_rounded,
                    size: 64,
                    color: Colors.green,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Team Created! 🎉',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _teamNameCtrl.text.isEmpty ? 'My Team' : _teamNameCtrl.text,
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  
                  // JOIN CONTEST BUTTON
                  if (widget.contest != null)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: joiningForDialog ? null : () async {
                          setDialogState(() => joiningForDialog = true);
                          try {
                            final userId = await UserProfileService.getSavedUserId();
                            await ContestService().joinContest(
                              contestId: widget.contest!.id,
                              teamId: teamId,
                              teamName: _teamNameCtrl.text.isEmpty ? "My Team" : _teamNameCtrl.text,
                              userId: userId,
                            );
                            
                            if (mounted) {
                              _snack('Joined contest successfully! 🏆');
                              Navigator.pop(dialogContext); // Close dialog
                              navigatorKey.currentState?.pop(); // Back to contests
                            }
                          } catch (e) {
                            setDialogState(() => joiningForDialog = false);
                            _snack('Join failed: ${e.toString().replaceAll('Exception: ', '')}');
                          }
                        },
                        icon: joiningForDialog 
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.emoji_events_rounded),
                        label: Text(joiningForDialog ? 'Joining...' : 'Join Contest 🏆'),
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
                  
                  if (widget.contest != null) const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: joiningForDialog ? null : () {
                        Navigator.pop(dialogContext); // Close dialog
                        navigatorKey.currentState?.pop(); // Back to main
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Done', style: TextStyle(color: Colors.black87)),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      ),
    );
  }

  Widget _row(String l, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Text(l, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
        const Spacer(),
        Text(
          v,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  SHARED HELPERS
// ─────────────────────────────────────────────────────────────────────────────
Widget _avatar(String url, String name, Color clr, double size) => Container(
  width: size,
  height: size,
  decoration: BoxDecoration(
    shape: BoxShape.circle,
    color: clr.withOpacity(0.12),
    border: Border.all(color: clr.withOpacity(0.3), width: 1.0),
  ),
  child: ClipOval(
    child: url.isNotEmpty
        ? Image.network(
            url,
            fit: BoxFit.cover,
            width: size,
            height: size,
            errorBuilder: (_, __, ___) => _initial(name, clr, size),
          )
        : _initial(name, clr, size),
  ),
);

Widget _initial(String name, Color clr, double size) => Center(
  child: Text(
    name.isNotEmpty ? name[0].toUpperCase() : '?',
    style: TextStyle(
      color: clr,
      fontWeight: FontWeight.bold,
      fontSize: size * 0.38,
    ),
  ),
);

Widget _badge(String label, Color color) => Container(
  padding: EdgeInsets.symmetric(
    horizontal: label.length == 1 ? 6 : 5,
    vertical: 2,
  ),
  decoration: BoxDecoration(
    color: color,
    borderRadius: BorderRadius.circular(4),
  ),
  child: Text(
    label,
    style: const TextStyle(
      color: Colors.white,
      fontSize: 9,
      fontWeight: FontWeight.bold,
    ),
  ),
);

extension _MapExt on Map<String, dynamic> {
  String? tryString(String key) => this[key]?.toString();
}
