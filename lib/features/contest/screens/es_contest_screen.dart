import 'package:flutter/material.dart';
import 'package:fantasy_crick/core/constants/app_colors.dart';
import 'package:fantasy_crick/core/services/api_client.dart';
import 'package:fantasy_crick/features/contest/screens/es_create_team_screen.dart';
import 'package:fantasy_crick/core/services/location_service.dart';
import 'package:fantasy_crick/core/services/teams_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  CONTEST SCREEN — white background, real contests from API
// ─────────────────────────────────────────────────────────────────────────────
class EsContestScreen extends StatefulWidget {
  final List<Map<String, dynamic>> matches;
  const EsContestScreen({super.key, required this.matches});

  @override
  State<EsContestScreen> createState() => _EsContestScreenState();
}

class _EsContestScreenState extends State<EsContestScreen>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _selectedMatch;
  List<dynamic> _contests = [];
  bool _loading = false;
  String _filter = 'all';
  late TabController _filterTab;
  String _currencySymbol = '₹';

  int _mainTab = 0; // 0 = Contests, 1 = My Teams
  List<Map<String, dynamic>> _myTeams = [];
  bool _loadingTeams = false;

  static const _filterLabels = ['all', 'mega', 'head-to-head', 'practice'];
  static const _filterDisplay = ['All', 'Mega', 'H2H', 'Free'];

  @override
  void initState() {
    super.initState();
    _filterTab = TabController(length: _filterLabels.length, vsync: this)
      ..addListener(() {
        if (!_filterTab.indexIsChanging) {
          setState(() => _filter = _filterLabels[_filterTab.index]);
          _loadContests();
        }
      });
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
        _currencySymbol = data['currency_symbol'] ?? LocationService.getCurrencySymbol(data['currency']);
      });
    }
  }

  @override
  void dispose() { _filterTab.dispose(); super.dispose(); }

  Future<void> _loadContests() async {
    if (_selectedMatch == null) return;
    setState(() { _loading = true; _loadingTeams = true; });
    final matchId = _selectedMatch!['match_id'];
    try {
      // Fetch all contests across all matches as per user request
      final res = await ApiClient.get('/contests?type=all&page=1&limit=100');
      final teams = await TeamsService().getMyTeams(matchId);
      
      if (!mounted) return;
      final itemsList = res?['data']?['contests'] ?? res?['data']?['items'] ?? res?['data'] ?? [];
      
      List<dynamic> filtered = [];
      if (itemsList is List) {
        filtered = itemsList.where((c) {
          // Categorize based on name since type is private/public
          if (_filter == 'all') return true;
          final name = c['name']?.toString().toLowerCase() ?? '';
          if (_filter == 'mega' && (name.contains('mega') || name.contains('grand') || name.contains('winner'))) return true;
          if (_filter == 'head-to-head' && (name.contains('head') || name.contains('h2h'))) return true;
          if (_filter == 'practice' && name.contains('practice')) return true;
          return false;
        }).toList();
      }

      setState(() { 
        _contests = filtered; 
        _myTeams = teams;
        _loading = false; 
        _loadingTeams = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() { 
        _contests = _fallbackContests(); 
        _loading = false; 
        _loadingTeams = false;
      });
    }
  }

  List<Map<String, dynamic>> _fallbackContests() => [
    {'name': 'Mega Contest',       'prize_pool': '50 Lakhs', 'total_spots': 200000, 'filled_spots': 123456, 'entry_fee': 49,  'contest_type': 'mega',         'winner_percentage': 50},
    {'name': 'Head to Head',       'prize_pool': '${_currencySymbol}1,000',   'total_spots': 2,      'filled_spots': 1,      'entry_fee': 25,  'contest_type': 'head-to-head', 'winner_percentage': 50},
    {'name': 'Small League',       'prize_pool': '${_currencySymbol}10,000',  'total_spots': 50,     'filled_spots': 45,     'entry_fee': 75,  'contest_type': 'small',        'winner_percentage': 60},
    {'name': 'Free Practice',      'prize_pool': '${_currencySymbol}500',     'total_spots': 500,    'filled_spots': 200,    'entry_fee': 0,   'contest_type': 'practice',     'winner_percentage': 30},
    {'name': 'Champions League',   'prize_pool': '25 Lakhs', 'total_spots': 100000, 'filled_spots': 80000,  'entry_fee': 199, 'contest_type': 'mega',         'winner_percentage': 40},
    {'name': 'Classic H2H',        'prize_pool': '${_currencySymbol}500',     'total_spots': 2,      'filled_spots': 0,      'entry_fee': 10,  'contest_type': 'head-to-head', 'winner_percentage': 50},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[50],
      child: Column(children: [
        // Match selector
        if (widget.matches.isNotEmpty) _matchSelector(),
        
        // Main Tabs (Contests | My Teams)
        Container(
          color: Colors.white,
          child: Row(
            children: [
              Expanded(child: _mainTabBtn('Contests', 0)),
              Expanded(child: _mainTabBtn('My Teams (${_myTeams.length})', 1)),
            ],
          ),
        ),
        
        if (_mainTab == 0) ...[
          // Filter tab bar
          _filterBar(),
          // Contest list
          Expanded(child: _loading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : _contestList()),
        ] else ...[
          Expanded(child: _loadingTeams
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : _myTeamsList()),
        ]
      ]),
    );
  }

  Widget _mainTabBtn(String label, int index) {
    bool sel = _mainTab == index;
    return GestureDetector(
      onTap: () => setState(() => _mainTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: sel ? AppColors.primary : Colors.transparent, width: 2.5)),
        ),
        child: Text(label, textAlign: TextAlign.center, style: TextStyle(
          color: sel ? AppColors.primary : Colors.grey[500],
          fontWeight: sel ? FontWeight.bold : FontWeight.w500,
          fontSize: 14,
        )),
      ),
    );
  }

  // ── MATCH SELECTOR ────────────────────────────────────────────────────────
  Widget _matchSelector() => Container(
    color: Colors.white,
    padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('SELECT MATCH', style: TextStyle(color: Colors.grey[500], fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
      const SizedBox(height: 8),
      SizedBox(height: 34, child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: widget.matches.length,
        itemBuilder: (_, i) {
          final m = widget.matches[i];
          final sel = _selectedMatch?['match_id'] == m['match_id'];
          final a = (m['teama'] as Map<String, dynamic>?)?['short_name'] ?? '';
          final b = (m['teamb'] as Map<String, dynamic>?)?['short_name'] ?? '';
          final isLive = (m['status'] as int? ?? 0) == 3;
          return GestureDetector(
            onTap: () { setState(() { _selectedMatch = m; _contests = []; }); _loadContests(); },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: sel ? AppColors.primary : Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: sel ? AppColors.primary : Colors.grey.shade300)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                if (isLive) Container(width: 5, height: 5, margin: const EdgeInsets.only(right: 5),
                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
                Text('$a vs $b', style: TextStyle(
                  color: sel ? Colors.white : Colors.grey[700],
                  fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12)),
              ]),
            ),
          );
        },
      )),
    ]),
  );

  // ── FILTER BAR ────────────────────────────────────────────────────────────
  Widget _filterBar() => Container(
    color: Colors.white,
    child: TabBar(
      controller: _filterTab,
      indicatorColor: AppColors.primary,
      labelColor: AppColors.primary,
      unselectedLabelColor: Colors.grey[500],
      labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 12),
      tabs: _filterDisplay.map((f) => Tab(text: f)).toList(),
    ),
  );

  // ── CONTEST LIST ──────────────────────────────────────────────────────────
  Widget _contestList() {
    if (_contests.isEmpty) return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.emoji_events_outlined, size: 56, color: Colors.grey[300]),
      const SizedBox(height: 12),
      Text('No contests available', style: TextStyle(color: Colors.grey[500], fontSize: 15)),
      const SizedBox(height: 16),
      ElevatedButton.icon(onPressed: _loadContests, icon: const Icon(Icons.refresh_rounded),
        label: const Text('Refresh'),
        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white)),
    ]));
    return RefreshIndicator(
      onRefresh: _loadContests,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 80),
        itemCount: _contests.length,
        itemBuilder: (_, i) => _contestCard(_contests[i] as Map<String, dynamic>? ?? {})));
  }

  // ── MY TEAMS LIST ─────────────────────────────────────────────────────────
  Widget _myTeamsList() {
    if (_myTeams.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.shield_outlined, size: 56, color: Colors.grey[300]),
        const SizedBox(height: 12),
        Text('No teams created yet', style: TextStyle(color: Colors.grey[500], fontSize: 15)),
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
      ]));
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
      if (pivot['is_captain'] == 1 || pivot['is_captain'] == true) capName = p['name'] ?? '-';
      if (pivot['is_vice_captain'] == 1 || pivot['is_vice_captain'] == true) vcName = p['name'] ?? '-';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                child: Text('$pts pts', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('CAPTAIN (2x)', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
              Text(capName, style: const TextStyle(fontWeight: FontWeight.bold)),
            ])),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('VICE CAPTAIN (1.5x)', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
              Text(vcName, style: const TextStyle(fontWeight: FontWeight.bold)),
            ])),
          ]),
        ],
      ),
    );
  }

  // ── CONTEST CARD ──────────────────────────────────────────────────────────
  Widget _contestCard(Map<String, dynamic> c) {
    final totalSpots  = (c['max_participants'] as num?)?.toInt() ?? (c['total_spots'] as num?)?.toInt() ?? 2;
    final filledSpots = (c['current_participants'] as num?)?.toInt() ?? (c['filled_spots'] as num?)?.toInt() ?? 0;
    final fee         = double.tryParse(c['entry_fee']?.toString() ?? '0')?.toInt() ?? 0;
    final isFree      = fee == 0;
    final prizeAmt    = double.tryParse(c['prize_pool']?.toString() ?? '0')?.toInt() ?? 0;
    final prize       = prizeAmt > 0 ? '${_currencySymbol}${prizeAmt.toString()}' : c['prize_pool']?.toString() ?? '${_currencySymbol}0';
    final winners     = double.tryParse(c['winner_percentage']?.toString() ?? '50')?.toInt() ?? 50;
    final spotsLeft   = totalSpots - filledSpots;
    final progress    = totalSpots > 0 ? (filledSpots / totalSpots).clamp(0.0, 1.0) : 0.0;
    final name        = c['name']?.toString() ?? 'Contest';
    final isGuaranteed = c['is_guaranteed'] as bool? ?? c['guaranteed'] as bool? ?? false;

    Color progressColor = progress >= 0.9 ? Colors.red : progress >= 0.6 ? Colors.orange : Colors.green;

    return GestureDetector(
      onTap: () => _showContestDetails(context, c),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Flexible(child: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis)),
                if (isGuaranteed) Container(
                  margin: const EdgeInsets.only(left: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(color: Colors.green.withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
                  child: const Text('G', style: TextStyle(color: Colors.green, fontSize: 9, fontWeight: FontWeight.bold))),
              ]),
              const SizedBox(height: 2),
              Row(children: [
                Text('Prize Pool  ', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                Text(prize.startsWith('${_currencySymbol}') ? prize : '${_currencySymbol}$prize',
                  style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 14)),
              ]),
            ])),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isFree ? Colors.green.withOpacity(0.1) : AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: isFree ? Colors.green.withOpacity(0.5) : AppColors.primary.withOpacity(0.3)),
              ),
              child: Text(isFree ? 'FREE' : '${_currencySymbol}$fee',
                style: TextStyle(color: isFree ? Colors.green : AppColors.primary, fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ]),
        ),

        Divider(height: 1, color: Colors.grey[100]),

        // Progress + stats
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
          child: Column(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(value: progress.toDouble(), minHeight: 4,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(progressColor))),
            const SizedBox(height: 6),
            Row(children: [
              Text(spotsLeft > 0 ? '$spotsLeft spots left' : 'Contest full',
                style: TextStyle(color: spotsLeft < 5 ? Colors.red : Colors.grey[600], fontSize: 11)),
              const Spacer(),
              Text('$winners% winners', style: const TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.w600)),
            ]),
          ]),
        ),

        // Join button
        Padding(
          padding: const EdgeInsets.all(12),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: spotsLeft > 0 ? () => _join(c) : null,
              icon: const Icon(Icons.group_add_rounded, size: 18),
              label: Text(spotsLeft > 0
                  ? (isFree ? 'Join Free' : 'Join Contest  ${_currencySymbol}$fee')
                  : 'Contest Full',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey[200],
                disabledForegroundColor: Colors.grey[400],
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ),
        ),
      ]),
    ));
  }

  void _join(Map<String, dynamic> contest) {
    if (_selectedMatch == null) return;
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => EsCreateTeamScreen(matchData: _selectedMatch),
    ));
  }

  void _showContestDetails(BuildContext ctx, Map<String, dynamic> c) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20))),
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Contest Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
            const Divider(height: 24),
            _detailRow('Total Spots', c['max_participants']?.toString() ?? c['total_spots']?.toString() ?? '-'),
            _detailRow('Spots Filled', c['current_participants']?.toString() ?? c['filled_spots']?.toString() ?? '-'),
            _detailRow('Entry Fee', '${_currencySymbol}${c['entry_fee']?.toString() ?? '0'}'),
            _detailRow('Prize Pool', '${_currencySymbol}${c['prize_pool']?.toString() ?? '0'}'),
            _detailRow('Winners', '${c['winner_percentage']?.toString() ?? '50'}%'),
            _detailRow('Multiple Entries', (c['multiple_entries'] == true) ? 'Allowed' : 'Not Allowed'),
            _detailRow('Contest Type', (c['type']?.toString().toUpperCase() ?? 'PUBLIC')),
            _detailRow('Guaranteed', (c['is_guaranteed'] == true || c['guaranteed'] == true) ? 'Yes' : 'No'),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _join(c);
                },
                icon: const Icon(Icons.group_add_rounded),
                label: const Text('Join Contest', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        )
      )
    );
  }

  Widget _detailRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[700], fontSize: 13)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    ),
  );
}
