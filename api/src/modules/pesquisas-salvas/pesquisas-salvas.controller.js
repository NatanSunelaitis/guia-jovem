const prisma = require('../../config/database');
const service = require('./pesquisas-salvas.service');

async function criar(req, res, next) {
  try {
    const pesquisa = await service.criar(prisma, req.user.id, req.body, req);
    res.status(201).json({ data: pesquisa, meta: {} });
  } catch (erro) {
    next(erro);
  }
}

async function listar(req, res, next) {
  try {
    const resultado = await service.listar(prisma, req.user.id, req.query);
    res.json(resultado);
  } catch (erro) {
    next(erro);
  }
}

async function obter(req, res, next) {
  try {
    const pesquisa = await service.obter(prisma, req.params.id);
    res.json({ data: pesquisa, meta: {} });
  } catch (erro) {
    next(erro);
  }
}

async function excluir(req, res, next) {
  try {
    await service.excluir(prisma, req.params.id, req);
    res.json({ data: { sucesso: true }, meta: {} });
  } catch (erro) {
    next(erro);
  }
}

/** Para o ownership.middleware (porUsuario): dono da pesquisa do :id. */
function resolverDono(req) {
  return service.donoDaPesquisa(prisma, req.params.id);
}

module.exports = { criar, listar, obter, excluir, resolverDono };
