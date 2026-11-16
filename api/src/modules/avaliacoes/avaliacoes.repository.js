function findById(prisma, id) {
  return prisma.avaliacao.findUnique({ where: { id } });
}

function findDoUsuario(prisma, usuarioId, universidadeId) {
  return prisma.avaliacao.findUnique({
    where: { usuarioId_universidadeId: { usuarioId, universidadeId } },
  });
}

function universidadeAprovada(prisma, id) {
  return prisma.universidade.findFirst({ where: { id, status: 'A' }, select: { id: true } });
}

/**
 * Trava a linha da universidade até o fim da transação: duas avaliações
 * simultâneas da mesma universidade recalculam a média uma depois da outra,
 * cada uma enxergando a gravação da anterior.
 */
function travarUniversidade(tx, universidadeId) {
  return tx.$queryRaw`SELECT id_universidade FROM universidade WHERE id_universidade = ${universidadeId} FOR UPDATE`;
}

function agregarNotas(tx, universidadeId) {
  return tx.avaliacao.aggregate({
    where: { universidadeId },
    _avg: { nota: true },
    _count: { _all: true },
  });
}

function atualizarMedia(tx, universidadeId, { mediaAvaliacao, totalAvaliacoes }) {
  return tx.universidade.update({
    where: { id: universidadeId },
    data: { mediaAvaliacao, totalAvaliacoes },
    select: { id: true, mediaAvaliacao: true, totalAvaliacoes: true },
  });
}

function create(tx, data) {
  return tx.avaliacao.create({ data });
}

function update(tx, id, data) {
  return tx.avaliacao.update({ where: { id }, data });
}

function remove(tx, id) {
  return tx.avaliacao.delete({ where: { id } });
}

function listDoUsuario(prisma, usuarioId, { skip, take }) {
  return prisma.avaliacao.findMany({
    where: { usuarioId },
    include: { universidade: { select: { id: true, nomeFantasia: true, logoUrl: true } } },
    orderBy: { criadoEm: 'desc' },
    skip,
    take,
  });
}

function countDoUsuario(prisma, usuarioId) {
  return prisma.avaliacao.count({ where: { usuarioId } });
}

module.exports = {
  findById,
  findDoUsuario,
  universidadeAprovada,
  travarUniversidade,
  agregarNotas,
  atualizarMedia,
  create,
  update,
  remove,
  listDoUsuario,
  countDoUsuario,
};
