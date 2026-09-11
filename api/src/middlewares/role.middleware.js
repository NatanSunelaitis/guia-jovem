const AppError = require('../shared/errors/AppError');

function requireRole(...tiposPermitidos) {
  return function roleMiddleware(req, res, next) {
    if (!req.user) {
      return next(AppError.unauthenticated());
    }

    if (!tiposPermitidos.includes(req.user.tipoUsuario)) {
      return next(AppError.forbidden());
    }

    return next();
  };
}

module.exports = requireRole;
