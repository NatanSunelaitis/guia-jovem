const AppError = require('../shared/errors/AppError');

// eslint-disable-next-line no-unused-vars
function errorHandler(err, req, res, next) {
  if (err instanceof AppError) {
    return res.status(err.statusCode).json({
      error: {
        code: err.code,
        message: err.message,
        details: err.details,
      },
    });
  }

  console.error(err);

  return res.status(500).json({
    error: {
      code: 'INTERNAL_ERROR',
      message: 'Erro interno. Tente novamente mais tarde.',
      details: [],
    },
  });
}

module.exports = errorHandler;
