import 'package:app/core/theme/gj_theme.dart';
import 'package:app/shared/widgets/gj_input.dart';
import 'package:app/shared/widgets/gj_select.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('rótulo acima, mesma altura do GJInput, escolha e erro', (tester) async {
    String? grau;
    await tester.pumpWidget(MaterialApp(
      theme: GJTheme.light,
      home: Scaffold(
        body: StatefulBuilder(
          builder: (context, setState) => Column(
            children: [
              const GJInput(key: Key('texto'), label: 'Nome'),
              GJSelect<String>(
                key: const Key('lista'),
                label: 'Grau',
                value: grau,
                items: const {null: 'Não informado', 'Bacharelado': 'Bacharelado'},
                errorText: grau == null ? 'Escolha o grau' : null,
                onChanged: (valor) => setState(() => grau = valor),
              ),
            ],
          ),
        ),
      ),
    ));

    // Rótulo como texto acima da caixa, não como rótulo flutuante do Material.
    final rotulo = tester.getRect(find.text('Grau'));
    final caixa = tester.getRect(find.byWidgetPredicate((w) => w is DropdownButtonFormField));
    expect(rotulo.bottom, lessThanOrEqualTo(caixa.top));
    final caixaTexto = tester.getRect(find.byType(TextField));
    expect(caixa.height, moreOrLessEquals(caixaTexto.height, epsilon: 2));
    expect(find.text('Escolha o grau'), findsOneWidget);

    await tester.tap(find.byWidgetPredicate((w) => w is DropdownButtonFormField));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bacharelado').last);
    await tester.pumpAndSettle();

    expect(grau, 'Bacharelado');
    expect(find.text('Escolha o grau'), findsNothing);
  });
}
