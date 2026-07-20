import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme.dart';
import 'settings_screen.dart';

class WildHeader extends StatelessWidget implements PreferredSizeWidget {
  final List<Widget>? actions;

  const WildHeader({super.key, this.actions});

  @override
  Size get preferredSize => const Size.fromHeight(66);

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.canPop(context);
    final List<Widget> finalActions = [];
    if (actions != null) {
      finalActions.addAll(actions!);
    }

    // Edit/Logs button in top-right on main screens
    if (!canPop) {
      finalActions.add(
        TextButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            );
          },
          icon: const Icon(Icons.edit_outlined, color: AppTheme.orangeSoft, size: 16),
          label: Text(
            'Edit',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppTheme.orangeSoft,
              letterSpacing: 1.2,
            ),
          ),
        ),
      );
    }

    return AppBar(
      toolbarHeight: 66,
      automaticallyImplyLeading: canPop,
      titleSpacing: 16,
      title: Text(
        'Ferox',
        style: Theme.of(context).appBarTheme.titleTextStyle,
      ),
      actions: finalActions,
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1),
      ),
    );
  }
}

/// Glassmorphism-style card — solid gradient glass (no BackdropFilter for perf)
class WildCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? accent;
  final double radius;
  final VoidCallback? onTap;

  const WildCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.accent,
    this.radius = 24,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF263530), Color(0xFF1A2520)],
        ),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: Color(0x2AFFFFFF), // ~0.16 white
          width: 1.4,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x50000000),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );

    final decorated = accent == null
        ? content
        : ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 4,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [accent!, accent!.withValues(alpha: 0.4)],
                      ),
                    ),
                  ),
                  Expanded(child: content),
                ],
              ),
            ),
          );

    if (onTap == null) return decorated;
    return InkWell(
      borderRadius: BorderRadius.circular(radius),
      onTap: onTap,
      child: decorated,
    );
  }
}

/// Forest panel with painted background + optional network image overlay + gradient
class ForestPanel extends StatelessWidget {
  final Widget child;
  final double? height;
  final EdgeInsetsGeometry padding;
  final String? imageUrl;

  const ForestPanel({
    super.key,
    required this.child,
    this.height,
    this.padding = const EdgeInsets.all(24),
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final inner = ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          // Always-present painted forest background (never blank)
          Positioned.fill(child: CustomPaint(painter: _ForestPainter())),

          // Network image on top of painted bg, with error/loading fallback to painted bg
          if (imageUrl != null)
            Positioned.fill(
              child: Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                // If loading fails, the painted bg underneath remains visible
                errorBuilder: (context, error, stackTrace) =>
                    const SizedBox.shrink(),
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  // While loading, the painted background is already visible
                  return const SizedBox.shrink();
                },
              ),
            ),

          // Dark gradient overlay for readability
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppTheme.forest.withValues(alpha: 0.08),
                    AppTheme.forest.withValues(alpha: 0.50),
                    AppTheme.forest.withValues(alpha: 0.88),
                  ],
                ),
              ),
            ),
          ),
          // Border glow
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: AppTheme.snow.withValues(alpha: 0.10),
                  width: 1.2,
                ),
              ),
            ),
          ),
          Padding(padding: padding, child: child),
        ],
      ),
    );

    return height != null ? SizedBox(height: height, child: inner) : inner;
  }
}

class MacroRing extends StatelessWidget {
  final double value;
  final String center;
  final String label;
  final double size;

  const MacroRing({
    super.key,
    required this.value,
    required this.center,
    required this.label,
    this.size = 158,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size.square(size),
            painter: _RingPainter(value.clamp(0.0, 1.0)),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(center, style: Theme.of(context).textTheme.displayMedium),
              Text(
                label.toUpperCase(),
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class PillButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;

  const PillButton({super.key, required this.label, this.icon, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon ?? Icons.play_arrow_rounded),
      label: Text(label),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double value;

  _RingPainter(this.value);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final stroke = size.width * 0.08;
    final base = Paint()
      ..color = AppTheme.snow.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    final progress = Paint()
      ..shader = const SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: math.pi * 1.5,
        colors: [AppTheme.orange, AppTheme.orangeSoft, AppTheme.orange],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      rect.deflate(stroke),
      -math.pi / 2,
      math.pi * 2,
      false,
      base,
    );
    canvas.drawArc(
      rect.deflate(stroke),
      -math.pi / 2,
      math.pi * 2 * value,
      false,
      progress,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.value != value;
}

class _ForestPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF1E4138), Color(0xFF0A1611), Color(0xFF2B2418)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bg);

    final sun = Paint()
      ..shader = RadialGradient(
        colors: [
          AppTheme.orangeSoft.withValues(alpha: 0.62),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * 0.82, size.height * 0.2),
          radius: size.width * 0.5,
        ),
      );
    canvas.drawCircle(
      Offset(size.width * 0.82, size.height * 0.22),
      size.width * 0.42,
      sun,
    );

    final trunkPaint = Paint()
      ..color = AppTheme.forestDeep.withValues(alpha: 0.72);
    for (var i = 0; i < 12; i++) {
      final x = (i / 11) * size.width;
      final width = 5.0 + (i % 4) * 3;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, -20, width, size.height + 70),
          const Radius.circular(6),
        ),
        trunkPaint,
      );
      final branch = Paint()
        ..color = AppTheme.canopyHigh.withValues(alpha: 0.65)
        ..strokeWidth = 2;
      canvas.drawLine(
        Offset(x + width, size.height * 0.38),
        Offset(x + 42, size.height * 0.2),
        branch,
      );
    }

    final fern = Paint()..color = AppTheme.pine.withValues(alpha: 0.16);
    for (var i = 0; i < 20; i++) {
      final x = (i / 19) * size.width;
      final y = size.height - 18 - (i % 5) * 7;
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x, y), width: 80, height: 24),
        fern,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
