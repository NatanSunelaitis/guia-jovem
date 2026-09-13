import 'package:app/features/auth/data/cadastro_universidade_state.dart';
import 'package:app/features/auth/presentation/cadastro_universidade_passo2_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'helpers/auth_test_setup.dart';
import 'helpers/mock_api.dart';
import 'helpers/pump_with_router.dart';

final _programas = [
  {'id': 1, 'nome': 'Exame Nacional do Ensino Médio', 'sigla': 'ENEM', 'tipo': 'ENTRADA', 'descricao': 'D', 'imagemUrl': null, 'universidadeId': null},
  {'id': 5, 'nome': 'Fundo de Financiamento Estudantil', 'sigla': 'FIES', 'tipo': 'FINANCIAMENTO', 'descricao': 'D', 'imagemUrl': null, 'universidadeId': null},
];

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  setUp(configurarAmbienteDeTeste);

  Future<void> pumpPasso2(WidgetTester tester) => pumpComRouter(
        tester,
        initialLocation: '/cadastro/universidade/programas',
        rotas: {
          '/cadastro/universidade/programas': (context) => const CadastroUniversidadePasso2Page(),
          '/cadastro/universidade/dados': (context) => const PaginaMarcadora('Passo1'),
          '/cadastro/universidade/campus': (context) => const PaginaMarcadora('Passo3'),
        },
      );

  testWidgets('carrega e agrupa os programas por tipo', (tester) async {
    mockApi({'/programas': envelope(_programas, {'total': 2, 'page': 1, 'perPage': 20})});

    await pumpPasso2(tester);
    await tester.pumpAndSettle();

    expect(find.text('PROGRAMAS DE ENTRADA'), findsOneWidget);
    expect(find.text('PROGRAMAS DE FINANCIAMENTO'), findsOneWidget);
    expect(find.text('ENEM'), findsOneWidget);
    expect(find.text('FIES'), findsOneWidget);
  });

  testWidgets('mostra estado de erro com opção de tentar novamente', (tester) async {
    mockApiError('/programas');

    await pumpPasso2(tester);
    await tester.pumpAndSettle();

    expect(find.text('Não foi possível carregar os programas'), findsOneWidget);
  });

  testWidgets('selecionar programas e avançar salva os ids no estado', (tester) async {
    mockApi({'/programas': envelope(_programas, {'total': 2, 'page': 1, 'perPage': 20})});

    await pumpPasso2(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.text('ENEM'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Próximo'));
    await tester.pumpAndSettle();

    expect(find.text('Passo3'), findsOneWidget);
    expect(cadastroUniversidadeState.programasIds, {1});
  });

  testWidgets('voltar preserva a seleção já feita ao reabrir a tela', (tester) async {
    mockApi({'/programas': envelope(_programas, {'total': 2, 'page': 1, 'perPage': 20})});
    cadastroUniversidadeState.programasIds = {5};

    await pumpPasso2(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Voltar'));
    await tester.pumpAndSettle();

    expect(find.text('Passo1'), findsOneWidget);
    expect(cadastroUniversidadeState.programasIds, {5});
  });
}
