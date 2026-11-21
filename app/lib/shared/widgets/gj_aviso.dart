import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/theme/gj_breakpoints.dart';
import '../../core/theme/gj_colors.dart';
import '../../core/theme/gj_radius.dart';
import '../../core/theme/gj_shadows.dart';
import '../../core/theme/gj_spacing.dart';
import '../../core/theme/gj_typography.dart';

enum GJAvisoTipo { sucesso, erro, alerta, info }

/// Cores, ícone e tempo de cada tipo de aviso. Erro fica mais tempo na tela,
/// para dar tempo de ler o que aconteceu.
({Color fundo, Color destaque, Color texto, IconData icone, Duration duracao}) _estilo(GJAvisoTipo tipo) => switch (tipo) {
      GJAvisoTipo.sucesso => (
          fundo: GJColors.successContainer,
          destaque: GJColors.success,
          texto: GJColors.textPrimary,
          icone: Symbols.check_circle,
          duracao: const Duration(seconds: 4),
        ),
      GJAvisoTipo.erro => (
          fundo: GJColors.errorContainer,
          destaque: GJColors.error,
          texto: GJColors.errorOnContainer,
          icone: Symbols.error,
          duracao: const Duration(seconds: 8),
        ),
      GJAvisoTipo.alerta => (
          fundo: GJColors.warningContainer,
          destaque: GJColors.warning,
          texto: GJColors.textPrimary,
          icone: Symbols.warning,
          duracao: const Duration(seconds: 6),
        ),
      GJAvisoTipo.info => (
          fundo: GJColors.primaryFixed,
          destaque: GJColors.primary,
          texto: GJColors.primaryContainerOn,
          icone: Symbols.info,
          duracao: const Duration(seconds: 5),
        ),
    };

/// Aviso do Guia Jovem (substitui a barra preta padrão do Flutter): cantos
/// arredondados, ícone e cor por tipo e botão de fechar. Aparece sempre no
/// mesmo lugar, centralizado na parte de baixo da tela.
class GJAviso extends StatelessWidget {
  const GJAviso({super.key, required this.mensagem, this.tipo = GJAvisoTipo.sucesso, this.onFechar});

  final String mensagem;
  final GJAvisoTipo tipo;
  final VoidCallback? onFechar;

  /// Largura no desktop; no celular o aviso ocupa a largura toda.
  static const double larguraMaxima = 460;

  @override
  Widget build(BuildContext context) {
    final estilo = _estilo(tipo);
    return Semantics(
      liveRegion: true,
      child: Container(
        key: Key('gj-aviso-${tipo.name}'),
        padding: const EdgeInsets.fromLTRB(GJSpace.s4, GJSpace.s3, GJSpace.s2, GJSpace.s3),
        decoration: BoxDecoration(
          color: estilo.fundo,
          borderRadius: GJRadius.borderLg,
          border: Border.all(color: estilo.destaque.withOpacity(0.35)),
          boxShadow: GJShadows.md,
        ),
        child: Row(
          children: [
            Icon(estilo.icone, color: estilo.destaque, size: 22, fill: 1),
            const SizedBox(width: GJSpace.s3),
            Expanded(child: Text(mensagem, style: GJTypography.label(color: estilo.texto))),
            if (onFechar != null) ...[
              const SizedBox(width: GJSpace.s2),
              IconButton(
                tooltip: 'Fechar aviso',
                visualDensity: VisualDensity.compact,
                onPressed: onFechar,
                icon: Icon(Symbols.close, size: 18, color: estilo.texto),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

extension GJAvisoMensageiro on ScaffoldMessengerState {
  /// Mostra um [GJAviso] no lugar do aviso atual (um de cada vez).
  void aviso(String mensagem, {GJAvisoTipo tipo = GJAvisoTipo.sucesso}) {
    final largura = MediaQuery.maybeSizeOf(context)?.width ?? 1024;
    final celular = largura < GJBreakpoints.tablet;
    hideCurrentSnackBar();
    showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        padding: EdgeInsets.zero,
        width: celular ? null : GJAviso.larguraMaxima,
        margin: celular ? const EdgeInsets.fromLTRB(GJSpace.s4, 0, GJSpace.s4, GJSpace.s4) : null,
        duration: _estilo(tipo).duracao,
        content: GJAviso(mensagem: mensagem, tipo: tipo, onFechar: hideCurrentSnackBar),
      ),
    );
  }

  void avisoDeErro(String mensagem) => aviso(mensagem, tipo: GJAvisoTipo.erro);
}

/// Atalho para quem tem o `context` à mão (antes de qualquer `await`).
void mostrarAviso(BuildContext context, String mensagem, {GJAvisoTipo tipo = GJAvisoTipo.sucesso}) =>
    ScaffoldMessenger.of(context).aviso(mensagem, tipo: tipo);
