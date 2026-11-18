import 'package:flutter/material.dart';

import '../../core/theme/gj_colors.dart';
import '../../core/theme/gj_spacing.dart';
import '../../core/theme/gj_typography.dart';

/// [neutral]: estado sem destaque (ex.: universidade inativa).
enum GJStatusTone { success, warning, error, neutral }

/// Badge de status com ponto colorido (seção 3.19).
/// Ponto de 8 px à esquerda; pulsante para "Publicado e Ativo".
class GJStatusBadge extends StatefulWidget {
  const GJStatusBadge({super.key, required this.label, required this.tone, this.pulsante = false});

  final String label;
  final GJStatusTone tone;
  final bool pulsante;

  ({Color background, Color foreground}) get _colors => switch (tone) {
        GJStatusTone.success => (background: GJColors.successContainer, foreground: GJColors.success),
        GJStatusTone.warning => (background: GJColors.warningContainer, foreground: GJColors.warning),
        GJStatusTone.error => (background: GJColors.errorContainer, foreground: GJColors.errorOnContainer),
        GJStatusTone.neutral => (background: GJColors.surface, foreground: GJColors.textSecondary),
      };

  @override
  State<GJStatusBadge> createState() => _GJStatusBadgeState();
}

class _GJStatusBadgeState extends State<GJStatusBadge> with SingleTickerProviderStateMixin {
  // Criado sempre em initState (não com `late final` preguiçoso): se nunca
  // fosse lido durante build (badge sem pulso), a primeira leitura aconteceria
  // dentro de dispose(), criando um AnimationController com vsync de um
  // widget já desativado.
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));
    if (widget.pulsante) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget._colors;
    final dot = Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: colors.foreground, shape: BoxShape.circle),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: GJSpace.s3, vertical: GJSpace.s1),
      decoration: BoxDecoration(color: colors.background, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.pulsante)
            FadeTransition(
              opacity: Tween(begin: 1.0, end: 0.4).animate(
                CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
              ),
              child: dot,
            )
          else
            dot,
          const SizedBox(width: GJSpace.s2),
          Text(widget.label, style: GJTypography.caption(color: colors.foreground).copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
