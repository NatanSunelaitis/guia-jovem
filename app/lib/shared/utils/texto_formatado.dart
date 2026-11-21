import 'package:markdown/markdown.dart' as md;

/// Descrições com formatação simples (curso, "Sobre" da universidade,
/// programa e bolsa institucional), escritas em Markdown.
///
/// Suportado: parágrafos, quebras de linha, subtítulos (`## `), listas com
/// marcadores (`- `) e numeradas (`1. `), negrito (`**`), itálico (`_` ou `*`)
/// e links (`[texto](https://...)` ou o endereço puro). Todo o resto, HTML e
/// imagens incluídos, aparece como texto puro: o interpretador só liga essas
/// sintaxes e não decodifica nem gera HTML.
///
/// Limite igual ao da API (api/src/shared/validation/textoFormatado.js).
const limiteTextoFormatado = 10000;

/// Trecho de texto dentro de um bloco, com o estilo que se aplica a ele.
class TrechoFormatado {
  const TrechoFormatado(this.texto, {this.negrito = false, this.italico = false, this.link});

  final String texto;
  final bool negrito;
  final bool italico;

  /// Endereço do link (só http, https e mailto); nulo para texto comum.
  final String? link;

  @override
  bool operator ==(Object other) =>
      other is TrechoFormatado &&
      other.texto == texto &&
      other.negrito == negrito &&
      other.italico == italico &&
      other.link == link;

  @override
  int get hashCode => Object.hash(texto, negrito, italico, link);

  @override
  String toString() => 'Trecho("$texto"${negrito ? ', negrito' : ''}${italico ? ', itálico' : ''}${link != null ? ', $link' : ''})';
}

sealed class BlocoFormatado {
  const BlocoFormatado();
}

class ParagrafoFormatado extends BlocoFormatado {
  const ParagrafoFormatado(this.trechos);

  final List<TrechoFormatado> trechos;
}

class SubtituloFormatado extends BlocoFormatado {
  const SubtituloFormatado(this.nivel, this.trechos);

  /// 1 a 6, como o número de `#`.
  final int nivel;
  final List<TrechoFormatado> trechos;
}

class ListaFormatada extends BlocoFormatado {
  const ListaFormatada({required this.numerada, required this.itens, this.inicio = 1});

  final bool numerada;
  final int inicio;

  /// Cada item é uma sequência de blocos (parágrafo e, às vezes, sublista).
  final List<List<BlocoFormatado>> itens;
}

/// Mostra `![texto](endereço)` como foi escrito, em vez de virar link.
class _ImagemComoTexto extends md.InlineSyntax {
  _ImagemComoTexto() : super(r'!\[[^\]\n]*\]\([^)\n]*\)', startCharacter: 0x21);

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    parser.addNode(md.Text(match[0]!));
    return true;
  }
}

md.Document _documento() => md.Document(
      blockSyntaxes: const [
        md.EmptyBlockSyntax(),
        md.HeaderSyntax(),
        md.UnorderedListSyntax(),
        md.OrderedListSyntax(),
        md.ParagraphSyntax(),
      ],
      inlineSyntaxes: [
        _ImagemComoTexto(),
        md.EscapeSyntax(),
        md.LineBreakSyntax(),
        md.SoftLineBreakSyntax(),
        md.EmphasisSyntax.asterisk(),
        md.EmphasisSyntax.underscore(),
        md.LinkSyntax(),
        md.AutolinkExtensionSyntax(),
      ],
      withDefaultBlockSyntaxes: false,
      withDefaultInlineSyntaxes: false,
      encodeHtml: false,
    );

final _esquemaPermitido = RegExp(r'^(https?:|mailto:)', caseSensitive: false);

/// Interpreta o texto em blocos. Texto nulo ou vazio dá lista vazia.
List<BlocoFormatado> interpretarTextoFormatado(String? texto) {
  if (texto == null || texto.trim().isEmpty) return const [];
  final nos = _documento().parse(texto.replaceAll('\r\n', '\n'));
  return _blocos(nos);
}

const _tagsDeBloco = {'p', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'ul', 'ol'};

List<BlocoFormatado> _blocos(List<md.Node> nos) {
  final blocos = <BlocoFormatado>[];
  final soltos = <md.Node>[];

  void fecharSoltos() {
    final trechos = _trechos(soltos);
    soltos.clear();
    if (trechos.any((t) => t.texto.trim().isNotEmpty)) blocos.add(ParagrafoFormatado(trechos));
  }

  for (final no in nos) {
    if (no is md.Element && _tagsDeBloco.contains(no.tag)) {
      fecharSoltos();
      final bloco = _bloco(no);
      if (bloco != null) blocos.add(bloco);
    } else {
      // Item de lista "apertado": o texto vem direto no <li>, sem <p>.
      soltos.add(no);
    }
  }
  fecharSoltos();
  return blocos;
}

BlocoFormatado? _bloco(md.Element elemento) {
  final filhos = elemento.children ?? const <md.Node>[];
  switch (elemento.tag) {
    case 'p':
      final trechos = _trechos(filhos);
      return trechos.isEmpty ? null : ParagrafoFormatado(trechos);
    case 'ul':
    case 'ol':
      return ListaFormatada(
        numerada: elemento.tag == 'ol',
        inicio: int.tryParse(elemento.attributes['start'] ?? '') ?? 1,
        itens: [
          for (final item in filhos)
            if (item is md.Element) _blocos(item.children ?? const []),
        ],
      );
    default:
      return SubtituloFormatado(int.parse(elemento.tag.substring(1)), _trechos(filhos));
  }
}

