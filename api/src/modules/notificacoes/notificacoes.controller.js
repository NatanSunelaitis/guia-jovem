const prisma = require('../../config/database');
const service = require('./notificacoes.service');

async function listar(req, res, next) {
  try {
    res.json(await service.listar(prisma, req.user.id, req.query));
  } catch (erro) {
    next(erro);
  }
}

async function contarNaoLidas(req, res, next) {
  try {
    const total = await service.contarNaoLidas(prisma, req.user.id);
    res.json({ data: { naoLidas: total }, meta: {} });
  } catch (erro) {
    next(erro);
  }
}

async function marcarLida(req, res, next) {
  try {
    const notificacao = await service.marcarLida(prisma, req.params.id, req);
    res.json({ data: notificacao, meta: {} });
  } catch (erro) {
    next(erro);
  }
}

async function marcarTodasLidas(req, res, next) {
  try {
    const resultado = await service.marcarTodasLidas(prisma, req);
    res.json({ data: resultado, meta: {} });
  } catch (erro) {
    next(erro);
  }
}

module.exports = { listar, contarNaoLidas, marcarLida, marcarTodasLidas };
