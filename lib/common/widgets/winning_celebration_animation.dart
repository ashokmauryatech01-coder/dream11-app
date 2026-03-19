import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:lottie/lottie.dart';
import 'package:fantasy_crick/core/constants/app_colors.dart';
import 'cricket_animation.dart';

class WinningCelebrationAnimation extends StatefulWidget {
  final String winnerName;
  final double prizeAmount;
  final String contestName;
  final VoidCallback? onCelebrationComplete;

  const WinningCelebrationAnimation({
    super.key,
    required this.winnerName,
    required this.prizeAmount,
    required this.contestName,
    this.onCelebrationComplete,
  });

  @override
  State<WinningCelebrationAnimation> createState() => _WinningCelebrationAnimationState();
}

class _WinningCelebrationAnimationState extends State<WinningCelebrationAnimation>
    with TickerProviderStateMixin {
  late AnimationController _confettiController;
  late AnimationController _trophyController;
  late AnimationController _textController;
  late AnimationController _coinController;
  
  late Animation<double> _confettiAnimation;
  late Animation<double> _trophyAnimation;
  late Animation<double> _textAnimation;
  late Animation<double> _coinAnimation;

  List<ConfettiParticle> _confettiParticles = [];

  @override
  void initState() {
    super.initState();
    
    _confettiController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _trophyController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _textController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _coinController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _confettiAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _confettiController,
      curve: Curves.easeOut,
    ));

    _trophyAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _trophyController,
      curve: Curves.elasticOut,
    ));

    _textAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeOutBack,
    ));

    _coinAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _coinController,
      curve: Curves.bounceOut,
    ));

    _generateConfetti();
    _startCelebration();
  }

  void _generateConfetti() {
    final random = math.Random();
    final colors = [
      AppColors.primary,
      AppColors.secondary,
      const Color(0xFFFF187C),
      const Color(0xFF63DAB9),
      Colors.white,
    ];
    
    for (int i = 0; i < 50; i++) {
      _confettiParticles.add(ConfettiParticle(
        x: random.nextDouble() * 2 - 1,
        y: random.nextDouble() * 2 - 1,
        color: colors[random.nextInt(colors.length)],
        size: random.nextDouble() * 8 + 4,
        velocity: random.nextDouble() * 2 + 1,
      ));
    }
  }

  void _startCelebration() {
    _trophyController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _textController.forward();
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _coinController.forward();
    });
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) _confettiController.forward();
    });
    
    Future.delayed(const Duration(milliseconds: 3000), () {
      if (widget.onCelebrationComplete != null) {
        widget.onCelebrationComplete!();
      }
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _trophyController.dispose();
    _textController.dispose();
    _coinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.8),
      body: Stack(
        children: [
          // Confetti Background
          AnimatedBuilder(
            animation: _confettiAnimation,
            builder: (context, child) {
              return CustomPaint(
                painter: ConfettiPainter(
                  particles: _confettiParticles,
                  progress: _confettiAnimation.value,
                ),
                child: Container(),
              );
            },
          ),
          
          // Main Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedBuilder(
                  animation: _trophyAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _trophyAnimation.value,
                      child: Container(
                        padding: const EdgeInsets.all(0),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.amber.withOpacity(0.3),
                              blurRadius: 40,
                              spreadRadius: 20,
                            ),
                          ],
                        ),
                        child: Lottie.network(
                          'https://lottie.host/80eeb877-a89e-4e44-8d99-ba8544d6da21/WpU6l4v4S0.json', // Trophy
                          width: 200,
                          height: 200,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => CricketAnimation(
                            type: AnimationType.trophy,
                            size: 100,
                            color: Colors.amber,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 30),
                
                // Winner Text
                AnimatedBuilder(
                  animation: _textAnimation,
                  builder: (context, child) {
                    return FadeTransition(
                      opacity: _textAnimation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.0, 0.3),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: _textController,
                          curve: Curves.easeOutBack,
                        )),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 15,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              const Text(
                                '🎉 CONGRATULATIONS! 🎉',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                widget.winnerName,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                widget.contestName,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 20),
                
                // Prize Amount
                AnimatedBuilder(
                  animation: _coinAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _coinAnimation.value,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.amber, Colors.orange],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.amber.withOpacity(0.4),
                              blurRadius: 12,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Lottie.network(
                              'https://lottie.host/9f5064e6-ee06-444f-8360-1436e2f1e2f3/5X2l9c2g8v.json', // Coin/Success
                              width: 40,
                              height: 40,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) => CricketAnimation(
                                type: AnimationType.coin,
                                size: 30,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Added: ₹${widget.prizeAmount.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ConfettiParticle {
  final double x;
  final double y;
  final Color color;
  final double size;
  final double velocity;

  ConfettiParticle({
    required this.x,
    required this.y,
    required this.color,
    required this.size,
    required this.velocity,
  });
}

class ConfettiPainter extends CustomPainter {
  final List<ConfettiParticle> particles;
  final double progress;

  ConfettiPainter({
    required this.particles,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      final paint = Paint()
        ..color = particle.color
        ..style = PaintingStyle.fill;

      final particleY = particle.y + (progress * particle.velocity * 200);
      final particleX = particle.x + (math.sin(progress * math.pi * 4) * 0.1);
      
      final centerX = size.width / 2 + particleX * size.width / 2;
      final centerY = size.height / 2 + particleY * size.height / 2;

      canvas.drawCircle(
        Offset(centerX, centerY),
        particle.size * (1.0 - progress * 0.5),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(ConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class VictoryAnimation extends StatefulWidget {
  final Widget child;
  final bool showVictory;

  const VictoryAnimation({
    super.key,
    required this.child,
    this.showVictory = false,
  });

  @override
  State<VictoryAnimation> createState() => _VictoryAnimationState();
}

class _VictoryAnimationState extends State<VictoryAnimation>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    if (widget.showVictory) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(VictoryAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.showVictory != widget.showVictory) {
      if (widget.showVictory) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
        _controller.reset();
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
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Transform.rotate(
            angle: _rotationAnimation.value,
            child: widget.child,
          ),
        );
      },
    );
  }
}
