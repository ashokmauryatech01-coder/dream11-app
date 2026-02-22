import 'package:flutter/material.dart';
import 'package:fantasy_crick/core/constants/app_colors.dart';
import 'package:fantasy_crick/core/services/match_service.dart';
import 'package:fantasy_crick/models/match_model.dart';
import 'package:fantasy_crick/models/series_model.dart';
import 'package:fantasy_crick/features/home/widgets/match_card.dart';
import 'package:fantasy_crick/features/matches/screens/before_match_start_screen.dart';

class SeriesDetailScreen extends StatefulWidget {
  final SeriesModel series;

  const SeriesDetailScreen({super.key, required this.series});

  @override
  State<SeriesDetailScreen> createState() => _SeriesDetailScreenState();
}

class _SeriesDetailScreenState extends State<SeriesDetailScreen> {
  final MatchService _matchService = MatchService();
  bool _loading = true;
  String? _error;
  List<MatchModel> _matches = [];

  @override
  void initState() {
    super.initState();
    _loadSeriesMatches();
  }

  Future<void> _loadSeriesMatches() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Load all matches and filter by this series name
      final allMatches = await _matchService.getAllMatches();
      final seriesMatches = allMatches.where((m) {
        final sName = (m.seriesName ?? '').toLowerCase();
        final targetName = widget.series.name.toLowerCase();
        return sName.contains(targetName) || targetName.contains(sName);
      }).toList();

      // If no filtered matches, show all from schedule
      final results = seriesMatches.isNotEmpty ? seriesMatches : allMatches.take(20).toList();

      if (!mounted) return;
      setState(() {
        _matches = results;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Failed to load series matches. Tap to retry.';
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
          widget.series.name,
          style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        iconTheme: const IconThemeData(color: AppColors.white),
      ),
      body: Column(
        children: [
          // Series header
          Container(
            color: AppColors.primary,
            padding: const EdgeInsets.only(left: 20, right: 20, bottom: 24),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.sports_cricket, color: AppColors.white, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.series.name,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppColors.white,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (widget.series.dateRange.isNotEmpty)
                        Text(
                          widget.series.dateRange,
                          style: const TextStyle(fontSize: 13, color: Colors.white70),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Match count
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Text(
                  'Matches (${_matches.length})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text,
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

    if (_error != null && _matches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, size: 48, color: AppColors.textLight),
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: AppColors.textLight)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loadSeriesMatches,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Retry', style: TextStyle(color: AppColors.white)),
            ),
          ],
        ),
      );
    }

    if (_matches.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sports_cricket, size: 48, color: AppColors.textLight),
            SizedBox(height: 12),
            Text('No matches found for this series', style: TextStyle(color: AppColors.textLight)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadSeriesMatches,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _matches.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: MatchCard(
              match: _matches[index],
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BeforeMatchStartScreen(match: _matches[index]),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
