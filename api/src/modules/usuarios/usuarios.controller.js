const prisma = require('../../config/database');
const service = require('./usuarios.service');

async function listar(req, res, next) {
  try {
    const resultado = await service.listar(prisma, req.query);
    res.json(resultado);
  } catch (erro) {
    next(erro);
  }
}

async function obter(req, res, next) {
  try {
    const usuario = await service.obter(prisma, req.params.id, req.user);
    res.json({ data: usuario, meta: {} });
  } catch (erro) {
    next(erro);
  }
}

async function criar(req, res, next) {
  try {
    const usuario = await service.criar(prisma, req.body, req);
    res.status(201).json({ data: usuario, meta: {} });
  } catch (erro) {
    next(erro);
  }
}

async function atualizar(req, res, next) {
  try {
    const usuario = await service.atualizar(prisma, req.params.id, req.body, req.user, req);
    res.json({ data: usuario, meta: {} });
  } catch (erro) {
    next(erro);
  }
}

async function alterarSenha(req, res, next) {
  try {
    await service.alterarSenha(prisma, req.params.id, req.body, req.user, req);
    res.json({ data: { sucesso: true }, meta: {} });
  } catch (erro) {
    next(erro);
  }
}

async function excluir(req, res, next) {
  try {
    await service.excluir(prisma, req.params.id, req.body, req.user, req);
    res.json({ data: { sucesso: true }, meta: {} });
  } catch (erro) {
    next(erro);
  }
}

module.exports = { listar, obter, criar, atualizar, alterarSenha, excluir };
