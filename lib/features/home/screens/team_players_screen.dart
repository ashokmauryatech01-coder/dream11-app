import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fantasy_crick/core/constants/app_colors.dart';
import 'package:fantasy_crick/core/services/cricket_api_service.dart';
import 'package:fantasy_crick/models/cricket_team_model.dart';

class TeamPlayersScreen extends StatefulWidget {
  final CricketTeamModel team;

  const TeamPlayersScreen({super.key, required this.team});

  @override
  State<TeamPlayersScreen> createState() => _TeamPlayersScreenState();
}

class _TeamPlayersScreenState extends State<TeamPlayersScreen> {
  final CricketApiService _api = CricketApiService();
  bool _loading = true;
  String? _error;
  List<_PlayerInfo> _players = [];

  @override
  void initState() {
    super.initState();
    _loadPlayers();
  }

  Future<void> _loadPlayers() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await _api.getPlayersList(search: widget.team.name);
      final List<_PlayerInfo> players = [];

      for (final item in data) {
        // Players may be nested under a 'player' list
        final playerList = item['player'] as List<dynamic>?;
        if (playerList != null) {
          for (final p in playerList) {
            if (p is Map<String, dynamic>) {
              players.add(_PlayerInfo.fromJson(p));
            }
          }
        } else {
          // Direct player object
          players.add(_PlayerInfo.fromJson(item));
        }
      }

      if (!mounted) return;
      setState(() {
        _players = players;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Failed to load players. Tap to retry.';
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
        title: Text(
          widget.team.teamName,
          style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: AppColors.white),
      ),
      body: Column(
        children: [
          // Team header
          Container(
            color: AppColors.primary,
            padding: const EdgeInsets.only(left: 20, right: 20, bottom: 24),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: widget.team.imageUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: CachedNetworkImage(
                            imageUrl: widget.team.imageUrl!,
                            width: 64,
                            height: 64,
                            fit: BoxFit.cover,
                            errorWidget: (context, url, error) =>
                                const Icon(Icons.groups, color: AppColors.white, size: 32),
                          ),
                        )
                      : const Icon(Icons.groups, color: AppColors.white, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.team.teamName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.white,
                        ),
                      ),
                      if (widget.team.shortName.isNotEmpty)
                        Text(
                          widget.team.shortName,
                          style: const TextStyle(fontSize: 14, color: Colors.white70),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_players.length} Players',
                    style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          // Body
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_error != null && _players.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, size: 48, color: AppColors.textLight),
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: AppColors.textLight)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loadPlayers,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Retry', style: TextStyle(color: AppColors.white)),
            ),
          ],
        ),
      );
    }

    if (_players.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off, size: 48, color: AppColors.textLight),
            SizedBox(height: 12),
            Text('No player data available', style: TextStyle(color: AppColors.textLight)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadPlayers,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _players.length,
        itemBuilder: (context, index) {
          final player = _players[index];
          return _buildPlayerCard(player);
        },
      ),
    );
  }

  Widget _buildPlayerCard(_PlayerInfo player) {
    return Container(
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
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(22),
            ),
            child: player.imageUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: CachedNetworkImage(
                      imageUrl: player.imageUrl!,
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) =>
                          const Icon(Icons.person, color: AppColors.primary, size: 24),
                    ),
                  )
                : const Icon(Icons.person, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                  ),
                ),
                if (player.role != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      player.role!,
                      style: const TextStyle(fontSize: 12, color: AppColors.textLight),
                    ),
                  ),
              ],
            ),
          ),
          if (player.battingStyle != null || player.bowlingStyle != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (player.battingStyle != null)
                  Text(
                    player.battingStyle!,
                    style: const TextStyle(fontSize: 10, color: AppColors.textLight),
                  ),
                if (player.bowlingStyle != null)
                  Text(
                    player.bowlingStyle!,
                    style: const TextStyle(fontSize: 10, color: AppColors.textLight),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _PlayerInfo {
  final String id;
  final String name;
  final String? role;
  final String? battingStyle;
  final String? bowlingStyle;
  final String? imageUrl;

  _PlayerInfo({
    required this.id,
    required this.name,
    this.role,
    this.battingStyle,
    this.bowlingStyle,
    this.imageUrl,
  });

  factory _PlayerInfo.fromJson(Map<String, dynamic> json) {
    final id = (json['id'] ?? json['playerId'] ?? '').toString();
    final faceImgId = json['faceImageId'] as int?;
    String? imageUrl;
    if (faceImgId != null) {
      imageUrl = 'https://static.cricbuzz.com/a/img/v1/50x50/i1/c$faceImgId/player.jpg';
    }

    return _PlayerInfo(
      id: id,
      name: json['name'] as String? ?? json['fullName'] as String? ?? 'Unknown',
      role: json['role'] as String?,
      battingStyle: json['battingStyle'] as String?,
      bowlingStyle: json['bowlingStyle'] as String?,
      imageUrl: imageUrl,
    );
  }
}
