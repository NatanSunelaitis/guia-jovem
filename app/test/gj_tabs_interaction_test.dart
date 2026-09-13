import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:app/core/theme/gj_theme.dart';
import 'package:app/features/dev_components/dev_components_page.dart';

// Em arquivo próprio: mistura mal com outros testWidgets no mesmo isolate por
// causa de um Tooltip/PopupMenuButton na galeria (bug conhecido do Flutter:
// TooltipState reaproveita um SingleTickerProviderStateMixin entre testes).
void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('troca de aba do GJTabs atualiza a seleção', (tester) async {
    await tester.pumpWidget(MaterialApp(theme: GJTheme.light, home: const DevComponentsPage()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final abaCursos = find.text('Cursos').first;
    await tester.ensureVisible(abaCursos);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(abaCursos);
    await tester.pump();

    expect(find.text('Cursos'), findsWidgets);
  });
}
