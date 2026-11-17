function list(prisma, { where, skip, take }) {
  return prisma.programa.findMany({
    where,
    orderBy: { criadoEm: 'asc' },
    skip,
    take,
  });
}

function count(prisma, where) {
  return prisma.programa.count({ where });
}

function destaques(prisma, take, tipo) {
  return prisma.programa.findMany({
    where: { ativo: true, ...(tipo ? { tipo } : {}) },
    orderBy: { criadoEm: 'asc' },
    take,
  });
}

function findDetalhePublicado(prisma, id) {
  return prisma.programa.findFirst({
    where: {
      id,
      ativo: true,
      OR: [{ universidadeId: null }, { universidade: { status: 'A' } }],
    },
    include: {
      eventos: { orderBy: { dataInicio: 'asc' } },
      universidades: {
        where: { universidade: { status: 'A' } },
        include: { universidade: { select: { id: true, nomeFantasia: true, logoUrl: true } } },
      },
    },
  });
}

module.exports = { list, count, destaques, findDetalhePublicado };
