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
    // Só programas globais: bolsas institucionais ficam no perfil da universidade (RF11).
    where: { ativo: true, universidadeId: null, ...(tipo ? { tipo } : {}) },
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
      universidade: { select: { id: true, nomeFantasia: true, logoUrl: true } },
      // Só uma prévia: a lista completa é paginada em /programas/:id/universidades.
      universidades: {
        where: { universidade: { status: 'A' } },
        include: { universidade: { select: SELECT_UNIVERSIDADE } },
        orderBy: { universidade: { nomeFantasia: 'asc' } },
        take: PREVIA_UNIVERSIDADES,
      },
      _count: { select: { universidades: { where: { universidade: { status: 'A' } } } } },
    },
  });
}

const PREVIA_UNIVERSIDADES = 8;

// Universidade que aceita o programa, com a cidade do campus principal.
const SELECT_UNIVERSIDADE = {
  id: true,
  nomeFantasia: true,
  logoUrl: true,
  campus: {
    where: { ativo: true },
    orderBy: [{ principal: 'desc' }, { id: 'asc' }],
    take: 1,
    select: { endereco: { select: { cidade: true, estado: true } } },
  },
};

function existePublicado(prisma, id) {
  return prisma.programa.findFirst({
    where: { id, ativo: true, OR: [{ universidadeId: null }, { universidade: { status: 'A' } }] },
    select: { id: true },
  });
}

/**
 * Universidades aprovadas que aceitam o programa, por nome, com busca por
 * nome ou cidade de qualquer campus ativo (a collation do MySQL ignora
 * maiúsculas e acentos).
 */
function whereUniversidades(programaId, q) {
  const universidade = { status: 'A' };
  if (q) {
    universidade.OR = [
      { nomeFantasia: { contains: q } },
      { razaoSocial: { contains: q } },
      { campus: { some: { ativo: true, endereco: { cidade: { contains: q } } } } },
    ];
  }
  return { programaId, universidade };
}

function universidadesQueAceitam(prisma, programaId, { q, skip, take }) {
  return prisma.universidadePrograma.findMany({
    where: whereUniversidades(programaId, q),
    include: { universidade: { select: SELECT_UNIVERSIDADE } },
    orderBy: { universidade: { nomeFantasia: 'asc' } },
    skip,
    take,
  });
}

function contarUniversidadesQueAceitam(prisma, programaId, q) {
  return prisma.universidadePrograma.count({ where: whereUniversidades(programaId, q) });
}

module.exports = {
  list,
  count,
  destaques,
  findDetalhePublicado,
  existePublicado,
  universidadesQueAceitam,
  contarUniversidadesQueAceitam,
};
