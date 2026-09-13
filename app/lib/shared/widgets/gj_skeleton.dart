import 'package:flutter/material.dart';

import '../../core/theme/gj_colors.dart';
import '../../core/theme/gj_radius.dart';
import '../../core/theme/gj_spacing.dart';

/// Bloco de carregamento (seção 3.20): `surface.highest` com "respiração"
/// de opacidade no lugar das dimensões do componente final.
class GJSkeleton extends StatefulWidget {
  const GJSkeleton({super.key, this.width, required this.height, this.radius = GJRadius.sm});

  final double? width;
  final double height;
  final double radius;

  @override
  State<GJSkeleton> createState() => _GJSkeletonState();
}

class _GJSkeletonState extends State<GJSkeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 1.0, end: 0.5).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut)),
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: GJColors.surfaceHighest,
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      ),
    );
  }
}

/// Skeleton pronto para um `GJCard.universidade`/`GJCard.programa` (seção 15 do deck).
class GJSkeletonCard extends StatelessWidget {
  const GJSkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(GJSpace.s6),
      decoration: BoxDecoration(color: GJColors.surfaceLow, borderRadius: GJRadius.borderLg),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GJSkeleton(height: 96, radius: GJRadius.md),
          SizedBox(height: GJSpace.s4),
          GJSkeleton(width: 160, height: 20, radius: GJRadius.xs),
          SizedBox(height: GJSpace.s2),
          GJSkeleton(width: 100, height: 14, radius: GJRadius.xs),
          SizedBox(height: GJSpace.s4),
          Row(
            children: [
              GJSkeleton(width: 56, height: 24, radius: 999),
              SizedBox(width: GJSpace.s2),
              GJSkeleton(width: 72, height: 24, radius: 999),
            ],
          ),
        ],
      ),
    );
  }
}
