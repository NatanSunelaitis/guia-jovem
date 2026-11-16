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

/**
 * Para rotas públicas que mudam a resposta quando há sessão (ex.: detalhe da
 * universidade dizendo se o aluno já avaliou). Sem cabeçalho, segue como
 * visitante; com token inválido ou expirado, responde 401 para o app renovar
 * a sessão em vez de mostrar o estado de visitante.
 */
function opcional(req, res, next) {
  if (!req.headers.authorization) {
    return next();
  }
  return auth(req, res, next);
}

module.exports = auth;
module.exports.opcional = opcional;
