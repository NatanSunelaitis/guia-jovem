const prisma = require('../../config/database');
const service = require('./universidades.service');

async function listar(req, res, next) {
  try {
    const resultado = await service.listar(prisma, req.query, req.user);
    res.json(resultado);
  } catch (erro) {
    next(erro);
  }
}

async function destaques(req, res, next) {
  try {
    const universidades = await service.listarDestaques(prisma, req.query.limite);
    res.json({ data: universidades, meta: {} });
  } catch (erro) {
    next(erro);
  }
}

async function obter(req, res, next) {
  try {
    const universidade = await service.obterDetalhe(prisma, req.params.id, req);
    res.json({ data: universidade, meta: {} });
  } catch (erro) {
    next(erro);
  }
}

async function campus(req, res, next) {
  try {
    const dados = await service.listarCampus(prisma, req.params.id);
    res.json({ data: dados, meta: {} });
  } catch (erro) {
    next(erro);
  }
}

async function cursos(req, res, next) {
  try {
    const dados = await service.listarCursos(prisma, req.params.id);
    res.json({ data: dados, meta: {} });
  } catch (erro) {
    next(erro);
  }
}

async function avaliacoes(req, res, next) {
  try {
    const resultado = await service.listarAvaliacoes(prisma, req.params.id, req.query);
    res.json(resultado);
  } catch (erro) {
    next(erro);
  }
}

module.exports = { listar, destaques, obter, campus, cursos, avaliacoes };
