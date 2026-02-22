import 'package:flutter/material.dart';
import 'package:fantasy_crick/core/constants/app_colors.dart';
import 'package:fantasy_crick/models/match_model.dart';
import 'package:fantasy_crick/models/contest_model.dart';
import 'package:fantasy_crick/features/home/widgets/match_card.dart';
import 'package:fantasy_crick/features/contest/widgets/contest_card.dart';
import 'package:fantasy_crick/core/services/match_service.dart';
import 'package:fantasy_crick/core/services/contest_service.dart';
import 'package:fantasy_crick/features/wallet/screens/wallet_screen.dart';
import 'package:fantasy_crick/features/profile/screens/my_profile_screen1.dart';
import 'package:fantasy_crick/features/profile/screens/my_matches_screen.dart';
import 'package:fantasy_crick/features/contest/screens/contest_screen.dart';
import 'package:fantasy_crick/features/contest/screens/my_contest_screen.dart';
import 'package:fantasy_crick/features/profile/screens/notifications_screen.dart';
import 'package:fantasy_crick/features/profile/screens/account_screen.dart';
import 'package:fantasy_crick/common/widgets/beauty_dialog.dart';
import 'package:fantasy_crick/features/matches/screens/before_match_start_screen.dart';
import 'package:fantasy_crick/features/contest/screens/create_new_team_screen.dart';
import 'package:fantasy_crick/features/home/screens/series_screen.dart';
import 'package:fantasy_crick/features/home/screens/teams_screen.dart';
import 'package:fantasy_crick/features/home/screens/series_detail_screen.dart';
import 'package:fantasy_crick/features/home/screens/team_players_screen.dart';
import 'package:fantasy_crick/features/live/screens/live_matches_screen.dart';
import 'package:fantasy_crick/features/matches/screens/on_going_match_screen.dart';
import 'package:fantasy_crick/core/services/series_service.dart';
import 'package:fantasy_crick/core/services/teams_service.dart';
import 'package:fantasy_crick/models/series_model.dart';
import 'package:fantasy_crick/models/cricket_team_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _loading = true;
  List<MatchModel> _upcomingMatches = [];
  List<MatchModel> _liveMatches = [];
  List<ContestModel> _contests = [];
  List<SeriesModel> _featuredSeries = [];
  List<CricketTeamModel> _featuredTeams = [];
  int _selectedBottomNavIndex = 0;
  String? _errorMessage;
  
  final MatchService _matchService = MatchService();
  final ContestService _contestService = ContestService();
  final SeriesService _seriesService = SeriesService();
  final TeamsService _teamsService = TeamsService();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _loading = true;
        _errorMessage = null;
      });

      final matchesFuture = _matchService.getUpcomingMatches();
      final liveMatchesFuture = _matchService.getLiveMatches();
      final contestsFuture = _contestService.getFeaturedContests();
      final seriesFuture = _seriesService.getInternationalSeries();
      final teamsFuture = _teamsService.getInternationalTeams();
      
      final results = await Future.wait([matchesFuture, liveMatchesFuture, contestsFuture, seriesFuture, teamsFuture]);
      
      if (!mounted) return;

      setState(() {
        _upcomingMatches = results[0] as List<MatchModel>;
        _liveMatches = results[1] as List<MatchModel>;
        _contests = results[2] as List<ContestModel>;
        _featuredSeries = (results[3] as List<SeriesModel>).take(5).toList();
        _featuredTeams = (results[4] as List<CricketTeamModel>).take(5).toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = 'Failed to load data. Pull down to retry.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: const Text('FantasyCrick', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: AppColors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotificationsScreen()),
              );
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const UserAccountsDrawerHeader(
              accountName: Text('John Doe'),
              accountEmail: Text('john.doe@example.com'),
              currentAccountPicture: CircleAvatar(
                backgroundColor: AppColors.white,
                child: Text('JD', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
              ),
              decoration: BoxDecoration(color: AppColors.primary),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('My Profile'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const MyProfileScreen1()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('My Matches'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const MyMatchesScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.account_balance_wallet),
              title: const Text('Wallet'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const WalletScreen()));
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.sports_cricket),
              title: const Text('Cricket Series'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const SeriesScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.groups),
              title: const Text('Cricket Teams'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const TeamsScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.live_tv),
              title: const Text('Live Matches'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const LiveMatchesScreen()));
              },
            ),
          ],
        ),
      ),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedBottomNavIndex,
        onTap: (index) {
          setState(() {
            _selectedBottomNavIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Matches'),
          BottomNavigationBarItem(icon: Icon(Icons.emoji_events), label: 'Contests'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedBottomNavIndex) {
      case 0:
        return _buildHomeTab();
      case 1:
        return _buildMatchesTab();
      case 2:
        return _buildContestsTab();
      case 3:
        return _buildProfileTab();
      default:
        return _buildHomeTab();
    }
  }

  Widget _buildHomeTab() {
    return Column(
      children: [
        _buildWalletHeader(),
        Expanded(
          child: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: _loadData,
            child: _errorMessage != null && _upcomingMatches.isEmpty
                ? ListView(
                    children: [
                      const SizedBox(height: 100),
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.cloud_off, size: 48, color: AppColors.textLight),
                            const SizedBox(height: 12),
                            Text(_errorMessage!, style: const TextStyle(color: AppColors.textLight)),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: _loadData,
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                              child: const Text('Retry', style: TextStyle(color: AppColors.white)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBanner(),
                _buildQuickStats(),
                // Live Matches section
                if (_liveMatches.isNotEmpty) ...[
                  _buildSectionHeader('Live Matches', () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const LiveMatchesScreen()));
                  }),
                  SizedBox(
                    height: 170,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      scrollDirection: Axis.horizontal,
                      itemCount: _liveMatches.length,
                      itemBuilder: (context, index) {
                        return MatchCard(
                          match: _liveMatches[index],
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => OnGoingMatchScreen(match: _liveMatches[index])),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                _buildSectionHeader('Upcoming Matches', () {
                  setState(() { _selectedBottomNavIndex = 1; });
                }),
                SizedBox(
                  height: 170,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    scrollDirection: Axis.horizontal,
                    itemCount: _upcomingMatches.length,
                    itemBuilder: (context, index) {
                      return MatchCard(
                        match: _upcomingMatches[index],
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => BeforeMatchStartScreen(match: _upcomingMatches[index])),
                          );
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                _buildSectionHeader('Featured Contests', () {
                  setState(() { _selectedBottomNavIndex = 2; });
                }),
                SizedBox(
                  height: 200,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    scrollDirection: Axis.horizontal,
                    itemCount: _contests.length,
                    itemBuilder: (context, index) {
                      return ContestCard(
                        contest: _contests[index],
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => ContestScreen(contestId: _contests[index].id)));
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                _buildSectionHeader('Cricket Series', () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const SeriesScreen()));
                }),
                if (_featuredSeries.isNotEmpty)
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _featuredSeries.length,
                    itemBuilder: (context, index) {
                      final series = _featuredSeries[index];
                      return _buildSeriesListItem(series);
                    },
                  ),
                const SizedBox(height: 20),
                _buildSectionHeader('Cricket Teams', () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const TeamsScreen()));
                }),
                if (_featuredTeams.isNotEmpty)
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _featuredTeams.length,
                    itemBuilder: (context, index) {
                      final team = _featuredTeams[index];
                      return _buildTeamListItem(team);
                    },
                  ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Swipe to explore more', style: TextStyle(color: AppColors.textLight)),
                        SizedBox(width: 5),
                        Icon(Icons.swipe, color: AppColors.textLight, size: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          ),
        ),
      ],
    );
  }

  Widget _buildMatchesTab() {
    return Column(
      children: [
        _buildWalletHeader(),
        Expanded(
          child: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: _loadData,
            child: _upcomingMatches.isEmpty
                ? ListView(
                    children: [
                      const SizedBox(height: 100),
                      const Center(
                        child: Column(
                          children: [
                            Icon(Icons.sports_cricket, size: 48, color: AppColors.textLight),
                            SizedBox(height: 12),
                            Text('No matches found', style: TextStyle(color: AppColors.textLight)),
                          ],
                        ),
                      ),
                    ],
                  )
                : SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('All Matches', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.text)),
                    Text('${_upcomingMatches.length} upcoming', style: const TextStyle(color: AppColors.textLight, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 15),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _upcomingMatches.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 15),
                      child: MatchCard(
                        match: _upcomingMatches[index],
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => BeforeMatchStartScreen(match: _upcomingMatches[index])),
                          );
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          ),
        ),
      ],
    );
  }

  Widget _buildContestsTab() {
    return Column(
      children: [
        _buildWalletHeader(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Contests', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.text)),
                const SizedBox(height: 15),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _contests.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 15),
                      child: ContestCard(
                        contest: _contests[index],
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => ContestScreen(contestId: _contests[index].id)));
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 50,
                  backgroundColor: AppColors.primary,
                  child: Text('JD', style: TextStyle(color: AppColors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 15),
                const Text('John Doe', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.text)),
                const Text('john.doe@example.com', style: TextStyle(color: AppColors.textLight)),
              ],
            ),
          ),
          const SizedBox(height: 30),
          _buildProfileMenuItem(Icons.person, 'Edit Profile', () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const MyProfileScreen1()));
          }),
          _buildProfileMenuItem(Icons.emoji_events, 'My Contests', () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const MyContestScreen()));
          }),
          _buildProfileMenuItem(Icons.calendar_today, 'My Matches', () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const MyMatchesScreen()));
          }),
          _buildProfileMenuItem(Icons.account_balance_wallet, 'Wallet', () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const WalletScreen()));
          }),
          _buildProfileMenuItem(Icons.settings, 'Settings', () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const AccountScreen()));
          }),
          _buildProfileMenuItem(Icons.logout, 'Logout', () async {
            final result = await BeautyDialog.showConfirmation(
              context, 
              title: 'Logout', 
              message: 'Are you sure you want to logout?', 
              confirmText: 'Logout', 
              cancelText: 'Cancel',
            );
            if (result == true && mounted) {
              Navigator.pushReplacementNamed(context, '/signin');
            }
          }),
        ],
      ),
    );
  }

  Widget _buildProfileMenuItem(IconData icon, String title, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 24),
            const SizedBox(width: 16),
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.text)),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textLight),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletHeader() {
    return Container(
      color: AppColors.primary,
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          GestureDetector(
            onTap: () {
               Navigator.push(context, MaterialPageRoute(builder: (context) => const WalletScreen()));
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                children: [
                  Icon(Icons.account_balance_wallet, color: AppColors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    '₹500',
                    style: TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 5),
                  Icon(Icons.add_circle, color: AppColors.white, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBanner() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          const Text(
            'Win Big Today!',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Join contests and create your dream team',
            style: TextStyle(
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CreateNewTeamScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.white,
              foregroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
            ),
            child: const Text(
              'Play Now',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatCard(Icons.emoji_events, '12', 'Won', AppColors.warning),
          _buildStatCard(Icons.groups, '45', 'Teams', AppColors.primary),
          _buildStatCard(Icons.trending_up, '85%', 'Win Rate', AppColors.success),
        ],
      ),
    );
  }

  Widget _buildStatCard(IconData icon, String value, String label, Color color) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 1),
            blurRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback onSeeAll) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
          GestureDetector(
            onTap: onSeeAll,
            child: const Row(
              children: [
                Text(
                  'See All',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Icon(Icons.arrow_forward, size: 16, color: AppColors.primary),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSeriesListItem(SeriesModel series) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => SeriesDetailScreen(series: series)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              offset: const Offset(0, 1),
              blurRadius: 3,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.sports_cricket, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    series.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (series.dateRange.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(
                        series.dateRange,
                        style: const TextStyle(fontSize: 11, color: AppColors.textLight),
                      ),
                    ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textLight),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamListItem(CricketTeamModel team) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => TeamPlayersScreen(team: team)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              offset: const Offset(0, 1),
              blurRadius: 3,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.groups, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    team.teamName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (team.shortName.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(
                        team.shortName,
                        style: const TextStyle(fontSize: 11, color: AppColors.textLight),
                      ),
                    ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textLight),
          ],
        ),
      ),
    );
  }
}
