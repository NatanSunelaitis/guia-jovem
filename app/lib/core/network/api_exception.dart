/// Erro retornado pela API no envelope `{ "error": { code, message, details } }`.
/// Também representa falha de rede e resposta inválida, com mensagens para o
/// usuário, para as telas tratarem tudo num `on ApiException`.
class ApiException implements Exception {
  const ApiException({required this.code, required this.message, this.details = const []});

  /// A API não respondeu (fora do ar, sem internet, bloqueio do navegador).
  factory ApiException.semConexao() => const ApiException(
        code: 'SEM_CONEXAO',
        message: 'Não foi possível falar com o servidor. Confira sua conexão e tente de novo.',
      );

  /// A API respondeu algo fora do envelope esperado.
  factory ApiException.respostaInvalida([int? status]) => ApiException(
        code: 'RESPOSTA_INVALIDA',
        message: 'O servidor respondeu de um jeito inesperado${status != null ? ' (código $status)' : ''}. Tente de novo em instantes.',
      );

  final String code;
  final String message;
  final List<dynamic> details;

  @override
  String toString() => 'ApiException($code): $message';
}
