const prisma = require('../config/database');

/**
 * RF16: registra visita_pagina para estatísticas do site.
 * RNF07: sem dados pessoais, sem IP. Anexa `req.registrarVisita` para as
 * rotas públicas de catálogo chamarem ao servir uma página/detalhe.
 * A gravação é assíncrona e nunca bloqueia ou derruba a resposta.
 */
function metrics(req, res, next) {
  // `rota` substitui a rota da API quando a visita é de uma página do app
  // servida por outra chamada (ex.: a home, pelos destaques de universidades).
  req.registrarVisita = ({ entidade = null, entidadeId = null, rota = null } = {}) => {
    prisma.visitaPagina
      .create({
        data: {
          rota: rota ?? req.baseUrl + (req.route?.path ?? req.path),
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
