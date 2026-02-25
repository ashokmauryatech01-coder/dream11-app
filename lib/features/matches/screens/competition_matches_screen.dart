import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fantasy_crick/core/constants/app_colors.dart';
import 'package:fantasy_crick/core/services/competition_service.dart';
import 'package:fantasy_crick/models/competition_match_model.dart';

class CompetitionMatchesScreen extends StatefulWidget {
  final int competitionId;
  final String competitionName;
  final String? competitionAbbr;
  final String? season;

  const CompetitionMatchesScreen({
    super.key,
    required this.competitionId,
    required this.competitionName,
    this.competitionAbbr,
    this.season,
  });

  @override
  State<CompetitionMatchesScreen> createState() => _CompetitionMatchesScreenState();
}

class _CompetitionMatchesScreenState extends State<CompetitionMatchesScreen>
    with SingleTickerProviderStateMixin {
  final CompetitionService _service = CompetitionService();

  bool _loading = true;
  String? _error;
  List<CompetitionMatchModel> _allMatches = [];
  List<CompetitionMatchModel> _filteredMatches = [];

  late TabController _tabController;
  final List<String> _tabs = ['All', 'Live', 'Upcoming', 'Completed'];
  int _currentPage = 1;
  bool _loadingMore = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadMatches();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      _applyFilter();
    }
  }

  void _applyFilter() {
    final tab = _tabs[_tabController.index];
    setState(() {
      switch (tab) {
        case 'Live':
          _filteredMatches = _allMatches.where((m) => m.isLive).toList();
          break;
        case 'Upcoming':
          _filteredMatches = _allMatches.where((m) => m.isUpcoming).toList();
          break;
        case 'Completed':
          _filteredMatches = _allMatches.where((m) => m.isCompleted).toList();
          break;
        default:
          _filteredMatches = List.from(_allMatches);
      }
    });
  }

  Future<void> _loadMatches({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _currentPage = 1;
        _hasMore = true;
        _error = null;
      });
    }
    setState(() => _loading = true);

    try {
      final matches = await _service.getCompetitionMatches(
        cid: widget.competitionId,
        perPage: 50,
        page: _currentPage,
      );
      setState(() {
        if (refresh) {
          _allMatches = matches;
        } else {
          _allMatches = [..._allMatches, ...matches];
        }
        _hasMore = matches.length == 50;
        _loading = false;
      });
      _applyFilter();
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Failed to load matches. Pull down to retry.';
      });
    }
  }

  Future<void> _loadMoreMatches() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    _currentPage++;
    try {
      final matches = await _service.getCompetitionMatches(
        cid: widget.competitionId,
        perPage: 50,
        page: _currentPage,
      );
      setState(() {
        _allMatches = [..._allMatches, ...matches];
        _hasMore = matches.length == 50;
        _loadingMore = false;
      });
      _applyFilter();
    } catch (_) {
      _currentPage--;
      setState(() => _loadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          _buildSliverAppBar(innerBoxIsScrolled),
        ],
        body: Column(
          children: [
            _buildTabBar(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(bool innerBoxIsScrolled) {
    return SliverAppBar(
      expandedHeight: 160,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.primary,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      iconTheme: const IconThemeData(color: AppColors.white),
      flexibleSpace: FlexibleSpaceBar(
        background: _buildHeader(),
      ),
      title: AnimatedOpacity(
        opacity: innerBoxIsScrolled ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: Text(
          widget.competitionAbbr ?? widget.competitionName,
          style: const TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final hasInfo = _allMatches.isNotEmpty;
    final comp = hasInfo ? _allMatches.first.competition : null;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.secondary],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 80, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Competition icon
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.sports_cricket, color: AppColors.white, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.competitionName,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (comp != null) ...[
                          _buildInfoChip(comp.season.isNotEmpty ? comp.season : (widget.season ?? ''), Icons.calendar_today),
                          const SizedBox(width: 8),
                          _buildInfoChip(comp.matchFormat.toUpperCase(), Icons.format_list_bulleted),
                          const SizedBox(width: 8),
                          _buildInfoChip('${comp.totalMatches} Matches', Icons.sports_cricket),
                        ] else if (widget.season != null) ...[
                          _buildInfoChip(widget.season!, Icons.calendar_today),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String text, IconData icon) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 11),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
          ),
        ],
      ),
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
        unselectedLabelColor: Colors.white54,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 13),
        tabs: _tabs.map((t) {
          // Show count badge
          int count = 0;
          switch (t) {
            case 'Live': count = _allMatches.where((m) => m.isLive).length; break;
            case 'Upcoming': count = _allMatches.where((m) => m.isUpcoming).length; break;
            case 'Completed': count = _allMatches.where((m) => m.isCompleted).length; break;
            default: count = _allMatches.length;
          }
          return Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(t),
                if (!_loading && count > 0) ...[
                  const SizedBox(width: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$count',
                      style: const TextStyle(fontSize: 10, color: AppColors.white),
                    ),
                  ),
                ],
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading && _allMatches.isEmpty) {
      return _buildLoader();
    }
    if (_error != null && _allMatches.isEmpty) {
      return _buildError();
    }
    if (_filteredMatches.isEmpty && !_loading) {
      return _buildEmptyState();
    }
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => _loadMatches(refresh: true),
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollEndNotification &&
              notification.metrics.extentAfter < 200) {
            _loadMoreMatches();
          }
          return false;
        },
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
          itemCount: _filteredMatches.length + (_loadingMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == _filteredMatches.length) {
              return const Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
              );
            }
            return _buildMatchCard(_filteredMatches[index]);
          },
        ),
      ),
    );
  }

  Widget _buildLoader() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppColors.primary),
          const SizedBox(height: 16),
          Text(
            'Loading matches...',
            style: TextStyle(color: AppColors.textLight, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.cloud_off_rounded, size: 40, color: AppColors.primary),
            ),
            const SizedBox(height: 20),
            const Text(
              'Unable to Load Matches',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Something went wrong. Please try again.',
              style: const TextStyle(color: AppColors.textLight, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _loadMatches(refresh: true),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final tab = _tabs[_tabController.index];
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.sports_cricket, size: 40, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          Text(
            'No $tab Matches',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.text),
          ),
          const SizedBox(height: 8),
          Text(
            'No $tab matches available for this competition.',
            style: const TextStyle(color: AppColors.textLight, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMatchCard(CompetitionMatchModel match) {
    final isLive = match.isLive;
    final isCompleted = match.isCompleted;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: isLive
            ? Border.all(color: Colors.red.withOpacity(0.4), width: 1.5)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Match header
          _buildMatchHeader(match, isLive, isCompleted),
          // Teams & scores
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: _buildTeamsRow(match),
          ),
          // Divider
          Divider(height: 1, color: AppColors.border.withOpacity(0.5)),
          // Footer
          _buildMatchFooter(match),
        ],
      ),
    );
  }

  Widget _buildMatchHeader(CompetitionMatchModel match, bool isLive, bool isCompleted) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isLive
            ? Colors.red.withOpacity(0.05)
            : AppColors.background.withOpacity(0.5),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          // Match number / subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  match.subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textLight,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  match.statusNote,
                  style: TextStyle(
                    fontSize: 12,
                    color: isCompleted ? AppColors.success : AppColors.textLight,
                    fontWeight: isCompleted ? FontWeight.w500 : FontWeight.normal,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Status badge
          _buildStatusBadge(match, isLive, isCompleted),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(CompetitionMatchModel match, bool isLive, bool isCompleted) {
    Color bgColor;
    Color textColor;
    String label;
    Widget? prefix;

    if (isLive) {
      bgColor = Colors.red;
      textColor = Colors.white;
      label = 'LIVE';
      prefix = Container(
        width: 6,
        height: 6,
        margin: const EdgeInsets.only(right: 5),
        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
      );
    } else if (isCompleted) {
      bgColor = AppColors.success.withOpacity(0.15);
      textColor = AppColors.success;
      label = 'Completed';
    } else {
      bgColor = AppColors.primary.withOpacity(0.12);
      textColor = AppColors.primary;
      label = 'Upcoming';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (prefix != null) prefix,
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamsRow(CompetitionMatchModel match) {
    return Row(
      children: [
        // Team A
        Expanded(child: _buildTeam(match.teama, isWinner: match.winningTeamId == match.teama.teamId)),
        // VS divider
        Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'VS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              match.formatStr,
              style: const TextStyle(fontSize: 10, color: AppColors.textLight),
            ),
          ],
        ),
        // Team B
        Expanded(child: _buildTeam(match.teamb, isWinner: match.winningTeamId == match.teamb.teamId, alignRight: true)),
      ],
    );
  }

  Widget _buildTeam(TeamInfo team, {bool isWinner = false, bool alignRight = false}) {
    final nameWidget = Text(
      team.shortName.isNotEmpty ? team.shortName : team.name,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: isWinner ? AppColors.success : AppColors.text,
      ),
      textAlign: alignRight ? TextAlign.right : TextAlign.left,
    );

    final scoreWidget = team.scoresFull.isNotEmpty
        ? Text(
            team.scoresFull,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isWinner ? AppColors.success : AppColors.textLight,
            ),
            textAlign: alignRight ? TextAlign.right : TextAlign.left,
          )
        : const SizedBox.shrink();

    return Column(
      crossAxisAlignment: alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        // Logo placeholder
        Container(
          width: 40,
          height: 40,
          margin: const EdgeInsets.only(bottom: 6),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: team.logoUrl.isNotEmpty
                ? Image.network(
                    team.logoUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.sports_cricket,
                      size: 22,
                      color: AppColors.primary,
                    ),
                  )
                : const Icon(Icons.sports_cricket, size: 22, color: AppColors.primary),
          ),
        ),
        nameWidget,
        const SizedBox(height: 3),
        scoreWidget,
        // Winner crown
        if (isWinner) ...[
          const SizedBox(height: 3),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.emoji_events, size: 13, color: AppColors.warning),
              const SizedBox(width: 3),
              const Text('Winner', style: TextStyle(fontSize: 10, color: AppColors.warning, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildMatchFooter(CompetitionMatchModel match) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.location_on_outlined, size: 13, color: AppColors.textLight),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              '${match.venue.name}, ${match.venue.location}'.trim().replaceAll(RegExp(r'^,\s*'), ''),
              style: const TextStyle(fontSize: 11, color: AppColors.textLight),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 10),
          const Icon(Icons.access_time, size: 13, color: AppColors.textLight),
          const SizedBox(width: 4),
          Text(
            _formatDate(match.dateStartIst.isNotEmpty ? match.dateStartIst : match.dateStart),
            style: const TextStyle(fontSize: 11, color: AppColors.textLight),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final amPm = dt.hour < 12 ? 'AM' : 'PM';
      final min = dt.minute.toString().padLeft(2, '0');
      return '${dt.day} ${months[dt.month - 1]}, $hour:$min $amPm';
    } catch (_) {
      return dateStr;
    }
  }
}
