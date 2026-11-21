import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../core/theme/gj_colors.dart';
import '../../core/theme/gj_spacing.dart';
import '../../core/theme/gj_typography.dart';
import '../../core/utils/link_launcher.dart';
import '../utils/texto_formatado.dart';

/// Exibe uma descrição formatada (ver `texto_formatado.dart`) com a
/// tipografia do GJDS: corpo em Inter, subtítulos em Plus Jakarta Sans.
/// Links abrem em nova aba.
class GJTextoFormatado extends StatelessWidget {
  GJTextoFormatado(String? texto, {super.key, this.cor, this.corLink, this.estilo})
      : blocos = interpretarTextoFormatado(texto);

  /// Blocos já interpretados (por exemplo, uma seção do texto).
  const GJTextoFormatado.blocos(this.blocos, {super.key, this.cor, this.corLink, this.estilo});

  final List<BlocoFormatado> blocos;

  /// Cor do texto; padrão `textPrimary`. Em fundo colorido, `primaryOn`.
  final Color? cor;

  /// Cor dos links; padrão `primary` (ou a cor do texto, quando ela é dada).
  final Color? corLink;

  /// Estilo do corpo; padrão `GJTypography.body()`.
  final TextStyle? estilo;

  @override
  Widget build(BuildContext context) {
    final corTexto = cor ?? GJColors.textPrimary;
    return _Blocos(
      blocos: blocos,
      corpo: (estilo ?? GJTypography.body()).copyWith(color: corTexto),
      corTexto: corTexto,
      corLink: corLink ?? (cor == null ? GJColors.primary : corTexto),
    );
  }
}

class _Blocos extends StatelessWidget {
  const _Blocos({required this.blocos, required this.corpo, required this.corTexto, required this.corLink});

  final List<BlocoFormatado> blocos;
  final TextStyle corpo;
  final Color corTexto;
  final Color corLink;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (indice, bloco) in blocos.indexed)
          Padding(
            padding: EdgeInsets.only(
              top: indice == 0 ? 0 : (bloco is SubtituloFormatado ? GJSpace.s5 : GJSpace.s3),
            ),
            child: _bloco(bloco),
          ),
      ],
    );
  }

  Widget _bloco(BlocoFormatado bloco) {
    switch (bloco) {
      case ParagrafoFormatado(:final trechos):
        return _TextoRico(trechos: trechos, estilo: corpo, corLink: corLink);
      case SubtituloFormatado(:final nivel, :final trechos):
        final estilo = (nivel <= 2 ? GJTypography.h4() : GJTypography.label().copyWith(fontSize: 16)).copyWith(color: corTexto);
        return Semantics(header: true, child: _TextoRico(trechos: trechos, estilo: estilo, corLink: corLink));
      case ListaFormatada(:final numerada, :final inicio, :final itens):
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (indice, item) in itens.indexed)
              Padding(
                padding: EdgeInsets.only(top: indice == 0 ? 0 : GJSpace.s2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: numerada ? GJSpace.s8 : GJSpace.s6,
                      child: Text(
                        numerada ? '${inicio + indice}.' : '•',
                        style: corpo.copyWith(fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(child: _Blocos(blocos: item, corpo: corpo, corTexto: corTexto, corLink: corLink)),
                  ],
                ),
              ),
          ],
        );
    }
  }
}

/// Parágrafo ou subtítulo com negrito, itálico e links clicáveis.
class _TextoRico extends StatefulWidget {
  const _TextoRico({required this.trechos, required this.estilo, required this.corLink});

  final List<TrechoFormatado> trechos;
  final TextStyle estilo;
  final Color corLink;

  @override
  State<_TextoRico> createState() => _TextoRicoState();
}

class _TextoRicoState extends State<_TextoRico> {
  final _reconhecedores = <TapGestureRecognizer>[];

  void _liberar() {
    for (final r in _reconhecedores) {
      r.dispose();
    }
    _reconhecedores.clear();
  }

  @override
  void dispose() {
    _liberar();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _liberar();
    return Text.rich(
      TextSpan(
        style: widget.estilo,
        children: [
          for (final trecho in widget.trechos) _span(trecho),
        ],
      ),
    );
  }

  TextSpan _span(TrechoFormatado trecho) {
    var estilo = TextStyle(
      fontWeight: trecho.negrito ? FontWeight.w700 : null,
      fontStyle: trecho.italico ? FontStyle.italic : null,
    );
    final link = trecho.link;
    if (link == null) return TextSpan(text: trecho.texto, style: estilo);

    estilo = estilo.copyWith(
      color: widget.corLink,
      decoration: TextDecoration.underline,
      decorationColor: widget.corLink,
      fontWeight: FontWeight.w600,
    );
    final reconhecedor = TapGestureRecognizer()..onTap = () => abrirLinkExterno(link);
    _reconhecedores.add(reconhecedor);
    return TextSpan(text: trecho.texto, style: estilo, recognizer: reconhecedor, mouseCursor: SystemMouseCursors.click);
  }
}
