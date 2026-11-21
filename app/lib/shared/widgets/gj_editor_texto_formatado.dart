import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/theme/gj_colors.dart';
import '../../core/theme/gj_radius.dart';
import '../../core/theme/gj_spacing.dart';
import '../../core/theme/gj_typography.dart';
import '../utils/texto_formatado.dart';
import 'gj_texto_formatado.dart';

enum FormatacaoTexto { negrito, subtitulo, lista, link }

const _textoPadrao = {
  FormatacaoTexto.negrito: 'texto em negrito',
  FormatacaoTexto.link: 'texto do link',
};

/// Aplica a formatação da barra ao texto: envolve a seleção (negrito, link)
/// ou marca as linhas selecionadas (subtítulo, lista). Sem seleção, insere um
/// exemplo já selecionado para a pessoa digitar por cima.
TextEditingValue aplicarFormatacao(TextEditingValue valor, FormatacaoTexto formatacao) {
  final texto = valor.text;
  final selecao = valor.selection.isValid
      ? valor.selection
      : TextSelection.collapsed(offset: texto.length);
  final inicio = selecao.start;
  final fim = selecao.end;
  final selecionado = texto.substring(inicio, fim);

  switch (formatacao) {
    case FormatacaoTexto.negrito:
      final miolo = selecionado.isEmpty ? _textoPadrao[formatacao]! : selecionado;
      final novo = texto.replaceRange(inicio, fim, '**$miolo**');
      return TextEditingValue(
        text: novo,
        selection: TextSelection(baseOffset: inicio + 2, extentOffset: inicio + 2 + miolo.length),
      );
    case FormatacaoTexto.link:
      final miolo = selecionado.isEmpty ? _textoPadrao[formatacao]! : selecionado;
      const endereco = 'https://';
      final novo = texto.replaceRange(inicio, fim, '[$miolo]($endereco)');
      // Com texto escolhido, seleciona o endereço para colar; sem, o texto do link.
      final selecaoNova = selecionado.isEmpty
          ? TextSelection(baseOffset: inicio + 1, extentOffset: inicio + 1 + miolo.length)
          : TextSelection(baseOffset: inicio + miolo.length + 3, extentOffset: inicio + miolo.length + 3 + endereco.length);
      return TextEditingValue(text: novo, selection: selecaoNova);
    case FormatacaoTexto.subtitulo:
    case FormatacaoTexto.lista:
      final marcador = formatacao == FormatacaoTexto.subtitulo ? '## ' : '- ';
      final inicioLinha = inicio == 0 ? 0 : texto.lastIndexOf('\n', inicio - 1) + 1;
      final fimBusca = fim > inicio && fim > 0 && texto[fim - 1] == '\n' ? fim - 1 : fim;
      final quebra = texto.indexOf('\n', fimBusca);
      final fimLinha = quebra == -1 ? texto.length : quebra;
      final linhas = texto.substring(inicioLinha, fimLinha).split('\n');
      // Se todas as linhas já têm o marcador, a barra tira; senão, põe.
      final remover = linhas.every((l) => l.startsWith(marcador));
      final novas = [
        for (final linha in linhas)
          remover ? linha.substring(marcador.length) : (linha.startsWith(marcador) ? linha : '$marcador$linha'),
      ].join('\n');
      final novo = texto.replaceRange(inicioLinha, fimLinha, novas);
      return TextEditingValue(
        text: novo,
        selection: linhas.length == 1
            ? TextSelection.collapsed(offset: inicioLinha + novas.length)
            : TextSelection(baseOffset: inicioLinha, extentOffset: inicioLinha + novas.length),
      );
  }
}

String _milhar(int numero) {
  final texto = '$numero';
  final grupos = <String>[];
  for (var i = texto.length; i > 0; i -= 3) {
    grupos.insert(0, texto.substring(i - 3 < 0 ? 0 : i - 3, i));
  }
  return grupos.join('.');
}

/// Contador do campo: "1.234 de 10.000 caracteres".
String contadorCaracteres(int usados, [int limite = limiteTextoFormatado]) =>
    '${_milhar(usados)} de ${_milhar(limite)} caracteres';

/// Campo de descrição longa com formatação simples (painéis do
/// administrador e da universidade): barra de formatação, abas "Escrever" e
/// "Pré-visualizar" (o painel lateral tem 480 px, não cabe lado a lado) e
/// contador de caracteres com o limite da API.
class GJEditorTextoFormatado extends StatefulWidget {
  const GJEditorTextoFormatado({
    super.key,
    required this.rotulo,
    required this.controller,
    this.erro,
    this.campoKey,
    this.limite = limiteTextoFormatado,
  });

  final String rotulo;
  final TextEditingController controller;
  final String? erro;

  /// Chave do TextField (os testes digitam nele).
  final Key? campoKey;
  final int limite;

