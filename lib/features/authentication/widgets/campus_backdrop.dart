import 'package:flutter/material.dart';

import '../../../app/theme.dart';

class CampusBackdrop extends StatelessWidget {
  const CampusBackdrop({super.key});

  static const String _campusImage = 'assets/images/sunway_campus.png';

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Campus photo
        Image.asset(
          _campusImage,
          fit: BoxFit.cover,
          alignment: Alignment.center,
          // If the asset is missing the screen still renders, just on navy.
          errorBuilder: (_, _, _) => const ColoredBox(color: AppColors.primary),
        ),

        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.primaryDark.withValues(alpha: 0.92),
                AppColors.primary.withValues(alpha: 0.55),
                AppColors.primary.withValues(alpha: 0.80),
              ],
              stops: const [0.0, 0.55, 1.0],
            ),
          ),
        ),
      ],
    );
  }
}
