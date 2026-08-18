import 'dart:math';
import 'package:flutter/material.dart';

/// عداد تنازلي على شكل ساعة: حلقة تتناقص + رقم الثواني المتبقية في المنتصف.
class ClockCountdown extends StatelessWidget {
  final int secondsLeft;
  final int totalSeconds;
  final double size;

  const ClockCountdown({
    super.key,
    required this.secondsLeft,
    required this.totalSeconds,
    this.size = 96,
  });

  @override
  Widget build(BuildContext context) {
    final fraction = totalSeconds <= 0 ? 0.0 : (secondsLeft / totalSeconds).clamp(0.0, 1.0);
    final scheme = Theme.of(context).colorScheme;
    final color = fraction < 0.25
        ? Colors.red.shade400
        : fraction < 0.5
            ? Colors.orange.shade400
            : scheme.primary;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _ClockPainter(
              fraction: fraction,
              color: color,
              trackColor: scheme.surfaceContainerHighest,
            ),
          ),
          Text(
            '$secondsLeft',
            style: TextStyle(
              fontSize: size * 0.32,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ClockPainter extends CustomPainter {
  final double fraction;
  final Color color;
  final Color trackColor;

  _ClockPainter({required this.fraction, required this.color, required this.trackColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 8;

    final tickPaint = Paint()
      ..color = trackColor
      ..strokeWidth = 1.5;
    for (int i = 0; i < 12; i++) {
      final angle = (i / 12) * 2 * pi;
      final outer = center + Offset(cos(angle), sin(angle)) * (radius + 7);
      final inner = center + Offset(cos(angle), sin(angle)) * (radius + 2);
      canvas.drawLine(inner, outer, tickPaint);
    }

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;
    canvas.drawCircle(center, radius, trackPaint);

    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * fraction,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ClockPainter oldDelegate) {
    return oldDelegate.fraction != fraction || oldDelegate.color != color;
  }
}
