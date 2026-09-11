const prisma = require('../config/database');

/**
 * RNF07: toda ação de escrita grava log_auditoria.
 * Anexa `req.registrarAuditoria` para os controllers/services chamarem
 * antes de responder, com o cliente Prisma (ou uma transação) desejado.
 */
function audit(req, res, next) {
  req.registrarAuditoria = ({ acao, entidade, entidadeId = null, dadosAntes = null, dadosDepois = null }, cliente = prisma) =>
    cliente.log_auditoria.create({
      data: {
        id_usuario: req.user?.id ?? null,
        acao,
        entidade,
        entidade_id: entidadeId,
        dados_antes: dadosAntes,
        dados_depois: dadosDepois,
        ip: req.ip,
      },
    });

  next();
}

module.exports = audit;
