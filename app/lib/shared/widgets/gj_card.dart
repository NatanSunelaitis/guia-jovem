import 'package:flutter/material.dart';

import '../../core/theme/gj_colors.dart';
import '../../core/theme/gj_radius.dart';
import '../../core/theme/gj_shadows.dart';
import '../../core/theme/gj_spacing.dart';

enum GJCardVariant { base, elevated }

/// Card base do Guia Jovem Design System (seção 3.4).
/// As variantes de domínio (GJCard.universidade, .programa, .curso, ...)
/// são compostas a partir deste componente quando as telas forem construídas.
class GJCard extends StatefulWidget {
  const GJCard({
    super.key,
    required this.child,
    this.variant = GJCardVariant.base,
    this.onTap,
    this.padding,
  });

  final Widget child;
  final GJCardVariant variant;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;

  @override
  State<GJCard> createState() => _GJCardState();
}

class _GJCardState extends State<GJCard> {
  bool _hovered = false;

  Color get _background {
    if (widget.variant == GJCardVariant.elevated) return GJColors.surfaceLowest;
    return _hovered ? GJColors.surface : GJColors.surfaceLow;
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 600;
    final defaultPadding = EdgeInsets.all(isMobile ? GJSpace.s6 : GJSpace.s8);

    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: widget.padding ?? defaultPadding,
      decoration: BoxDecoration(
        color: _background,
        borderRadius: GJRadius.borderLg,
        border: widget.variant == GJCardVariant.elevated ? GJShadows.borderSubtle : null,
        boxShadow: widget.variant == GJCardVariant.elevated ? GJShadows.sm : GJShadows.none,
      ),
      child: widget.child,
    );

    if (widget.onTap == null) return card;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(onTap: widget.onTap, child: card),
    );
  }
}
