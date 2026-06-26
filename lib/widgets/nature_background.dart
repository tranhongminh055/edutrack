import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Animated nature-themed background with floating leaves and particles
class NatureBackground extends StatefulWidget {
  final Widget child;

  const NatureBackground({super.key, required this.child});

  @override
  State<NatureBackground> createState() => _NatureBackgroundState();
}

class _NatureBackgroundState extends State<NatureBackground>
    with TickerProviderStateMixin {
  late AnimationController _particleController;
  late List<_FloatingParticle> _particles;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _particles = List.generate(15, (i) => _FloatingParticle(
      x: _random.nextDouble(),
      y: _random.nextDouble(),
      size: _random.nextDouble() * 8 + 3,
      speed: _random.nextDouble() * 0.3 + 0.1,
      opacity: _random.nextDouble() * 0.4 + 0.1,
      phase: _random.nextDouble() * 2 * pi,
    ));
  }

  @override
  void dispose() {
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Dark gradient background
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0D1F12),
                Color(0xFF0A1A0F),
                Color(0xFF061208),
                Color(0xFF0A1A10),
              ],
              stops: [0.0, 0.3, 0.7, 1.0],
            ),
          ),
        ),

        // Green glow spots
        Positioned(
          top: -50,
          right: -30,
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.darkGreen.withOpacity(0.3),
                  AppColors.darkGreen.withOpacity(0.05),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -80,
          left: -50,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.primaryGreen.withOpacity(0.15),
                  AppColors.primaryGreen.withOpacity(0.03),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: MediaQuery.of(context).size.height * 0.4,
          left: MediaQuery.of(context).size.width * 0.3,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.accentGreen.withOpacity(0.12),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // Animated floating particles
        AnimatedBuilder(
          animation: _particleController,
          builder: (context, _) {
            return CustomPaint(
              painter: _ParticlePainter(
                particles: _particles,
                progress: _particleController.value,
              ),
              size: Size.infinite,
            );
          },
        ),

        // Child content
        widget.child,
      ],
    );
  }
}

class _FloatingParticle {
  final double x;
  final double y;
  final double size;
  final double speed;
  final double opacity;
  final double phase;

  _FloatingParticle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
    required this.phase,
  });
}

class _ParticlePainter extends CustomPainter {
  final List<_FloatingParticle> particles;
  final double progress;

  _ParticlePainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      final animatedY = (particle.y + progress * particle.speed) % 1.0;
      final animatedX = particle.x +
          sin((progress * 2 * pi) + particle.phase) * 0.02;

      final paint = Paint()
        ..color = AppColors.primaryGreen.withOpacity(
          particle.opacity * (0.5 + 0.5 * sin(progress * 2 * pi + particle.phase)),
        )
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, particle.size * 0.5);

      canvas.drawCircle(
        Offset(animatedX * size.width, animatedY * size.height),
        particle.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) => true;
}
