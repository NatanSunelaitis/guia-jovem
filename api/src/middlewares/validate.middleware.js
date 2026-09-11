const AppError = require('../shared/errors/AppError');

function formatarErrosZod(zodError) {
  return zodError.issues.map((issue) => ({
    campo: issue.path.join('.'),
    mensagem: issue.message,
  }));
}

/**
 * Valida partes da requisição (body, query, params) com schemas Zod.
 * Uso: validate({ body: schemaCriarUsuario, query: schemaPaginacao })
 */
function validate(schemas) {
  return function validateMiddleware(req, res, next) {
    for (const parte of ['body', 'query', 'params']) {
      const schema = schemas[parte];
      if (!schema) continue;

      const resultado = schema.safeParse(req[parte]);
      if (!resultado.success) {
        return next(AppError.validation(formatarErrosZod(resultado.error)));
      }

      req[parte] = resultado.data;
    }

    return next();
  };
}

module.exports = validate;
