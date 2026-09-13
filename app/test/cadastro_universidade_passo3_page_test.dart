import 'package:app/features/auth/data/cadastro_universidade_state.dart';
import 'package:app/features/auth/presentation/cadastro_universidade_passo3_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'helpers/auth_test_setup.dart';
import 'helpers/mock_auth_api.dart';
import 'helpers/pump_with_router.dart';

const _usuarioUniversidade = {
  'id': 10,
  'nome': 'Fatec Sorocaba',
  'email': 'contato@fatecsorocaba.edu.br',
  'tipoUsuario': 'U',
  'fotoUrl': null,
  'universidade': {'id': 3, 'status': 'P'},
};

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  setUp(configurarAmbienteDeTeste);

  Future<void> pumpPasso3(WidgetTester tester) => pumpComRouter(
        tester,
        initialLocation: '/cadastro/universidade/campus',
        rotas: {
          '/cadastro/universidade/campus': (context) => const CadastroUniversidadePasso3Page(),
          '/cadastro/universidade/programas': (context) => const PaginaMarcadora('Passo2'),
          '/cadastro/universidade/sucesso': (context) => const PaginaMarcadora('Sucesso'),
        },
      );

  Future<void> preencherCampoObrigatorios(WidgetTester tester) async {
    await tester.enterText(find.byType(TextField).at(0), 'Fatec Sorocaba');
    await tester.enterText(find.byType(TextField).at(1), 'Av. Engenheiro Carlos Reinaldo Mendes');
    await tester.enterText(find.byType(TextField).at(2), '2015');
    await tester.enterText(find.byType(TextField).at(4), 'Alto da Boa Vista');
    await tester.enterText(find.byType(TextField).at(5), 'Sorocaba');
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('SP').last);
    await tester.pumpAndSettle();
  }

  testWidgets('mostra erros de validação quando os campos obrigatórios estão vazios', (tester) async {
    await pumpPasso3(tester);

    await tester.tap(find.text('Cadastrar'));
    await tester.pumpAndSettle();

    expect(find.text('Informe o nome do campus'), findsOneWidget);
    expect(find.text('Informe o logradouro'), findsOneWidget);
    expect(find.text('Informe o número'), findsOneWidget);
    expect(find.text('Informe o bairro'), findsOneWidget);
    expect(find.text('Informe a cidade'), findsOneWidget);
    expect(find.text('Selecione o estado'), findsOneWidget);
  });

  testWidgets('"Voltar" salva o preenchido no estado e retorna ao passo 2', (tester) async {
    await pumpPasso3(tester);

    await tester.enterText(find.byType(TextField).at(0), 'Campus parcial');
    await tester.tap(find.text('Voltar'));
    await tester.pumpAndSettle();

    expect(find.text('Passo2'), findsOneWidget);
    expect(cadastroUniversidadeState.nomeCampus, 'Campus parcial');
  });

  testWidgets('cadastro completo chama a API e navega para a tela de sucesso', (tester) async {
    mockAuthApi({
      '/auth/register/universidade': envelope({
        'accessToken': 'access-3',
        'refreshToken': 'refresh-3',
        'usuario': _usuarioUniversidade,
      }, {}),
    });

    await pumpPasso3(tester);
    await preencherCampoObrigatorios(tester);

    await tester.tap(find.text('Cadastrar'));
    await tester.pumpAndSettle();

    expect(find.text('Sucesso'), findsOneWidget);
    expect(cadastroUniversidadeState.nomeCampus, '');
  });

  testWidgets('mostra a mensagem de erro geral quando a API rejeita o cadastro', (tester) async {
    mockAuthApiError('/auth/register/universidade', message: 'Este CNPJ já está cadastrado.');

    await pumpPasso3(tester);
    await preencherCampoObrigatorios(tester);

    await tester.tap(find.text('Cadastrar'));
    await tester.pumpAndSettle();

    expect(find.text('Este CNPJ já está cadastrado.'), findsOneWidget);
    expect(find.text('Sucesso'), findsNothing);
  });
}
