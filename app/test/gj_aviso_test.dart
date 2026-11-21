import 'package:app/core/theme/gj_colors.dart';
import 'package:app/shared/widgets/gj_aviso.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<void> abrir(WidgetTester tester, GJAvisoTipo tipo, {Size tela = const Size(1366, 768)}) async {
    tester.view.physicalSize = tela;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => mostrarAviso(context, 'Mensagem de teste', tipo: tipo),
            child: const Text('mostrar'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('mostrar'));
    await tester.pumpAndSettle();
  }

  testWidgets('cada tipo tem a sua cor de fundo e o aviso tem botão de fechar', (tester) async {
    const fundos = {
      GJAvisoTipo.sucesso: GJColors.successContainer,
      GJAvisoTipo.erro: GJColors.errorContainer,
      GJAvisoTipo.alerta: GJColors.warningContainer,
      GJAvisoTipo.info: GJColors.primaryFixed,
    };
    for (final MapEntry(key: tipo, value: fundo) in fundos.entries) {
      await abrir(tester, tipo);
      final caixa = tester.widget<Container>(find.byKey(Key('gj-aviso-${tipo.name}')));
      expect((caixa.decoration! as BoxDecoration).color, fundo, reason: tipo.name);
      expect((caixa.decoration! as BoxDecoration).borderRadius, isNotNull);
      expect(find.text('Mensagem de teste'), findsOneWidget);
      expect(find.byTooltip('Fechar aviso'), findsOneWidget);
    }
  });

  testWidgets('o botão fecha o aviso', (tester) async {
    await abrir(tester, GJAvisoTipo.sucesso);

    await tester.tap(find.byTooltip('Fechar aviso'));
    await tester.pumpAndSettle();

    expect(find.text('Mensagem de teste'), findsNothing);
  });

  testWidgets('erro fica mais tempo que sucesso', (tester) async {
    await abrir(tester, GJAvisoTipo.sucesso);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(find.text('Mensagem de teste'), findsNothing);

    await abrir(tester, GJAvisoTipo.erro);
    await tester.pump(const Duration(seconds: 5));
    expect(find.text('Mensagem de teste'), findsOneWidget);
  });

  testWidgets('no desktop tem largura fixa; no celular ocupa a largura com margem', (tester) async {
    await abrir(tester, GJAvisoTipo.info);
    expect(tester.getSize(find.byKey(const Key('gj-aviso-info'))).width, GJAviso.larguraMaxima);

    await abrir(tester, GJAvisoTipo.info, tela: const Size(390, 800));
    expect(tester.getSize(find.byKey(const Key('gj-aviso-info'))).width, lessThan(390));
  });
}
