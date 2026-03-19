import 'package:flutter/material.dart';
import 'cricket_animation.dart';

class TeamCreationAnimation extends StatefulWidget {
  final Widget child;
  final bool isCreating;
  final VoidCallback? onCreateComplete;

  const TeamCreationAnimation({
    super.key,
    required this.child,
    this.isCreating = false,
    this.onCreateComplete,
  });

  @override
  State<TeamCreationAnimation> createState() => _TeamCreationAnimationState();
}

class _TeamCreationAnimationState extends State<TeamCreationAnimation>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late AnimationController _fadeController;

  late Animation<double> _pulseAnimation;
  late Animation<double> _rotateAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _rotateController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _rotateAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * 3.14159,
    ).animate(CurvedAnimation(parent: _rotateController, curve: Curves.linear));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

    _startAnimations();
  }

  void _startAnimations() {
    _fadeController.forward();
    _rotateController.repeat();

    if (widget.isCreating) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(TeamCreationAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.isCreating != widget.isCreating) {
      if (widget.isCreating) {
        _pulseController.repeat(reverse: true);
      } else {
        _pulseController.stop();
        _pulseController.reset();
        _showSuccessAnimation();
      }
    }
  }

  void _showSuccessAnimation() {
    _pulseController.forward().then((_) {
      if (widget.onCreateComplete != null) {
        widget.onCreateComplete!();
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
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
          child: Stack(
            children: [
              widget.child,
              if (widget.isCreating)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _pulseAnimation.value,
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blue.withOpacity(0.3),
                                    blurRadius: 12,
                                    spreadRadius: 4,
                                  ),
                                ],
                              ),
                              child: AnimatedBuilder(
                                animation: _rotateAnimation,
                                builder: (context, child) {
                                  return Transform.rotate(
                                    angle: _rotateAnimation.value,
                                    child: const CricketAnimation(
                                      type: AnimationType.cricketBall,
                                      size: 40,
                                      color: Colors.blue,
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class PlayerSelectionAnimation extends StatefulWidget {
  final String playerName;
  final String role;
  final String team;
  final bool isSelected;
  final VoidCallback? onTap;

  const PlayerSelectionAnimation({
    super.key,
    required this.playerName,
    required this.role,
    required this.team,
    this.isSelected = false,
    this.onTap,
  });

  @override
  State<PlayerSelectionAnimation> createState() =>
      _PlayerSelectionAnimationState();
}

class _PlayerSelectionAnimationState extends State<PlayerSelectionAnimation>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _borderAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _borderAnimation = Tween<double>(
      begin: 2.0,
      end: 4.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    if (widget.isSelected) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(PlayerSelectionAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.isSelected != widget.isSelected) {
      if (widget.isSelected) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
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
        return GestureDetector(
          onTap: widget.onTap,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              margin: const EdgeInsets.all(4),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: widget.isSelected
                    ? Colors.blue.withOpacity(0.1)
                    : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: widget.isSelected ? Colors.blue : Colors.grey.shade300,
                  width: _borderAnimation.value,
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.isSelected
                        ? Colors.blue.withOpacity(0.2)
                        : Colors.grey.withOpacity(0.1),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Player Avatar with Animation
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: widget.isSelected
                          ? Colors.blue
                          : Colors.grey.shade200,
                      shape: BoxShape.circle,
                    ),
                    child: widget.isSelected
                        ? CricketAnimation(
                            type: AnimationType.cricketBall,
                            size: 20,
                            color: Colors.white,
                            duration: const Duration(seconds: 2),
                          )
                        : Icon(
                            Icons.person,
                            color: widget.isSelected
                                ? Colors.white
                                : Colors.grey.shade600,
                            size: 20,
                          ),
                  ),

                  const SizedBox(width: 12),

                  // Player Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.playerName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: widget.isSelected
                                ? Colors.blue
                                : Colors.black87,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _getRoleColor(widget.role),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                widget.role,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              widget.team,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
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

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'batsman':
        return Colors.green;
      case 'bowler':
        return Colors.red;
      case 'all-rounder':
        return Colors.blue;
      case 'wicket keeper':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}

class TeamSuccessAnimation extends StatefulWidget {
  final String teamName;
  final int playerCount;
  final VoidCallback? onAnimationComplete;

  const TeamSuccessAnimation({
    super.key,
    required this.teamName,
    required this.playerCount,
    this.onAnimationComplete,
  });

  @override
  State<TeamSuccessAnimation> createState() => _TeamSuccessAnimationState();
}

class _TeamSuccessAnimationState extends State<TeamSuccessAnimation>
    with TickerProviderStateMixin {
  late AnimationController _confettiController;
  late AnimationController _scaleController;
  late AnimationController _fadeController;

  late Animation<double> _confettiAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _confettiController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _confettiAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _confettiController, curve: Curves.easeOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

    _startSuccessAnimation();
  }

  void _startSuccessAnimation() {
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _scaleController.forward();
    });
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _confettiController.forward();
    });

    Future.delayed(const Duration(milliseconds: 2000), () {
      if (widget.onAnimationComplete != null) {
        widget.onAnimationComplete!();
      }
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
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
          child: Center(
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 8,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CricketAnimation(
                      type: AnimationType.trophy,
                      size: 60,
                      color: Colors.amber,
                      duration: const Duration(seconds: 2),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Team Created!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.teamName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.playerCount} Players',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
