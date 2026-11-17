const INCLUDE_RELACOES = {
  universidade: { select: { id: true, nomeFantasia: true, usuarioId: true } },
  usuario: { select: { id: true, nome: true } },
};

function universidadeAprovada(prisma, id) {
  return prisma.universidade.findFirst({
    where: { id, status: 'A' },
    select: { id: true, nomeFantasia: true, usuarioId: true },
  });
}

function create(tx, data) {
  return tx.sugestao.create({ data, include: INCLUDE_RELACOES });
}

function findById(prisma, id) {
  return prisma.sugestao.findUnique({ where: { id }, include: INCLUDE_RELACOES });
}

function list(prisma, { where, skip, take }) {
  return prisma.sugestao.findMany({
    where,
    include: INCLUDE_RELACOES,
    orderBy: [{ criadoEm: 'desc' }, { id: 'desc' }],
    skip,
    take,
  });
}

function count(prisma, where) {
  return prisma.sugestao.count({ where });
}

/**
 * Grava a avaliação só se a sugestão ainda estiver "Em análise": duas
 * avaliações simultâneas não se sobrescrevem, a segunda atualiza 0 linhas.
 */
function avaliarSeEmAnalise(tx, id, data) {
  return tx.sugestao.updateMany({ where: { id, status: 'EM_ANALISE' }, data });
}

module.exports = { universidadeAprovada, create, findById, list, count, avaliarSeEmAnalise };
