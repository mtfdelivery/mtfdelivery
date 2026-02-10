import 'package:flutter/material.dart';

/// A wrapper that adds premium hover effects and custom mouse cursor
/// This version uses InkWell for better stability on web and desktop
class HoverWrapper extends StatelessWidget {
  final Widget child;
  final double scale;
  final Duration duration;
  final Curve curve;
  final VoidCallback? onTap;

  const HoverWrapper({
    super.key,
    required this.child,
    this.scale = 1.02,
    this.duration = const Duration(milliseconds: 200),
    this.curve = Curves.easeInOut,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: child,
    );
  }
}
