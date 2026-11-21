import 'dart:convert';

import 'package:app/core/network/api_client.dart';
import 'package:app/core/network/api_exception.dart';
import 'package:app/core/network/auth_api_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('ApiClient', () {
    test('falha de rede vira ApiException SEM_CONEXAO com mensagem para o usuário', () async {
      final cliente = ApiClient(baseUrl: 'http://api', client: MockClient((_) async => throw http.ClientException('Failed to fetch')));

      await expectLater(
        cliente.get('/universidades'),
        throwsA(isA<ApiException>()
            .having((e) => e.code, 'code', 'SEM_CONEXAO')
            .having((e) => e.message, 'message', contains('Confira sua conexão'))),
      );
    });

    test('resposta fora do envelope (página de erro do proxy) vira RESPOSTA_INVALIDA', () async {
      final cliente = ApiClient(baseUrl: 'http://api', client: MockClient((_) async => http.Response('<html>502</html>', 502)));

      await expectLater(cliente.get('/universidades'), throwsA(isA<ApiException>().having((e) => e.code, 'code', 'RESPOSTA_INVALIDA')));
    });

    test('erro da API mantém código e mensagem', () async {
      final cliente = ApiClient(
        baseUrl: 'http://api',
        client: MockClient((_) async => http.Response(jsonEncode({'error': {'code': 'NOT_FOUND', 'message': 'Não encontrada'}}), 404)),
      );

      await expectLater(cliente.get('/x'), throwsA(isA<ApiException>().having((e) => e.message, 'message', 'Não encontrada')));
    });

    test('baixar lê os bytes, o tipo e o nome do Content-Disposition', () async {
      late Uri pedida;
      final cliente = ApiClient(
        baseUrl: 'http://api',
        client: MockClient((req) async {
          pedida = req.url;
          return http.Response.bytes(utf8.encode('nome;cidade\n'), 200, headers: {
            'content-type': 'text/csv; charset=utf-8',
            'content-disposition': 'attachment; filename="relatorio-pesquisa.csv"',
          });
        }),
      );

      final arquivo = await cliente.baixar('/relatorios/pesquisa', query: {'formato': 'csv', 'q': null}, nomePadrao: 'x.csv');

      expect(pedida.queryParameters, {'formato': 'csv'});
      expect(arquivo.nome, 'relatorio-pesquisa.csv');
      expect(arquivo.tipo, 'text/csv');
      expect(utf8.decode(arquivo.bytes), 'nome;cidade\n');
    });

    test('baixar sem Content-Disposition usa o nome padrão; vazio é erro', () async {
      final semNome = ApiClient(baseUrl: 'http://api', client: MockClient((_) async => http.Response('a', 200)));
      expect((await semNome.baixar('/r', nomePadrao: 'relatorio.pdf')).nome, 'relatorio.pdf');

      final vazio = ApiClient(baseUrl: 'http://api', client: MockClient((_) async => http.Response('', 200)));
      await expectLater(vazio.baixar('/r', nomePadrao: 'r.pdf'), throwsA(isA<ApiException>()));
    });
  });

  group('AuthApiClient', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('sem resposta do servidor vira SEM_CONEXAO; corpo não JSON vira RESPOSTA_INVALIDA', () async {
      final semRede = Dio()..httpClientAdapter = _Adaptador((opcoes) => throw DioException.connectionError(requestOptions: opcoes, reason: 'offline'));
      await expectLater(
        AuthApiClient(baseUrl: 'http://api', dio: semRede).get('/auth/me'),
        throwsA(isA<ApiException>().having((e) => e.code, 'code', 'SEM_CONEXAO')),
      );

      final html = Dio()..httpClientAdapter = _Adaptador((_) => ResponseBody.fromString('<html>erro</html>', 500, headers: {
            Headers.contentTypeHeader: ['text/html'],
          }));
      await expectLater(
        AuthApiClient(baseUrl: 'http://api', dio: html).post('/sugestoes'),
        throwsA(isA<ApiException>().having((e) => e.code, 'code', 'RESPOSTA_INVALIDA')),
      );
    });
  });
}

class _Adaptador implements HttpClientAdapter {
  _Adaptador(this.responder);

  final ResponseBody Function(RequestOptions) responder;

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<List<int>>? requestStream, Future<void>? cancelFuture) async =>
      responder(options);

  @override
  void close({bool force = false}) {}
}
