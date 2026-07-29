import 'package:flutter/material.dart';

import '../../../app/theme.dart';

/// Sunway campus photo used as the header of the auth screens.
///
/// The photo is cropped to fill whatever slice of the screen the header is
/// given, with a navy gradient scrim over it so the 404 lockup and the "Back"
/// chip stay legible and the header blends into the white form card below.
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
          errorBuilder: (_, __, ___) => const ColoredBox(
            color: AppColors.primary,
          ),
        ),

        // Navy scrim: darkest at the top for status-bar contrast, and again at
        // the bottom so the white card meets the photo cleanly.
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
