import 'dart:convert';

import 'package:app/core/network/auth_api_client.dart';
import 'package:app/core/storage/token_storage.dart';
import 'package:app/features/auth/data/auth_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Adaptador implements HttpClientAdapter {
  _Adaptador(this.responder);

  final Future<ResponseBody> Function(RequestOptions) responder;

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<List<int>>? requestStream, Future<void>? cancelFuture) =>
      responder(options);

  @override
  void close({bool force = false}) {}
}

AuthRepository _repositorio(Future<ResponseBody> Function(RequestOptions) responder) =>
    AuthRepository(client: AuthApiClient(baseUrl: 'http://api', dio: Dio()..httpClientAdapter = _Adaptador(responder)));

ResponseBody _json(Map<String, dynamic> corpo, int status) =>
    ResponseBody.fromString(jsonEncode(corpo), status, headers: {Headers.contentTypeHeader: ['application/json']});

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await tokenStorage.salvar(accessToken: 'a', refreshToken: 'r');
  });

  test('sem conexão: segue como visitante, mas a sessão salva continua para a próxima abertura', () async {
    final repositorio = _repositorio((opcoes) async => throw DioException.connectionError(requestOptions: opcoes, reason: 'offline'));

    expect(await repositorio.tentarRestaurarSessao(), isNull);
    expect(await tokenStorage.lerAccessToken(), 'a');
  });

  test('sessão recusada pela API: os tokens são apagados', () async {
    final repositorio = _repositorio((opcoes) async {
      if (opcoes.path.contains('/auth/refresh')) return _json({'error': {'code': 'TOKEN_INVALIDO', 'message': 'Sessão expirada'}}, 401);
      return _json({'error': {'code': 'NAO_AUTENTICADO', 'message': 'Sessão expirada'}}, 401);
    });

    expect(await repositorio.tentarRestaurarSessao(), isNull);
    expect(await tokenStorage.lerAccessToken(), isNull);
  });

  test('API que não responde: desiste em até 8 segundos sem travar a abertura', () async {
    final repositorio = _repositorio((_) => Future<ResponseBody>.delayed(const Duration(seconds: 30), () => _json({}, 200)));

    final inicio = DateTime.now();
    expect(await repositorio.tentarRestaurarSessao(), isNull);
    expect(DateTime.now().difference(inicio).inSeconds, lessThan(10));
  }, timeout: const Timeout(Duration(seconds: 20)));
}
