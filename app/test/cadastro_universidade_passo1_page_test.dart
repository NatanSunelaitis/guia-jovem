import 'package:app/features/auth/data/cadastro_universidade_state.dart';
import 'package:app/features/auth/presentation/cadastro_universidade_passo1_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'helpers/auth_test_setup.dart';
import 'helpers/pump_with_router.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  setUp(configurarAmbienteDeTeste);

  Future<void> pumpPasso1(WidgetTester tester) => pumpComRouter(
        tester,
        initialLocation: '/cadastro/universidade/dados',
        rotas: {
          '/cadastro/universidade/dados': (context) => const CadastroUniversidadePasso1Page(),
          '/cadastro/universidade/programas': (context) => const PaginaMarcadora('Passo2'),
        },
      );

  testWidgets('mostra erros de validação quando os campos obrigatórios estão vazios', (tester) async {
    await pumpPasso1(tester);

    await tester.tap(find.text('Próximo'));
    await tester.pumpAndSettle();

    expect(find.text('Informe a razão social'), findsOneWidget);
    expect(find.text('Informe o nome fantasia'), findsOneWidget);
    expect(find.text('CNPJ deve ter 14 dígitos'), findsOneWidget);
    expect(find.text('Informe o telefone'), findsOneWidget);
    expect(find.text('Informe o link da página inicial'), findsOneWidget);
    expect(find.text('Informe um e-mail válido'), findsOneWidget);
    expect(find.text('Informe uma senha com 7 ou mais caracteres'), findsOneWidget);
    expect(find.text('Passo2'), findsNothing);
  });

  testWidgets('com dados válidos, salva no estado em memória e avança para o passo 2', (tester) async {
    await pumpPasso1(tester);

    await tester.enterText(find.byType(TextField).at(0), 'Fatec Sorocaba Ltda');
    await tester.enterText(find.byType(TextField).at(1), 'Fatec Sorocaba');
    await tester.enterText(find.byType(TextField).at(2), '11.222.333/0001-81');
    await tester.enterText(find.byType(TextField).at(3), '(15) 3212-3456');
    await tester.enterText(find.byType(TextField).at(4), 'fatecsorocaba.edu.br');
    await tester.enterText(find.byType(TextField).at(6), 'contato@fatecsorocaba.edu.br');
    await tester.enterText(find.byType(TextField).at(7), 'senha1234');
    await tester.enterText(find.byType(TextField).at(8), 'senha1234');

    await tester.tap(find.text('Próximo'));
    await tester.pumpAndSettle();

    expect(find.text('Passo2'), findsOneWidget);
    expect(cadastroUniversidadeState.razaoSocial, 'Fatec Sorocaba Ltda');
    expect(cadastroUniversidadeState.nomeFantasia, 'Fatec Sorocaba');
    expect(cadastroUniversidadeState.cnpj, '11.222.333/0001-81');
    expect(cadastroUniversidadeState.email, 'contato@fatecsorocaba.edu.br');
    expect(cadastroUniversidadeState.senha, 'senha1234');
    expect(cadastroUniversidadeState.natureza, 'P');
  });

  testWidgets('ao voltar para a tela, os campos já preenchidos continuam lá (estado em memória)', (tester) async {
    cadastroUniversidadeState
      ..razaoSocial = 'USP'
      ..nomeFantasia = 'Universidade de São Paulo'
      ..cnpj = '63.025.530/0001-04'
      ..telefonePrincipal = '(11) 3091-3121'
      ..linkPagina = 'https://www5.usp.br'
      ..email = 'contato@usp.br'
      ..senha = 'senhaSalva1';

    await pumpPasso1(tester);

    expect(find.text('USP'), findsOneWidget);
    expect(find.text('Universidade de São Paulo'), findsOneWidget);
    expect(find.text('63.025.530/0001-04'), findsOneWidget);
    expect(find.text('contato@usp.br'), findsOneWidget);
  });

  testWidgets('selecionar natureza Privada é salvo no estado', (tester) async {
    await pumpPasso1(tester);

    await tester.tap(find.text('Privada'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), 'Instituto Privado');
    await tester.enterText(find.byType(TextField).at(1), 'IP');
    await tester.enterText(find.byType(TextField).at(2), '11.222.333/0001-81');
    await tester.enterText(find.byType(TextField).at(3), '(15) 3212-3456');
    await tester.enterText(find.byType(TextField).at(4), 'ip.edu.br');
    await tester.enterText(find.byType(TextField).at(6), 'contato@ip.edu.br');
    await tester.enterText(find.byType(TextField).at(7), 'senha1234');
    await tester.enterText(find.byType(TextField).at(8), 'senha1234');
    await tester.tap(find.text('Próximo'));
    await tester.pumpAndSettle();

    expect(cadastroUniversidadeState.natureza, 'V');
  });
}
