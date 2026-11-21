import 'package:app/shared/utils/texto_formatado.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('interpretarTextoFormatado', () {
    test('parágrafos, quebra de linha, negrito, itálico e link', () {
      final blocos = interpretarTextoFormatado(
        'Primeira linha\nsegunda linha com **negrito** e _itálico_.\n\nVeja o [site](https://www.example.com).',
      );

      expect(blocos, hasLength(2));
      final primeiro = blocos[0] as ParagrafoFormatado;
      expect(primeiro.trechos, [
        const TrechoFormatado('Primeira linha\nsegunda linha com '),
        const TrechoFormatado('negrito', negrito: true),
        const TrechoFormatado(' e '),
        const TrechoFormatado('itálico', italico: true),
        const TrechoFormatado('.'),
      ]);
      final segundo = blocos[1] as ParagrafoFormatado;
      expect(segundo.trechos[1], const TrechoFormatado('site', link: 'https://www.example.com'));
    });

    test('subtítulos e listas com marcadores e numeradas', () {
      final blocos = interpretarTextoFormatado(
        '## O que você estuda\n\n- Anatomia\n- Farmacologia\n\n### Passo a passo\n\n1. Faça o Enem\n2. Inscreva-se',
      );

      expect(blocos[0], isA<SubtituloFormatado>().having((s) => s.nivel, 'nivel', 2));
      final marcadores = blocos[1] as ListaFormatada;
      expect(marcadores.numerada, isFalse);
      expect(marcadores.itens, hasLength(2));
      expect((marcadores.itens[0].single as ParagrafoFormatado).trechos.single.texto, 'Anatomia');
      expect(blocos[2], isA<SubtituloFormatado>().having((s) => s.nivel, 'nivel', 3));
      final numerada = blocos[3] as ListaFormatada;
      expect(numerada.numerada, isTrue);
      expect(numerada.inicio, 1);
      expect((numerada.itens[1].single as ParagrafoFormatado).trechos.single.texto, 'Inscreva-se');
    });

    test('lista numerada que começa em outro número', () {
      final lista = interpretarTextoFormatado('3. Terceiro\n4. Quarto').single as ListaFormatada;
      expect(lista.inicio, 3);
    });

    test('endereço puro vira link', () {
      final paragrafo = interpretarTextoFormatado('Confira em https://www.gov.br/inep agora.').single as ParagrafoFormatado;
      expect(paragrafo.trechos.where((t) => t.link != null).single.texto, 'https://www.gov.br/inep');
    });

    test('HTML aparece como texto puro', () {
      final blocos = interpretarTextoFormatado('<b>forte</b> <script>alert(1)</script>\n\n<div>bloco</div>');

      expect(blocos, hasLength(2));
      expect((blocos[0] as ParagrafoFormatado).trechos.single, const TrechoFormatado('<b>forte</b> <script>alert(1)</script>'));
      expect((blocos[1] as ParagrafoFormatado).trechos.single.texto, '<div>bloco</div>');
    });

    test('imagem não é carregada nem vira link: aparece como foi escrita', () {
      final paragrafo = interpretarTextoFormatado('Foto: ![campus](https://www.example.com/a.png)').single as ParagrafoFormatado;

      expect(paragrafo.trechos.single, const TrechoFormatado('Foto: ![campus](https://www.example.com/a.png)'));
    });

    test('o que não é suportado (citação, código, tabela, linha) fica como texto', () {
      final blocos = interpretarTextoFormatado('> citação\n\n```\ncódigo\n```\n\n| a | b |\n\n---');
      final textos = [for (final b in blocos) (b as ParagrafoFormatado).trechos.map((t) => t.texto).join()];

      expect(textos.join('\n'), contains('> citação'));
      expect(textos.join('\n'), contains('```'));
      expect(textos.join('\n'), contains('| a | b |'));
      expect(textos.join('\n'), contains('---'));
    });

    test('link com esquema não permitido vira texto comum', () {
      final paragrafo = interpretarTextoFormatado('[clique](javascript:alert(1))').single as ParagrafoFormatado;
      expect(paragrafo.trechos.every((t) => t.link == null), isTrue);
    });

    test('texto vazio ou nulo não gera blocos', () {
      expect(interpretarTextoFormatado(null), isEmpty);
      expect(interpretarTextoFormatado('  \n '), isEmpty);
    });
  });

  group('resumoTextoFormatado', () {
    const texto = '## O que você estuda\n\nCuidado com **pacientes** e _comunidades_.\n\n'
        '## Onde pode trabalhar\n\n- Hospitais\n- [Clínicas](https://www.example.com)\n\n1. Primeiro\n2. Segundo';

    test('sai sem os símbolos da formatação e sem os subtítulos', () {
      final resumo = resumoTextoFormatado(texto);

      expect(resumo, 'Cuidado com pacientes e comunidades. Hospitais Clínicas Primeiro Segundo');
      for (final simbolo in ['**', '_', '#', '[', '](', '- ', '1.']) {
        expect(resumo, isNot(contains(simbolo)), reason: simbolo);
      }
    });

    test('corta no fim de uma palavra e termina com reticências', () {
      final resumo = resumoTextoFormatado(texto, limite: 30);

      expect(resumo, 'Cuidado com pacientes e…');
      expect(resumo.length, lessThanOrEqualTo(31));
    });

    test('quebras de linha viram espaço', () {
      expect(resumoTextoFormatado('linha um\nlinha dois'), 'linha um linha dois');
    });

    test('texto só com subtítulos usa os subtítulos', () {
      expect(resumoTextoFormatado('## Só o título'), 'Só o título');
    });

    test('nulo vira texto vazio', () {
      expect(resumoTextoFormatado(null), '');
    });
  });

  group('separarSecoes', () {
    test('divide nos subtítulos de nível 1 e 2 e mantém a abertura', () {
      final secoes = separarSecoes(interpretarTextoFormatado(
        'Abertura.\n\n## O que é\n\nTexto.\n\n### Detalhe\n\nMais.\n\n## Vazia\n\n## Passo a passo\n\n1. Um',
      ));

      expect(secoes.map((s) => s.titulo), [null, 'O que é', 'Passo a passo']);
      expect(secoes[1].blocos, hasLength(3));
    });

    test('primeiroParagrafo pega o primeiro parágrafo em texto puro', () {
      expect(primeiroParagrafo(interpretarTextoFormatado('## Título\n\nTexto **forte**\ncom quebra.')), 'Texto forte com quebra.');
    });
  });
}
