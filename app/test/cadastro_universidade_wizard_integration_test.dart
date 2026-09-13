import 'package:app/features/auth/data/cadastro_universidade_state.dart';
import 'package:app/features/auth/presentation/aviso_cadastro_universidade_page.dart';
import 'package:app/features/auth/presentation/cadastro_universidade_passo1_page.dart';
import 'package:app/features/auth/presentation/cadastro_universidade_passo2_page.dart';
import 'package:app/features/auth/presentation/cadastro_universidade_passo3_page.dart';
import 'package:app/features/auth/presentation/cadastro_universidade_sucesso_page.dart';
import 'dart:convert';
import 'dart:typed_data';

import 'package:app/features/auth/presentation/tipo_cadastro_page.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'helpers/auth_test_setup.dart';
import 'helpers/mock_api.dart';
import 'helpers/mock_auth_api.dart' hide envelope;
import 'helpers/pump_with_router.dart';

final _programas = [
  {'id': 1, 'nome': 'Exame Nacional do Ensino Médio', 'sigla': 'ENEM', 'tipo': 'ENTRADA', 'descricao': 'D', 'imagemUrl': null, 'universidadeId': null},
  {'id': 5, 'nome': 'Fundo de Financiamento Estudantil', 'sigla': 'FIES', 'tipo': 'FINANCIAMENTO', 'descricao': 'D', 'imagemUrl': null, 'universidadeId': null},
];

