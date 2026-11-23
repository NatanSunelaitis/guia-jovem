import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/theme/gj_colors.dart';
import '../../core/theme/gj_radius.dart';
import '../../core/theme/gj_spacing.dart';
import '../../core/theme/gj_typography.dart';
import 'gj_input.dart';

/// Lista de opções com o mesmo visual do [GJInput] (seção 3.2): rótulo
/// acima, caixa preenchida com a mesma borda, cantos e altura, e o erro
/// embaixo. Para os formulários não misturarem o campo de texto com o
/// seletor de borda contornada do Material.
class GJSelect<T> extends StatefulWidget {
  const GJSelect({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.variant = GJInputVariant.public,
    this.hint,
    this.errorText,
    this.enabled = true,
  });

  final String label;
  final T? value;

  /// Valor e texto de cada opção, na ordem.
  final Map<T?, String> items;
  final ValueChanged<T?> onChanged;
  final GJInputVariant variant;
  final String? hint;
  final String? errorText;
  final bool enabled;

  @override
  State<GJSelect<T>> createState() => _GJSelectState<T>();
}

class _GJSelectState<T> extends State<GJSelect<T>> {
  final FocusNode _focusNode = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() => setState(() => _focused = _focusNode.hasFocus));
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  bool get _hasError => widget.errorText != null && widget.errorText!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final publico = widget.variant == GJInputVariant.public;
    final anel = _hasError ? GJColors.error : (_focused ? GJColors.primary : Colors.transparent);
    final valor = widget.items.containsKey(widget.value) ? widget.value : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: GJSpace.s1, bottom: GJSpace.s2),
          child: Text(widget.label, style: GJTypography.label()),
        ),
        Opacity(
          opacity: widget.enabled ? 1 : 0.6,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: publico ? GJColors.surfaceLowest : GJColors.surfaceLow,
              borderRadius: BorderRadius.circular(publico ? GJRadius.md : GJRadius.sm),
              border: Border.all(color: anel, width: 2),
              boxShadow: publico ? const [BoxShadow(color: Color(0x0F000000), blurRadius: 2, offset: Offset(0, 1))] : null,
            ),
            child: DropdownButtonFormField<T?>(
              value: valor,
              focusNode: _focusNode,
              isExpanded: true,
              icon: const Icon(Symbols.expand_more, size: 20, color: GJColors.textSecondary),
              style: GJTypography.body(),
              borderRadius: GJRadius.borderMd,
              dropdownColor: GJColors.surfaceLowest,
              decoration: InputDecoration(
                hintText: widget.hint,
                hintStyle: GJTypography.body().copyWith(color: GJColors.textDisabled),
                border: InputBorder.none,
                isDense: false,
                contentPadding: const EdgeInsets.symmetric(horizontal: GJSpace.s4, vertical: GJSpace.s4),
              ),
              items: [
                for (final item in widget.items.entries)
                  DropdownMenuItem<T?>(
                    value: item.key,
                    child: Text(item.value, style: GJTypography.body(), overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: widget.enabled ? widget.onChanged : null,
            ),
          ),
        ),
        if (_hasError)
          Padding(
            padding: const EdgeInsets.only(top: GJSpace.s1, left: GJSpace.s1),
            child: Text(widget.errorText!, style: GJTypography.caption(color: GJColors.error)),
          ),
      ],
    );
  }
}
