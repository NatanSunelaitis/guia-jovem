import 'package:app/shared/widgets/gj_estrelas.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';

void main() {
  test('arredonda a média para o meio ponto mais próximo', () {
    expect(estrelasDaMedia(4.5), (cheias: 4, meia: true));
    expect(estrelasDaMedia(4.2), (cheias: 4, meia: false));
    expect(estrelasDaMedia(4.8), (cheias: 5, meia: false));
    expect(estrelasDaMedia(3.0), (cheias: 3, meia: false));
  });

  testWidgets('4.5 mostra quatro estrelas e meia', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: GJEstrelasMedia(media: 4.5))));

    expect(find.byIcon(Symbols.star_half), findsOneWidget);
    expect(find.byIcon(Symbols.star), findsNWidgets(4));
  });
}
