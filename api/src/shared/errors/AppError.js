class AppError extends Error {
  constructor(code, message, statusCode = 400, details = []) {
    super(message);
    this.code = code;
    this.statusCode = statusCode;
    this.details = details;
  }

  static validation(details) {
    return new AppError('VALIDATION_ERROR', 'Dados inválidos', 400, details);
  }

  static unauthenticated(message = 'Não autenticado') {
    return new AppError('UNAUTHENTICATED', message, 401);
  }

  static forbidden(message = 'Acesso não permitido') {
    return new AppError('FORBIDDEN', message, 403);
  }

  static notFound(message = 'Recurso não encontrado') {
    return new AppError('NOT_FOUND', message, 404);
  }

  static conflict(code, message) {
    return new AppError(code, message, 409);
  }
}

module.exports = AppError;
