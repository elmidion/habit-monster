import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Draws the egg with warmth-based cracks and glow.
/// [warmth]  0.0 → 1.0  (0 = cold egg, 1.0 = ready to hatch)
/// [animValue] 0→1 drives wiggle + glow pulse
class EggPainter extends CustomPainter {
  final double warmth;
  final double animValue;
  final Color eggColor;

  EggPainter({
    required this.warmth,
    required this.animValue,
    this.eggColor = const Color(0xFFFFF9E6),
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    final s = size.shortestSide / 200;
    canvas.translate(
        (size.width - 200 * s) / 2, (size.height - 200 * s) / 2);
    canvas.scale(s, s);

    // Wiggle angle based on warmth
    final wiggle =
        math.sin(animValue * 2 * math.pi) * warmth * 10 * math.pi / 180;
    canvas.translate(100, 100);
    canvas.rotate(wiggle);
    canvas.translate(-100, -100);

    _drawShadow(canvas);
    _drawGlow(canvas);
    _drawEggBody(canvas);
    _drawSpots(canvas);
    if (warmth > 0.3) _drawCracks(canvas, warmth);
    _drawSheen(canvas);

    canvas.restore();
  }

  void _drawShadow(Canvas canvas) {
    canvas.drawOval(
      Rect.fromCenter(
          center: const Offset(100, 172), width: 72, height: 16),
      Paint()
        ..color = Colors.black.withOpacity(0.12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
  }

  void _drawGlow(Canvas canvas) {
    if (warmth < 0.1) return;
    final pulse = (math.sin(animValue * 2 * math.pi) + 1) / 2; // 0→1
    final glowAlpha = (warmth * 0.35 + pulse * warmth * 0.15).clamp(0.0, 0.5);
    canvas.drawOval(
      const Rect.fromLTWH(26, 34, 148, 142),
      Paint()
        ..color = const Color(0xFFFFE066).withOpacity(glowAlpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
    );
  }

  void _drawEggBody(Canvas canvas) {
    const eggRect = Rect.fromLTWH(38, 42, 124, 132);
    // Outline
    canvas.drawOval(
        eggRect.inflate(2.5),
        Paint()..color = const Color(0xFFE8D5A3).withOpacity(0.7));
    // Fill
    canvas.drawOval(eggRect, Paint()..color = eggColor);
  }

  void _drawSpots(Canvas canvas) {
    final spotPaint = Paint()
      ..color = const Color(0xFFD4C07A).withOpacity(0.55);
    const spots = [
      Offset(70, 80), Offset(120, 68), Offset(88, 130),
      Offset(130, 110), Offset(60, 118),
    ];
    for (final s in spots) {
      canvas.drawCircle(s, 7, spotPaint);
    }
  }

  void _drawCracks(Canvas canvas, double w) {
    final paint = Paint()
      ..color = const Color(0xFFB89A4E).withOpacity(0.7 * w)
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Crack 1 (appears at w > 0.3)
    if (w > 0.3) {
      canvas.drawPath(
          Path()
            ..moveTo(100, 58)
            ..lineTo(94, 72)
            ..lineTo(102, 78),
          paint);
    }
    // Crack 2 (w > 0.5)
    if (w > 0.5) {
      canvas.drawPath(
          Path()
            ..moveTo(124, 80)
            ..lineTo(116, 92)
            ..lineTo(122, 98)
            ..lineTo(115, 108),
          paint);
    }
    // Crack 3 — big top crack (w > 0.75)
    if (w > 0.75) {
      canvas.drawPath(
          Path()
            ..moveTo(88, 54)
            ..lineTo(96, 70)
            ..lineTo(88, 82)
            ..lineTo(100, 88)
            ..lineTo(92, 100),
          paint..strokeWidth = 2.2);
    }
  }

  void _drawSheen(Canvas canvas) {
    canvas.drawOval(
      const Rect.fromLTWH(56, 52, 38, 22),
      Paint()
        ..color = Colors.white.withOpacity(0.30)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
  }

  @override
  bool shouldRepaint(EggPainter old) =>
      old.warmth != warmth ||
      old.animValue != animValue ||
      old.eggColor != eggColor;
}
