import 'package:flutter/material.dart';
import 'cricket_animation.dart';

class DashboardAnimation extends StatefulWidget {
  final Widget child;
  final bool showAnimation;

  const DashboardAnimation({
    super.key,
    required this.child,
    this.showAnimation = true,
  });

  @override
  State<DashboardAnimation> createState() => _DashboardAnimationState();
}

class _DashboardAnimationState extends State<DashboardAnimation>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late AnimationController _fadeController;
  
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, -0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));

    if (widget.showAnimation) {
      _startAnimations();
    }
  }

  void _startAnimations() {
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _slideController.forward();
    });
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _scaleController.forward();
    });
  }

  @override
  void dispose() {
    _slideController.dispose();
    _scaleController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: widget.child,
            ),
          ),
        );
      },
    );
  }
}

class LeaderboardAnimation extends StatefulWidget {
  final List<Map<String, dynamic>> leaderboardData;
  final String currentUserRank;

  const LeaderboardAnimation({
    super.key,
    required this.leaderboardData,
    required this.currentUserRank,
  });

  @override
  State<LeaderboardAnimation> createState() => _LeaderboardAnimationState();
}

class _LeaderboardAnimationState extends State<LeaderboardAnimation>
    with TickerProviderStateMixin {
  late List<AnimationController> _itemControllers;
  late List<Animation<double>> _itemAnimations;

  @override
  void initState() {
    super.initState();
    
    // Ensure data is not null and has valid length
    final dataLength = widget.leaderboardData?.length ?? 0;
    if (dataLength == 0) {
      _itemControllers = [];
      _itemAnimations = [];
      return;
    }
    
    _itemControllers = List.generate(
      dataLength,
      (index) => AnimationController(
        duration: Duration(milliseconds: 400 + (index * 100)),
        vsync: this,
      ),
    );

    _itemAnimations = _itemControllers.map((controller) {
      return Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.easeOutBack,
      ));
    }).toList();

    _startAnimations();
  }

  void _startAnimations() {
    for (int i = 0; i < _itemControllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 100), () {
        if (mounted) _itemControllers[i].forward();
      });
    }
  }

  @override
  void dispose() {
    for (final controller in _itemControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_itemAnimations.isEmpty) {
      return const Center(
        child: Text(
          'No leaderboard data available',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.purple.withOpacity(0.1),
            Colors.blue.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.purple.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.1),
            blurRadius: 12,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.purple,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CricketAnimation(
                  type: AnimationType.trophy,
                  size: 30,
                  color: Colors.amber,
                  duration: const Duration(seconds: 2),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Leaderboard',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Leaderboard Items
          Expanded(
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.leaderboardData?.length ?? 0,
              itemBuilder: (context, index) {
                final data = widget.leaderboardData;
                if (data == null || index >= data.length || index >= _itemAnimations.length) {
                  return const SizedBox();
                }
                
                final player = data[index];
                final rank = index + 1;
                final isCurrentUser = player['rank'].toString() == widget.currentUserRank;
                
                return AnimatedBuilder(
                  animation: _itemAnimations[index],
                  builder: (context, child) {
                    return FadeTransition(
                      opacity: _itemAnimations[index] ?? AlwaysStoppedAnimation(0.0),
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(1.0, 0.0),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: _itemControllers[index] ?? _itemControllers.first,
                          curve: Curves.easeOutBack,
                        )),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isCurrentUser 
                                ? Colors.amber.withOpacity(0.2)
                                : (rank <= 3 
                                    ? _getRankColor(rank).withOpacity(0.1) 
                                    : Colors.white),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isCurrentUser 
                                  ? Colors.amber
                                  : (rank <= 3 ? _getRankColor(rank) : Colors.grey.shade300),
                              width: isCurrentUser ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              // Rank
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: _getRankColor(rank),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '$rank',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                              
                              const SizedBox(width: 12),
                              
                              // Player Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      player['name']?.toString() ?? 'Player',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isCurrentUser ? Colors.amber.shade800 : Colors.black87,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        CricketAnimation(
                                          type: AnimationType.coin,
                                          size: 16,
                                          color: Colors.green,
                                          duration: const Duration(seconds: 3),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          player['winnings']?.toString() ?? '₹0',
                                          style: TextStyle(
                                            color: Colors.green.shade700,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Trophy for top 3
                              if (rank <= 3) ...[
                                const SizedBox(width: 8),
                                CricketAnimation(
                                  type: AnimationType.trophy,
                                  size: 24,
                                  color: _getRankColor(rank),
                                  duration: const Duration(seconds: 2),
                                ),
                              ],
                              
                              // Current User Badge
                              if (isCurrentUser) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.amber,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'YOU',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber;
      case 2:
        return Colors.grey.shade400;
      case 3:
        return Colors.brown.shade400;
      default:
        return Colors.grey;
    }
  }
}

class AnimatedStatsCard extends StatefulWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final AnimationType animationType;

  const AnimatedStatsCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.animationType,
  });

  @override
  State<AnimatedStatsCard> createState() => _AnimatedStatsCardState();
}

class _AnimatedStatsCardState extends State<AnimatedStatsCard>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
    ));

    Future.delayed(Duration(milliseconds: 100 + (widget.value.hashCode % 200)), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              padding: const EdgeInsets.all(12), // Reduced from 16
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withOpacity(0.2),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        widget.icon,
                        size: 24, // Reduced from 30
                        color: widget.color,
                      ),
                      const SizedBox(width: 8), // Reduced from 12
                      Text(
                        widget.title,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12, // Reduced from 14
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6), // Reduced from 8
                  Text(
                    widget.value,
                    style: TextStyle(
                      color: widget.color,
                      fontSize: 20, // Reduced from 24
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
