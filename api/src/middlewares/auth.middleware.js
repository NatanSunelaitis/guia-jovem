const jwt = require('jsonwebtoken');

const env = require('../config/env');
const AppError = require('../shared/errors/AppError');

function auth(req, res, next) {
  const cabecalho = req.headers.authorization || '';
  const [tipo, token] = cabecalho.split(' ');

  if (tipo !== 'Bearer' || !token) {
    return next(AppError.unauthenticated());
  }

  try {
    const payload = jwt.verify(token, env.JWT_ACCESS_SECRET);
    req.user = {
      id: payload.sub,
      tipoUsuario: payload.tipoUsuario,
      universidadeId: payload.universidadeId ?? null,
    };
    return next();
  } catch (erro) {
    return next(AppError.unauthenticated('Sessão expirada ou inválida'));
  }
}

module.exports = auth;
