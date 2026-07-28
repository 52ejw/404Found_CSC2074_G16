import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../models/enums.dart';

/// Small pill showing whether a post is Lost (yellow) or Found (blue),
/// per the design system.
class TypeBadge extends StatelessWidget {
  final PostType type;
  const TypeBadge({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    final isLost = type == PostType.lost;
    final bg = isLost ? AppColors.lostBg : AppColors.foundBg;
    final fg = isLost ? AppColors.lostFg : AppColors.foundFg;
    final label = isLost ? 'Lost' : 'Found';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w500),
      ),
    );
  }
}
