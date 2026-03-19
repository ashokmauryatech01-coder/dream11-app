import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:lottie/lottie.dart';
import 'package:fantasy_crick/core/constants/app_colors.dart';

class CricketAnimation extends StatefulWidget {
  final AnimationType type;
  final double size;
  final Color? color;
  final bool autoPlay;
  final Duration duration;

  const CricketAnimation({
    super.key,
    required this.type,
    this.size = 100,
    this.color,
    this.autoPlay = true,
    this.duration = const Duration(seconds: 2),
  });

  @override
  State<CricketAnimation> createState() => _CricketAnimationState();
}

class _CricketAnimationState extends State<CricketAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.linear,
    ));

    _bounceAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.bounceOut),
    ));

    if (widget.autoPlay) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cricketWidget = _buildCricketWidget();
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Transform.rotate(
            angle: _rotationAnimation.value,
            child: child,
          ),
        );
      },
      child: cricketWidget,
    );
  }

  Widget _buildCricketWidget() {
    String? lottieUrl;
    switch (widget.type) {
      case AnimationType.cricketBall:
        lottieUrl = 'https://lottie.host/7e923ade-37a5-4f40-a359-54817a195325/oP5Wre18iS.json';
        break;
      case AnimationType.bat:
        lottieUrl = 'https://lottie.host/5b2446a8-f860-4ce0-8c24-81e5f884a460/uYy3k4XzH7.json';
        break;
      case AnimationType.stumps:
        lottieUrl = 'https://assets2.lottiefiles.com/packages/lf20_m6cu8yq8.json'; // Search for cricket stumps
        break;
      case AnimationType.trophy:
        lottieUrl = 'https://lottie.host/80eeb877-a89e-4e44-8d99-ba8544d6da21/WpU6l4v4S0.json';
        break;
      case AnimationType.coin:
        lottieUrl = 'https://lottie.host/9f5064e6-ee06-444f-8360-1436e2f1e2f3/5X2l9c2g8v.json';
        break;
      case AnimationType.wicket:
        lottieUrl = 'https://lottie.host/d6be3364-706f-4c54-8c88-f54f1650b868/jA77A6e2vS.json';
        break;
      default:
        break;
    }

    if (lottieUrl != null) {
      return Lottie.network(
        lottieUrl,
        width: widget.size,
        height: widget.size,
        fit: BoxFit.contain,
        animate: widget.autoPlay,
        errorBuilder: (context, error, stackTrace) => _buildFallbackWidget(),
      );
    }

    return _buildFallbackWidget();
  }

  Widget _buildFallbackWidget() {
    switch (widget.type) {
      case AnimationType.cricketBall:
        return _buildCricketBall();
      case AnimationType.bat:
        return _buildCricketBat();
      case AnimationType.stumps:
        return _buildCricketStumps();
      case AnimationType.six:
        return _buildSixAnimation();
      case AnimationType.four:
        return _buildFourAnimation();
      case AnimationType.wicket:
        return _buildWicketAnimation();
      case AnimationType.trophy:
        return _buildTrophyAnimation();
      case AnimationType.coin:
        return _buildCoinAnimation();
      default:
        return _buildCricketBall();
    }
  }

  Widget _buildCricketBall() {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: widget.color ?? AppColors.primary,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: widget.size * 0.8,
          height: widget.size * 0.8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(color: widget.color ?? AppColors.primary, width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildCricketBat() {
    return Container(
      width: widget.size * 1.5,
      height: widget.size * 0.3,
      decoration: BoxDecoration(
        color: widget.color ?? Colors.brown[700],
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: widget.size * 0.1,
          height: widget.size * 0.2,
          color: widget.color ?? Colors.brown[900],
        ),
      ),
    );
  }

  Widget _buildCricketStumps() {
    return SizedBox(
      width: widget.size,
      height: widget.size * 1.2,
      child: Stack(
        children: [
          // Stumps
          Positioned(
            left: widget.size * 0.2,
            bottom: 0,
            child: Container(
              width: widget.size * 0.08,
              height: widget.size,
              color: widget.color ?? Colors.brown[600],
            ),
          ),
          Positioned(
            left: widget.size * 0.35,
            bottom: 0,
            child: Container(
              width: widget.size * 0.08,
              height: widget.size,
              color: widget.color ?? Colors.brown[600],
            ),
          ),
          Positioned(
            left: widget.size * 0.5,
            bottom: 0,
            child: Container(
              width: widget.size * 0.08,
              height: widget.size,
              color: widget.color ?? Colors.brown[600],
            ),
          ),
          // Bails
          Positioned(
            left: widget.size * 0.2,
            top: widget.size * 0.05,
            child: Container(
              width: widget.size * 0.35,
              height: widget.size * 0.04,
              color: widget.color ?? Colors.brown[400],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSixAnimation() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Transform.scale(
          scale: _bounceAnimation.value,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.5),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Text(
              'SIX! 🏏‍♂️',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
          ),
        ),
        SizedBox(height: widget.size * 0.2),
        _buildCricketBall(),
      ],
    );
  }

  Widget _buildFourAnimation() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Transform.scale(
          scale: _bounceAnimation.value,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.secondary.withOpacity(0.5),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Text(
              'FOUR! 🏏‍♂️',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
          ),
        ),
        SizedBox(height: widget.size * 0.2),
        _buildCricketBall(),
      ],
    );
  }

  Widget _buildWicketAnimation() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Transform.scale(
          scale: _bounceAnimation.value,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.5),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Text(
              'WICKET! 🏏‍♂️',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
          ),
        ),
        SizedBox(height: widget.size * 0.2),
        _buildCricketStumps(),
      ],
    );
  }

  Widget _buildTrophyAnimation() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Transform.scale(
          scale: _bounceAnimation.value,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.amber.shade300,
                  Colors.amber.shade600,
                  Colors.amber.shade800,
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withOpacity(0.6),
                  blurRadius: 16,
                  spreadRadius: 6,
                ),
                // Add sparkle effect
                BoxShadow(
                  color: Colors.white.withOpacity(0.8),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Stack(
              children: [
                // Trophy cup
                Positioned(
                  top: widget.size * 0.15,
                  left: widget.size * 0.25,
                  child: Container(
                    width: widget.size * 0.5,
                    height: widget.size * 0.4,
                    decoration: BoxDecoration(
                      color: Colors.amber.shade700,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(widget.size * 0.25),
                        topRight: Radius.circular(widget.size * 0.25),
                      ),
                    ),
                  ),
                ),
                // Trophy handles
                Positioned(
                  top: widget.size * 0.35,
                  left: widget.size * 0.15,
                  child: Container(
                    width: widget.size * 0.1,
                    height: widget.size * 0.3,
                    decoration: BoxDecoration(
                      color: Colors.amber.shade700,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                Positioned(
                  top: widget.size * 0.35,
                  right: widget.size * 0.15,
                  child: Container(
                    width: widget.size * 0.1,
                    height: widget.size * 0.3,
                    decoration: BoxDecoration(
                      color: Colors.amber.shade700,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                // Star on top
                Positioned(
                  top: widget.size * 0.05,
                  left: widget.size * 0.45,
                  child: Transform.rotate(
                    angle: _rotationAnimation.value,
                    child: Icon(
                      Icons.star,
                      color: Colors.white,
                      size: widget.size * 0.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Sparkle particles
        if (_controller.isAnimating)
          Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: widget.size * 1.2,
              height: widget.size * 1.2,
              child: _buildSparkleParticles(),
            ),
          ),
      ],
    );
  }

  Widget _buildCoinAnimation() {
    return Transform.rotate(
      angle: _rotationAnimation.value,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: Colors.amber[600],
          shape: BoxShape.circle,
          border: Border.all(color: Colors.amber[800]!, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.amber.withOpacity(0.5),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Center(
          child: Text(
            '₹',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: widget.size * 0.4,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSparkleParticles() {
    return Stack(
      children: List.generate(8, (index) {
        final angle = (index * 45.0) * (math.pi / 180.0);
        final distance = widget.size * 0.6;
        final x = math.cos(angle) * distance;
        final y = math.sin(angle) * distance;
        
        return Positioned(
          left: widget.size * 0.5 + x,
          top: widget.size * 0.5 + y,
          child: Transform.scale(
            scale: _scaleAnimation.value * (1.0 - index * 0.1),
            child: Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.8),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}

enum AnimationType {
  cricketBall,
  bat,
  stumps,
  six,
  four,
  wicket,
  trophy,
  coin,
}
