const prisma = require('../../config/database');
const service = require('./estatisticas.service');

function responder(funcao) {
  return async function handler(req, res, next) {
    try {
      res.json({ data: await funcao(prisma, req.query), meta: {} });
    } catch (erro) {
      next(erro);
    }
  };
}

module.exports = {
  resumo: responder((prisma) => service.resumo(prisma)),
  visitas: responder((prisma, query) => service.visitas(prisma, query)),
  ranking: responder((prisma, query) => service.ranking(prisma, query)),
};
