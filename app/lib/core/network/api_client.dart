import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_exception.dart';

/// Cliente HTTP fino para a API do Guia Jovem.
/// Decodifica o envelope `{ data, meta }` / `{ error }` (seção 3.5 da especificação).
class ApiClient {
  ApiClient({String? baseUrl, http.Client? client})
      : baseUrl = baseUrl ?? const String.fromEnvironment('API_BASE_URL', defaultValue: kDefaultBaseUrl),
        _client = client ?? http.Client();

  static const kDefaultBaseUrl = 'http://localhost:3000/api/v1';

  final String baseUrl;
  final http.Client _client;

  Future<Map<String, dynamic>> get(String path, {Map<String, dynamic>? query}) async {
    final queryLimpa = <String, String>{
      for (final entrada in (query ?? {}).entries)
        if (entrada.value != null) entrada.key: entrada.value.toString(),
    };

    final uri = Uri.parse('$baseUrl$path').replace(
      queryParameters: queryLimpa.isEmpty ? null : queryLimpa,
    );

    final resposta = await _client.get(uri);
    final corpo = resposta.body.isEmpty ? <String, dynamic>{} : jsonDecode(resposta.body) as Map<String, dynamic>;

    if (resposta.statusCode >= 400) {
      final erro = corpo['error'] as Map<String, dynamic>? ?? {};
      throw ApiException(
        code: erro['code'] as String? ?? 'ERRO_DESCONHECIDO',
        message: erro['message'] as String? ?? 'Ocorreu um erro inesperado.',
        details: erro['details'] as List<dynamic>? ?? const [],
      );
    }

    return corpo;
  }
}

/// Instância compartilhada, usada por padrão pelos repositórios.
/// Não é `final`: os testes de widget substituem por uma instância com
/// `http.Client` mockado antes de montar a página.
ApiClient apiClient = ApiClient();
