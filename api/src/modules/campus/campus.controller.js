const prisma = require('../../config/database');
const service = require('./campus.service');

async function obter(req, res, next) {
  try {
    const campus = await service.obterDetalhe(prisma, req.params.id, req);
    res.json({ data: campus, meta: {} });
  } catch (erro) {
    next(erro);
  }
}

module.exports = { obter };
