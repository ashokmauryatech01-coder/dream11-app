import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'cricket_animation.dart';

class WelcomeAnimation extends StatefulWidget {
  final String userName;
  final VoidCallback? onAnimationComplete;

  const WelcomeAnimation({
    super.key,
    required this.userName,
    this.onAnimationComplete,
  });

  @override
  State<WelcomeAnimation> createState() => _WelcomeAnimationState();
}

class _WelcomeAnimationState extends State<WelcomeAnimation>
    with TickerProviderStateMixin {
  late AnimationController _confettiController;
  late AnimationController _textController;
  late AnimationController _scaleController;
  
  late Animation<double> _confettiAnimation;
  late Animation<double> _textAnimation;
  late Animation<double> _scaleAnimation;

  List<ConfettiParticle> _confettiParticles = [];

  @override
  void initState() {
    super.initState();
    
    _confettiController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _textController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _confettiAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _confettiController,
      curve: Curves.easeOut,
    ));

    _textAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeOutBack,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    _generateConfetti();
    _startWelcomeAnimation();
  }

  void _generateConfetti() {
    final random = math.Random();
    final colors = [
      Colors.amber, Colors.blue, Colors.green, 
      Colors.orange, Colors.purple, Colors.red
    ];
    
    for (int i = 0; i < 30; i++) {
      _confettiParticles.add(ConfettiParticle(
        x: random.nextDouble() * 2 - 1,
        y: random.nextDouble() * 2 - 1,
        color: colors[random.nextInt(colors.length)],
        size: random.nextDouble() * 6 + 2,
        velocity: random.nextDouble() * 1.5 + 0.5,
      ));
    }
  }

  void _startWelcomeAnimation() {
    _scaleController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _textController.forward();
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _confettiController.forward();
    });
    
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (widget.onAnimationComplete != null) {
        widget.onAnimationComplete!();
      }
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _textController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.9),
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
            child: AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Container(
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.amber.withOpacity(0.4),
                          blurRadius: 30,
                          spreadRadius: 15,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Cricket Animation
                        AnimatedBuilder(
                          animation: _textAnimation,
                          builder: (context, child) {
                            return FadeTransition(
                              opacity: _textAnimation.value,
                              child: Transform.rotate(
                                angle: _textAnimation.value * math.pi * 2,
                                child: CricketAnimation(
                                  type: AnimationType.trophy,
                                  size: 60,
                                  color: Colors.amber,
                                  duration: const Duration(seconds: 1),
                                ),
                              ),
                            );
                          },
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Welcome Text
                        AnimatedBuilder(
                          animation: _textAnimation,
                          builder: (context, child) {
                            return FadeTransition(
                              opacity: _textAnimation.value,
                              child: Text(
                                'Welcome\n${widget.userName}!',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            );
                          },
                        ),
                        
                        const SizedBox(height: 8),
                        
                        AnimatedBuilder(
                          animation: _textAnimation,
                          builder: (context, child) {
                            return FadeTransition(
                              opacity: _textAnimation.value,
                              child: Text(
                                'Ready to Play!',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
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