List<TrechoFormatado> _trechos(List<md.Node> nos, {bool negrito = false, bool italico = false, String? link}) {
  final trechos = <TrechoFormatado>[];
  for (final no in nos) {
    if (no is md.Text) {
      trechos.add(TrechoFormatado(no.text, negrito: negrito, italico: italico, link: link));
    } else if (no is md.Element) {
      final filhos = no.children ?? const <md.Node>[];
      switch (no.tag) {
        case 'strong':
          trechos.addAll(_trechos(filhos, negrito: true, italico: italico, link: link));
        case 'em':
          trechos.addAll(_trechos(filhos, negrito: negrito, italico: true, link: link));
        case 'br':
          trechos.add(TrechoFormatado('\n', negrito: negrito, italico: italico, link: link));
        case 'a':
          final destino = no.attributes['href'];
          final permitido = destino != null && _esquemaPermitido.hasMatch(destino) ? destino : null;
          trechos.addAll(_trechos(filhos, negrito: negrito, italico: italico, link: permitido ?? link));
        default:
          trechos.add(TrechoFormatado(no.textContent, negrito: negrito, italico: italico, link: link));
      }
    }
  }
  return _juntar(trechos);
}

/// Junta trechos vizinhos com o mesmo estilo.
List<TrechoFormatado> _juntar(List<TrechoFormatado> trechos) {
  final juntos = <TrechoFormatado>[];
  for (final trecho in trechos) {
    if (trecho.texto.isEmpty) continue;
    final ultimo = juntos.isEmpty ? null : juntos.last;
    if (ultimo != null && ultimo.negrito == trecho.negrito && ultimo.italico == trecho.italico && ultimo.link == trecho.link) {
      juntos[juntos.length - 1] =
          TrechoFormatado(ultimo.texto + trecho.texto, negrito: trecho.negrito, italico: trecho.italico, link: trecho.link);
    } else {
      juntos.add(trecho);
    }
  }
  return juntos;
}

String _textoDe(List<TrechoFormatado> trechos) => trechos.map((t) => t.texto).join();

String _espacosSimples(String texto) => texto.replaceAll(RegExp(r'\s+'), ' ').trim();

void _coletarTexto(List<BlocoFormatado> blocos, List<String> partes, {required bool comSubtitulos}) {
  for (final bloco in blocos) {
    switch (bloco) {
      case ParagrafoFormatado(:final trechos):
        partes.add(_textoDe(trechos));
      case SubtituloFormatado(:final trechos):
        if (comSubtitulos) partes.add(_textoDe(trechos));
      case ListaFormatada(:final itens):
        for (final item in itens) {
          _coletarTexto(item, partes, comSubtitulos: comSubtitulos);
        }
    }
  }
}

/// Resumo em texto puro para cards e listas: sem os símbolos da formatação,
/// sem os subtítulos (a não ser que o texto só tenha subtítulos) e com os
/// espaços e as quebras de linha reduzidos a um espaço. Com [limite], corta
/// no fim da última palavra que cabe e termina com reticências.
String resumoTextoFormatado(String? texto, {int? limite}) {
  final blocos = interpretarTextoFormatado(texto);
  final partes = <String>[];
  _coletarTexto(blocos, partes, comSubtitulos: false);
  if (partes.every((p) => p.trim().isEmpty)) _coletarTexto(blocos, partes, comSubtitulos: true);

  final resumo = _espacosSimples(partes.where((p) => p.trim().isNotEmpty).map((p) => p.trim()).join(' '));
  if (limite == null || resumo.length <= limite) return resumo;

  final corte = resumo.substring(0, limite);
  final ultimoEspaco = corte.lastIndexOf(' ');
  final semPalavraPartida = ultimoEspaco > limite ~/ 2 ? corte.substring(0, ultimoEspaco) : corte;
  return '${semPalavraPartida.replaceAll(RegExp(r'[\s,;:.]+$'), '')}…';
}

/// Primeiro parágrafo do texto, em texto puro (abertura da página do programa).
String? primeiroParagrafo(List<BlocoFormatado> blocos) {
  for (final bloco in blocos) {
    if (bloco is ParagrafoFormatado) return _espacosSimples(_textoDe(bloco.trechos));
  }
  return null;
}

/// Uma seção do texto: o subtítulo (nulo na abertura, antes do primeiro
/// subtítulo) e os blocos até o próximo subtítulo do mesmo nível ou acima.
class SecaoFormatada {
  const SecaoFormatada({this.titulo, required this.blocos});

  final String? titulo;
  final List<BlocoFormatado> blocos;
}

/// Divide o texto nas seções marcadas por subtítulos de nível 1 ou 2
/// (`#` ou `##`). Seções sem conteúdo ficam de fora.
List<SecaoFormatada> separarSecoes(List<BlocoFormatado> blocos) {
  final secoes = <SecaoFormatada>[];
  String? titulo;
  var atuais = <BlocoFormatado>[];

  void fechar() {
    if (atuais.isNotEmpty) secoes.add(SecaoFormatada(titulo: titulo, blocos: atuais));
  }

  for (final bloco in blocos) {
    if (bloco is SubtituloFormatado && bloco.nivel <= 2) {
      fechar();
      titulo = _espacosSimples(_textoDe(bloco.trechos));
      atuais = <BlocoFormatado>[];
    } else {
      atuais.add(bloco);
    }
  }
  fechar();
  return secoes;
}
