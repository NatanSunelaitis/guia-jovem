const prisma = require('../../config/database');
const { paraLista } = require('../universidades/universidades.service');
const service = require('./favoritos.service');

async function listar(req, res, next) {
  try {
    const resultado = await service.listar(prisma, req.user.id, req.query, paraLista);
    res.json(resultado);
  } catch (erro) {
    next(erro);
  }
}

async function salvar(req, res, next) {
  try {
    const { criada, dados } = await service.salvar(prisma, req.user.id, req.body.universidadeId, req);
    res.status(criada ? 201 : 200).json({ data: dados, meta: {} });
  } catch (erro) {
    next(erro);
  }
}

async function remover(req, res, next) {
  try {
    await service.remover(prisma, req.user.id, req.params.id, req);
    res.json({ data: { sucesso: true, universidadeId: req.params.id, salva: false }, meta: {} });
  } catch (erro) {
    next(erro);
  }
}

module.exports = { listar, salvar, remover };
