import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// One step of the first-run walkthrough: the widget to highlight plus the
/// copy that explains it.
class CoachMark {
  final GlobalKey key;
  final String title;
  final String body;

  final bool circle;

  const CoachMark({
    required this.key,
    required this.title,
    required this.body,
    this.circle = false,
  });
}

class CoachMarkOverlay extends StatefulWidget {
  final List<CoachMark> steps;
  final VoidCallback onFinish;

  const CoachMarkOverlay({
    super.key,
    required this.steps,
    required this.onFinish,
  });

  @override
  State<CoachMarkOverlay> createState() => _CoachMarkOverlayState();
}

class _CoachMarkOverlayState extends State<CoachMarkOverlay> {
  int _index = 0;
  Rect? _targetRect() {
    final ctx = widget.steps[_index].key.currentContext;
    if (ctx == null) return null;
    final target = ctx.findRenderObject() as RenderBox?;
    final self = context.findRenderObject() as RenderBox?;
    if (target == null || !target.hasSize) return null;
    if (self == null || !self.hasSize) return null;

    final topLeft = self.globalToLocal(target.localToGlobal(Offset.zero));
    return topLeft & target.size;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  void _next() {
    if (_index >= widget.steps.length - 1) {
      widget.onFinish();
    } else {
      setState(() => _index++);
    }
  }

  void _back() {
    if (_index > 0) setState(() => _index--);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return _buildOverlay(context, constraints.biggest);
      },
    );
  }

  Widget _buildOverlay(BuildContext context, Size size) {
    final step = widget.steps[_index];
    final rect = _targetRect();

    // Padded spotlight so the highlight breathes around the target.
    final spot = rect == null
        ? Rect.fromCenter(
            center: Offset(size.width / 2, size.height / 2),
            width: 0,
            height: 0,
          )
        : rect.inflate(8);

    // Put the card on whichever side has more room.
    final showBelow = spot.center.dy < size.height * 0.5;

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Dimmed backdrop with the spotlight cut out. Tapping advances.
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _next,
              child: CustomPaint(
                painter: _SpotlightPainter(spot: spot, circle: step.circle),
              ),
            ),
          ),

          // Explanation card
          Positioned(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            top: showBelow ? spot.bottom + AppSpacing.lg : null,
            bottom: showBelow ? null : size.height - spot.top + AppSpacing.lg,
            child: _CoachCard(
              step: step,
              index: _index,
              total: widget.steps.length,
              onNext: _next,
              onBack: _index == 0 ? null : _back,
              onSkip: widget.onFinish,
            ),
          ),
        ],
      ),
    );
  }
}

class _CoachCard extends StatelessWidget {
  final CoachMark step;
  final int index;
  final int total;
  final VoidCallback onNext;
  final VoidCallback? onBack;
  final VoidCallback onSkip;

  const _CoachCard({
    required this.step,
    required this.index,
    required this.total,
    required this.onNext,
    required this.onSkip,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLast = index == total - 1;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius + 4),
        border: const Border(
          left: BorderSide(color: AppColors.accent, width: 5),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 28,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Step ${index + 1} of $total',
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.accentText,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            step.title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
              height: 1.2,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            step.body,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Tap anywhere to continue',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          Row(
            children: [
              // Progress dots
              Row(
                children: List.generate(
                  total,
                  (i) => Container(
                    width: i == index ? 16 : 6,
                    height: 6,
                    margin: const EdgeInsets.only(right: 4),
                    decoration: BoxDecoration(
                      color: i == index
                          ? AppColors.primary
                          : AppColors.placeholder,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
              const Spacer(),
              if (onBack != null)
                TextButton(onPressed: onBack, child: const Text('Back')),
              if (!isLast)
                TextButton(onPressed: onSkip, child: const Text('Skip')),
              FilledButton(
                onPressed: onNext,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(88, 40),
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                ),
                child: Text(isLast ? 'Got it' : 'Next'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Paints the dim scrim with a transparent hole over the target.
class _SpotlightPainter extends CustomPainter {
  final Rect spot;
  final bool circle;

  _SpotlightPainter({required this.spot, required this.circle});

  @override
  void paint(Canvas canvas, Size size) {
    final scrim = Path()..addRect(Offset.zero & size);

    final hole = Path();
    if (circle) {
      hole.addOval(
        Rect.fromCircle(center: spot.center, radius: spot.longestSide / 2),
      );
    } else {
      hole.addRRect(RRect.fromRectAndRadius(spot, const Radius.circular(12)));
    }

    canvas.drawPath(
      Path.combine(PathOperation.difference, scrim, hole),
      Paint()..color = const Color(0xFF06132B).withValues(alpha: 0.72),
    );

    canvas.drawPath(
      hole,
      Paint()..color = Colors.white.withValues(alpha: 0.14),
    );

    canvas.drawPath(
      hole,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 16
        ..color = AppColors.accent.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    canvas.drawPath(
      hole,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = AppColors.accent,
    );
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter old) =>
      old.spot != spot || old.circle != circle;
}
