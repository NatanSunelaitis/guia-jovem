const INCLUDE_UNIVERSIDADE = {
  universidade: { select: { id: true, nomeFantasia: true, logoUrl: true } },
};

function list(prisma, { where, skip, take }) {
  return prisma.curso.findMany({
    where,
    include: INCLUDE_UNIVERSIDADE,
    orderBy: { nome: 'asc' },
    skip,
    take,
  });
}

function count(prisma, where) {
  return prisma.curso.count({ where });
}

function nomesAtivos(prisma, where) {
  return prisma.curso.findMany({
    where,
    select: { nome: true, areaCurso: true },
  });
}

function findDetalhePublicado(prisma, id) {
  return prisma.curso.findFirst({
    where: { id, ativo: true, universidade: { status: 'A' } },
    include: {
      ...INCLUDE_UNIVERSIDADE,
      campusCursos: { include: { campus: { include: { endereco: true } } } },
    },
  });
}

function findPorNome(prisma, nome) {
  return prisma.curso.findMany({
    where: { nome: { equals: nome }, ativo: true, universidade: { status: 'A' } },
    include: {
      ...INCLUDE_UNIVERSIDADE,
      campusCursos: { include: { campus: { include: { endereco: true } } } },
    },
  });
}

module.exports = { list, count, nomesAtivos, findDetalhePublicado, findPorNome };
