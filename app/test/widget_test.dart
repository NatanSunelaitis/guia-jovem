import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:app/app.dart';

void main() {
  setUpAll(() {
    // Evita chamadas de rede por fontes durante os testes.
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  // Evita pumpAndSettle: a galeria inclui um GJButton em estado "loading",
  // cujo spinner anima indefinidamente.
  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(const GuiaJovemApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('abre a galeria de componentes em /dev/components', (tester) async {
    await pumpApp(tester);

    expect(find.text('Galeria de componentes'), findsOneWidget);
    expect(find.text('GJButton'), findsOneWidget);
    expect(find.text('GJInput'), findsOneWidget);
    expect(find.text('GJCard'), findsOneWidget);
    expect(find.text('GJTag'), findsOneWidget);
    expect(find.text('GJTabs'), findsOneWidget);
  });

  testWidgets('troca de aba do GJTabs atualiza a seleção', (tester) async {
    await pumpApp(tester);

    final abaCursos = find.text('Cursos');
    await tester.ensureVisible(abaCursos);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(abaCursos);
    await tester.pump();

    expect(find.text('Cursos'), findsOneWidget);
  });
}
