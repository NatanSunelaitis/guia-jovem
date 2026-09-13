/// Erro retornado pela API no envelope `{ "error": { code, message, details } }`.
class ApiException implements Exception {
  const ApiException({required this.code, required this.message, this.details = const []});

  final String code;
  final String message;
  final List<dynamic> details;

  @override
  String toString() => 'ApiException($code): $message';
}
