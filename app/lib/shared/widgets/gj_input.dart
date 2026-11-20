import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/theme/gj_colors.dart';
import '../../core/theme/gj_radius.dart';
import '../../core/theme/gj_spacing.dart';
import '../../core/theme/gj_typography.dart';

enum GJInputVariant { public, painel }

/// Campo de texto do Guia Jovem Design System (seção 3.2).
class GJInput extends StatefulWidget {
  const GJInput({
    super.key,
    required this.label,
    this.controller,
    this.variant = GJInputVariant.public,
    this.hint,
    this.helperText,
    this.errorText,
    this.obscureText = false,
    this.icon,
    this.maxLength,
    this.enabled = true,
    this.readOnly = false,
    this.keyboardType,
    this.onChanged,
    this.inputFormatters,
  });

  final String label;
  final TextEditingController? controller;
  final GJInputVariant variant;
  final String? hint;
  final String? helperText;
  final String? errorText;
  final bool obscureText;
  final IconData? icon;
  final int? maxLength;
  final bool enabled;
  final bool readOnly;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;

  /// Máscaras aplicadas durante a digitação (CNPJ, CEP).
  final List<TextInputFormatter>? inputFormatters;

  @override
  State<GJInput> createState() => _GJInputState();
}

class _GJInputState extends State<GJInput> {
  late bool _obscure = widget.obscureText;
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

  Color get _fillColor {
    if (widget.readOnly) return GJColors.surfaceHigh;
    return widget.variant == GJInputVariant.public ? GJColors.surfaceLowest : GJColors.surfaceLow;
  }

  double get _radius => widget.variant == GJInputVariant.public ? GJRadius.md : GJRadius.sm;

  Color get _ringColor {
    if (_hasError) return GJColors.error;
    if (_focused) return GJColors.primary;
    return Colors.transparent;
  }

  @override
  Widget build(BuildContext context) {
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
              color: _fillColor,
              borderRadius: BorderRadius.circular(_radius),
              border: Border.all(color: _ringColor, width: 2),
              boxShadow: widget.variant == GJInputVariant.public
                  ? const [BoxShadow(color: Color(0x0F000000), blurRadius: 2, offset: Offset(0, 1))]
                  : null,
            ),
            child: TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              obscureText: _obscure,
              enabled: widget.enabled,
              readOnly: widget.readOnly,
              maxLength: widget.maxLength,
              keyboardType: widget.keyboardType,
              onChanged: widget.onChanged,
              inputFormatters: widget.inputFormatters,
              style: GJTypography.body(),
              cursorColor: GJColors.primary,
              decoration: InputDecoration(
                hintText: widget.hint,
                hintStyle: GJTypography.body().copyWith(color: GJColors.textDisabled),
                border: InputBorder.none,
                counterText: '',
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: GJSpace.s4,
                  vertical: GJSpace.s4,
                ),
                prefixIcon: widget.icon != null
                    ? Icon(widget.icon, size: 20, color: GJColors.textDisabled)
                    : null,
                suffixIcon: widget.obscureText
                    ? IconButton(
                        icon: Icon(
                          _obscure ? Symbols.visibility : Symbols.visibility_off,
                          size: 20,
                          color: GJColors.textDisabled,
                        ),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      )
                    : null,
              ),
            ),
          ),
        ),
        if (_hasError || (widget.helperText?.isNotEmpty ?? false))
          Padding(
            padding: const EdgeInsets.only(top: GJSpace.s1, left: GJSpace.s1),
            child: Text(
              _hasError ? widget.errorText! : widget.helperText!,
              style: GJTypography.caption(color: _hasError ? GJColors.error : GJColors.textSecondary),
            ),
          ),
      ],
    );
  }
}
