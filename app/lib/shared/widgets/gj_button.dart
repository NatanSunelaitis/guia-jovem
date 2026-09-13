import 'package:flutter/material.dart';

import '../../core/theme/gj_colors.dart';
import '../../core/theme/gj_radius.dart';
import '../../core/theme/gj_spacing.dart';
import '../../core/theme/gj_typography.dart';

enum GJButtonVariant { primary, secondary, ghost, danger, google, financiamento }

enum GJButtonShape { pill, rect }

enum GJButtonSize { sm, md, lg }

/// Botão do Guia Jovem Design System (seção 3.1).
/// Um único botão `primary` deve existir por região visual.
class GJButton extends StatefulWidget {
  const GJButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = GJButtonVariant.primary,
    this.shape = GJButtonShape.pill,
    this.size = GJButtonSize.md,
    this.icon,
    this.loading = false,
    this.expand = false,
    this.color = GJColors.primary,
  });

  final String label;
  final VoidCallback? onPressed;
  final GJButtonVariant variant;
  final GJButtonShape shape;
  final GJButtonSize size;
  final IconData? icon;
  final bool loading;
  final bool expand;

  /// Cor de destaque da variante `secondary` (contorno + preenchimento no
  /// hover). Usada para reproduzir o "Ver detalhes" dos cards de programa,
  /// que muda de cor por categoria (entrada/bolsa/financiamento).
  final Color color;

  double get _height => switch (size) {
        GJButtonSize.sm => 36,
        GJButtonSize.md => 44,
        GJButtonSize.lg => 52,
      };

  double get _horizontalPadding => switch (size) {
        GJButtonSize.sm => GJSpace.s4,
        GJButtonSize.md => GJSpace.s6,
        GJButtonSize.lg => GJSpace.s8,
      };

  @override
  State<GJButton> createState() => _GJButtonState();
}

class _GJButtonState extends State<GJButton> {
  bool _hovered = false;
  bool _pressed = false;

  bool get _disabled => widget.onPressed == null || widget.loading;

  _ButtonPalette get _palette {
    switch (widget.variant) {
      case GJButtonVariant.primary:
        return _ButtonPalette(
          background: _hovered ? GJColors.primaryDark : GJColors.primaryContainer,
          foreground: GJColors.primaryOn,
          border: null,
        );
      case GJButtonVariant.secondary:
        return _ButtonPalette(
          background: _hovered ? widget.color : Colors.transparent,
          foreground: _hovered ? GJColors.primaryOn : widget.color,
          border: widget.color.withOpacity(0.2),
        );
      case GJButtonVariant.ghost:
        return _ButtonPalette(
          background: _hovered ? GJColors.surfaceLow : Colors.transparent,
          foreground: GJColors.primary,
          border: null,
        );
      case GJButtonVariant.danger:
        return _ButtonPalette(
          background: _hovered ? GJColors.errorOnContainer : GJColors.error,
          foreground: GJColors.primaryOn,
          border: null,
        );
      case GJButtonVariant.google:
        return const _ButtonPalette(
          background: GJColors.surfaceLowest,
          foreground: GJColors.textPrimary,
          border: GJColors.border,
        );
      case GJButtonVariant.financiamento:
        // Categoria Financiamento (FIES): mesmo padrão do primary, em tertiary.
        return _ButtonPalette(
          background: _hovered ? GJColors.tertiaryDark : GJColors.tertiaryContainer,
          foreground: GJColors.primaryOn,
          border: null,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = _palette;
    final OutlinedBorder shapeBorder = widget.shape == GJButtonShape.pill
        ? GJRadius.full
        : RoundedRectangleBorder(borderRadius: GJRadius.borderMd);

    final content = widget.loading
        ? SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: palette.foreground),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: 20, color: palette.foreground),
                const SizedBox(width: GJSpace.s2),
              ],
              // Flexible com ellipsis: com `expand: true` dentro de um card
              // estreito, o Row recebe menos largura do que o texto pediria;
              // sem isso, o botão estoura em RenderFlex overflow em vez de
              // truncar o rótulo.
              Flexible(
                child: Text(
                  widget.label,
                  style: GJTypography.label(color: palette.foreground),
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                ),
              ),
            ],
          );

    return MouseRegion(
      cursor: _disabled ? SystemMouseCursors.basic : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTapDown: _disabled ? null : (_) => setState(() => _pressed = true),
        onTapUp: _disabled ? null : (_) => setState(() => _pressed = false),
        onTapCancel: _disabled ? null : () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1,
          duration: const Duration(milliseconds: 150),
          child: Opacity(
            opacity: _disabled && !widget.loading ? 0.4 : 1,
            child: Material(
              color: palette.background,
              shape: shapeBorder.copyWith(
                side: palette.border != null ? BorderSide(color: palette.border!) : BorderSide.none,
              ),
              child: InkWell(
                customBorder: shapeBorder,
                onTap: _disabled ? null : widget.onPressed,
                child: Container(
                  height: widget._height,
                  width: widget.expand ? double.infinity : null,
                  padding: EdgeInsets.symmetric(horizontal: widget._horizontalPadding),
                  // Sem `alignment`: com width null, um Container com
                  // alignment se expande para preencher o espaço disponível
                  // em vez de abraçar o conteúdo, esticando o botão dentro
                  // de um Wrap. A Row já centraliza verticalmente sozinha.
                  child: content,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ButtonPalette {
  const _ButtonPalette({required this.background, required this.foreground, this.border});

  final Color background;
  final Color foreground;
  final Color? border;
}
