import 'package:flutter/material.dart';
import 'dart:math' as math;

class ConfettiAnimation extends StatefulWidget {
  final VoidCallback? onAnimationComplete;

  const ConfettiAnimation({
    super.key,
    this.onAnimationComplete,
  });

  @override
  State<ConfettiAnimation> createState() => _ConfettiAnimationState();
}

class _ConfettiAnimationState extends State<ConfettiAnimation>
    with TickerProviderStateMixin {
  late AnimationController _confettiController;
  late AnimationController _textController;
  late Animation<double> _confettiAnimation;
  late Animation<double> _textScaleAnimation;
  late Animation<double> _textRotationAnimation;
  late Animation<Offset> _textSlideAnimation;

  List<ConfettiPiece> confettiPieces = [];
  final int numberOfPieces = 50;

  @override
  void initState() {
    super.initState();
    
    // Confetti animation controller
    _confettiController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    
    // Text animation controller
    _textController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _confettiAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _confettiController,
      curve: Curves.easeOut,
    ));

    _textScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
    ));

    _textRotationAnimation = Tween<double>(
      begin: -0.5,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: const Interval(0.2, 0.8, curve: Curves.easeOut),
    ));

    _textSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    ));

    _generateConfetti();
    _startAnimation();
  }

  void _generateConfetti() {
    final random = math.Random();
    confettiPieces.clear();
    
    for (int i = 0; i < numberOfPieces; i++) {
      confettiPieces.add(ConfettiPiece(
        x: random.nextDouble(),
        y: -0.1,
        color: _getRandomColor(random),
        size: random.nextDouble() * 8 + 4,
        rotation: random.nextDouble() * 2 * math.pi,
        velocityX: (random.nextDouble() - 0.5) * 2,
        velocityY: random.nextDouble() * 3 + 2,
        rotationSpeed: (random.nextDouble() - 0.5) * 0.2,
      ));
    }
  }

  Color _getRandomColor(math.Random random) {
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.yellow,
      Colors.purple,
      Colors.orange,
      Colors.pink,
      Colors.cyan,
    ];
    return colors[random.nextInt(colors.length)];
  }

  void _startAnimation() {
    _confettiController.forward();
    
    // Start text animation after a short delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _textController.forward();
      }
    });

    // Complete animation after duration
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted && widget.onAnimationComplete != null) {
        widget.onAnimationComplete!();
      }
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.8),
      body: Stack(
        children: [
          // Confetti layer
          AnimatedBuilder(
            animation: _confettiAnimation,
            builder: (context, child) {
              return CustomPaint(
                painter: ConfettiPainter(
                  confettiPieces: confettiPieces,
                  progress: _confettiAnimation.value,
                ),
                size: Size.infinite,
              );
            },
          ),
          
          // Text layer
          Center(
            child: AnimatedBuilder(
              animation: _textController,
              builder: (context, child) {
                return SlideTransition(
                  position: _textSlideAnimation,
                  child: Transform.scale(
                    scale: _textScaleAnimation.value,
                    child: Transform.rotate(
                      angle: _textRotationAnimation.value,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // "PARTIDO" text
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 30,
                              vertical: 15,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.yellow.shade400,
                                  Colors.orange.shade500,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: const Text(
                              'PARTIDO',
                              style: TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 3,
                                shadows: [
                                  Shadow(
                                    color: Colors.black54,
                                    offset: Offset(2, 2),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // "CERRADO" text with tilt
                          Transform.rotate(
                            angle: -0.1, // Slight tilt like taking off
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 25,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.green.shade400,
                                    Colors.teal.shade500,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Text(
                                'CERRADO',
                                style: TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 2,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black54,
                                      offset: Offset(2, 2),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
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

class ConfettiPiece {
  double x;
  double y;
  final Color color;
  final double size;
  double rotation;
  final double velocityX;
  final double velocityY;
  final double rotationSpeed;

  ConfettiPiece({
    required this.x,
    required this.y,
    required this.color,
    required this.size,
    required this.rotation,
    required this.velocityX,
    required this.velocityY,
    required this.rotationSpeed,
  });

  void update(double progress) {
    x += velocityX * 0.02;
    y += velocityY * progress * 0.02;
    rotation += rotationSpeed;
  }
}

class ConfettiPainter extends CustomPainter {
  final List<ConfettiPiece> confettiPieces;
  final double progress;

  ConfettiPainter({
    required this.confettiPieces,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var piece in confettiPieces) {
      piece.update(progress);
      
      final paint = Paint()
        ..color = piece.color
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(
        piece.x * size.width,
        piece.y * size.height,
      );
      canvas.rotate(piece.rotation);
      
      // Draw confetti piece as a small rectangle
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: piece.size,
            height: piece.size * 0.6,
          ),
          const Radius.circular(2),
        ),
        paint,
      );
      
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
