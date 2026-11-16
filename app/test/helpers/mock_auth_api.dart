import 'dart:convert';
import 'dart:typed_data';

import 'package:app/core/network/auth_api_client.dart';
import 'package:dio/dio.dart';

/// Equivalente a `mock_api.dart`, mas para o `AuthApiClient` (Dio): aponta o
/// `authApiClient` global para um Dio com um `HttpClientAdapter` falso que
/// devolve corpos JSON já decodificados, por path.
void mockAuthApi(Map<String, Map<String, dynamic>> respostas, {int status = 200}) {
  final dio = Dio();
  dio.httpClientAdapter = _FakeHttpClientAdapter(respostas: respostas, status: status);
  authApiClient = AuthApiClient(dio: dio);
}

void mockAuthApiError(String path, {String code = 'INTERNAL_ERROR', String message = 'Erro', int status = 500}) {
  final dio = Dio();
  dio.httpClientAdapter = _FakeHttpClientAdapter(
    respostas: {
      path: {
        'error': {'code': code, 'message': message, 'details': <dynamic>[]},
      },
    },
    status: status,
  );
  authApiClient = AuthApiClient(dio: dio);
}

Map<String, dynamic> envelope(dynamic data, [Map<String, dynamic> meta = const {}]) => {
      'data': data,
      'meta': meta,
    };

/// Como [mockAuthApi], mas com um `Dio` já configurado pelo chamador (ex.:
/// um adapter que também captura o corpo enviado, para testes de integração
/// que precisam inspecionar exatamente o que foi mandado para a API).
void mockAuthApiComAdapter(Dio dio) {
  authApiClient = AuthApiClient(dio: dio);
}

/// Resposta falsa de uma rota do [mockAuthApiRotas].
class RespostaFalsa {
  const RespostaFalsa(this.corpo, {this.status = 200});

  final Map<String, dynamic> corpo;
  final int status;
}

/// Requisições recebidas pelo [mockAuthApiRotas], na ordem, para o teste
/// conferir método, caminho, query e corpo enviados.
final requisicoesAuthApi = <RequestOptions>[];

/// Como [mockAuthApi], mas com rotas por método e caminho (chave
/// `'POST /pesquisas-salvas'`), cada uma com seu status: para fluxos que
/// fazem várias chamadas autenticadas (ex.: GET 200 e POST 409).
void mockAuthApiRotas(Map<String, RespostaFalsa> rotas) {
  requisicoesAuthApi.clear();
  final dio = Dio();
  dio.httpClientAdapter = _RotasHttpClientAdapter(rotas);
  authApiClient = AuthApiClient(dio: dio);
}

class _RotasHttpClientAdapter implements HttpClientAdapter {
  _RotasHttpClientAdapter(this.rotas);

  final Map<String, RespostaFalsa> rotas;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requisicoesAuthApi.add(options);
    final caminho = options.uri.path;

    RespostaFalsa? resposta;
    for (final entrada in rotas.entries) {
      final partes = entrada.key.split(' ');
      if (partes[0] == options.method && caminho.endsWith(partes[1])) {
        resposta = entrada.value;
        break;
      }
    }

    resposta ??= RespostaFalsa(
      {
        'error': {'code': 'NOT_MOCKED', 'message': 'Sem mock para ${options.method} $caminho', 'details': <dynamic>[]},
      },
      status: 404,
    );

    return ResponseBody.fromBytes(
      utf8.encode(jsonEncode(resposta.corpo)),
      resposta.status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}

class _FakeHttpClientAdapter implements HttpClientAdapter {
  _FakeHttpClientAdapter({required this.respostas, required this.status});

  final Map<String, Map<String, dynamic>> respostas;
  final int status;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final caminho = options.uri.path;

    Map<String, dynamic>? corpo;
    for (final entrada in respostas.entries) {
      if (caminho.endsWith(entrada.key)) {
        corpo = entrada.value;
        break;
      }
    }

    final estatusFinal = corpo != null ? status : 404;
    final dados = corpo ??
        {
          'error': {'code': 'NOT_MOCKED', 'message': 'Sem mock para $caminho', 'details': <dynamic>[]},
        };

    final bytes = utf8.encode(jsonEncode(dados));
    return ResponseBody.fromBytes(
      bytes,
      estatusFinal,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}
