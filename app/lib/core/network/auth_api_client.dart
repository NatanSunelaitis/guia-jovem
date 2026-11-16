import 'package:dio/dio.dart';

import '../storage/token_storage.dart';
import 'api_client.dart';
import 'api_exception.dart';

/// Cliente HTTP para os endpoints de sessão (`/auth/*`, seção 5.1), com dois
/// diferenciais que o `ApiClient` (http simples, usado pelo catálogo público)
/// não precisa: anexar o access token nas requisições e, quando a API
/// responde 401, tentar renovar a sessão via `/auth/refresh` e repetir a
/// requisição original uma única vez antes de desistir.
class AuthApiClient {
  AuthApiClient({String? baseUrl, Dio? dio})
      : baseUrl = baseUrl ?? const String.fromEnvironment('API_BASE_URL', defaultValue: ApiClient.kDefaultBaseUrl),
        _dio = dio ?? Dio() {
    _dio.options.baseUrl = this.baseUrl;
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await tokenStorage.lerAccessToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          final jaTentouRenovar = error.requestOptions.extra['gjRetentativa'] == true;
          final eraRotaDeRefresh = error.requestOptions.path.contains('/auth/refresh');

          if (error.response?.statusCode == 401 && !jaTentouRenovar && !eraRotaDeRefresh) {
            final renovou = await _tentarRenovarSessao();
            if (renovou) {
              try {
                final novoToken = await tokenStorage.lerAccessToken();
                final requisicaoRepetida = await _dio.fetch<dynamic>(
                  error.requestOptions
                    ..extra['gjRetentativa'] = true
                    ..headers['Authorization'] = 'Bearer $novoToken',
                );
                return handler.resolve(requisicaoRepetida);
              } on DioException catch (novoErro) {
                return handler.next(novoErro);
              }
            }
            onSessaoExpirada?.call();
          }

          handler.next(error);
        },
      ),
    );
  }

  static const kDefaultBaseUrl = ApiClient.kDefaultBaseUrl;

  final String baseUrl;
  final Dio _dio;

  /// Chamado quando o refresh falha (refresh token expirado/revogado): a
  /// sessão local deve ser encerrada. Ligado pelo SessionController.
  void Function()? onSessaoExpirada;

  Future<bool> _tentarRenovarSessao() async {
    final refreshToken = await tokenStorage.lerRefreshToken();
    if (refreshToken == null) return false;

    try {
      final resposta = await _dio.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
        options: Options(extra: {'gjRetentativa': true}),
      );
      final dados = resposta.data!['data'] as Map<String, dynamic>;
      await tokenStorage.salvar(
        accessToken: dados['accessToken'] as String,
        refreshToken: dados['refreshToken'] as String,
      );
      return true;
    } on DioException {
      await tokenStorage.limpar();
      return false;
    }
  }

  Map<String, dynamic> _corpoOuErro(Response<dynamic> resposta) {
    return (resposta.data as Map<String, dynamic>?) ?? <String, dynamic>{};
  }

  Never _lancarExcecaoDe(DioException erro) {
    final corpo = erro.response?.data as Map<String, dynamic>?;
    final erroCorpo = corpo?['error'] as Map<String, dynamic>?;
    if (erroCorpo != null) {
      throw ApiException(
        code: erroCorpo['code'] as String? ?? 'ERRO_DESCONHECIDO',
        message: erroCorpo['message'] as String? ?? 'Ocorreu um erro inesperado.',
        details: erroCorpo['details'] as List<dynamic>? ?? const [],
      );
    }
    throw const ApiException(code: 'ERRO_DESCONHECIDO', message: 'Não foi possível conectar ao servidor.');
  }

  Future<Map<String, dynamic>> post(String path, {Map<String, dynamic>? body}) async {
    try {
      final resposta = await _dio.post<Map<String, dynamic>>(path, data: body);
      return _corpoOuErro(resposta);
    } on DioException catch (erro) {
      _lancarExcecaoDe(erro);
    }
  }

  Future<Map<String, dynamic>> get(String path, {Map<String, dynamic>? query}) async {
    final queryLimpa = <String, dynamic>{
      for (final entrada in (query ?? {}).entries)
        if (entrada.value != null) entrada.key: entrada.value.toString(),
    };

    try {
      final resposta = await _dio.get<Map<String, dynamic>>(path, queryParameters: queryLimpa);
      return _corpoOuErro(resposta);
    } on DioException catch (erro) {
      _lancarExcecaoDe(erro);
    }
  }

  Future<Map<String, dynamic>> put(String path, {Map<String, dynamic>? body}) async {
    try {
      final resposta = await _dio.put<Map<String, dynamic>>(path, data: body);
      return _corpoOuErro(resposta);
    } on DioException catch (erro) {
      _lancarExcecaoDe(erro);
    }
  }

  Future<Map<String, dynamic>> delete(String path, {Map<String, dynamic>? body}) async {
    try {
      final resposta = await _dio.delete<Map<String, dynamic>>(path, data: body);
      return _corpoOuErro(resposta);
    } on DioException catch (erro) {
      _lancarExcecaoDe(erro);
    }
  }
}

/// Instância compartilhada; mutável para os testes substituírem por uma com
/// `Dio` configurado com um adapter falso.
AuthApiClient authApiClient = AuthApiClient();
