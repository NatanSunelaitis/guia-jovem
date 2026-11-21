const prisma = require('../../config/database');
const gestao = require('./campus.gestao.service');
const service = require('./campus.service');

async function obter(req, res, next) {
  try {
    const campus = await service.obterDetalhe(prisma, req.params.id, req);
    res.json({ data: campus, meta: {} });
  } catch (erro) {
    next(erro);
  }
}

async function listarCursos(req, res, next) {
  try {
    res.json(await service.listarCursos(prisma, req.params.id, req.query));
  } catch (erro) {
    next(erro);
  }
}

async function listarGestao(req, res, next) {
  try {
    res.json({ data: await gestao.listar(prisma, req.params.id), meta: {} });
  } catch (erro) {
    next(erro);
  }
}

async function criar(req, res, next) {
  try {
    res.status(201).json({ data: await gestao.criar(prisma, req.params.id, req.body, req), meta: {} });
  } catch (erro) {
    next(erro);
  }
}

async function atualizar(req, res, next) {
  try {
    res.json({ data: await gestao.atualizar(prisma, req.params.id, req.body, req), meta: {} });
  } catch (erro) {
    next(erro);
  }
}

async function excluir(req, res, next) {
  try {
    await gestao.excluir(prisma, req.params.id, req);
    res.json({ data: { sucesso: true }, meta: {} });
  } catch (erro) {
    next(erro);
  }
}

module.exports = { obter, listarCursos, listarGestao, criar, atualizar, excluir };
