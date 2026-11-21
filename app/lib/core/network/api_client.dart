import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'api_exception.dart';

/// Arquivo baixado da API (relatório da pesquisa, RF02).
class ArquivoBaixado {
  const ArquivoBaixado({required this.bytes, required this.nome, required this.tipo});

  final Uint8List bytes;
  final String nome;
  final String tipo;
}

/// Cliente HTTP fino para a API do Guia Jovem.
/// Decodifica o envelope `{ data, meta }` / `{ error }` (seção 3.5 da especificação).
/// Falha de rede e resposta fora do envelope também viram [ApiException],
/// para nenhuma tela ficar sem aviso quando a API não responde.
class ApiClient {
  ApiClient({String? baseUrl, http.Client? client})
      : baseUrl = baseUrl ?? const String.fromEnvironment('API_BASE_URL', defaultValue: kDefaultBaseUrl),
        _client = client ?? http.Client();

  static const kDefaultBaseUrl = 'http://localhost:3000/api/v1';

  final String baseUrl;
  final http.Client _client;

  Uri _uri(String path, Map<String, dynamic>? query) {
    final queryLimpa = <String, String>{
      for (final entrada in (query ?? {}).entries)
        if (entrada.value != null) entrada.key: entrada.value.toString(),
    };
    return Uri.parse('$baseUrl$path').replace(queryParameters: queryLimpa.isEmpty ? null : queryLimpa);
  }

  Future<http.Response> _enviar(Future<http.Response> Function() requisicao) async {
    try {
      return await requisicao();
    } catch (_) {
      throw ApiException.semConexao();
    }
  }

  Map<String, dynamic> _corpo(http.Response resposta) {
    if (resposta.body.isEmpty) return <String, dynamic>{};
    try {
      final corpo = jsonDecode(resposta.body);
      if (corpo is Map<String, dynamic>) return corpo;
    } on FormatException {
      // Cai no erro abaixo: a resposta não veio no envelope da API.
    }
    throw ApiException.respostaInvalida(resposta.statusCode);
  }

  Never _lancarErro(http.Response resposta) {
    final corpo = _corpo(resposta);
    final erro = corpo['error'] as Map<String, dynamic>? ?? {};
    throw ApiException(
      code: erro['code'] as String? ?? 'ERRO_DESCONHECIDO',
      message: erro['message'] as String? ?? 'Ocorreu um erro inesperado.',
      details: erro['details'] as List<dynamic>? ?? const [],
    );
  }

  Future<Map<String, dynamic>> get(String path, {Map<String, dynamic>? query}) async {
    final resposta = await _enviar(() => _client.get(_uri(path, query)));
    if (resposta.statusCode >= 400) _lancarErro(resposta);
    return _corpo(resposta);
  }

  /// Baixa um arquivo (CSV, PDF). O nome vem do Content-Disposition, que a
  /// API expõe no CORS; sem ele, usa [nomePadrao].
  Future<ArquivoBaixado> baixar(String path, {Map<String, dynamic>? query, required String nomePadrao}) async {
    final resposta = await _enviar(() => _client.get(_uri(path, query)));
    if (resposta.statusCode >= 400) _lancarErro(resposta);
    if (resposta.bodyBytes.isEmpty) throw ApiException.respostaInvalida(resposta.statusCode);
    final disposicao = resposta.headers['content-disposition'] ?? '';
    final nome = RegExp(r'filename="?([^";]+)"?').firstMatch(disposicao)?.group(1) ?? nomePadrao;
    return ArquivoBaixado(
      bytes: resposta.bodyBytes,
      nome: nome,
      tipo: (resposta.headers['content-type'] ?? 'application/octet-stream').split(';').first.trim(),
    );
  }
}

/// Instância compartilhada, usada por padrão pelos repositórios.
/// Não é `final`: os testes de widget substituem por uma instância com
/// `http.Client` mockado antes de montar a página.
ApiClient apiClient = ApiClient();
