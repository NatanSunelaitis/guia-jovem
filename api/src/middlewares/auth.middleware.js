const jwt = require('jsonwebtoken');

const prisma = require('../config/database');
const env = require('../config/env');
const AppError = require('../shared/errors/AppError');

/**
 * Valida o access token e confere no banco que a conta ainda existe e está
 * ativa: conta inativada ou excluída perde o acesso na hora, sem esperar o
 * token expirar (até 15 minutos).
 */
async function auth(req, res, next) {
  const cabecalho = req.headers.authorization || '';
  const [tipo, token] = cabecalho.split(' ');

  if (tipo !== 'Bearer' || !token) {
    return next(AppError.unauthenticated());
  }

  let payload;
  try {
    payload = jwt.verify(token, env.JWT_ACCESS_SECRET);
  } catch (erro) {
    return next(AppError.unauthenticated('Sessão expirada ou inválida'));
  }

  try {
    const contaAtiva = await prisma.usuario.findFirst({
      where: { id: payload.sub, ativo: true },
      select: { id: true },
    });
    if (!contaAtiva) {
      return next(AppError.unauthenticated('Conta inativa ou excluída'));
    }
  } catch (erro) {
    return next(erro);
  }

  req.user = {
    id: payload.sub,
    tipoUsuario: payload.tipoUsuario,
    universidadeId: payload.universidadeId ?? null,
  };
  return next();
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
