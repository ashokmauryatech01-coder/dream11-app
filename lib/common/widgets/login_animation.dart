import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'cricket_animation.dart';

class LoginAnimation extends StatefulWidget {
  final Widget child;
  final bool showAnimation;

  const LoginAnimation({
    super.key,
    required this.child,
    this.showAnimation = true,
  });

  @override
  State<LoginAnimation> createState() => _LoginAnimationState();
}

class _LoginAnimationState extends State<LoginAnimation>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.3),
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

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
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
    _fadeController.dispose();
    _scaleController.dispose();
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

class AnimatedLoginScreen extends StatefulWidget {
  const AnimatedLoginScreen({super.key});

  @override
  State<AnimatedLoginScreen> createState() => _AnimatedLoginScreenState();
}

class _AnimatedLoginScreenState extends State<AnimatedLoginScreen>
    with TickerProviderStateMixin {
  late AnimationController _backgroundController;
  late AnimationController _cricketController;
  late Animation<double> _backgroundAnimation;
  late Animation<double> _cricketAnimation;

  @override
  void initState() {
    super.initState();
    
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    
    _cricketController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _backgroundAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _backgroundController,
      curve: Curves.linear,
    ));

    _cricketAnimation = Tween<double>(
      begin: -math.pi,
      end: math.pi,
    ).animate(CurvedAnimation(
      parent: _cricketController,
      curve: Curves.linear,
    ));

    _backgroundController.repeat();
    _cricketController.repeat();
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _cricketController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Animated Background
          AnimatedBuilder(
            animation: _backgroundAnimation,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.blue.withOpacity(0.1 + _backgroundAnimation.value * 0.2),
                      Colors.purple.withOpacity(0.1 + _backgroundAnimation.value * 0.1),
                      Colors.green.withOpacity(0.05 + _backgroundAnimation.value * 0.1),
                    ],
                  ),
                ),
              );
            },
          ),
          
          // Floating Cricket Animations
          Positioned(
            top: 50,
            left: 30,
            child: AnimatedBuilder(
              animation: _cricketAnimation,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _cricketAnimation.value,
                  child: CricketAnimation(
                    type: AnimationType.cricketBall,
                    size: 40,
                    color: Colors.red.withOpacity(0.3),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
            ),
          ),
          
          Positioned(
            top: 100,
            right: 40,
            child: AnimatedBuilder(
              animation: _cricketAnimation,
              builder: (context, child) {
                return Transform.rotate(
                  angle: -_cricketAnimation.value,
                  child: CricketAnimation(
                    type: AnimationType.bat,
                    size: 60,
                    color: Colors.brown.withOpacity(0.3),
                    duration: const Duration(milliseconds: 1500),
                  ),
                );
              },
            ),
          ),
          
          Positioned(
            bottom: 80,
            left: 50,
            child: AnimatedBuilder(
              animation: _cricketAnimation,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _cricketAnimation.value * 0.5,
                  child: CricketAnimation(
                    type: AnimationType.stumps,
                    size: 50,
                    color: Colors.brown.withOpacity(0.3),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            ),
          ),
          
          // Login Form Content
          Center(
            child: LoginAnimation(
              showAnimation: true,
              child: Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo with Animation
                    CricketAnimation(
                      type: AnimationType.cricketBall,
                      size: 60,
                      color: Colors.blue,
                      duration: const Duration(seconds: 2),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    Text(
                      'Welcome Back!',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    Text(
                      'Sign in to continue',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Login Form Fields would go here
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        children: [
                          TextField(
                            decoration: InputDecoration(
                              hintText: 'Email or Phone',
                              prefixIcon: Icon(Icons.person, color: Colors.grey.shade400),
                              border: InputBorder.none,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            obscureText: true,
                            decoration: InputDecoration(
                              hintText: 'Password',
                              prefixIcon: Icon(Icons.lock, color: Colors.grey.shade400),
                              border: InputBorder.none,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Login Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          // Handle login
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CricketAnimation(
                              type: AnimationType.cricketBall,
                              size: 20,
                              color: Colors.white,
                              duration: const Duration(seconds: 1),
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Sign In',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
