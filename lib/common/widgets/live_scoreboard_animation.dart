import 'package:flutter/material.dart';
import 'cricket_animation.dart';

class LiveScoreboardAnimation extends StatefulWidget {
  final int runs;
  final bool isSix;
  final bool isFour;
  final bool isWicket;
  final String batsmanName;
  final String bowlerName;

  const LiveScoreboardAnimation({
    super.key,
    required this.runs,
    this.isSix = false,
    this.isFour = false,
    this.isWicket = false,
    this.batsmanName = '',
    this.bowlerName = '',
  });

  @override
  State<LiveScoreboardAnimation> createState() => _LiveScoreboardAnimationState();
}

class _LiveScoreboardAnimationState extends State<LiveScoreboardAnimation>
    with TickerProviderStateMixin {
  late AnimationController _bounceController;
  late AnimationController _slideController;
  late AnimationController _fadeController;
  
  late Animation<double> _bounceAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _bounceAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.bounceOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));

    _startAnimations();
  }

  void _startAnimations() {
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _slideController.forward();
    });
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _bounceController.forward();
    });
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _slideController.dispose();
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
              scale: _bounceAnimation,
              child: _buildScoreboardContent(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildScoreboardContent() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _getScoreColor().withOpacity(0.9),
            _getScoreColor().withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: _getScoreColor().withOpacity(0.3),
            blurRadius: 12,
            spreadRadius: 4,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Score Display
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.isSix) ...[
                CricketAnimation(
                  type: AnimationType.six,
                  size: 40,
                  color: Colors.orange,
                  duration: const Duration(seconds: 1),
                ),
                const SizedBox(width: 16),
              ] else if (widget.isFour) ...[
                CricketAnimation(
                  type: AnimationType.four,
                  size: 40,
                  color: Colors.blue,
                  duration: const Duration(seconds: 1),
                ),
                const SizedBox(width: 16),
              ] else if (widget.isWicket) ...[
                CricketAnimation(
                  type: AnimationType.wicket,
                  size: 40,
                  color: Colors.red,
                  duration: const Duration(seconds: 1),
                ),
                const SizedBox(width: 16),
              ],
              Column(
                children: [
                  Text(
                    '${widget.runs}',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 4,
                          offset: const Offset(2, 2),
                        ),
                      ],
                    ),
                  ),
                  if (widget.isSix)
                    const Text(
                      'SIX!',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    )
                  else if (widget.isFour)
                    const Text(
                      'FOUR!',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    )
                  else if (widget.isWicket)
                    const Text(
                      'WICKET!',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                ],
              ),
            ],
          ),
          
          // Player Details
          if (widget.batsmanName.isNotEmpty || widget.bowlerName.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(color: Colors.white54),
            const SizedBox(height: 8),
            if (widget.batsmanName.isNotEmpty)
              Text(
                'Batsman: ${widget.batsmanName}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            if (widget.bowlerName.isNotEmpty)
              Text(
                'Bowler: ${widget.bowlerName}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ],
      ),
    );
  }

  Color _getScoreColor() {
    if (widget.isSix) return Colors.orange;
    if (widget.isFour) return Colors.blue;
    if (widget.isWicket) return Colors.red;
    return Colors.green;
  }
}

class ScoreboardOverlay extends StatefulWidget {
  final Widget child;
  final bool showAnimation;

  const ScoreboardOverlay({
    super.key,
    required this.child,
    this.showAnimation = false,
  });

  @override
  State<ScoreboardOverlay> createState() => _ScoreboardOverlayState();
}

class _ScoreboardOverlayState extends State<ScoreboardOverlay>
    with TickerProviderStateMixin {
  late AnimationController _overlayController;
  late Animation<double> _overlayAnimation;

  @override
  void initState() {
    super.initState();
    _overlayController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _overlayAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _overlayController,
      curve: Curves.easeInOut,
    ));

    if (widget.showAnimation) {
      _overlayController.forward();
    }
  }

  @override
  void didUpdateWidget(ScoreboardOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.showAnimation != widget.showAnimation) {
      if (widget.showAnimation) {
        _overlayController.forward();
      } else {
        _overlayController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _overlayController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (widget.showAnimation)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _overlayAnimation,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3 * _overlayAnimation.value),
                  ),
                  child: Center(
                    child: LiveScoreboardAnimation(
                      runs: 6,
                      isSix: true,
                      batsmanName: 'Player',
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
