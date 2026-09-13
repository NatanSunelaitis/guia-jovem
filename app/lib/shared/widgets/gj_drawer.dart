import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/theme/gj_breakpoints.dart';
import '../../core/theme/gj_colors.dart';
import '../../core/theme/gj_spacing.dart';
import '../../core/theme/gj_typography.dart';

/// Painel lateral direito, 480 px (seção 3.10), para formulários dentro
/// de painéis administrativos.
class GJDrawer extends StatelessWidget {
  const GJDrawer({super.key, required this.titulo, required this.child, this.acoes});

  final String titulo;
  final Widget child;
  final List<Widget>? acoes;

  static Future<T?> show<T>(
    BuildContext context, {
    required String titulo,
    required Widget child,
    List<Widget>? acoes,
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: true,
      barrierLabel: titulo,
      barrierColor: GJColors.textPrimary.withOpacity(0.2),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, animation, secondaryAnimation) {
        return GJDrawer(titulo: titulo, acoes: acoes, child: child);
      },
      transitionBuilder: (context, animation, secondaryAnimation, widget) {
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
              .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
          child: widget,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final largura = GJBreakpoints.isMobile(context) ? MediaQuery.sizeOf(context).width : 480.0;

    return Align(
      alignment: Alignment.centerRight,
      child: Material(
        color: GJColors.surfaceLowest,
        child: SizedBox(
          width: largura,
          height: double.infinity,
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: GJSpace.s6, vertical: GJSpace.s4),
                  child: Row(
                    children: [
                      Expanded(child: Text(titulo, style: GJTypography.h4())),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: const Icon(Symbols.close, color: GJColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: GJColors.surfaceHigh),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(GJSpace.s6),
                    child: child,
                  ),
                ),
                if (acoes != null) ...[
                  const Divider(height: 1, color: GJColors.surfaceHigh),
                  Container(
                    color: GJColors.background,
                    padding: const EdgeInsets.all(GJSpace.s4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [for (final acao in acoes!) Padding(padding: const EdgeInsets.only(left: GJSpace.s3), child: acao)],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