  @override
  State<GJEditorTextoFormatado> createState() => _GJEditorTextoFormatadoState();
}

class _GJEditorTextoFormatadoState extends State<GJEditorTextoFormatado> {
  final _foco = FocusNode();
  bool _previa = false;

  @override
  void dispose() {
    _foco.dispose();
    super.dispose();
  }

  void _formatar(FormatacaoTexto formatacao) {
    final novo = aplicarFormatacao(widget.controller.value, formatacao);
    if (novo.text.length > widget.limite) return;
    widget.controller.value = novo;
    _foco.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: GJSpace.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(widget.rotulo, style: GJTypography.label())),
              _Aba(rotulo: 'Escrever', ativa: !_previa, onTap: () => setState(() => _previa = false)),
              const SizedBox(width: GJSpace.s1),
              _Aba(rotulo: 'Pré-visualizar', ativa: _previa, onTap: () => setState(() => _previa = true)),
            ],
          ),
          const SizedBox(height: GJSpace.s2),
          Container(
            decoration: BoxDecoration(
              color: GJColors.surfaceLow,
              borderRadius: GJRadius.borderMd,
              border: widget.erro != null ? Border.all(color: GJColors.error, width: 2) : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!_previa) _barra(),
                if (_previa) _previaConteudo() else _campo(),
              ],
            ),
          ),
          const SizedBox(height: GJSpace.s1),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: widget.erro != null
                    ? Text(widget.erro!, style: GJTypography.caption(color: GJColors.error))
                    : Text('Use a barra para negrito, subtítulo, lista e link.', style: GJTypography.caption()),
              ),
              const SizedBox(width: GJSpace.s2),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: widget.controller,
                builder: (context, valor, _) => Text(
                  contadorCaracteres(valor.text.length, widget.limite),
                  style: GJTypography.caption(
                    color: valor.text.length >= widget.limite ? GJColors.error : GJColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _barra() {
    Widget botao(FormatacaoTexto formatacao, IconData icone, String dica) => IconButton(
          tooltip: dica,
          onPressed: () => _formatar(formatacao),
          icon: Icon(icone, size: 20, color: GJColors.textSecondary),
          visualDensity: VisualDensity.compact,
        );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: GJSpace.s1),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: GJColors.surfaceHigh))),
      child: Row(
        children: [
          botao(FormatacaoTexto.negrito, Symbols.format_bold, 'Negrito'),
          botao(FormatacaoTexto.subtitulo, Symbols.title, 'Subtítulo'),
          botao(FormatacaoTexto.lista, Symbols.format_list_bulleted, 'Lista'),
          botao(FormatacaoTexto.link, Symbols.link, 'Link'),
          const Spacer(),
          const Tooltip(
            message: '**negrito**   _itálico_\n## Subtítulo\n- item de lista\n1. item numerado\n[texto](https://endereco)\n'
                'Linha em branco separa parágrafos. HTML e imagens aparecem como texto.',
            child: Padding(
              padding: EdgeInsets.all(GJSpace.s2),
              child: Icon(Symbols.help, size: 20, color: GJColors.textDisabled),
            ),
          ),
        ],
      ),
    );
  }

  Widget _campo() {
    return TextField(
      key: widget.campoKey,
      controller: widget.controller,
      focusNode: _foco,
      style: GJTypography.body(),
      minLines: 6,
      maxLines: 14,
      keyboardType: TextInputType.multiline,
      maxLength: widget.limite,
      maxLengthEnforcement: MaxLengthEnforcement.enforced,
      decoration: const InputDecoration(
        border: InputBorder.none,
        counterText: '',
        contentPadding: EdgeInsets.all(GJSpace.s4),
      ),
    );
  }

  Widget _previaConteudo() {
    return ConstrainedBox(
      key: const Key('previa-texto-formatado'),
      constraints: const BoxConstraints(minHeight: GJSpace.s24 + GJSpace.s16),
      child: Padding(
        padding: const EdgeInsets.all(GJSpace.s4),
        child: widget.controller.text.trim().isEmpty
            ? Text('Nada para pré-visualizar ainda.', style: GJTypography.bodySm())
            : GJTextoFormatado(widget.controller.text),
      ),
    );
  }
}

class _Aba extends StatelessWidget {
  const _Aba({required this.rotulo, required this.ativa, required this.onTap});

  final String rotulo;
  final bool ativa;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ativa ? GJColors.primaryFixed : Colors.transparent,
      borderRadius: GJRadius.borderSm,
      child: InkWell(
        borderRadius: GJRadius.borderSm,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: GJSpace.s3, vertical: GJSpace.s1),
          child: Text(
            rotulo,
            style: GJTypography.caption(color: ativa ? GJColors.primaryDark : GJColors.textSecondary)
                .copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}
