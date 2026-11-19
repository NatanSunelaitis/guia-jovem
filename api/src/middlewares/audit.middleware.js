const prisma = require('../config/database');

/**
 * RNF09: toda ação de escrita grava log_auditoria.
 * Anexa `req.registrarAuditoria` para os controllers/services chamarem
 * antes de responder, com o cliente Prisma (ou uma transação) desejado.
 */
function audit(req, res, next) {
  req.registrarAuditoria = (
    { acao, entidade, entidadeId = null, dadosAntes = null, dadosDepois = null },
    cliente = prisma,
  ) =>
    cliente.logAuditoria.create({
      data: {
        usuarioId: req.user?.id ?? null,
        acao,
        entidade,
        entidadeId,
        dadosAntes,
        dadosDepois,
        ip: req.ip,
      },
    });

  next();
}

module.exports = audit;
