import 'dart:convert';

import 'package:app/core/network/api_client.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Aponta o `apiClient` global (usado por padrão em todos os repositórios)
/// para um `MockClient`. [respostas] mapeia o path do request (ex.:
/// `/universidades/destaques`) para o corpo JSON já decodificado que a
/// API retornaria (o envelope `{data, meta}` completo).
void mockApi(Map<String, Map<String, dynamic>> respostas, {int status = 200}) {
  requisicoesApi.clear();
  apiClient = ApiClient(
    client: MockClient((request) async {
      requisicoesApi.add(request);
      // Uri.path não decodifica porcentagens (ex.: "Farm%C3%A1cia"
      // continua assim); pathSegments decodifica cada segmento.
      final caminho = '/${request.url.pathSegments.join('/')}';

      Map<String, dynamic>? corpo;
      for (final entrada in respostas.entries) {
        if (caminho.endsWith(entrada.key)) {
          corpo = entrada.value;
          break;
        }
      }
      if (corpo == null) {
        return http.Response(
          jsonEncode({
            'error': {'code': 'NOT_MOCKED', 'message': 'Sem mock para $caminho'},
          }),
          404,
        );
      }
      return http.Response(jsonEncode(corpo), status);
    }),
  );
}

/// Requisições recebidas pelo [mockApi], na ordem, para o teste conferir a query.
final requisicoesApi = <http.BaseRequest>[];

void mockApiError(String path, {String code = 'INTERNAL_ERROR', String message = 'Erro', int status = 500}) {
  apiClient = ApiClient(
    client: MockClient((request) async {
      return http.Response(
        jsonEncode({
          'error': {'code': code, 'message': message},
        }),
        status,
      );
    }),
  );
}

Map<String, dynamic> envelope(dynamic data, [Map<String, dynamic> meta = const {}]) => {
      'data': data,
      'meta': meta,
    };