const _usuarioUniversidade = {
  'id': 20,
  'nome': 'Fatec Sorocaba',
  'email': 'contato@fatecsorocaba.edu.br',
  'tipoUsuario': 'U',
  'fotoUrl': null,
  'universidade': {'id': 7, 'status': 'P'},
};

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  setUp(configurarAmbienteDeTeste);

  Future<void> pumpFluxoCompleto(WidgetTester tester) => pumpComRouter(
        tester,
        initialLocation: '/cadastro',
        rotas: {
          '/cadastro': (context) => const TipoCadastroPage(),
          '/cadastro/universidade': (context) => const AvisoCadastroUniversidadePage(),
          '/cadastro/universidade/dados': (context) => const CadastroUniversidadePasso1Page(),
          '/cadastro/universidade/programas': (context) => const CadastroUniversidadePasso2Page(),
          '/cadastro/universidade/campus': (context) => const CadastroUniversidadePasso3Page(),
          '/cadastro/universidade/sucesso': (context) => const CadastroUniversidadeSucessoPage(),
        },
      );

  testWidgets(
    'fluxo 7.3 completo: T10 -> T12 -> T13 -> T14 -> T15 -> sucesso, com dados preservados ao voltar',
    (tester) async {
      mockApi({'/programas': envelope(_programas, {'total': 2, 'page': 1, 'perPage': 20})});

      Map<String, dynamic>? corpoEnviado;
      final dio = Dio();
      dio.httpClientAdapter = _CapturaCorpoAdapter(
        onRequisicao: (options) {
          if (options.path.endsWith('/auth/register/universidade')) {
            corpoEnviado = options.data as Map<String, dynamic>;
          }
        },
        respostas: {
          '/auth/register/universidade': {
            'data': {
              'accessToken': 'access-9',
              'refreshToken': 'refresh-9',
              'usuario': _usuarioUniversidade,
            },
            'meta': {},
          },
        },
      );
      mockAuthApiComAdapter(dio);

      await pumpFluxoCompleto(tester);

      // T10: escolhe "Represento uma instituição".
      await tester.tap(find.text('Universidade'));
      await tester.pumpAndSettle();
      expect(find.text('Atenção!'), findsOneWidget);

      // T12: aceita os termos e prossegue.
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Prosseguir'));
      await tester.pumpAndSettle();

      // T13: dados institucionais.
      expect(find.text('Cadastre sua Universidade!'), findsOneWidget);
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

      // T14: programas aceitos.
      expect(find.text('Adicione os programas de entrada aceitos por sua instituição!'), findsOneWidget);
      await tester.tap(find.text('ENEM'));
      await tester.pumpAndSettle();

      // Volta para o T13 e confirma que os dados digitados continuam lá.
      await tester.tap(find.text('Voltar'));
      await tester.pumpAndSettle();
      expect(find.text('Fatec Sorocaba Ltda'), findsOneWidget);
      expect(find.text('contato@fatecsorocaba.edu.br'), findsOneWidget);

      // Avança de novo para o T14: a seleção de programas também foi preservada.
      await tester.tap(find.text('Próximo'));
      await tester.pumpAndSettle();
      expect(cadastroUniversidadeState.programasIds, {1});
      await tester.tap(find.text('Próximo'));
      await tester.pumpAndSettle();

      // T15: primeiro campus.
      expect(find.text('Cadastre seu primeiro Campus!'), findsOneWidget);
      await tester.enterText(find.byType(TextField).at(0), 'Fatec Sorocaba');
      await tester.enterText(find.byType(TextField).at(1), 'Av. Engenheiro Carlos Reinaldo Mendes');
      await tester.enterText(find.byType(TextField).at(2), '2015');
      await tester.enterText(find.byType(TextField).at(4), 'Alto da Boa Vista');
      await tester.enterText(find.byType(TextField).at(5), 'Sorocaba');
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('SP').last);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(6), '18085-000');

      await tester.tap(find.text('Cadastrar'));
      await tester.pumpAndSettle();

      // Tela de sucesso.
      expect(find.text('Cadastro enviado para análise'), findsOneWidget);

      // O corpo enviado para a API reflete os dados de todos os 3 passos.
      expect(corpoEnviado, isNotNull);
      expect(corpoEnviado!['aceitouTermos'], isTrue);
      expect(corpoEnviado!['usuario'], {'nome': 'Fatec Sorocaba', 'email': 'contato@fatecsorocaba.edu.br', 'senha': 'senha1234'});
      expect(corpoEnviado!['universidade']['razaoSocial'], 'Fatec Sorocaba Ltda');
      expect(corpoEnviado!['universidade']['cnpj'], '11222333000181');
      expect(corpoEnviado!['universidade']['linkPagina'], 'https://fatecsorocaba.edu.br');
      expect(corpoEnviado!['programasIds'], [1]);
      expect(corpoEnviado!['campus']['nome'], 'Fatec Sorocaba');
      expect(corpoEnviado!['campus']['endereco']['cidade'], 'Sorocaba');
      expect(corpoEnviado!['campus']['endereco']['estado'], 'SP');
      expect(corpoEnviado!['campus']['endereco']['cep'], '18085000');

      // O estado em memória do wizard foi limpo após o sucesso.
      expect(cadastroUniversidadeState.razaoSocial, '');
      expect(cadastroUniversidadeState.programasIds, isEmpty);
    },
  );
}

/// Adapter falso que devolve as [respostas] mockadas (mesmo formato de
/// `_FakeHttpClientAdapter` em `mock_auth_api.dart`) e, antes disso, entrega
/// as `RequestOptions` de cada chamada para [onRequisicao] — usado aqui para
/// capturar o corpo exato que o wizard monta para `POST
/// /auth/register/universidade`.
class _CapturaCorpoAdapter implements HttpClientAdapter {
  _CapturaCorpoAdapter({required this.onRequisicao, required this.respostas});

  final void Function(RequestOptions options) onRequisicao;
  final Map<String, Map<String, dynamic>> respostas;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    onRequisicao(options);

    final caminho = options.uri.path;
    Map<String, dynamic>? corpo;
    for (final entrada in respostas.entries) {
      if (caminho.endsWith(entrada.key)) {
        corpo = entrada.value;
        break;
      }
    }

    final dados = corpo ??
        {
          'error': {'code': 'NOT_MOCKED', 'message': 'Sem mock para $caminho', 'details': <dynamic>[]},
        };
    final bytes = utf8.encode(jsonEncode(dados));
    return ResponseBody.fromBytes(
      bytes,
      corpo != null ? 200 : 404,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}
