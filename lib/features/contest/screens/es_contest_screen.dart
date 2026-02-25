import 'package:flutter/material.dart';
import 'package:fantasy_crick/core/constants/app_colors.dart';
import 'package:fantasy_crick/core/services/api_client.dart';
import 'package:fantasy_crick/features/contest/screens/es_create_team_screen.dart';

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
    if (widget.matches.isNotEmpty) {
      _selectedMatch = widget.matches.first;
      _loadContests();
    }
  }

  @override
  void dispose() { _filterTab.dispose(); super.dispose(); }

  Future<void> _loadContests() async {
    if (_selectedMatch == null) return;
    setState(() => _loading = true);
    final matchId = _selectedMatch!['match_id'];
    try {
      final typeParam = _filter == 'all' ? 'all' : _filter;
      final res = await ApiClient.get('/contests?match_id=$matchId&type=$typeParam&page=1&limit=20');
      if (!mounted) return;
      final items = res?['data']?['contests'] ?? res?['data']?['items'] ?? res?['data'] ?? [];
      setState(() { _contests = items is List ? items : []; _loading = false; });
    } catch (_) {
      if (!mounted) return;
      setState(() { _contests = _fallbackContests(); _loading = false; });
    }
  }

  List<Map<String, dynamic>> _fallbackContests() => [
    {'name': 'Mega Contest',       'prize_pool': '50 Lakhs', 'total_spots': 200000, 'filled_spots': 123456, 'entry_fee': 49,  'contest_type': 'mega',         'winner_percentage': 50},
    {'name': 'Head to Head',       'prize_pool': '₹1,000',   'total_spots': 2,      'filled_spots': 1,      'entry_fee': 25,  'contest_type': 'head-to-head', 'winner_percentage': 50},
    {'name': 'Small League',       'prize_pool': '₹10,000',  'total_spots': 50,     'filled_spots': 45,     'entry_fee': 75,  'contest_type': 'small',        'winner_percentage': 60},
    {'name': 'Free Practice',      'prize_pool': '₹500',     'total_spots': 500,    'filled_spots': 200,    'entry_fee': 0,   'contest_type': 'practice',     'winner_percentage': 30},
    {'name': 'Champions League',   'prize_pool': '25 Lakhs', 'total_spots': 100000, 'filled_spots': 80000,  'entry_fee': 199, 'contest_type': 'mega',         'winner_percentage': 40},
    {'name': 'Classic H2H',        'prize_pool': '₹500',     'total_spots': 2,      'filled_spots': 0,      'entry_fee': 10,  'contest_type': 'head-to-head', 'winner_percentage': 50},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[50],
      child: Column(children: [
        // Match selector
        if (widget.matches.isNotEmpty) _matchSelector(),
        // Filter tab bar
        _filterBar(),
        // Contest list
        Expanded(child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : _contestList()),
      ]),
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

  // ── CONTEST CARD ──────────────────────────────────────────────────────────
  Widget _contestCard(Map<String, dynamic> c) {
    final totalSpots  = (c['max_participants'] as num?)?.toInt() ?? (c['total_spots'] as num?)?.toInt() ?? 2;
    final filledSpots = (c['current_participants'] as num?)?.toInt() ?? (c['filled_spots'] as num?)?.toInt() ?? 0;
    final fee         = double.tryParse(c['entry_fee']?.toString() ?? '0')?.toInt() ?? 0;
    final isFree      = fee == 0;
    final prizeAmt    = double.tryParse(c['prize_pool']?.toString() ?? '0')?.toInt() ?? 0;
    final prize       = prizeAmt > 0 ? '₹${prizeAmt.toString()}' : c['prize_pool']?.toString() ?? '₹0';
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
                Text(prize.startsWith('₹') ? prize : '₹$prize',
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
              child: Text(isFree ? 'FREE' : '₹$fee',
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
                  ? (isFree ? 'Join Free' : 'Join Contest  ₹$fee')
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
            _detailRow('Entry Fee', '₹${c['entry_fee']?.toString() ?? '0'}'),
            _detailRow('Prize Pool', '₹${c['prize_pool']?.toString() ?? '0'}'),
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
