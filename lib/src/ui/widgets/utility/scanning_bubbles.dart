import 'dart:math';
import 'package:flutter/material.dart';

/// Model for animated bubble
class _Bubble {
  Offset position;
  Color color;
  late Animation<double> radius;
  late AnimationController controller;

  _Bubble({
    required this.position,
    required this.color,
    required TickerProvider vsync,
  }) {
    controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: vsync,
    )..repeat(reverse: true);

    radius = Tween<double>(begin: 0, end: 20.0).animate(controller);
  }
}

/// Animated bubbles widget that shows scanning activity
/// Ported from BitNet project
class ScanningBubbles extends StatefulWidget {
  final double width;
  final double height;
  final Color? bubbleColor;
  final int spawnIntervalMs;
  final double maxRadius;

  const ScanningBubbles({
    super.key,
    required this.width,
    required this.height,
    this.bubbleColor,
    this.spawnIntervalMs = 200,
    this.maxRadius = 10,
  });

  @override
  State<ScanningBubbles> createState() => _ScanningBubblesState();
}

class _ScanningBubblesState extends State<ScanningBubbles>
    with TickerProviderStateMixin {
  List<_Bubble> bubbles = [];
  Random random = Random();
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _startBubbleSpawning();
  }

  void _startBubbleSpawning() {
    Future.doWhile(() async {
      await Future.delayed(
        Duration(milliseconds: widget.spawnIntervalMs),
      );

      if (!mounted || !_isActive) {
        return false;
      }

      final baseColor = widget.bubbleColor ?? Colors.white;
      final bubble = _Bubble(
        position: Offset(
          random.nextDouble() * widget.width,
          random.nextDouble() * widget.height,
        ),
        color: baseColor.withAlpha(50 + random.nextInt(150)),
        vsync: this,
      );

      // Randomize the bubble size
      double endRadius = 3 + random.nextDouble() * widget.maxRadius;
      bubble.radius = Tween<double>(
        begin: 0,
        end: endRadius,
      ).animate(
        CurvedAnimation(
          parent: bubble.controller,
          curve: Curves.easeInOut,
        ),
      );

      // Speed up the animation
      bubble.controller.duration = Duration(
        milliseconds: 500 + random.nextInt(500),
      );

      bubble.controller.addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          bubble.controller.reverse();
        } else if (status == AnimationStatus.dismissed) {
          if (mounted) {
            bubble.controller.dispose();
            setState(() {
              bubbles.remove(bubble);
            });
          }
        }
      });

      bubble.controller.forward();

      if (mounted) {
        setState(() {
          bubbles.add(bubble);
        });
      }

      return _isActive;
    });
  }

  @override
  void dispose() {
    _isActive = false;
    for (var bubble in bubbles) {
      bubble.controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BubblePainter(bubbles: bubbles),
      child: const SizedBox.expand(),
    );
  }
}

class _BubblePainter extends CustomPainter {
  final List<_Bubble> bubbles;

  _BubblePainter({required this.bubbles})
      : super(
          repaint: Listenable.merge(
            bubbles.map((e) => e.controller).toList(),
          ),
        );

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (var bubble in bubbles) {
      paint.color = bubble.color;
      canvas.drawCircle(bubble.position, bubble.radius.value, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BubblePainter oldDelegate) {
    return true;
  }
}
