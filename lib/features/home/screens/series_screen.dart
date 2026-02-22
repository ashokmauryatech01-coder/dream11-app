import 'package:flutter/material.dart';
import 'package:fantasy_crick/core/constants/app_colors.dart';
import 'package:fantasy_crick/core/services/series_service.dart';
import 'package:fantasy_crick/models/series_model.dart';
import 'package:fantasy_crick/features/home/widgets/series_card.dart';
import 'package:fantasy_crick/features/home/screens/series_detail_screen.dart';

class SeriesScreen extends StatefulWidget {
  const SeriesScreen({super.key});

  @override
  State<SeriesScreen> createState() => _SeriesScreenState();
}

class _SeriesScreenState extends State<SeriesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final SeriesService _seriesService = SeriesService();

  // Data per tab
  List<SeriesModel> _allSeries = [];
  List<SeriesModel> _internationalSeries = [];
  List<SeriesModel> _leagueSeries = [];
  List<SeriesModel> _domesticSeries = [];
  List<SeriesModel> _womenSeries = [];

  // Loading states per tab
  final Map<int, bool> _loading = {0: true, 1: true, 2: true, 3: true, 4: true};
  final Map<int, String?> _errors = {0: null, 1: null, 2: null, 3: null, 4: null};
  final Set<int> _loaded = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(_onTabChanged);
    // Load first tab data
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
      List<SeriesModel> result;
      switch (tabIndex) {
        case 0:
          result = await _seriesService.getAllSeries();
          _allSeries = result;
          break;
        case 1:
          result = await _seriesService.getInternationalSeries();
          _internationalSeries = result;
          break;
        case 2:
          result = await _seriesService.getLeagueSeries();
          _leagueSeries = result;
          break;
        case 3:
          result = await _seriesService.getDomesticSeries();
          _domesticSeries = result;
          break;
        case 4:
          result = await _seriesService.getWomenSeries();
          _womenSeries = result;
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
        _errors[tabIndex] = 'Failed to load series. Pull down to retry.';
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
          'Cricket Series',
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
            Tab(text: 'All'),
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
          _buildSeriesTab(0, _allSeries),
          _buildSeriesTab(1, _internationalSeries),
          _buildSeriesTab(2, _leagueSeries),
          _buildSeriesTab(3, _domesticSeries),
          _buildSeriesTab(4, _womenSeries),
        ],
      ),
    );
  }

  Widget _buildSeriesTab(int tabIndex, List<SeriesModel> seriesList) {
    if (_loading[tabIndex] == true) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_errors[tabIndex] != null && seriesList.isEmpty) {
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

    if (seriesList.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sports_cricket, size: 48, color: AppColors.textLight),
            SizedBox(height: 12),
            Text('No series found', style: TextStyle(color: AppColors.textLight)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => _loadTabData(tabIndex),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: seriesList.length,
        itemBuilder: (context, index) {
          return SeriesCard(
            series: seriesList[index],
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SeriesDetailScreen(series: seriesList[index]),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
