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
