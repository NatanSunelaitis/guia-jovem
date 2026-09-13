import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:app/core/theme/gj_theme.dart';
import 'package:app/features/dev_components/dev_components_page.dart';

void main() {
  setUpAll(() {
    // Evita chamadas de rede por fontes durante os testes.
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('abre a galeria de componentes em /dev/components', (tester) async {
    await tester.pumpWidget(MaterialApp(theme: GJTheme.light, home: const DevComponentsPage()));
    await tester.pump();
    // Evita pumpAndSettle: a galeria tem um GJButton "loading" e badges/skeletons
    // com animação indefinida.
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Galeria de componentes'), findsOneWidget);
    expect(find.text('GJButton'), findsOneWidget);
    expect(find.text('GJInput'), findsOneWidget);
    expect(find.text('GJCard'), findsOneWidget);
    expect(find.text('GJTag'), findsOneWidget);
    expect(find.text('GJTabs'), findsOneWidget);
    expect(find.text('GJHeader'), findsOneWidget);
    expect(find.text('GJFooter'), findsOneWidget);
    expect(find.text('GJDataTable'), findsOneWidget);
  });
}
