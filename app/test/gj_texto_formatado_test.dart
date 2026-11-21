import 'package:app/shared/utils/texto_formatado.dart';
import 'package:app/shared/widgets/gj_editor_texto_formatado.dart';
import 'package:app/shared/widgets/gj_texto_formatado.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

Widget _app(Widget filho) => MaterialApp(home: Scaffold(body: SingleChildScrollView(child: filho)));

/// Todos os TextSpan desenhados na tela, achatados.
List<TextSpan> _spans(WidgetTester tester) {
  final spans = <TextSpan>[];
  for (final rich in tester.widgetList<RichText>(find.byType(RichText))) {
    rich.text.visitChildren((span) {
      if (span is TextSpan && span.text != null) spans.add(span);
      return true;
    });
  }
  return spans;
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('GJTextoFormatado', () {
    testWidgets('desenha subtítulo, parágrafo com negrito e itálico, listas e link', (tester) async {
      await tester.pumpWidget(_app(GJTextoFormatado(
        '## O que você estuda\n\nTexto com **negrito** e _itálico_.\n\n- Anatomia\n- Fisiologia\n\n'
        '1. Primeiro\n2. Segundo\n\nVeja o [site oficial](https://www.example.com).',
      )));

      expect(find.text('O que você estuda', findRichText: true), findsOneWidget);
      expect(find.text('•'), findsNWidgets(2));
      expect(find.text('1.'), findsOneWidget);
      expect(find.text('2.'), findsOneWidget);
      expect(find.text('Anatomia', findRichText: true), findsOneWidget);

      final spans = _spans(tester);
      expect(spans.firstWhere((s) => s.text == 'negrito').style!.fontWeight, FontWeight.w700);
      expect(spans.firstWhere((s) => s.text == 'itálico').style!.fontStyle, FontStyle.italic);
      final link = spans.firstWhere((s) => s.text == 'site oficial');
      expect(link.recognizer, isA<TapGestureRecognizer>());
      expect(link.style!.decoration, TextDecoration.underline);
      // O texto do link aparece sem os colchetes e o endereço.
      expect(spans.any((s) => s.text!.contains('](')), isFalse);
    });

    testWidgets('HTML e imagem aparecem como texto puro', (tester) async {
      await tester.pumpWidget(_app(GJTextoFormatado('<b>oi</b> ![foto](https://www.example.com/a.png)')));

      expect(find.text('<b>oi</b> ![foto](https://www.example.com/a.png)', findRichText: true), findsOneWidget);
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('texto vazio não desenha nada', (tester) async {
      await tester.pumpWidget(_app(GJTextoFormatado(null)));

      expect(find.byType(RichText), findsNothing);
    });
  });

  group('aplicarFormatacao', () {
    TextEditingValue valor(String texto, int inicio, [int? fim]) =>
        TextEditingValue(text: texto, selection: TextSelection(baseOffset: inicio, extentOffset: fim ?? inicio));

    test('negrito envolve a seleção', () {
      final novo = aplicarFormatacao(valor('um dois três', 3, 7), FormatacaoTexto.negrito);
      expect(novo.text, 'um **dois** três');
      expect(novo.selection, const TextSelection(baseOffset: 5, extentOffset: 9));
    });

    test('negrito sem seleção insere um exemplo selecionado', () {
      final novo = aplicarFormatacao(valor('', 0), FormatacaoTexto.negrito);
      expect(novo.text, '**texto em negrito**');
      expect(novo.selection.textInside(novo.text), 'texto em negrito');
    });

    test('subtítulo marca a linha do cursor e, de novo, desmarca', () {
      final marcado = aplicarFormatacao(valor('Intro\nO que é\nTexto', 8), FormatacaoTexto.subtitulo);
      expect(marcado.text, 'Intro\n## O que é\nTexto');

      final desmarcado = aplicarFormatacao(marcado.copyWith(selection: const TextSelection.collapsed(offset: 10)), FormatacaoTexto.subtitulo);
      expect(desmarcado.text, 'Intro\nO que é\nTexto');
    });

    test('lista marca todas as linhas selecionadas', () {
      final novo = aplicarFormatacao(valor('Hospitais\nClínicas\nEscolas', 0, 18), FormatacaoTexto.lista);
      expect(novo.text, '- Hospitais\n- Clínicas\nEscolas');
    });

    test('link com seleção seleciona o endereço para colar', () {
      final novo = aplicarFormatacao(valor('veja o edital', 7, 13), FormatacaoTexto.link);
      expect(novo.text, 'veja o [edital](https://)');
      expect(novo.selection.textInside(novo.text), 'https://');
    });

    test('contador com separador de milhar', () {
      expect(contadorCaracteres(1234), '1.234 de 10.000 caracteres');
      expect(contadorCaracteres(0), '0 de 10.000 caracteres');
    });
  });

  group('GJEditorTextoFormatado', () {
    testWidgets('barra formata, pré-visualização mostra o resultado e o contador acompanha', (tester) async {
      final controller = TextEditingController();
      await tester.pumpWidget(_app(GJEditorTextoFormatado(
        rotulo: 'Descrição',
        controller: controller,
        campoKey: const Key('campo'),
      )));

      expect(find.text('0 de 10.000 caracteres'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('campo')), 'Cursos');
      controller.selection = const TextSelection(baseOffset: 0, extentOffset: 6);
      await tester.tap(find.byTooltip('Negrito'));
      await tester.pump();
      expect(controller.text, '**Cursos**');
      expect(find.text('10 de 10.000 caracteres'), findsOneWidget);

      await tester.tap(find.text('Pré-visualizar'));
      await tester.pump();
      expect(find.byKey(const Key('previa-texto-formatado')), findsOneWidget);
      expect(find.byKey(const Key('campo')), findsNothing);
      final negrito = _spans(tester).firstWhere((s) => s.text == 'Cursos');
      expect(negrito.style!.fontWeight, FontWeight.w700);
      expect(find.byTooltip('Negrito'), findsNothing);

      await tester.tap(find.text('Escrever'));
      await tester.pump();
      expect(find.byKey(const Key('campo')), findsOneWidget);
    });

    testWidgets('não deixa passar do limite', (tester) async {
      final controller = TextEditingController();
      await tester.pumpWidget(_app(GJEditorTextoFormatado(rotulo: 'Sobre', controller: controller, campoKey: const Key('campo'), limite: 10)));

      await tester.enterText(find.byKey(const Key('campo')), 'a' * 15);
      await tester.pump();

      expect(controller.text.length, 10);
      expect(find.text('10 de 10 caracteres'), findsOneWidget);
    });

    testWidgets('mostra o erro da API no lugar da dica', (tester) async {
      await tester.pumpWidget(_app(GJEditorTextoFormatado(
        rotulo: 'Sobre',
        controller: TextEditingController(),
        erro: 'Use no máximo 10.000 caracteres',
      )));

      expect(find.text('Use no máximo 10.000 caracteres'), findsOneWidget);
      expect(limiteTextoFormatado, 10000);
    });
  });
}
