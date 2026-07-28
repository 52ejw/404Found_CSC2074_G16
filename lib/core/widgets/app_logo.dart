import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// The "404" brand mark — a nod to the group name, 404 Found.
///
/// A rounded navy tile with the numerals set in gold; the middle "0" is drawn
/// as a ring so it reads as a magnifier/lost-item motif rather than plain type.
/// Used on the splash, landing, drawer and auth screens so the brand is
/// consistent everywhere (NFR11).
class AppLogo extends StatelessWidget {
  /// Overall side length of the tile.
  final double size;

  /// Light variant (gold on navy) for dark backdrops, or inverted for white.
  final bool onDark;

  const AppLogo({super.key, this.size = 72, this.onDark = true});

  @override
  Widget build(BuildContext context) {
    final tileColor =
        onDark ? Colors.white.withValues(alpha: 0.14) : AppColors.primary;
    final digitColor = AppColors.accent;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: tileColor,
        borderRadius: BorderRadius.circular(size * 0.26),
        border: Border.all(color: AppColors.accent, width: size * 0.028),
      ),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: size * 0.12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _Digit('4', color: digitColor, size: size),
                SizedBox(width: size * 0.03),
                // Middle "0" as a ring — the "lost item" lens
                Container(
                  width: size * 0.26,
                  height: size * 0.26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: digitColor,
                      width: size * 0.055,
                    ),
                  ),
                ),
                SizedBox(width: size * 0.03),
                _Digit('4', color: digitColor, size: size),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Digit extends StatelessWidget {
  final String text;
  final Color color;
  final double size;

  const _Digit(this.text, {required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: color,
        fontSize: size * 0.40,
        fontWeight: FontWeight.w800,
        height: 1.0,
        letterSpacing: -0.5,
      ),
    );
  }
}

/// Horizontal "404 FOUND" wordmark for headers and the auth backdrop.
class AppWordmark extends StatelessWidget {
  final Color color;
  final double scale;

  const AppWordmark({super.key, this.color = Colors.white, this.scale = 1});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              '4',
              style: TextStyle(
                color: color,
                fontSize: 34 * scale,
                fontWeight: FontWeight.w800,
                height: 1.0,
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 2 * scale),
              child: Container(
                width: 22 * scale,
                height: 22 * scale,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.accent, width: 4 * scale),
                ),
              ),
            ),
            Text(
              '4',
              style: TextStyle(
                color: color,
                fontSize: 34 * scale,
                fontWeight: FontWeight.w800,
                height: 1.0,
              ),
            ),
          ],
        ),
        SizedBox(height: 4 * scale),
        Text(
          'FOUND',
          style: TextStyle(
            color: color,
            fontSize: 12 * scale,
            fontWeight: FontWeight.w500,
            letterSpacing: 7 * scale,
          ),
        ),
      ],
    );
  }
}
