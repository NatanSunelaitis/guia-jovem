import 'dart:async';
import 'dart:convert';

import 'package:app/core/network/api_client.dart';
import 'package:app/core/theme/gj_theme.dart';
import 'package:app/core/utils/salvar_arquivo.dart';
import 'package:app/features/universidades/presentation/pesquisa_universidades_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

final _pesquisa = jsonEncode({
  'data': [
    {'id': 1, 'nomeFantasia': 'Fatec Sorocaba', 'natureza': 'P', 'totalAvaliacoes': 0, 'cidade': 'Sorocaba', 'estado': 'SP', 'programas': <dynamic>[]},
  ],
  'meta': {'page': 1, 'pageSize': 20, 'total': 1, 'totalPages': 1},
});

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  late List<ArquivoBaixado> salvos;
  late List<Uri> pedidos;

  setUp(() {
    salvos = [];
    pedidos = [];
    salvarArquivo = (arquivo) async => salvos.add(arquivo);
  });

  void api(Future<http.Response> Function(http.Request) relatorio) {
    apiClient = ApiClient(
      baseUrl: 'http://api',
      client: MockClient((req) async {
        pedidos.add(req.url);
        if (req.url.path.endsWith('/relatorios/pesquisa')) return relatorio(req);
        if (req.url.path.endsWith('/universidades')) return http.Response(_pesquisa, 200, headers: {'content-type': 'application/json'});
        return http.Response(jsonEncode({'data': <dynamic>[], 'meta': <String, dynamic>{}}), 200);
      }),
    );
  }

  Future<void> gerar(WidgetTester tester, String formato) async {
    tester.view.physicalSize = const Size(1366, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(theme: GJTheme.light, home: const PesquisaUniversidadesPage()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Gerar relatório'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(formato));
    await tester.pump();
  }

  testWidgets('baixa o CSV com os filtros da pesquisa, mostra o carregamento e avisa o sucesso', (tester) async {
    final resposta = Completer<http.Response>();
    api((_) => resposta.future);

    await gerar(tester, 'Exportar CSV');

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    final pedido = pedidos.lastWhere((u) => u.path.endsWith('/relatorios/pesquisa'));
    expect(pedido.queryParameters['formato'], 'csv');
    expect(pedido.queryParameters.containsKey('page'), isFalse);

    resposta.complete(http.Response.bytes(utf8.encode('Nome;Cidade\n'), 200, headers: {
      'content-type': 'text/csv; charset=utf-8',
      'content-disposition': 'attachment; filename="relatorio-pesquisa.csv"',
    }));
    await tester.pumpAndSettle();

    expect(salvos.single.nome, 'relatorio-pesquisa.csv');
    expect(salvos.single.tipo, 'text/csv');
    expect(find.text('Relatório em CSV gerado: relatorio-pesquisa.csv.'), findsOneWidget);
    expect(find.byKey(const Key('gj-aviso-sucesso')), findsOneWidget);
    expect(find.text('Gerar relatório'), findsOneWidget);
  });

  testWidgets('erro da API vira aviso de erro e nada é salvo', (tester) async {
    api((_) async => http.Response(jsonEncode({'error': {'code': 'INTERNAL', 'message': 'Erro interno.'}}), 500));

    await gerar(tester, 'Exportar PDF');
    await tester.pumpAndSettle();

    expect(salvos, isEmpty);
    expect(find.byKey(const Key('gj-aviso-erro')), findsOneWidget);
    expect(find.text('Não foi possível gerar o relatório. Erro interno.'), findsOneWidget);
  });

  testWidgets('sem conexão com a API também avisa', (tester) async {
    api((_) async => throw http.ClientException('Failed to fetch'));

    await gerar(tester, 'Exportar PDF');
    await tester.pumpAndSettle();

    expect(find.textContaining('Confira sua conexão'), findsOneWidget);
  });

  testWidgets('falha ao salvar no navegador também avisa', (tester) async {
    api((_) async => http.Response.bytes([37, 80, 68, 70], 200, headers: {'content-type': 'application/pdf'}));
    salvarArquivo = (_) async => throw StateError('bloqueado');

    await gerar(tester, 'Exportar PDF');
    await tester.pumpAndSettle();

    expect(find.text('O navegador não conseguiu salvar o relatório. Tente de novo.'), findsOneWidget);
  });
}
