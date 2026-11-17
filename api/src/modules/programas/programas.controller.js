const prisma = require('../../config/database');
const service = require('./programas.service');

async function listar(req, res, next) {
  try {
    const resultado = await service.listar(prisma, req.query);
    res.json(resultado);
  } catch (erro) {
    next(erro);
  }
}

async function destaques(req, res, next) {
  try {
    const programas = await service.listarDestaques(prisma, req.query.limite, req.query.tipo);
    res.json({ data: programas, meta: {} });
  } catch (erro) {
    next(erro);
  }
}

async function obter(req, res, next) {
  try {
    const programa = await service.obterDetalhe(prisma, req.params.id, req);
    res.json({ data: programa, meta: {} });
  } catch (erro) {
    next(erro);
  }
}

async function universidades(req, res, next) {
  try {
    const dados = await service.listarUniversidades(prisma, req.params.id);
    res.json({ data: dados, meta: {} });
  } catch (erro) {
    next(erro);
  }
}

module.exports = { listar, destaques, obter, universidades };
