import 'package:app/shared/widgets/gj_aligned_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pump(WidgetTester tester, {required int itens, bool ocuparLargura = false}) async {
    tester.view.physicalSize = const Size(1366, 768);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 1200,
            child: GJAlignedGrid(
              itemWidth: 280,
              spacing: 24,
              ocuparLargura: ocuparLargura,
              children: [for (var i = 0; i < itens; i++) SizedBox(key: ValueKey('card-$i'), height: 100)],
            ),
          ),
        ),
      ),
    );
  }

  // 1200 px com cards de 280 e espaço de 24: quatro colunas de 282 px.
  const larguraNaGrade = (1200 - 3 * 24) / 4;

  testWidgets('um resultado só mantém a largura de card da grade', (tester) async {
    await pump(tester, itens: 1);
    expect(tester.getSize(find.byKey(const ValueKey('card-0'))).width, larguraNaGrade);
  });

  testWidgets('a última linha incompleta não estica os cards', (tester) async {
    await pump(tester, itens: 6);
    expect(tester.getSize(find.byKey(const ValueKey('card-0'))).width, larguraNaGrade);
    expect(tester.getSize(find.byKey(const ValueKey('card-5'))).width, larguraNaGrade);
    expect(tester.getTopLeft(find.byKey(const ValueKey('card-4'))).dx, 0);
  });

  testWidgets('ocuparLargura divide a largura entre poucos cards', (tester) async {
    await pump(tester, itens: 2, ocuparLargura: true);
    expect(tester.getSize(find.byKey(const ValueKey('card-0'))).width, (1200 - 24) / 2);
  });
}
