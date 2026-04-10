import 'package:flutter/material.dart';
import 'package:fantasy_crick/core/constants/app_colors.dart';
import 'package:fantasy_crick/core/services/api_client.dart';
import 'package:fantasy_crick/core/services/profile_service.dart';
import 'package:fantasy_crick/core/services/location_service.dart';
import 'package:fantasy_crick/features/profile/screens/es_edit_profile_screen.dart';
import 'package:fantasy_crick/common/widgets/dashboard_animation.dart';

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
  Map<String, dynamic> _statsObj = {};
  Map<String, dynamic>? _walletObj;
  List<dynamic> _myTeams = [];
  List<dynamic> _history = [];
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
    // Refresh data when switching to specific tabs (like My Teams)
    if (_tab.indexIsChanging) return;
    if (_tab.index == 1 || _tab.index == 0) {
      print('DEBUG: Tab changed to index ${_tab.index}, refreshing data...');
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
    print('DEBUG: [EsProfileScreenState@$hashCode] _load() starting');
    try {
      // Step 1: Fetch and save Profile FIRST to establish Identity (UserId 62)
      final profileData = await ProfileService.getProfile();

      // Step 2: Fetch the rest in parallel with the correct ID established
      final results = await Future.wait([
        ProfileService.getMyTeams(),
        ProfileService.getHistory(),
        ProfileService.getLeaderboard(type: _leaderboardType),
        LocationService.getLocationData(),
        ProfileService.getUserWallets(),
      ]);
      print(
        'DEBUG: EsProfileScreen._load() results received: ${results.length}',
      );

      if (!mounted) return;

      setState(() {
        _userObj = profileData?['user'] as Map<String, dynamic>? ?? {};
        _myTeams = results[0] as List<dynamic>? ?? [];
        _history = results[1] as List<dynamic>? ?? [];
        _leaderboard = results[2] as List<dynamic>? ?? [];
        _location = results[3] as Map<String, dynamic>?;
        _walletObj = results[4] as Map<String, dynamic>?;

        // Use wallet balance if wallet exists, else 0.0
        final double balance =
            double.tryParse(_walletObj?['balance']?.toString() ?? '0') ?? 0.0;
        _userObj?['wallet_balance'] = balance;

        // Handle stats (API might return List or Map)
        final statsData = profileData?['stats'];
        if (statsData is Map) {
          _statsObj = Map<String, dynamic>.from(statsData);
        } else if (statsData is List) {
          // Alternative format: list of {label, value}
          final Map<String, dynamic> st = {};
          for (var item in statsData) {
            if (item is Map) {
              final String label = (item['label'] ?? '')
                  .toString()
                  .toLowerCase();
              final val = item['value'];
              if (label.contains('teams')) st['total_contests'] = val;
              if (label.contains('won')) st['total_wins'] = val;
              if (label.contains('rate')) st['win_rate'] = val;
              if (label.contains('points')) st['total_points'] = val;
            }
          }
          _statsObj = st;
        }

        _loading = false;
      });
      print(
        'DEBUG: EsProfileScreen._load() state updated. _myTeams.length = ${_myTeams.length}',
      );
    } catch (e) {
      print('DEBUG: EsProfileScreen._load() Error: $e');
      if (mounted) setState(() => _loading = false);
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

  // getters
  String get _name => _userObj?['name']?.toString() ?? 'Your Name';
  String get _email => _userObj?['email']?.toString() ?? '';
  String get _phone => _userObj?['phone']?.toString() ?? '';
  String get _balance => LocationService.formatAmount(
    _userObj?['wallet_balance'] ??
        _userObj?['total_points'] ??
        _userObj?['points'] ??
        0,
    _location,
  );
  String get _matches =>
      (_userObj?['teams_created'] ??
              _statsObj['total_contests'] ??
              _myTeams.length)
          .toString();
  String get _wins =>
      (_userObj?['contests_won'] ?? _statsObj['total_wins'] ?? 0).toString();
  String get _earnings =>
      LocationService.formatAmount(_statsObj['total_winnings'] ?? 0, _location);
  String get _initial => _name.isNotEmpty ? _name[0].toUpperCase() : '?';

  @override
  Widget build(BuildContext context) {
    print(
      'DEBUG: [EsProfileScreenState@$hashCode Build] _loading=$_loading, _myTeams.length=${_myTeams.length}',
    );
    return Scaffold(
      backgroundColor: AppColors.background,
      body: DashboardAnimation(
        child: RefreshIndicator(
          onRefresh: _load,
          color: AppColors.primary,
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                )
              : NestedScrollView(
                  headerSliverBuilder: (_, __) => [_appBar()],
                  body: Column(
                    children: [
                      _tabBar(),
                      Expanded(
                        child: TabBarView(
                          key: ValueKey(
                            '${_userObj?['id']}_${_myTeams.length}',
                          ),
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

  // ── APP BAR ───────────────────────────────────────────────────────────────
  SliverAppBar _appBar() => SliverAppBar(
    expandedHeight: 220,
    pinned: true,
    automaticallyImplyLeading: false,
    backgroundColor: AppColors.background,
    flexibleSpace: FlexibleSpaceBar(
      background: ClipRect(
        child: Container(
          decoration: BoxDecoration(color: AppColors.primary),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Profile',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      // Avatar circle
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.25),
                          border: Border.all(color: Colors.white, width: 2.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            _initial,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _name,
                              style: const TextStyle(
                                color: AppColors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (_email.isNotEmpty)
                              Text(
                                _email,
                                style: const TextStyle(
                                  color: AppColors.white70,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            if (_phone.isNotEmpty)
                              Text(
                                _phone,
                                style: const TextStyle(
                                  color: AppColors.white60,
                                  fontSize: 12,
                                ),
                              ),
                            const SizedBox(height: 6),
                            // Wallet balance badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.account_balance_wallet,
                                    color: AppColors.white,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _balance,
                                    style: const TextStyle(
                                      color: AppColors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Action buttons
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _iconBtn(Icons.edit_rounded, () async {
                            final changed = await Navigator.push<bool>(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EsEditProfileScreen(
                                  initialProfile: _userObj,
                                ),
                              ),
                            );
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
    ),
    actions: [
      IconButton(
        icon: const Icon(
          Icons.notifications_none_rounded,
          color: AppColors.white,
        ),
        onPressed: () {},
      ),
      IconButton(
        icon: const Icon(
          Icons.account_balance_wallet_outlined,
          color: AppColors.white,
        ),
        onPressed: () => Navigator.pushNamed(context, '/add-cash'),
      ),
      const SizedBox(width: 8),
    ],
  );

  Widget _iconBtn(IconData icon, VoidCallback fn) => GestureDetector(
    onTap: fn,
    child: Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: Colors.white, size: 18),
    ),
  );

  // ── TABS ──────────────────────────────────────────────────────────────────
  Widget _tabBar() => Container(
    color: Colors.white,
    child: TabBar(
      controller: _tab,
      indicatorColor: AppColors.primary,
      labelColor: AppColors.primary,
      unselectedLabelColor: Colors.grey[500],
      labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
      tabs: const [
        Tab(text: 'Overview'),
        Tab(text: 'My Teams'),
        Tab(text: 'History'),
        Tab(text: 'Leaderboard'),
      ],
    ),
  );

  // ── OVERVIEW TAB ──────────────────────────────────────────────────────────
  Widget _overviewTab() => ListView(
    children: [
      const SizedBox(height: 12),
      // Stats row
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            _statCard(
              'Matches',
              _matches,
              Icons.sports_cricket_rounded,
              AppColors.primary,
            ),
            const SizedBox(width: 10),
            _statCard(
              'Wins',
              _wins,
              Icons.emoji_events_rounded,
              AppColors.secondary,
            ),
            const SizedBox(width: 10),
            _statCard(
              'Earnings',
              _earnings,
              Icons.currency_rupee_rounded,
              AppColors.primary,
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      // Wallet card
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: _walletCard(),
      ),
      const SizedBox(height: 14),
      // Menu items
      _sectionTitle('Quick Actions'),
      _menuCard([
        _menuItem(
          Icons.account_balance_wallet_rounded,
          'Add Cash',
          'Add funds to wallet',
          AppColors.secondary,
          () async {
            await Navigator.pushNamed(context, '/add-cash');
            _load();
          },
        ),
        _menuItem(
          Icons.money_off_rounded,
          'Withdraw',
          'Withdraw funds to bank',
          AppColors.primary,
          () async {
            await Navigator.pushNamed(context, '/withdrawal');
            _load();
          },
        ),
        _menuItem(
          Icons.history_rounded,
          'History',
          'Contest & match history',
          AppColors.primary,
          () => _tab.animateTo(2),
        ),
        _menuItem(
          Icons.leaderboard_rounded,
          'Leaderboard',
          'See top players',
          Colors.orange,
          () => _tab.animateTo(3),
        ),
      ]),
      const SizedBox(height: 10),
      _sectionTitle('Settings'),
      _menuCard([
        _menuItem(
          Icons.public_rounded,
          'Select Country',
          _location?['country_name'] ??
              _location?['country'] ??
              'Select your location',
          Colors.blueGrey,
          _showCountryPicker,
        ),
      ]),
      const SizedBox(height: 10),
      _sectionTitle('Support'),
      _menuCard([
        _menuItem(
          Icons.help_outline_rounded,
          'How To Play',
          'Learn points & rules',
          Colors.grey,
          () {
            Navigator.pushNamed(context, '/how-to-play'); // we'll bind this
          },
        ),
        _menuItem(
          Icons.privacy_tip_outlined,
          'Privacy Policy',
          'How we use your data',
          Colors.grey,
          () {
            Navigator.pushNamed(context, '/privacy-policy');
          },
        ),
      ]),
      const SizedBox(height: 14),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: OutlinedButton.icon(
          onPressed: () => _confirmSignOut(context),
          icon: const Icon(Icons.logout_rounded, color: AppColors.primary),
          label: const Text(
            'Sign Out',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.primary),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      const SizedBox(height: 40),
    ],
  );

  Widget _statCard(String label, String val, IconData icon, Color color) =>
      Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 6),
              Text(
                val,
                style: TextStyle(
                  color: AppColors.text,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  letterSpacing: -0.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                label,
                style: TextStyle(color: AppColors.textLight, fontSize: 11),
              ),
            ],
          ),
        ),
      );

  Widget _walletBtn(String label, Color bg, Color fg) => GestureDetector(
    onTap: () async {
      if (label.contains('Add Cash')) {
        await Navigator.pushNamed(context, '/add-cash');
      } else if (label.contains('Withdraw')) {
        await Navigator.pushNamed(context, '/withdrawal');
      }
      _load();
    },
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg, width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(color: fg, fontWeight: FontWeight.bold, fontSize: 11),
      ),
    ),
  );

  Widget _walletCard() {
    final hasWallet = _walletObj != null;
    final balance =
        double.tryParse(_walletObj?['balance']?.toString() ?? '0') ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: hasWallet
          ? Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Wallet Balance',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '₹${balance.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
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
                const Text(
                  'YOUR WALLET IS NOT CONNECTED',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      setState(() => _loading = true);
                      final saved = await ProfileService.getSavedUserData();
                      final int userId = saved['id'] ?? 56;

                      await ProfileService.createWallet(
                        userId: userId,
                        initialBalance: 100.00,
                        description: "Welcome bonus wallet created",
                      );
                      _load();
                    },
                    icon: const Icon(
                      Icons.card_giftcard_rounded,
                      color: AppColors.primary,
                    ),
                    label: const Text(
                      'TAKE THE WELCOME BONUS',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                        fontSize: 12,
                        color: AppColors.primary,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _sectionTitle(String t) => Padding(
    padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
    child: Text(
      t.toUpperCase(),
      style: TextStyle(
        color: AppColors.textLight,
        fontSize: 10,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    ),
  );

  Widget _menuCard(List<Widget> items) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(14),
      boxShadow: [
        BoxShadow(
          color: AppColors.shadow,
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      children: items
          .asMap()
          .entries
          .map(
            (e) => Column(
              children: [
                e.value,
                if (e.key < items.length - 1)
                  Divider(height: 1, indent: 60, color: AppColors.border),
              ],
            ),
          )
          .toList(),
    ),
  );

  Widget _menuItem(
    IconData icon,
    String title,
    String sub,
    Color color,
    VoidCallback onTap,
  ) => ListTile(
    onTap: onTap,
    leading: Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 20),
    ),
    title: Text(
      title,
      style: TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 14,
        color: AppColors.text,
      ),
    ),
    subtitle: Text(
      sub,
      style: TextStyle(color: AppColors.textLight, fontSize: 11),
    ),
    trailing: Icon(
      Icons.chevron_right_rounded,
      color: AppColors.textLight,
      size: 20,
    ),
    dense: true,
  );

  // ── MY TEAMS TAB ──────────────────────────────────────────────────────────
  Widget _teamsTab() {
    print('DEBUG: Building _teamsTab UI. _myTeams.length = ${_myTeams.length}');

    if (_myTeams.isEmpty) {
      return _emptyState(
        Icons.groups_rounded,
        'No Teams Yet',
        'Create your first team!',
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // Count indicator
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'You have created ${_myTeams.length} teams',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          ..._myTeams
              .map((t) => _teamCard(Map<String, dynamic>.from(t)))
              .toList(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _teamCard(Map<String, dynamic> t) {
    final players = t['players'] as List<dynamic>? ?? [];
    String captainName = '';
    String viceCaptainName = '';

    for (var p in players) {
      if (p is Map) {
        final pivot = p['pivot'] as Map<String, dynamic>? ?? {};
        if (pivot['is_captain'] == 1 ||
            p['id']?.toString() == t['captain_id']?.toString()) {
          captainName = p['name']?.toString() ?? 'Player ${p['id']}';
        }
        if (pivot['is_vice_captain'] == 1 ||
            p['id']?.toString() == t['vice_captain_id']?.toString()) {
          viceCaptainName = p['name']?.toString() ?? 'Player ${p['id']}';
        }
      } else if (p is num || p is String) {
        if (p.toString() == t['captain_id']?.toString())
          captainName = 'Player $p';
        if (p.toString() == t['vice_captain_id']?.toString())
          viceCaptainName = 'Player $p';
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(
                    255,
                    24,
                    124,
                    1,
                  ).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: t['logo_url'] != null || t['thumb_url'] != null
                      ? Image.network(
                          t['logo_url'] ?? t['thumb_url'],
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.sports_cricket_rounded,
                            color: AppColors.primary,
                            size: 26,
                          ),
                        )
                      : const Icon(
                          Icons.sports_cricket_rounded,
                          color: AppColors.primary,
                          size: 26,
                        ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t['name']?.toString() ?? 'My Team',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          'Match ID: ${t['match_id'] ?? '-'}',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color:
                                (t['status']?.toString().toLowerCase() ==
                                            'active'
                                        ? Colors.green
                                        : Colors.orange)
                                    .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            t['status']?.toString().toUpperCase() ?? 'PENDING',
                            style: TextStyle(
                              color:
                                  t['status']?.toString().toLowerCase() ==
                                      'active'
                                  ? Colors.green
                                  : Colors.orange,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${players.length} players selected',
                      style: TextStyle(color: Colors.grey[400], fontSize: 11),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${t['total_points'] ?? t['points'] ?? '0.0'}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.primary,
                    ),
                  ),
                  const Text(
                    'pts',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
          if (captainName.isNotEmpty || viceCaptainName.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(height: 1, color: Colors.grey.withOpacity(0.08)),
            const SizedBox(height: 16),
            Row(
              children: [
                if (captainName.isNotEmpty)
                  Expanded(
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 12,
                          backgroundColor: AppColors.primary,
                          child: Text(
                            'C',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'CAPTAIN',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                captainName,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.text,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(width: 12),
                if (viceCaptainName.isNotEmpty)
                  Expanded(
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 12,
                          backgroundColor: AppColors.secondary,
                          child: Text(
                            'VC',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'VICE CAPTAIN',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                viceCaptainName,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.text,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ── HISTORY TAB ───────────────────────────────────────────────────────────
  Widget _historyTab() {
    if (_history.isEmpty)
      return _emptyState(
        Icons.history_rounded,
        'No History',
        'Your contest history will appear here.',
      );
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _history.length,
      itemBuilder: (_, i) {
        final h = _history[i] as Map<String, dynamic>? ?? {};
        return _historyCard(h);
      },
    );
  }

  Widget _historyCard(Map<String, dynamic> h) {
    final won = (h['result'] ?? h['status'])?.toString().toLowerCase() == 'won';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: won
                  ? Colors.green.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              won ? Icons.emoji_events_rounded : Icons.sports_cricket_rounded,
              color: won ? Colors.green : Colors.grey,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  h['match_title']?.toString() ??
                      h['title']?.toString() ??
                      'Match',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  h['contest_name']?.toString() ??
                      h['contest']?.toString() ??
                      '',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
                Text(
                  h['created_at']?.toString() ?? '',
                  style: TextStyle(color: Colors.grey[400], fontSize: 11),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                h['points']?.toString() != null ? '${h['points']} pts' : '',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                  fontSize: 13,
                ),
              ),
              if (h['winnings'] != null)
                Text(
                  LocationService.formatAmount(h['winnings'], _location),
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ── LEADERBOARD TAB ───────────────────────────────────────────────────────
  Widget _leaderboardTab() {
    return Column(
      children: [
        // Type Filter
        Container(
          margin: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              _filterBtn('weekly', 'Weekly'),
              _filterBtn('monthly', 'Monthly'),
              _filterBtn('all-time', 'All Time'),
            ],
          ),
        ),
        Expanded(
          child: _loadingLeaderboard
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                )
              : _leaderboard.isEmpty
              ? _emptyState(
                  Icons.leaderboard_rounded,
                  'No Data',
                  'Leaderboard is empty for this period.',
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: _leaderboard.length,
                  itemBuilder: (_, i) {
                    final l = _leaderboard[i] as Map<String, dynamic>? ?? {};
                    final rank = i + 1;
                    final color = rank == 1
                        ? Colors.amber
                        : rank == 2
                        ? Colors.grey.shade400
                        : rank == 3
                        ? Colors.brown.shade400
                        : null;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: rank <= 3
                            ? Border.all(color: color!.withOpacity(0.4))
                            : null,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 32,
                            child: Text(
                              '$rank',
                              style: TextStyle(
                                color: color ?? Colors.grey[400],
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(width: 10),
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: AppColors.primary.withOpacity(
                              0.15,
                            ),
                            child: Text(
                              (l['name']?.toString() ?? '?')[0].toUpperCase(),
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l['name']?.toString() ?? 'Player',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  l['level']?.toString() ?? 'Beginner',
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 11,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                LocationService.formatAmount(
                                  l['total_winnings'] ?? 0,
                                  _location,
                                ),
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                '${l['total_points'] ?? 0} pts',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _filterBtn(String type, String label) {
    final active = _leaderboardType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => _changeLeaderboardType(type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: active ? Colors.white : Colors.grey[600],
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  // ── EMPTY STATE ───────────────────────────────────────────────────────────
  Widget _emptyState(IconData icon, String title, String sub) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 64, color: Colors.grey[300]),
        const SizedBox(height: 16),
        Text(
          title,
          style: TextStyle(
            color: Colors.grey[600],
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 6),
        Text(sub, style: TextStyle(color: Colors.grey[400], fontSize: 13)),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: _load,
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: const Text('SYNC NOW'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      ],
    ),
  );

  void _showCountryPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          const Text(
            'Select Country',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const Divider(),
          ...LocationService.countries.map(
            (c) => ListTile(
              leading: Text(
                c['code'],
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              title: Text(c['name']),
              trailing: Text(
                c['symbol'],
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () async {
                await LocationService.setCountry(c);
                Navigator.pop(ctx);
                _load();
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _confirmSignOut(BuildContext ctx) => showDialog(
    context: ctx,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        'Sign Out',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: const Text('Are you sure you want to sign out?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(ctx);
            await ApiClient.clearToken();
            if (!ctx.mounted) return;
            Navigator.of(ctx).pushNamedAndRemoveUntil('/signin', (_) => false);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: const Text('Sign Out'),
        ),
      ],
    ),
  );
}
