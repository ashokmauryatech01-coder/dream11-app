import 'package:flutter/material.dart';
import 'package:fantasy_crick/core/constants/app_colors.dart';
import 'package:fantasy_crick/core/services/teams_service.dart';
import 'package:fantasy_crick/models/cricket_team_model.dart';
import 'package:fantasy_crick/features/home/widgets/team_card.dart';
import 'package:fantasy_crick/features/home/screens/team_players_screen.dart';

class TeamsScreen extends StatefulWidget {
  const TeamsScreen({super.key});

  @override
  State<TeamsScreen> createState() => _TeamsScreenState();
}

class _TeamsScreenState extends State<TeamsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TeamsService _teamsService = TeamsService();

  // Data per tab
  List<CricketTeamModel> _internationalTeams = [];
  List<CricketTeamModel> _leagueTeams = [];
  List<CricketTeamModel> _domesticTeams = [];
  List<CricketTeamModel> _womenTeams = [];

  // Loading / error states per tab
  final Map<int, bool> _loading = {0: true, 1: true, 2: true, 3: true};
  final Map<int, String?> _errors = {0: null, 1: null, 2: null, 3: null};
  final Set<int> _loaded = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadTabData(0);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      final index = _tabController.index;
      if (!_loaded.contains(index)) {
        _loadTabData(index);
      }
    }
  }

  Future<void> _loadTabData(int tabIndex) async {
    setState(() {
      _loading[tabIndex] = true;
      _errors[tabIndex] = null;
    });

    try {
      List<CricketTeamModel> result;
      switch (tabIndex) {
        case 0:
          result = await _teamsService.getInternationalTeams();
          _internationalTeams = result;
          break;
        case 1:
          result = await _teamsService.getLeagueTeams();
          _leagueTeams = result;
          break;
        case 2:
          result = await _teamsService.getDomesticTeams();
          _domesticTeams = result;
          break;
        case 3:
          result = await _teamsService.getWomenTeams();
          _womenTeams = result;
          break;
        default:
          result = [];
      }

      if (!mounted) return;
      setState(() {
        _loading[tabIndex] = false;
        _loaded.add(tabIndex);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading[tabIndex] = false;
        _errors[tabIndex] = 'Failed to load teams. Pull down to retry.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: const Text(
          'Cricket Teams',
          style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: AppColors.white),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppColors.white,
          indicatorWeight: 3,
          labelColor: AppColors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 14),
          tabAlignment: TabAlignment.start,
          tabs: const [
            Tab(text: 'International'),
            Tab(text: 'League'),
            Tab(text: 'Domestic'),
            Tab(text: 'Women'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTeamsTab(0, _internationalTeams),
          _buildTeamsTab(1, _leagueTeams),
          _buildTeamsTab(2, _domesticTeams),
          _buildTeamsTab(3, _womenTeams),
        ],
      ),
    );
  }

  Widget _buildTeamsTab(int tabIndex, List<CricketTeamModel> teamsList) {
    if (_loading[tabIndex] == true) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_errors[tabIndex] != null && teamsList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, size: 48, color: AppColors.textLight),
            const SizedBox(height: 12),
            Text(
              _errors[tabIndex]!,
              style: const TextStyle(color: AppColors.textLight),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => _loadTabData(tabIndex),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Retry', style: TextStyle(color: AppColors.white)),
            ),
          ],
        ),
      );
    }

    if (teamsList.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.groups, size: 48, color: AppColors.textLight),
            SizedBox(height: 12),
            Text('No teams found', style: TextStyle(color: AppColors.textLight)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => _loadTabData(tabIndex),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: teamsList.length,
        itemBuilder: (context, index) {
          return TeamCard(
            team: teamsList[index],
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TeamPlayersScreen(team: teamsList[index]),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
