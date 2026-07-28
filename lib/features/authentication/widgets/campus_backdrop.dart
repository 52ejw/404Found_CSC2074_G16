import 'package:flutter/material.dart';

import '../../../app/theme.dart';

/// Illustrated Sunway campus backdrop used behind the auth screens.
///
/// Drawn with [CustomPaint] rather than a photo so it scales to any device,
/// adds no asset weight, and always matches the app palette. The composition
/// mirrors the familiar campus view: the university block on the left, the
/// residence towers behind it, the sports field in front, and the elevated
/// BRT line running along the right.
class CampusBackdrop extends StatelessWidget {
  const CampusBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF0C1E3E), // night navy
            AppColors.primary, // Sunway navy
            Color(0xFF4C77B8), // hazy daylight blue
          ],
          stops: [0.0, 0.55, 1.0],
        ),
      ),
      child: CustomPaint(
        painter: _CampusPainter(),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _CampusPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Sun glow behind the skyline (crest gold)
    canvas.drawCircle(
      Offset(w * 0.78, h * 0.20),
      w * 0.13,
      Paint()
        ..shader = RadialGradient(
          colors: [
            AppColors.accent.withValues(alpha: 0.85),
            AppColors.accent.withValues(alpha: 0.0),
          ],
        ).createShader(
          Rect.fromCircle(center: Offset(w * 0.78, h * 0.20), radius: w * 0.20),
        ),
    );

    // Drifting clouds
    final cloud = Paint()..color = Colors.white.withValues(alpha: 0.10);
    _cloud(canvas, cloud, Offset(w * 0.22, h * 0.14), w * 0.16);
    _cloud(canvas, cloud, Offset(w * 0.62, h * 0.09), w * 0.12);

    final baseline = h * 0.82;

    // ---- Residence towers (back layer, silhouetted) -------------------
    final backTower = Paint()..color = Colors.white.withValues(alpha: 0.16);
    _tower(canvas, backTower, w * 0.52, baseline, w * 0.10, h * 0.34);
    _tower(canvas, backTower, w * 0.65, baseline, w * 0.09, h * 0.42);
    _tower(canvas, backTower, w * 0.77, baseline, w * 0.11, h * 0.30);
    _tower(canvas, backTower, w * 0.90, baseline, w * 0.10, h * 0.38);

    // ---- University block (front left, brighter) ----------------------
    final frontBlock = Paint()..color = Colors.white.withValues(alpha: 0.30);
    _tower(canvas, frontBlock, w * 0.06, baseline, w * 0.13, h * 0.28);
    _tower(canvas, frontBlock, w * 0.21, baseline, w * 0.18, h * 0.22);

    // Window grid on the university block
    final window = Paint()..color = AppColors.accent.withValues(alpha: 0.55);
    for (var row = 0; row < 5; row++) {
      for (var col = 0; col < 4; col++) {
        canvas.drawRect(
          Rect.fromLTWH(
            w * 0.075 + col * w * 0.029,
            baseline - h * 0.25 + row * h * 0.045,
            w * 0.012,
            h * 0.016,
          ),
          window,
        );
      }
    }

    // Red canopy over the entrance — the campus's signature accent
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.20, baseline - h * 0.23, w * 0.20, h * 0.014),
        const Radius.circular(4),
      ),
      Paint()..color = AppColors.sunwayRed.withValues(alpha: 0.75),
    );

    // ---- Sports field (foreground) ------------------------------------
    final fieldRect = Rect.fromLTWH(0, baseline, w, h - baseline);
    canvas.drawRect(
      fieldRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.campusGreen.withValues(alpha: 0.55),
            AppColors.campusGreen.withValues(alpha: 0.20),
          ],
        ).createShader(fieldRect),
    );

    // Pitch markings — centre circle and halfway line
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = Colors.white.withValues(alpha: 0.28);
    final centre = Offset(w * 0.5, baseline + (h - baseline) * 0.55);
    canvas.drawCircle(centre, w * 0.10, line);
    canvas.drawLine(
      Offset(0, centre.dy),
      Offset(w, centre.dy),
      line,
    );

    // ---- Elevated BRT line (right edge) -------------------------------
    final rail = Paint()..color = Colors.white.withValues(alpha: 0.22);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.72, baseline - h * 0.02, w * 0.34, h * 0.012),
        const Radius.circular(3),
      ),
      rail,
    );
    for (var i = 0; i < 4; i++) {
      canvas.drawRect(
        Rect.fromLTWH(w * (0.76 + i * 0.07), baseline - h * 0.01, w * 0.012,
            h * 0.05),
        rail,
      );
    }
  }

  void _tower(Canvas c, Paint p, double x, double baseline, double width,
      double height) {
    c.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(x, baseline - height, width, height),
        topLeft: const Radius.circular(4),
        topRight: const Radius.circular(4),
      ),
      p,
    );
  }

  void _cloud(Canvas c, Paint p, Offset at, double size) {
    c.drawCircle(at, size * 0.30, p);
    c.drawCircle(at + Offset(size * 0.26, size * 0.05), size * 0.24, p);
    c.drawCircle(at - Offset(size * 0.26, -size * 0.06), size * 0.20, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
