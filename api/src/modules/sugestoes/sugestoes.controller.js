const prisma = require('../../config/database');
const service = require('./sugestoes.service');

async function criar(req, res, next) {
  try {
    const sugestao = await service.criar(prisma, req.body, req);
    res.status(201).json({ data: sugestao, meta: {} });
  } catch (erro) {
    next(erro);
  }
}

async function minhas(req, res, next) {
  try {
    res.json(await service.listarMinhas(prisma, req.user.id, req.query));
  } catch (erro) {
    next(erro);
  }
}

async function recebidas(req, res, next) {
  try {
    res.json(await service.listarRecebidas(prisma, req.user, req.query));
  } catch (erro) {
    next(erro);
  }
}

async function detalhe(req, res, next) {
  try {
    const sugestao = await service.obterDetalhe(prisma, req.params.id, req.user);
    res.json({ data: sugestao, meta: {} });
  } catch (erro) {
    next(erro);
  }
}

async function avaliar(req, res, next) {
  try {
    const sugestao = await service.avaliar(prisma, req.params.id, req.body, req);
    res.json({ data: sugestao, meta: {} });
  } catch (erro) {
    next(erro);
  }
}

module.exports = { criar, minhas, recebidas, detalhe, avaliar };
