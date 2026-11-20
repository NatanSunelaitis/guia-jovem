import 'package:app/core/theme/gj_colors.dart';
import 'package:app/core/theme/gj_theme.dart';
import 'package:app/shared/widgets/gj_card.dart';
import 'package:app/shared/widgets/gj_carousel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Widget card(String nome) => GJCard.programa(
        key: ValueKey(nome),
        imagemUrl: 'assets/fotos/programas/fies.jpg',
        icone: Symbols.account_balance_wallet,
        cor: GJColors.tertiary,
        sigla: 'FIES',
        nome: nome,
        descricao: 'Descrição',
        onTap: () {},
      );

  testWidgets('títulos longos aparecem em até três linhas e os cards ficam com a mesma altura', (tester) async {
    tester.view.physicalSize = const Size(1366, 768);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: GJTheme.light,
        home: Scaffold(
          body: SingleChildScrollView(
            child: GJCarousel(
              titulo: 'Programas',
              itemWidth: 260,
              itemCount: 2,
              itemBuilder: (context, i) => card(i == 0 ? 'Fundo de Financiamento Estudantil' : 'Sistema'),
            ),
          ),
        ),
      ),
    );

    final titulo = tester.widget<Text>(find.text('Fundo de Financiamento Estudantil'));
    expect(titulo.maxLines, 3);

    final alturaLongo = tester.getSize(find.byKey(const ValueKey('Fundo de Financiamento Estudantil'))).height;
    final alturaCurto = tester.getSize(find.byKey(const ValueKey('Sistema'))).height;
    expect(alturaCurto, alturaLongo);

    // O botão fica no rodapé dos dois cards, na mesma altura.
    final botoes = find.text('Ver detalhes');
    expect(tester.getTopLeft(botoes.at(0)).dy, tester.getTopLeft(botoes.at(1)).dy);
  });
}
