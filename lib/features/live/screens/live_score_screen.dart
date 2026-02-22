/// ============================================================================
/// LIVE SCORE SCREEN - CricAPI Integration
/// ============================================================================
/// 
/// Uses the /cricScore endpoint for simplified live scores data
/// API Key: 2d7407ac-645c-4c1a-96bb-15647ad63f71
/// 
/// ============================================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fantasy_crick/core/constants/app_colors.dart';
import 'package:fantasy_crick/core/services/live_score_service.dart';
import 'package:fantasy_crick/models/live_score_model.dart';

class LiveScoreScreen extends StatefulWidget {
  const LiveScoreScreen({super.key});

  @override
  State<LiveScoreScreen> createState() => _LiveScoreScreenState();
}

class _LiveScoreScreenState extends State<LiveScoreScreen>
    with SingleTickerProviderStateMixin {
  final LiveScoreService _scoreService = LiveScoreService();
  
  late TabController _tabController;
  Timer? _autoRefreshTimer;
  
  List<CricScoreMatch> _allMatches = [];
  bool _isLoading = true;
  String? _error;
  DateTime? _lastUpdated;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadMatches();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _autoRefreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _loadMatches(showLoading: false),
    );
  }

  Future<void> _loadMatches({bool showLoading = true}) async {
    if (showLoading && mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    final result = await _scoreService.getLiveScores(forceRefresh: true);

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result.isSuccess && result.data != null) {
          _allMatches = result.data!;
          _lastUpdated = DateTime.now();
          _error = null;
        } else {
          _error = result.error ?? 'Failed to load matches';
        }
      });
    }
  }

  List<CricScoreMatch> get _liveMatches =>
      _allMatches.where((m) => m.isLive).toList();

  List<CricScoreMatch> get _upcomingMatches =>
      _allMatches.where((m) => m.isUpcoming).toList();

  List<CricScoreMatch> get _completedMatches =>
      _allMatches.where((m) => m.isCompleted).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMatchesList(_liveMatches, isLive: true),
                _buildMatchesList(_upcomingMatches),
                _buildMatchesList(_completedMatches, isCompleted: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.primary,
      elevation: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Live Scores',
            style: TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          if (_lastUpdated != null)
            Text(
              'Updated ${_formatTime(_lastUpdated!)}',
              style: TextStyle(
                color: AppColors.white.withOpacity(0.7),
                fontSize: 11,
              ),
            ),
        ],
      ),
      actions: [
        // API calls remaining indicator
        Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.api,
                size: 14,
                color: AppColors.white.withOpacity(0.8),
              ),
              const SizedBox(width: 4),
              Text(
                '${_scoreService.remainingApiCalls}',
                style: TextStyle(
                  color: AppColors.white.withOpacity(0.9),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.refresh, color: AppColors.white),
          onPressed: () => _loadMatches(),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: AppColors.primary,
      child: TabBar(
        controller: _tabController,
        indicatorColor: AppColors.white,
        indicatorWeight: 3,
        labelColor: AppColors.white,
        unselectedLabelColor: AppColors.white.withOpacity(0.6),
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        tabs: [
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text('Live (${_liveMatches.length})'),
              ],
            ),
          ),
          Tab(text: 'Upcoming (${_upcomingMatches.length})'),
          Tab(text: 'Completed (${_completedMatches.length})'),
        ],
      ),
    );
  }

  Widget _buildMatchesList(List<CricScoreMatch> matches,
      {bool isLive = false, bool isCompleted = false}) {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_error != null && matches.isEmpty) {
      return _buildErrorState();
    }

    if (matches.isEmpty) {
      return _buildEmptyState(isLive: isLive, isCompleted: isCompleted);
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => _loadMatches(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: matches.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _MatchCard(match: matches[index]),
          );
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) => const Padding(
        padding: EdgeInsets.only(bottom: 12),
        child: _SkeletonCard(),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off,
              size: 64,
              color: AppColors.textLight.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              _error ?? 'Something went wrong',
              style: const TextStyle(color: AppColors.textLight, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _loadMatches(),
              icon: const Icon(Icons.refresh, color: AppColors.white),
              label: const Text('Retry', style: TextStyle(color: AppColors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({bool isLive = false, bool isCompleted = false}) {
    String title;
    String subtitle;
    IconData icon;

    if (isLive) {
      title = 'No Live Matches';
      subtitle = 'Check back when matches are in progress';
      icon = Icons.live_tv;
    } else if (isCompleted) {
      title = 'No Completed Matches';
      subtitle = 'Finished matches will appear here';
      icon = Icons.check_circle_outline;
    } else {
      title = 'No Upcoming Matches';
      subtitle = 'No scheduled matches at the moment';
      icon = Icons.schedule;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: AppColors.textLight.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(color: AppColors.textLight, fontSize: 14),
          ),
          const SizedBox(height: 20),
          TextButton.icon(
            onPressed: () => _loadMatches(),
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else {
      return '${difference.inHours}h ago';
    }
  }
}

/// ============================================================================
/// MATCH CARD WIDGET
/// ============================================================================

class _MatchCard extends StatelessWidget {
  final CricScoreMatch match;

  const _MatchCard({required this.match});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: match.isLive
            ? Border.all(color: Colors.red.withOpacity(0.3), width: 2)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          _buildTeamsSection(),
          if (match.status.isNotEmpty) _buildStatus(),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          // Live indicator
          if (match.isLive)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'LIVE',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          // Series name
          Expanded(
            child: Text(
              match.seriesName,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textLight,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Match format badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: _getFormatColor(match.matchType).withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              match.formatDisplay,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: _getFormatColor(match.matchType),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamsSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildTeamRow(
            match.team1Name,
            match.team1ShortName,
            match.team1Score,
            match.team1Img,
          ),
          const SizedBox(height: 12),
          _buildTeamRow(
            match.team2Name,
            match.team2ShortName,
            match.team2Score,
            match.team2Img,
          ),
        ],
      ),
    );
  }

  Widget _buildTeamRow(
    String teamName,
    String shortName,
    String score,
    String imageUrl,
  ) {
    return Row(
      children: [
        // Team logo
        _buildTeamLogo(imageUrl, shortName),
        const SizedBox(width: 12),
        // Team name
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                teamName,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                shortName,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textLight,
                ),
              ),
            ],
          ),
        ),
        // Score
        if (score.isNotEmpty)
          Text(
            score,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          )
        else
          const Text(
            'Yet to bat',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textLight,
              fontStyle: FontStyle.italic,
            ),
          ),
      ],
    );
  }

  Widget _buildTeamLogo(String imageUrl, String shortName) {
    if (imageUrl.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          imageUrl,
          width: 40,
          height: 40,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildDefaultLogo(shortName),
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return _buildDefaultLogo(shortName);
          },
        ),
      );
    }
    return _buildDefaultLogo(shortName);
  }

  Widget _buildDefaultLogo(String shortName) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        shortName.isNotEmpty
            ? shortName.substring(0, shortName.length.clamp(0, 3))
            : '?',
        style: const TextStyle(
          color: AppColors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildStatus() {
    Color statusColor;
    IconData statusIcon;

    if (match.isLive) {
      statusColor = Colors.green;
      statusIcon = Icons.play_circle_filled;
    } else if (match.isCompleted) {
      statusColor = Colors.blue;
      statusIcon = Icons.check_circle;
    } else {
      statusColor = Colors.orange;
      statusIcon = Icons.schedule;
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(statusIcon, size: 16, color: statusColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              match.status,
              style: TextStyle(
                fontSize: 13,
                color: statusColor,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.background.withOpacity(0.5),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.sports_cricket,
            size: 14,
            color: AppColors.textLight.withOpacity(0.7),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              match.seriesName,
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textLight.withOpacity(0.7),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            _formatMatchDate(match.dateTime),
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textLight.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Color _getFormatColor(String format) {
    switch (format.toLowerCase()) {
      case 't20':
        return Colors.purple;
      case 'odi':
        return Colors.blue;
      case 'test':
        return Colors.red;
      default:
        return AppColors.primary;
    }
  }

  String _formatMatchDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final matchDate = DateTime(date.year, date.month, date.day);

    if (matchDate == today) {
      return 'Today';
    } else if (matchDate == today.add(const Duration(days: 1))) {
      return 'Tomorrow';
    } else if (matchDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}';
    }
  }
}

/// ============================================================================
/// SKELETON LOADING CARD
/// ============================================================================

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 36,
            decoration: const BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildTeamSkeleton(),
                const SizedBox(height: 12),
                _buildTeamSkeleton(),
              ],
            ),
          ),
          const Spacer(),
          Container(
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.background.withOpacity(0.5),
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamSkeleton() {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            color: AppColors.background,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 100,
                height: 14,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: 60,
                height: 10,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 50,
          height: 24,
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }
}
