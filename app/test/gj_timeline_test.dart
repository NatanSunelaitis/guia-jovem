import 'package:app/core/theme/gj_colors.dart';
import 'package:app/shared/widgets/gj_timeline.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('os pontos aparecem inteiros: cheio no concluído, anel na cor do programa no futuro', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GJTimeline(
            cor: GJColors.tertiary,
            itens: [
              GJTimelineItem(mes: 'jan', dia: '10', titulo: 'Passou', concluido: true),
              GJTimelineItem(mes: 'fev', dia: '20', titulo: 'Vem aí'),
            ],
          ),
        ),
      ),
    );

    final concluido = find.byKey(const ValueKey('ponto-concluido'));
    final futuro = find.byKey(const ValueKey('ponto-futuro'));

    // Antes o ponto ficava preso numa coluna de 2 px e não aparecia.
    expect(tester.getSize(find.descendant(of: concluido, matching: find.byType(DecoratedBox))), const Size(12, 12));
    expect(tester.getSize(find.descendant(of: futuro, matching: find.byType(DecoratedBox))), const Size(12, 12));

    final decoracaoConcluido = tester.widget<Container>(concluido).decoration! as BoxDecoration;
    expect(decoracaoConcluido.color, GJColors.tertiary);

    final decoracaoFuturo = tester.widget<Container>(futuro).decoration! as BoxDecoration;
    expect(decoracaoFuturo.color, GJColors.surfaceLowest);
    expect((decoracaoFuturo.border! as Border).top.color, GJColors.tertiary);
    expect((decoracaoFuturo.border! as Border).top.width, 2);
  });
}
