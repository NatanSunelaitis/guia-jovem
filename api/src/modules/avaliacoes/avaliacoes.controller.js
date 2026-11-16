const prisma = require('../../config/database');
const service = require('./avaliacoes.service');

async function criar(req, res, next) {
  try {
    const avaliacao = await service.criar(prisma, req.params.id, req.body, req);
    res.status(201).json({ data: avaliacao, meta: {} });
  } catch (erro) {
    next(erro);
  }
}

async function atualizar(req, res, next) {
  try {
    const avaliacao = await service.atualizar(prisma, req.params.id, req.body, req);
    res.json({ data: avaliacao, meta: {} });
  } catch (erro) {
    next(erro);
  }
}

async function excluir(req, res, next) {
  try {
    const resultado = await service.excluir(prisma, req.params.id, req);
    res.json({ data: { sucesso: true, ...resultado }, meta: {} });
  } catch (erro) {
    next(erro);
  }
}

async function minhas(req, res, next) {
  try {
    const resultado = await service.listarMinhas(prisma, req.user.id, req.query);
    res.json(resultado);
  } catch (erro) {
    next(erro);
  }
}

/** Para o ownership.middleware (porUsuario): dono da avaliação do :id. */
function resolverDono(req) {
  return service.donoDaAvaliacao(prisma, req.params.id);
}

module.exports = { criar, atualizar, excluir, minhas, resolverDono };
