const prisma = require('../config/database');

/**
 * RF18: registra visita_pagina para estatísticas do site.
 * RNF24: sem dados pessoais, sem IP. Anexa `req.registrarVisita` para as
 * rotas públicas de catálogo chamarem ao servir uma página/detalhe.
 * A gravação é assíncrona e nunca bloqueia ou derruba a resposta.
 */
function metrics(req, res, next) {
  req.registrarVisita = ({ entidade = null, entidadeId = null } = {}) => {
    prisma.visitaPagina
      .create({
        data: {
          rota: req.baseUrl + (req.route?.path ?? req.path),
          entidade,
          entidadeId,
          tipoUsuario: req.user?.tipoUsuario ?? null,
        },
      })
      .catch((erro) => {
        console.error('Falha ao registrar visita_pagina:', erro.message);
      });
  };

  next();
}

module.exports = metrics;
