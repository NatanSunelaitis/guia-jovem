const AppError = require('../../shared/errors/AppError');
const { buildMeta, parsePagination } = require('../../shared/utils/pagination');
const repo = require('./notificacoes.repository');

/**
 * RF14: grava a mesma notificação para cada destinatário. `cliente` pode ser
 * o Prisma ou uma transação, para a notificação nascer junto com o registro
 * que a originou. `referenciaTipo` + `referenciaId` dizem ao app o que abrir
 * (ex.: `sugestao` 12).
 */
async function notificar(cliente, usuariosIds, { tipo, titulo, mensagem, referenciaTipo = null, referenciaId = null }) {
  const destinatarios = [...new Set(usuariosIds.filter((id) => id != null))];
  if (destinatarios.length === 0) return 0;

  await repo.criarVarias(
    cliente,
    destinatarios.map((usuarioId) => ({ usuarioId, tipo, titulo, mensagem, referenciaTipo, referenciaId })),
  );
  return destinatarios.length;
}

/** Destinatários das notificações para "a administração": todo D ativo. */
function idsAdministradoresAtivos(cliente) {
  return repo.idsAdministradoresAtivos(cliente);
}

function paraPublico(notificacao) {
  return {
    id: notificacao.id,
    tipo: notificacao.tipo,
    titulo: notificacao.titulo,
    mensagem: notificacao.mensagem,
    referenciaTipo: notificacao.referenciaTipo,
    referenciaId: notificacao.referenciaId,
    lida: notificacao.lida,
    criadoEm: notificacao.criadoEm,
  };
}

async function listar(prisma, usuarioId, query) {
  const { page, pageSize, skip, take } = parsePagination(query);
  const where = query.lida === undefined ? {} : { lida: query.lida };

  const [notificacoes, total, naoLidas] = await Promise.all([
    repo.listDoUsuario(prisma, usuarioId, { where, skip, take }),
    repo.countDoUsuario(prisma, usuarioId, where),
    repo.countDoUsuario(prisma, usuarioId, { lida: false }),
  ]);

  return {
    data: notificacoes.map(paraPublico),
    meta: { ...buildMeta({ page, pageSize, total }), naoLidas },
  };
}

function contarNaoLidas(prisma, usuarioId) {
  return repo.countDoUsuario(prisma, usuarioId, { lida: false });
}

async function marcarLida(prisma, id, req) {
  const notificacao = await repo.findById(prisma, id);
  if (!notificacao) {
    throw AppError.notFound('Notificação não encontrada');
  }
  if (notificacao.usuarioId !== req.user.id) {
    throw AppError.forbidden();
  }
  if (notificacao.lida) {
    return paraPublico(notificacao);
  }

  const atualizada = await repo.marcarLida(prisma, id);
  await req.registrarAuditoria({
    acao: 'UPDATE',
    entidade: 'notificacao',
    entidadeId: id,
    dadosAntes: { lida: false },
    dadosDepois: { lida: true },
  });
  return paraPublico(atualizada);
}

async function marcarTodasLidas(prisma, req) {
  const { count } = await repo.marcarTodasLidas(prisma, req.user.id);
  if (count > 0) {
    await req.registrarAuditoria({
      acao: 'UPDATE',
      entidade: 'notificacao',
      dadosDepois: { lida: true, quantidade: count },
    });
  }
  return { atualizadas: count };
}

module.exports = {
  notificar,
  idsAdministradoresAtivos,
  paraPublico,
  listar,
  contarNaoLidas,
  marcarLida,
  marcarTodasLidas,
};
