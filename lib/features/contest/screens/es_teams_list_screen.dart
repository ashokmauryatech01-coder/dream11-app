import 'package:flutter/material.dart';
import 'package:fantasy_crick/core/constants/app_colors.dart';
import 'package:fantasy_crick/core/services/teams_service.dart';
import 'package:fantasy_crick/features/contest/screens/es_team_preview_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

class EsTeamsListScreen extends StatefulWidget {
  const EsTeamsListScreen({super.key});

  @override
  State<EsTeamsListScreen> createState() => _EsTeamsListScreenState();
}

class _EsTeamsListScreenState extends State<EsTeamsListScreen> {
  List<Map<String, dynamic>> _teams = [];
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadTeams();
  }

  Future<void> _loadTeams() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final teams = await TeamsService.getAllUserTeams();
      setState(() {
        _teams = teams;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load teams: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text(
          'My Teams',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: _loadTeams,
            icon: const Icon(Icons.refresh, color: Colors.white),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _errorMessage,
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadTeams,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Retry', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    if (_teams.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sports_cricket, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No teams found',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first team to get started',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTeams,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _teams.length,
        itemBuilder: (context, index) {
          final team = _teams[index];
          return _TeamCard(
            team: team,
            onTap: () => _navigateToTeamPoints(team),
          );
        },
      ),
    );
  }

  void _navigateToTeamPoints(Map<String, dynamic> team) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EsTeamPreviewScreen(team: team),
      ),
    );
  }
}

class _TeamCard extends StatelessWidget {
  final Map<String, dynamic> team;
  final VoidCallback onTap;

  const _TeamCard({
    required this.team,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final teamName = team['name']?.toString() ?? 'My Team';
    final matchName = team['match_name']?.toString() ?? 
                     team['match']?['name']?.toString() ?? 
                     team['competition']?['title']?.toString() ?? 
                     'Unknown Match';
    final players = team['players'] as List? ?? [];
    final captainId = team['captain_id']?.toString();
    final viceCaptainId = team['vice_captain_id']?.toString();
    
    // Count players by role
    int wkCount = 0, batCount = 0, arCount = 0, bowlCount = 0;
    for (var player in players) {
      final role = _getRole(player);
      switch (role) {
        case 'WK': wkCount++; break;
        case 'BAT': batCount++; break;
        case 'AR': arCount++; break;
        case 'BOWL': bowlCount++; break;
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withOpacity(0.05),
                AppColors.primary.withOpacity(0.02),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          teamName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.text,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          matchName,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${players.length} Players',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildRoleBadge('WK', wkCount, Colors.orange),
                  const SizedBox(width: 8),
                  _buildRoleBadge('BAT', batCount, Colors.blue),
                  const SizedBox(width: 8),
                  _buildRoleBadge('AR', arCount, Colors.green),
                  const SizedBox(width: 8),
                  _buildRoleBadge('BOWL', bowlCount, Colors.purple),
                  const Spacer(),
                  if (captainId != null)
                    _buildLeaderBadge('C', AppColors.warning),
                  if (viceCaptainId != null) ...[
                    const SizedBox(width: 4),
                    _buildLeaderBadge('VC', Colors.grey),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleBadge(String role, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        '$role: $count',
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildLeaderBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _getRole(dynamic player) {
    if (player is! Map) return 'BAT';
    final role = (player['playing_role'] ?? player['role'])?.toString().toLowerCase() ?? 'bat';
    if (role.contains('wk')) return 'WK';
    if (role.contains('bat')) return 'BAT';
    if (role.contains('ar') || role.contains('all')) return 'AR';
    if (role.contains('bowl')) return 'BOWL';
    return 'BAT';
  }
}
