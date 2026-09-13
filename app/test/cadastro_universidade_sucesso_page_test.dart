import 'package:app/features/auth/presentation/cadastro_universidade_sucesso_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'helpers/auth_test_setup.dart';
import 'helpers/pump_with_router.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  setUp(configurarAmbienteDeTeste);

  testWidgets('mostra a confirmação de envio para análise e volta para a home', (tester) async {
    await pumpComRouter(
      tester,
      initialLocation: '/cadastro/universidade/sucesso',
      rotas: {
        '/cadastro/universidade/sucesso': (context) => const CadastroUniversidadeSucessoPage(),
        '/': (context) => const PaginaMarcadora('Home'),
      },
    );

    expect(find.text('Cadastro enviado para análise'), findsOneWidget);

    await tester.tap(find.text('Voltar para a página inicial'));
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
  });
}
