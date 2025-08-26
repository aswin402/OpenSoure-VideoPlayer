import 'package:flutter/material.dart';

class ShimmerPlaceholder extends StatefulWidget {
  const ShimmerPlaceholder({
    super.key,
    required this.startColor,
    required this.endColor,
    this.icon = Icons.image_outlined,
  });
  final Color startColor;
  final Color endColor;
  final IconData icon;

  @override
  State<ShimmerPlaceholder> createState() => _ShimmerPlaceholderState();
}

class _ShimmerPlaceholderState extends State<ShimmerPlaceholder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = CurvedAnimation(
          parent: _controller,
          curve: Curves.easeInOut,
        ).value;
        final color1 = Color.lerp(
          widget.startColor,
          widget.endColor,
          t,
        )!.withValues(alpha: 0.6);
        final color2 = Color.lerp(
          widget.endColor,
          widget.startColor,
          t,
        )!.withValues(alpha: 0.6);
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color1, color2],
            ),
          ),
          child: Center(
            child: Icon(widget.icon, size: 40, color: Colors.white70),
          ),
        );
      },
    );
  }
}
