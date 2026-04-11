import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:fantasy_crick/core/constants/app_colors.dart';
import 'package:fantasy_crick/core/services/api_client.dart';
import 'package:fantasy_crick/core/services/profile_service.dart';
import 'package:fantasy_crick/core/services/entity_sport_service.dart';
import 'package:fantasy_crick/core/services/location_service.dart';
import 'package:fantasy_crick/core/services/teams_service.dart';
import 'package:fantasy_crick/core/services/user_profile_service.dart';
import 'package:fantasy_crick/features/profile/screens/es_edit_profile_screen.dart';
import 'package:fantasy_crick/features/contest/screens/es_create_team_screen.dart';
import 'package:fantasy_crick/features/contest/screens/es_team_preview_screen.dart';
import 'package:fantasy_crick/common/widgets/dashboard_animation.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  PROFILE SCREEN  — Modernized Dashboard
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
  Map<String, dynamic> _statsObj = {};
  Map<String, dynamic>? _walletObj;
  List<dynamic> _myTeams = [];
  List<dynamic> _history = [];
  Map<String, dynamic>? _historySummary;
  List<dynamic> _leaderboard = [];
  String _leaderboardType = 'all-time';
  bool _loading = true;
  bool _loadingLeaderboard = false;
  Map<String, dynamic>? _location;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
    _tab.addListener(_handleTabChange);
    _load();
  }

  void _handleTabChange() {
    if (_tab.indexIsChanging) return;
    if (_tab.index == 1 || _tab.index == 0) {
      _load();
    }
  }

  @override
  void dispose() {
    _tab.removeListener(_handleTabChange);
    _tab.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final profileData = await ProfileService.getProfile();
      final results = await Future.wait([
        ProfileService.getMyTeams(),
        ProfileService.getHistoryData(),
        ProfileService.getLeaderboard(type: _leaderboardType),
        LocationService.getLocationData(),
        ProfileService.getUserWallets(),
      ]);

      if (!mounted) return;

      setState(() {
        _userObj = profileData?['user'] as Map<String, dynamic>? ?? {};
        _myTeams = (results[0] as List<dynamic>? ?? []).map((t) => Map<String, dynamic>.from(t)).toList();
        final historyData = results[1] as Map<String, dynamic>?;
        _history = historyData?['transactions'] as List<dynamic>? ?? [];
        _historySummary = historyData?['summary'] as Map<String, dynamic>?;
        _leaderboard = results[2] as List<dynamic>? ?? [];
        _location = results[3] as Map<String, dynamic>?;
        _walletObj = results[4] as Map<String, dynamic>?;
        final double balance = double.tryParse(_walletObj?['balance']?.toString() ?? '0') ?? 0.0;
        _userObj?['wallet_balance'] = balance;
        final statsData = profileData?['stats'];
        if (statsData is Map) _statsObj = Map<String, dynamic>.from(statsData);
        _loading = false;
      });

      // Background background points sync for the teams
      _syncTeamPoints();
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _syncTeamPoints() async {
    final matchesToFetch = _myTeams.map((t) => int.tryParse(t['match_id']?.toString() ?? '0') ?? 0).where((id) => id > 0).toSet();
    debugPrint('FANTASY_DEBUG: Profile Sync - Matches to fetch points for: $matchesToFetch');
    
    for (final mid in matchesToFetch) {
      try {
        final ptsData = await EntitySportService.getMatchPoints(mid);
        final pMap = <String, dynamic>{};
        final ta = ptsData['points']?['teama']?['playing11'] as List? ?? [];
        final tb = ptsData['points']?['teamb']?['playing11'] as List? ?? [];
        for (var p in [...ta, ...tb]) {
          if (p is Map) pMap[p['pid']?.toString() ?? ''] = p['point'];
        }

        if (mounted) {
          setState(() {
            for (var i = 0; i < _myTeams.length; i++) {
              final teamMatchId = int.tryParse(_myTeams[i]['match_id']?.toString() ?? '0') ?? 0;
              if (teamMatchId == mid) {
                double total = 0;
                var rawPlayers = _myTeams[i]['players'];
                List<dynamic> players = [];
                
                if (rawPlayers is List) {
                  players = rawPlayers;
                } else if (rawPlayers is String) {
                  // Handle if backend returns players as JSON string
                  try {
                    players = jsonDecode(rawPlayers) as List? ?? [];
                  } catch(_) {}
                }

                final capId = _myTeams[i]['captain_id']?.toString();
                final vcId = _myTeams[i]['vice_captain_id']?.toString();
                
                debugPrint('FANTASY_DEBUG: Syncing Team ID ${_myTeams[i]['id']} (Match $mid) - Players count: ${players.length}');

                for (var p in players) {
                  final pid = (p is Map ? (p['id'] ?? p['player_id'] ?? p['pid']) : p).toString();
                  double base = double.tryParse(pMap[pid]?.toString() ?? '0') ?? 0;
                  if (pid == capId) base *= 2; else if (pid == vcId) base *= 1.5;
                  total += base;
                }
                
                _myTeams[i]['total_points'] = total.toStringAsFixed(1);
                debugPrint('FANTASY_DEBUG: Team ${_myTeams[i]['id']} Final Points: $total');
              }
            }
          });
        }
      } catch (e) {
        debugPrint('FANTASY_DEBUG: Sync Error for Match $mid: $e');
      }
    }
  }

  Future<void> _changeLeaderboardType(String type) async {
    if (type == _leaderboardType) return;
    setState(() {
      _leaderboardType = type;
      _loadingLeaderboard = true;
    });
    try {
      final list = await ProfileService.getLeaderboard(type: type);
      if (mounted) {
        setState(() {
          _leaderboard = list;
          _loadingLeaderboard = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingLeaderboard = false);
    }
  }

  String get _name => _userObj?['name']?.toString() ?? 'Player';
  String get _email => _userObj?['email']?.toString() ?? '';
  String get _phone => _userObj?['phone']?.toString() ?? '';
  String get _balance => LocationService.formatAmount(
    _userObj?['wallet_balance'] ?? _userObj?['total_points'] ?? _userObj?['points'] ?? 0,
    _location,
  );
  String get _wins => (_userObj?['contests_won'] ?? _statsObj['total_wins'] ?? 0).toString();
  String get _earnings => LocationService.formatAmount(_statsObj['total_winnings'] ?? 0, _location);
  String get _initial => _name.isNotEmpty ? _name[0].toUpperCase() : '?';

  // ── EDIT TEAM → Navigate to Create Team Screen in EDIT mode ────────────
  void _showEditTeamDialog(Map<String, dynamic> team) {
    final matchId = team['match_id']?.toString() ?? '';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EsCreateTeamScreen(
          matchData: {'match_id': matchId},
          existingTeam: team,
        ),
      ),
    ).then((result) {
      if (result == true) {
        _load(); // Refresh teams after edit
      }
    });
  }

  // ── DELETE TEAM ────────────────────────────────────────────────────────────
  void _showDeleteTeamDialog(Map<String, dynamic> team) {
    final teamId = int.tryParse(team['id']?.toString() ?? '0') ?? 0;
    final teamName = team['name']?.toString() ?? 'Team';
    bool deleting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(children: [
            Container(width: 40, height: 40, decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.delete_forever_rounded, color: Colors.red, size: 22)),
            const SizedBox(width: 12),
            const Text('Delete Team', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ]),
          content: RichText(text: TextSpan(style: const TextStyle(color: Colors.black87, fontSize: 14, height: 1.5), children: [
            const TextSpan(text: 'Are you sure you want to delete '),
            TextSpan(text: '"$teamName"', style: const TextStyle(fontWeight: FontWeight.bold)),
            const TextSpan(text: '?\n\nThis action cannot be undone.'),
          ])),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: TextStyle(color: Colors.grey[500]))),
            ElevatedButton(
              onPressed: deleting ? null : () async {
                setDialogState(() => deleting = true);
                try {
                  await TeamsService().deleteTeam(teamId: teamId);
                  if (mounted) { Navigator.pop(ctx); ScaffoldMessenger.of(this.context).showSnackBar(const SnackBar(content: Text('Team deleted successfully! 🗑️'), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating)); _load(); }
                } catch (e) {
                  setDialogState(() => deleting = false);
                  if (mounted) ScaffoldMessenger.of(this.context).showSnackBar(SnackBar(content: Text('Delete failed: ${e.toString().replaceAll('Exception: ', '')}'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating));
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
              child: deleting ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: DashboardAnimation(
        child: RefreshIndicator(
          onRefresh: _load,
          color: AppColors.primary,
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : NestedScrollView(
                  headerSliverBuilder: (_, __) => [_appBar()],
                  body: Column(
                    children: [
                      _tabBar(),
                      Expanded(
                        child: TabBarView(
                          key: ValueKey('${_userObj?['id']}_${_myTeams.length}'),
                          controller: _tab,
                          children: [
                            _overviewTab(),
                            _teamsTab(),
                            _historyTab(),
                            _leaderboardTab(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  SliverAppBar _appBar() => SliverAppBar(
    expandedHeight: 180,
    pinned: true,
    automaticallyImplyLeading: false,
    backgroundColor: AppColors.background,
    flexibleSpace: FlexibleSpaceBar(
      background: Container(
        decoration: const BoxDecoration(color: AppColors.primary),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 70, height: 70,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.25), border: Border.all(color: Colors.white, width: 2.5)),
                      child: Center(child: Text(_initial, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900))),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(_name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20), maxLines: 1, overflow: TextOverflow.ellipsis),
                          if (_email.isNotEmpty) Text(_email, style: const TextStyle(color: Colors.white70, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                          if (_phone.isNotEmpty) Text(_phone, style: const TextStyle(color: Colors.white60, fontSize: 12)),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.account_balance_wallet, color: Colors.white, size: 14),
                                const SizedBox(width: 4),
                                Text(_balance, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _iconBtn(Icons.edit_rounded, () async {
                          final changed = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => EsEditProfileScreen(initialProfile: _userObj)));
                          if (changed == true) _load();
                        }),
                        const SizedBox(height: 8),
                        _iconBtn(Icons.refresh_rounded, _load),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
    actions: const [],
  );

  Widget _iconBtn(IconData icon, VoidCallback fn) => GestureDetector(
    onTap: fn,
    child: Container(width: 34, height: 34, decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle), child: Icon(icon, color: Colors.white, size: 18)),
  );

  Widget _tabBar() => Container(
    color: Colors.white,
    child: TabBar(
      controller: _tab,
      indicatorColor: AppColors.primary,
      labelColor: AppColors.primary,
      unselectedLabelColor: Colors.grey[500],
      labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
      tabs: const [Tab(text: 'Overview'), Tab(text: 'My Teams'), Tab(text: 'History'), Tab(text: 'Leaderboard')],
    ),
  );

  Widget _overviewTab() => ListView(
    children: [
      const SizedBox(height: 12),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            _statCard('Wins', _wins, Icons.emoji_events_rounded, AppColors.secondary),
            const SizedBox(width: 10),
            _statCard('Earnings', _earnings, Icons.currency_rupee_rounded, AppColors.primary),
          ],
        ),
      ),
      const SizedBox(height: 14),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: _walletCard()),
      const SizedBox(height: 14),
      _sectionTitle('Quick Actions'),
      _menuCard([
        _menuItem(Icons.account_balance_wallet_rounded, 'Add Cash', 'Add funds to wallet', AppColors.secondary, () async { await Navigator.pushNamed(context, '/add-cash'); _load(); }),
        _menuItem(Icons.money_off_rounded, 'Withdraw', 'Withdraw funds to bank', AppColors.primary, () async { await Navigator.pushNamed(context, '/withdrawal'); _load(); }),
        _menuItem(Icons.history_rounded, 'History', 'Contest & match history', AppColors.primary, () => _tab.animateTo(2)),
        _menuItem(Icons.leaderboard_rounded, 'Leaderboard', 'See top players', Colors.orange, () => _tab.animateTo(3)),
      ]),
      const SizedBox(height: 10),
      _sectionTitle('Settings'),
      _menuCard([
        _menuItem(Icons.public_rounded, 'Select Country', _location?['country_name'] ?? _location?['country'] ?? 'Select location', Colors.blueGrey, _showCountryPicker),
      ]),
      const SizedBox(height: 10),
      _sectionTitle('Support'),
      _menuCard([
        _menuItem(Icons.help_outline_rounded, 'How To Play', 'Learn points & rules', Colors.grey, () => Navigator.pushNamed(context, '/how-to-play')),
        _menuItem(Icons.privacy_tip_outlined, 'Privacy Policy', 'Data security policy', Colors.grey, () => Navigator.pushNamed(context, '/privacy-policy')),
      ]),
      const SizedBox(height: 14),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: OutlinedButton.icon(
          onPressed: () => _confirmSignOut(context),
          icon: const Icon(Icons.logout_rounded, color: AppColors.primary),
          label: const Text('Sign Out', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
          style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.primary), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        ),
      ),
      const SizedBox(height: 40),
    ],
  );

  Widget _statCard(String label, String val, IconData icon, Color color) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border), boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 8, offset: const Offset(0, 2))]),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(val, style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w900, fontSize: 18), maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(label, style: TextStyle(color: AppColors.textLight, fontSize: 11)),
        ],
      ),
    ),
  );

  Widget _walletCard() {
    final hasWallet = _walletObj != null;
    final balance = double.tryParse(_walletObj?['balance']?.toString() ?? '0') ?? 0.0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))]),
      child: hasWallet
          ? Row(
              children: [
                Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 24)),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Wallet Balance', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11)),
                    Text('₹${balance.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                  ],
                ),
                const Spacer(),
                Column(
                  children: [
                    _walletBtn('Add Cash', Colors.white, AppColors.primary),
                    const SizedBox(height: 6),
                    _walletBtn('Withdraw', Colors.transparent, Colors.white),
                  ],
                ),
              ],
            )
          : Column(
              children: [
                const Text('YOUR WALLET IS NOT CONNECTED', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      setState(() => _loading = true);
                      final saved = await ProfileService.getSavedUserData();
                      final int userId = saved['id'] ?? 56;
                      await ProfileService.createWallet(userId: userId, initialBalance: 100.0, description: "Welcome bonus");
                      _load();
                    },
                    icon: const Icon(Icons.card_giftcard_rounded, color: AppColors.primary),
                    label: const Text('CLAIM WELCOME BONUS', style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.primary)),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _walletBtn(String label, Color bg, Color fg) => GestureDetector(
    onTap: () async {
      if (label.contains('Add Cash')) await Navigator.pushNamed(context, '/add-cash');
      else if (label.contains('Withdraw')) await Navigator.pushNamed(context, '/withdrawal');
      _load();
    },
    child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20), border: Border.all(color: fg)), child: Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.bold, fontSize: 11))),
  );

  Widget _sectionTitle(String t) => Padding(padding: const EdgeInsets.fromLTRB(14, 4, 14, 8), child: Text(t.toUpperCase(), style: TextStyle(color: AppColors.textLight, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)));

  Widget _menuCard(List<Widget> items) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 8, offset: const Offset(0, 2))], border: Border.all(color: AppColors.border)),
    child: Column(children: items.asMap().entries.map((e) => Column(children: [e.value, if (e.key < items.length - 1) Divider(height: 1, indent: 60, color: AppColors.border)])).toList()),
  );

  Widget _menuItem(IconData icon, String title, String sub, Color color, VoidCallback onTap) => ListTile(
    onTap: onTap, dense: true,
    leading: Container(width: 38, height: 38, decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color, size: 20)),
    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.text)),
    subtitle: Text(sub, style: TextStyle(color: AppColors.textLight, fontSize: 11)),
    trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textLight, size: 20),
  );

  Widget _teamsTab() {
    if (_myTeams.isEmpty) return _emptyState(Icons.groups_rounded, 'No Teams Yet', 'Create your first team!');
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Container(padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16), margin: const EdgeInsets.only(bottom: 12), decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.05), borderRadius: BorderRadius.circular(8)), child: Row(children: [const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.primary), const SizedBox(width: 8), Text('You have created ${_myTeams.length} teams', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13))])),
          ..._myTeams.map((t) => _teamCard(Map<String, dynamic>.from(t))).toList(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _teamCard(Map<String, dynamic> t) {
    final players = t['players'] as List<dynamic>? ?? [];
    String captainName = '', viceCaptainName = '';
    for (var p in players) {
      if (p is Map) {
        final pivot = p['pivot'] as Map<String, dynamic>? ?? {};
        if (pivot['is_captain'] == 1 || p['id']?.toString() == t['captain_id']?.toString()) captainName = p['name']?.toString() ?? 'Player ${p['id']}';
        if (pivot['is_vice_captain'] == 1 || p['id']?.toString() == t['vice_captain_id']?.toString()) viceCaptainName = p['name']?.toString() ?? 'Player ${p['id']}';
      }
    }
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => EsTeamPreviewScreen(team: t)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.withOpacity(0.08)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))]),
        child: Column(
          children: [
            Row(
              children: [
                Container(width: 52, height: 52, decoration: BoxDecoration(color: AppColors.secondary.withOpacity(0.08), borderRadius: BorderRadius.circular(12)), child: ClipRRect(borderRadius: BorderRadius.circular(12), child: t['logo_url'] != null ? Image.network(t['logo_url'], fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.sports_cricket_rounded, color: AppColors.primary)) : const Icon(Icons.sports_cricket_rounded, color: AppColors.primary))),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(t['name']?.toString() ?? 'My Team', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.text)), Row(children: [Text('Match ID: ${t['match_id'] ?? '-'}', style: TextStyle(color: Colors.grey[500], fontSize: 12)), const SizedBox(width: 8), Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: (t['status']?.toString().toLowerCase() == 'active' ? Colors.green : Colors.orange).withOpacity(0.1), borderRadius: BorderRadius.circular(4)), child: Text(t['status']?.toString().toUpperCase() ?? 'PENDING', style: TextStyle(color: t['status']?.toString().toLowerCase() == 'active' ? Colors.green : Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)))])])),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () => _showEditTeamDialog(t),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(6)),
                            child: const Icon(Icons.edit_rounded, size: 14, color: AppColors.primary),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _showDeleteTeamDialog(t),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(color: Colors.red.withOpacity(0.08), borderRadius: BorderRadius.circular(6)),
                            child: const Icon(Icons.delete_outline_rounded, size: 14, color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${t['total_points'] ?? t['points'] ?? '0'}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1B2430)),
                    ),
                    const Text('pts', style: TextStyle(color: Colors.grey, fontSize: 10)),
                  ],
                ),
              ],
            ),
            if (captainName.isNotEmpty || viceCaptainName.isNotEmpty) ...[
              const SizedBox(height: 16), Divider(height: 1, color: Colors.grey.withOpacity(0.08)), const SizedBox(height: 16),
              Row(children: [
                if (captainName.isNotEmpty) Expanded(child: Row(children: [const CircleAvatar(radius: 12, backgroundColor: AppColors.primary, child: Text('C', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))), const SizedBox(width: 8), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('CAPTAIN', style: TextStyle(color: Colors.grey, fontSize: 8, fontWeight: FontWeight.bold)), Text(captainName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis)]))])),
                if (viceCaptainName.isNotEmpty) Expanded(child: Row(children: [const CircleAvatar(radius: 12, backgroundColor: AppColors.secondary, child: Text('VC', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))), const SizedBox(width: 8), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('VICE CAPTAIN', style: TextStyle(color: Colors.grey, fontSize: 8, fontWeight: FontWeight.bold)), Text(viceCaptainName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis)]))])),
              ]),
            ],
            // ── BOTTOM ROW ───────────────────────────────────────────────
            const SizedBox(height: 14),
            Divider(height: 1, color: Colors.grey.withOpacity(0.08)),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.touch_app_outlined, size: 12, color: Colors.grey[400]),
                const SizedBox(width: 4),
                Text('Tap to view team', style: TextStyle(color: Colors.grey[400], fontSize: 10, fontStyle: FontStyle.italic)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _historyTab() {
    if (_history.isEmpty) return _emptyState(Icons.history_rounded, 'No History', 'Your contest history will appear here.');
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        if (_historySummary != null) _historySummarySection(),
        ..._history.map((h) => _historyCard(Map<String, dynamic>.from(h))).toList(),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _historySummarySection() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('TRANSACTION SUMMARY', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1.2, color: AppColors.primary)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _summaryItem('Deposits', _historySummary?['total_deposits'], Colors.green),
              _summaryItem('Withdrawals', _historySummary?['total_withdrawals'], Colors.red),
              _summaryItem('Winnings', _historySummary?['total_winnings'], Colors.orange),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(String label, dynamic val, Color color) {
    return Column(
      children: [
        Text(
          LocationService.formatAmount(val ?? 0, _location),
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: color),
        ),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 10)),
      ],
    );
  }

  Widget _historyCard(Map<String, dynamic> h) {
    final type = h['type']?.toString().toLowerCase() ?? '';
    final isDeposit = type == 'deposit';
    final isWinnings = type == 'winnings' || type == 'won';
    final isContestEntry = type == 'contest_entry' || type == 'entry';
    final isWithdrawal = type == 'withdrawal';
    
    IconData icon;
    Color color;
    if (isDeposit) {
      icon = Icons.add_circle_outline_rounded;
      color = Colors.green;
    } else if (isWinnings) {
      icon = Icons.emoji_events_rounded;
      color = Colors.orange;
    } else if (isContestEntry) {
      icon = Icons.sports_cricket_rounded;
      color = AppColors.primary;
    } else if (isWithdrawal) {
      icon = Icons.remove_circle_outline_rounded;
      color = Colors.red;
    } else {
      icon = Icons.account_balance_wallet_rounded;
      color = Colors.blue;
    }

    final amount = double.tryParse(h['amount']?.toString() ?? '0') ?? 0.0;
    final isNegative = isContestEntry || isWithdrawal;
    final status = h['status']?.toString().toLowerCase() ?? 'completed';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  h['description'] ?? h['match_title'] ?? type.toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.text),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  h['created_at'] ?? '',
                  style: TextStyle(color: Colors.grey[500], fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isNegative ? "-" : "+"}${LocationService.formatAmount(amount, _location)}',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: isNegative ? Colors.red : Colors.green,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: (status == 'completed' || status == 'success' ? Colors.green : Colors.orange).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    color: status == 'completed' || status == 'success' ? Colors.green : Colors.orange,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _leaderboardTab() => Column(
    children: [
      Container(margin: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(10)), child: Row(children: [_filterBtn('weekly', 'Weekly'), _filterBtn('monthly', 'Monthly'), _filterBtn('all-time', 'All Time')])),
      Expanded(child: _loadingLeaderboard ? const Center(child: CircularProgressIndicator(color: AppColors.primary)) : _leaderboard.isEmpty ? _emptyState(Icons.leaderboard_rounded, 'No Data', 'Leaderboard is empty.') : ListView.builder(padding: const EdgeInsets.symmetric(horizontal: 12), itemCount: _leaderboard.length, itemBuilder: (_, i) {
        final l = Map<String, dynamic>.from(_leaderboard[i]);
        final rank = i + 1;
        final color = rank == 1 ? Colors.amber : rank == 2 ? Colors.grey.shade400 : rank == 3 ? Colors.brown.shade400 : null;
        return Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: rank <= 3 ? Border.all(color: color!.withOpacity(0.4)) : null, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 2))]), child: Row(children: [SizedBox(width: 32, child: Text('$rank', style: TextStyle(color: color ?? Colors.grey[400], fontWeight: FontWeight.bold, fontSize: 16), textAlign: TextAlign.center)), const SizedBox(width: 10), CircleAvatar(radius: 18, backgroundColor: AppColors.primary.withOpacity(0.15), child: Text((l['name']?.toString() ?? '?')[0].toUpperCase(), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold))), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(l['name'] ?? 'Player', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)), Text(l['level'] ?? 'Beginner', style: TextStyle(color: Colors.grey[400], fontSize: 11))])), Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text(LocationService.formatAmount(l['total_winnings'] ?? 0, _location), style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13)), Text('${l['total_points'] ?? 0} pts', style: TextStyle(color: Colors.grey[400], fontSize: 11))])]));
      }))
    ],
  );

  Widget _filterBtn(String type, String label) {
    final active = _leaderboardType == type;
    return Expanded(child: GestureDetector(onTap: () => _changeLeaderboardType(type), child: Container(padding: const EdgeInsets.symmetric(vertical: 10), decoration: BoxDecoration(color: active ? AppColors.primary : Colors.transparent, borderRadius: BorderRadius.circular(10)), child: Text(label, textAlign: TextAlign.center, style: TextStyle(color: active ? Colors.white : Colors.grey[600], fontWeight: FontWeight.bold, fontSize: 12)))));
  }

  Widget _emptyState(IconData icon, String title, String sub) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, size: 64, color: Colors.grey[300]), const SizedBox(height: 16), Text(title, style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold, fontSize: 18)), const Text(''), Text(sub, style: TextStyle(color: Colors.grey[400], fontSize: 13)), const SizedBox(height: 20), ElevatedButton.icon(onPressed: _load, icon: const Icon(Icons.refresh_rounded, size: 18), label: const Text('SYNC NOW'), style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))))]));

  void _showCountryPicker() {
    showModalBottomSheet(context: context, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), builder: (ctx) => Column(mainAxisSize: MainAxisSize.min, children: [const SizedBox(height: 16), const Text('Select Country', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)), const Divider(), ...LocationService.countries.map((c) => ListTile(leading: Text(c['code'], style: const TextStyle(fontWeight: FontWeight.bold)), title: Text(c['name']), trailing: Text(c['symbol'], style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)), onTap: () async { await LocationService.setCountry(c); Navigator.pop(ctx); _load(); })), const SizedBox(height: 16)]));
  }

  void _confirmSignOut(BuildContext ctx) => showDialog(context: ctx, builder: (_) => AlertDialog(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), title: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold)), content: const Text('Are you sure you want to sign out?'), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')), ElevatedButton(onPressed: () async { Navigator.pop(ctx); await ApiClient.clearToken(); Navigator.of(ctx).pushNamedAndRemoveUntil('/signin', (_) => false); }, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white), child: const Text('Sign Out'))]));
}
