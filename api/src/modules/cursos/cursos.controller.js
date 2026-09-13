const prisma = require('../../config/database');
const service = require('./cursos.service');

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
    const cursos = await service.listarDestaques(prisma, req.query);
    res.json({ data: cursos, meta: {} });
  } catch (erro) {
    next(erro);
  }
}

async function obter(req, res, next) {
  try {
    const curso = await service.obterDetalhe(prisma, req.params.id);
    res.json({ data: curso, meta: {} });
  } catch (erro) {
    next(erro);
  }
}

async function obterPorNome(req, res, next) {
  try {
    const resultado = await service.obterPorNome(prisma, req.params.nome);
    res.json({ data: resultado, meta: {} });
  } catch (erro) {
    next(erro);
  }
}

module.exports = { listar, destaques, obter, obterPorNome };
