import 'package:flutter/material.dart';
import 'package:fantasy_crick/core/constants/app_colors.dart';
import 'package:fantasy_crick/core/services/api_client.dart';
import 'package:fantasy_crick/features/profile/screens/es_edit_profile_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  PROFILE SCREEN  — white background, light cards, real API
// ─────────────────────────────────────────────────────────────────────────────
class EsProfileScreen extends StatefulWidget {
  const EsProfileScreen({super.key});

  @override
  State<EsProfileScreen> createState() => _EsProfileScreenState();
}

class _EsProfileScreenState extends State<EsProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  Map<String, dynamic>? _userObj;
  Map<String, dynamic>? _statsObj;
  List<dynamic> _myTeams = [];
  List<dynamic> _history = [];
  List<dynamic> _leaderboard = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
    _load();
  }

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        ApiClient.get('/user/profile').catchError((_) => null),
        ApiClient.get('/teams?page=1&limit=20').catchError((_) => null),
        ApiClient.get('/history?type=all&page=1&limit=20').catchError((_) => null),
        ApiClient.get('/leaderboard?type=weekly&page=1&limit=20').catchError((_) => null),
      ]);
      if (!mounted) return;
      
      final profileData = results[0]?['data'] as Map<String, dynamic>?;
      
      setState(() {
        _userObj    = profileData?['user'] as Map<String, dynamic>?;
        _statsObj   = profileData?['stats'] as Map<String, dynamic>?;
        _myTeams    = results[1]?['data']?['items'] ?? results[1]?['data'] ?? [];
        _history    = results[2]?['data']?['items'] ?? results[2]?['data'] ?? [];
        _leaderboard = results[3]?['data']?['items'] ?? results[3]?['data'] ?? [];
        _loading    = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  // getters
  String get _name    => _userObj?['name']?.toString() ?? 'Your Name';
  String get _email   => _userObj?['email']?.toString() ?? '';
  String get _phone   => _userObj?['phone']?.toString() ?? '';
  String get _balance => '₹${_userObj?['wallet_balance']?.toString() ?? _userObj?['points']?.toString() ?? '0'}';
  String get _matches => (_statsObj?['total_contests'] ?? _myTeams.length).toString();
  String get _wins    => (_statsObj?['total_wins'] ?? 0).toString();
  String get _earnings => '₹${_statsObj?['total_winnings'] ?? 0}';
  String get _initial => _name.isNotEmpty ? _name[0].toUpperCase() : '?';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppColors.primary,
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : NestedScrollView(
                headerSliverBuilder: (_,__) => [_appBar()],
                body: Column(children: [
                  _tabBar(),
                  Expanded(child: TabBarView(controller: _tab, children: [
                    _overviewTab(),
                    _teamsTab(),
                    _historyTab(),
                    _leaderboardTab(),
                  ])),
                ]),
              ),
      ),
    );
  }

  // ── APP BAR ───────────────────────────────────────────────────────────────
  SliverAppBar _appBar() => SliverAppBar(
    expandedHeight: 220,
    pinned: true,
    automaticallyImplyLeading: false,
    backgroundColor: AppColors.primary,
    flexibleSpace: FlexibleSpaceBar(
      background: ClipRect(child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFFCE404D), Color(0xFF8B1421)],
            begin: Alignment.topLeft, end: Alignment.bottomRight)),
        child: SafeArea(child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(children: [
            // Avatar circle
            Container(width: 70, height: 70,
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.25),
                border: Border.all(color: Colors.white, width: 2.5),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 8)]),
              child: Center(child: Text(_initial, style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold)))),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(_name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20), maxLines: 1, overflow: TextOverflow.ellipsis),
              if (_email.isNotEmpty) Text(_email, style: const TextStyle(color: Colors.white70, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
              if (_phone.isNotEmpty) Text(_phone, style: const TextStyle(color: Colors.white60, fontSize: 12)),
              const SizedBox(height: 6),
              // Wallet balance badge
              Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.account_balance_wallet, color: Colors.white, size: 14),
                  const SizedBox(width: 4),
                  Text(_balance, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                ])),
            ])),
            // Action buttons
            Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              _iconBtn(Icons.edit_rounded, () async {
                final changed = await Navigator.push<bool>(context, MaterialPageRoute(
                  builder: (_) => EsEditProfileScreen(initialProfile: _userObj),
                ));
                if (changed == true) _load();
              }),
              const SizedBox(height: 8),
              _iconBtn(Icons.refresh_rounded, _load),
            ]),
          ]),
        )),
      )),
    ),
    title: const Text('Profile', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
  );

  Widget _iconBtn(IconData icon, VoidCallback fn) => GestureDetector(
    onTap: fn,
    child: Container(width: 34, height: 34,
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
      child: Icon(icon, color: Colors.white, size: 18)));

  // ── TABS ──────────────────────────────────────────────────────────────────
  Widget _tabBar() => Container(
    color: Colors.white,
    child: TabBar(controller: _tab, indicatorColor: AppColors.primary,
      labelColor: AppColors.primary, unselectedLabelColor: Colors.grey[500],
      labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
      tabs: const [Tab(text: 'Overview'), Tab(text: 'My Teams'), Tab(text: 'History'), Tab(text: 'Leaderboard')]),
  );

  // ── OVERVIEW TAB ──────────────────────────────────────────────────────────
  Widget _overviewTab() => ListView(children: [
    const SizedBox(height: 12),
    // Stats row
    Padding(padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(children: [
        _statCard('Matches', _matches, Icons.sports_cricket_rounded, AppColors.primary),
        const SizedBox(width: 10),
        _statCard('Wins', _wins, Icons.emoji_events_rounded, Colors.orange),
        const SizedBox(width: 10),
        _statCard('Earnings', _earnings, Icons.currency_rupee_rounded, Colors.green),
      ])),
    const SizedBox(height: 14),
    // Wallet card
    Padding(padding: const EdgeInsets.symmetric(horizontal: 12),
      child: _walletCard()),
    const SizedBox(height: 14),
    // Menu items
    _sectionTitle('Quick Actions'),
    _menuCard([
      _menuItem(Icons.groups_rounded, 'My Teams', 'View your saved teams', Colors.blue, () => _tab.animateTo(1)),
      _menuItem(Icons.history_rounded, 'History', 'Contest & match history', Colors.purple, () => _tab.animateTo(2)),
      _menuItem(Icons.leaderboard_rounded, 'Leaderboard', 'See top players', Colors.orange, () => _tab.animateTo(3)),
    ]),
    const SizedBox(height: 10),
    _sectionTitle('Account'),
    _menuCard([
      _menuItem(Icons.account_balance_wallet_rounded, 'Add Cash', 'Top up your wallet', Colors.green, () {}),
      _menuItem(Icons.arrow_downward_rounded, 'Withdraw', 'Withdraw winnings', Colors.teal, () {}),
      _menuItem(Icons.card_giftcard_rounded, 'Refer & Earn', 'Get ₹100 per referral', Colors.pink, () {}),
      _menuItem(Icons.verified_user_rounded, 'KYC Verify', 'Complete your verification', Colors.indigo, () {}),
    ]),
    const SizedBox(height: 10),
    _sectionTitle('Support'),
    _menuCard([
      _menuItem(Icons.help_outline_rounded, 'How To Play', 'Learn points & rules', Colors.grey, () {
        Navigator.pushNamed(context, '/how-to-play'); // we'll bind this
      }),
      _menuItem(Icons.privacy_tip_outlined, 'Privacy Policy', 'How we use your data', Colors.grey, () {}),
    ]),
    const SizedBox(height: 14),
    Padding(padding: const EdgeInsets.symmetric(horizontal: 12),
      child: OutlinedButton.icon(
        onPressed: () => _confirmSignOut(context),
        icon: const Icon(Icons.logout_rounded, color: AppColors.primary),
        label: const Text('Sign Out', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.primary),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      )),
    const SizedBox(height: 40),
  ]);

  Widget _statCard(String label, String val, IconData icon, Color color) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))]),
      child: Column(children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 6),
        Text(val, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
        Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
      ])));

  Widget _walletCard() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.primary,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))]),
    child: Row(children: [
      Container(width: 44, height: 44,
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
        child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 24)),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Wallet Balance', style: TextStyle(color: Colors.white70, fontSize: 11)),
        Text(_balance, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24)),
      ])),
      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        _walletBtn('+ Add Cash', Colors.white, AppColors.primary),
        const SizedBox(height: 6),
        _walletBtn('Withdraw', Colors.transparent, Colors.white),
      ]),
    ]));

  Widget _walletBtn(String label, Color bg, Color fg) => GestureDetector(
    onTap: () {},
    child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8),
        border: Border.all(color: fg.withOpacity(0.7))),
      child: Text(label, style: TextStyle(color: fg == Colors.white ? Colors.white : AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold))));

  Widget _sectionTitle(String t) => Padding(
    padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
    child: Text(t.toUpperCase(), style: TextStyle(color: Colors.grey[500], fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)));

  Widget _menuCard(List<Widget> items) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))]),
    child: Column(children: items.asMap().entries.map((e) => Column(children: [
      e.value,
      if (e.key < items.length - 1) Divider(height: 1, indent: 60, color: Colors.grey[100]),
    ])).toList()));

  Widget _menuItem(IconData icon, String title, String sub, Color color, VoidCallback onTap) =>
      ListTile(
        onTap: onTap,
        leading: Container(width: 38, height: 38,
          decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 20)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(sub, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
        trailing: Icon(Icons.chevron_right_rounded, color: Colors.grey[300], size: 20),
        dense: true,
      );

  // ── MY TEAMS TAB ──────────────────────────────────────────────────────────
  Widget _teamsTab() {
    if (_myTeams.isEmpty) return _emptyState(Icons.groups_rounded, 'No Teams Yet', 'Create your first team!');
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _myTeams.length,
      itemBuilder: (_, i) {
        final t = _myTeams[i] as Map<String, dynamic>? ?? {};
        return _teamCard(t);
      });
  }

  Widget _teamCard(Map<String, dynamic> t) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))]),
    child: Row(children: [
      Container(width: 44, height: 44,
        decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
        child: const Icon(Icons.sports_cricket_rounded, color: AppColors.primary, size: 22)),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(t['name']?.toString() ?? 'My Team', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        Text('Match #${t['match_id'] ?? '-'}  •  ${t['players']?.length ?? 11} players', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
        if (t['captain'] != null) Text('C: ${t['captain']}', style: TextStyle(color: Colors.grey[400], fontSize: 11)),
      ])),
      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Text(t['status']?.toString() ?? 'Saved', style: const TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold))),
        const SizedBox(height: 4),
        Text(t['total_points']?.toString() != null ? '${t['total_points']} pts' : '', style: TextStyle(color: Colors.grey[400], fontSize: 11)),
      ]),
    ]));

  // ── HISTORY TAB ───────────────────────────────────────────────────────────
  Widget _historyTab() {
    if (_history.isEmpty) return _emptyState(Icons.history_rounded, 'No History', 'Your contest history will appear here.');
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _history.length,
      itemBuilder: (_, i) {
        final h = _history[i] as Map<String, dynamic>? ?? {};
        return _historyCard(h);
      });
  }

  Widget _historyCard(Map<String, dynamic> h) {
    final won = (h['result'] ?? h['status'])?.toString().toLowerCase() == 'won';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))]),
      child: Row(children: [
        Container(width: 44, height: 44,
          decoration: BoxDecoration(
            color: won ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10)),
          child: Icon(won ? Icons.emoji_events_rounded : Icons.sports_cricket_rounded,
            color: won ? Colors.green : Colors.grey, size: 22)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(h['match_title']?.toString() ?? h['title']?.toString() ?? 'Match', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(h['contest_name']?.toString() ?? h['contest']?.toString() ?? '', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
          Text(h['created_at']?.toString() ?? '', style: TextStyle(color: Colors.grey[400], fontSize: 11)),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(h['points']?.toString() != null ? '${h['points']} pts' : '', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 13)),
          if (h['winnings'] != null) Text('₹${h['winnings']}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
        ]),
      ]));
  }

  // ── LEADERBOARD TAB ───────────────────────────────────────────────────────
  Widget _leaderboardTab() {
    if (_leaderboard.isEmpty) return _emptyState(Icons.leaderboard_rounded, 'No Data', 'Leaderboard coming soon.');
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _leaderboard.length,
      itemBuilder: (_, i) {
        final l = _leaderboard[i] as Map<String, dynamic>? ?? {};
        final rank = i + 1;
        final color = rank == 1 ? Colors.amber : rank == 2 ? Colors.grey.shade400 : rank == 3 ? Colors.brown.shade400 : null;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
            border: rank <= 3 ? Border.all(color: color!.withOpacity(0.4)) : null,
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 2))]),
          child: Row(children: [
            SizedBox(width: 32, child: Text('$rank', style: TextStyle(color: color ?? Colors.grey[400], fontWeight: FontWeight.bold, fontSize: 16), textAlign: TextAlign.center)),
            const SizedBox(width: 10),
            CircleAvatar(radius: 18, backgroundColor: AppColors.primary.withOpacity(0.15),
              child: Text((l['name']?.toString() ?? '?')[0].toUpperCase(), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold))),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l['name']?.toString() ?? 'Player', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              Text(l['email']?.toString() ?? '', style: TextStyle(color: Colors.grey[400], fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(l['total_winnings']?.toString() != null ? '₹${l['total_winnings']}' : '', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13)),
              Text(l['total_points']?.toString() != null ? '${l['total_points']} pts' : '', style: TextStyle(color: Colors.grey[400], fontSize: 11)),
            ]),
          ]),
        );
      });
  }

  // ── EMPTY STATE ───────────────────────────────────────────────────────────
  Widget _emptyState(IconData icon, String title, String sub) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(icon, size: 64, color: Colors.grey[300]),
      const SizedBox(height: 16),
      Text(title, style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold, fontSize: 18)),
      const SizedBox(height: 6),
      Text(sub, style: TextStyle(color: Colors.grey[400], fontSize: 13)),
    ]));

  void _confirmSignOut(BuildContext ctx) => showDialog(
    context: ctx,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold)),
      content: const Text('Are you sure you want to sign out?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(ctx);
            await ApiClient.clearToken();
            if (!ctx.mounted) return;
            Navigator.of(ctx).pushNamedAndRemoveUntil('/signin', (_) => false);
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
          child: const Text('Sign Out'),
        ),
      ],
    ));
}
