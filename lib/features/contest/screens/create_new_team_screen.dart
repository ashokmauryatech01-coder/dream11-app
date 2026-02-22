import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fantasy_crick/common/widgets/beauty_dialog.dart';
import 'package:fantasy_crick/core/constants/app_colors.dart';
import 'package:fantasy_crick/core/services/cricket_api_service.dart';

class CreateNewTeamScreen extends StatefulWidget {
  const CreateNewTeamScreen({super.key});

  @override
  State<CreateNewTeamScreen> createState() => _CreateNewTeamScreenState();
}

class _CreateNewTeamScreenState extends State<CreateNewTeamScreen> {
  final TextEditingController _teamNameController = TextEditingController();
  final double _totalCredits = 100;
  List<_Player> _players = [];
  bool _loadingPlayers = true;
  String? _errorMessage;

  final Set<String> _selectedPlayers = {};

  // Default team ID for India = 2
  final String _teamId = '2';

  @override
  void initState() {
    super.initState();
    _loadPlayers();
  }

  Future<void> _loadPlayers() async {
    try {
      setState(() {
        _loadingPlayers = true;
        _errorMessage = null;
      });

      final api = CricketApiService();
      final playersData = await api.getPlayersList(search: 'India');

      final players = <_Player>[];
      for (int i = 0; i < playersData.length; i++) {
        final p = playersData[i];
        final name = p['title'] as String? ?? 'Unknown';
        final image = p['image'] as String? ?? '';
        final id = p['id'] as String? ?? '$i';

        // Assign roles based on position in list (API doesn't provide role)
        String role;
        final credits = 8.0 + (i % 4) * 0.5; // 8.0 - 9.5 range
        if (i < 4) {
          role = 'BAT';
        } else if (i >= playersData.length - 8) {
          role = 'BOWL';
        } else if (i < 8) {
          role = 'AR';
        } else {
          role = 'WK';
        }

        players.add(_Player(
          id: id,
          name: name,
          role: role,
          credits: credits,
          imageUrl: image,
        ));
      }

      if (!mounted) return;
      setState(() {
        _players = players;
        _loadingPlayers = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingPlayers = false;
        _errorMessage = 'Failed to load players. Please try again.';
      });
    }
  }

  double get _usedCredits {
    return _players
        .where((p) => _selectedPlayers.contains(p.id))
        .fold(0.0, (sum, p) => sum + p.credits);
  }

  int get _selectedCount => _selectedPlayers.length;

  @override
  void dispose() {
    _teamNameController.dispose();
    super.dispose();
  }

  void _togglePlayer(_Player player) async {
    final isSelected = _selectedPlayers.contains(player.id);

    if (!isSelected && _selectedCount >= 11) {
      await BeautyDialog.show(
        context,
        title: 'Limit Reached',
        message: 'You can only select 11 players.',
        type: BeautyDialogType.warning,
      );
      return;
    }

    if (!isSelected && _usedCredits + player.credits > _totalCredits) {
      await BeautyDialog.show(
        context,
        title: 'Insufficient Credits',
        message: 'Not enough credits to add this player.',
        type: BeautyDialogType.error,
      );
      return;
    }

    setState(() {
      if (isSelected) {
        _selectedPlayers.remove(player.id);
      } else {
        _selectedPlayers.add(player.id);
      }
    });
  }

  Future<void> _createTeam() async {
    if (_teamNameController.text.trim().isEmpty) {
      await BeautyDialog.show(
        context,
        title: 'Team Name Required',
        message: 'Please enter a team name to continue.',
        type: BeautyDialogType.warning,
      );
      return;
    }

    if (_selectedCount != 11) {
      await BeautyDialog.show(
        context,
        title: 'Incomplete Team',
        message: 'Please select exactly 11 players.',
        type: BeautyDialogType.warning,
      );
      return;
    }

    await BeautyDialog.show(
      context,
      title: 'Team Created',
      message: 'Your team has been created successfully!',
      type: BeautyDialogType.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    final remainingCredits = (_totalCredits - _usedCredits).toStringAsFixed(1);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Create Team', style: TextStyle(color: AppColors.text, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.text),
      ),
      body: _loadingPlayers
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                      const SizedBox(height: 12),
                      Text(_errorMessage!, style: const TextStyle(color: AppColors.textLight)),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _loadPlayers,
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                        child: const Text('Retry', style: TextStyle(color: AppColors.white)),
                      ),
                    ],
                  ),
                )
              : Column(
        children: [
          _buildSummary(remainingCredits),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildTeamNameInput(),
                const SizedBox(height: 10),
                ..._buildCategorySection('Wicket Keepers'),
                const SizedBox(height: 10),
                ..._buildCategorySection('Batters'),
                const SizedBox(height: 10),
                ..._buildCategorySection('All Rounders'),
                const SizedBox(height: 10),
                ..._buildCategorySection('Bowlers'),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _createTeam,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Create Team', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(String remainingCredits) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: AppColors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildSummaryItem('Players', '$_selectedCount/11'),
          _buildSummaryItem('Credits Left', remainingCredits),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.text)),
      ],
    );
  }

  Widget _buildTeamNameInput() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        controller: _teamNameController,
        decoration: const InputDecoration(
          border: InputBorder.none,
          hintText: 'Enter Team Name',
        ),
      ),
    );
  }

  List<Widget> _buildCategorySection(String title) {
    final categoryKey = title.startsWith('Wicket')
        ? 'WK'
        : title.startsWith('Batters')
            ? 'BAT'
            : title.startsWith('All')
                ? 'AR'
                : 'BOWL';

    final players = _players.where((p) => p.role == categoryKey).toList();

    return [
      Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.text)),
      const SizedBox(height: 8),
      ...players.map(_buildPlayerTile),
    ];
  }

  Widget _buildPlayerTile(_Player player) {
    final bool selected = _selectedPlayers.contains(player.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: selected ? AppColors.primary : AppColors.border),
      ),
      child: Row(
        children: [
          player.imageUrl.isNotEmpty
              ? ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: player.imageUrl,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => CircleAvatar(
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      child: Text(player.name.isNotEmpty ? player.name[0] : '?', style: const TextStyle(color: AppColors.primary)),
                    ),
                    errorWidget: (context, url, error) => CircleAvatar(
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      child: Text(player.name.isNotEmpty ? player.name[0] : '?', style: const TextStyle(color: AppColors.primary)),
                    ),
                  ),
                )
              : CircleAvatar(
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: Text(player.name.isNotEmpty ? player.name[0] : '?', style: const TextStyle(color: AppColors.primary)),
                ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(player.name, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.text)),
                Text('${player.role} • ${player.credits} credits', style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _togglePlayer(player),
            icon: Icon(selected ? Icons.check_circle : Icons.add_circle_outline, color: selected ? AppColors.success : AppColors.primary),
          ),
        ],
      ),
    );
  }
}

class _Player {
  final String id;
  final String name;
  final String role;
  final double credits;
  final String imageUrl;

  const _Player({
    required this.id,
    required this.name,
    required this.role,
    required this.credits,
    required this.imageUrl,
  });
}
