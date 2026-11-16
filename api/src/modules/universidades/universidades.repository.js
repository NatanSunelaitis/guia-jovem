const RESUMO_CAMPUS_PRINCIPAL = {
  orderBy: { principal: 'desc' },
  take: 1,
  include: { endereco: true },
};

const RESUMO_PROGRAMAS = {
  take: 3,
  include: { programa: { select: { id: true, nome: true, sigla: true, tipo: true } } },
};

function list(prisma, { where, orderBy, skip, take }) {
  return prisma.universidade.findMany({
    where,
    orderBy,
    skip,
    take,
    include: {
      campus: RESUMO_CAMPUS_PRINCIPAL,
      universidadeProgramas: RESUMO_PROGRAMAS,
    },
  });
}

function count(prisma, where) {
  return prisma.universidade.count({ where });
}

function destaques(prisma, take) {
  return prisma.universidade.findMany({
    where: { status: 'A' },
    orderBy: [{ mediaAvaliacao: 'desc' }, { totalAvaliacoes: 'desc' }],
    take,
    include: {
      campus: RESUMO_CAMPUS_PRINCIPAL,
      universidadeProgramas: RESUMO_PROGRAMAS,
    },
  });
}

function findDetalhePublicado(prisma, id) {
  return prisma.universidade.findFirst({
    where: { id, status: 'A' },
    include: {
      campus: { include: { endereco: true } },
      universidadeProgramas: { include: { programa: true } },
    },
  });
}

function existeAprovada(prisma, id) {
  return prisma.universidade.findFirst({ where: { id, status: 'A' }, select: { id: true } });
}

function campusComCursos(prisma, universidadeId) {
  return prisma.campus.findMany({
    where: { universidadeId, ativo: true },
    include: {
      endereco: true,
      campusCursos: { include: { curso: true } },
    },
    orderBy: [{ principal: 'desc' }, { nome: 'asc' }],
  });
}

function cursosDaUniversidade(prisma, universidadeId) {
  return prisma.curso.findMany({
    where: { universidadeId, ativo: true },
    orderBy: { nome: 'asc' },
  });
}

function avaliacoes(prisma, universidadeId, { skip, take }) {
  return prisma.avaliacao.findMany({
    where: { universidadeId },
    include: { usuario: { select: { nome: true } } },
    orderBy: { criadoEm: 'desc' },
    skip,
    take,
  });
}

function countAvaliacoes(prisma, universidadeId) {
  return prisma.avaliacao.count({ where: { universidadeId } });
}

module.exports = {
  // Reaproveitados por favoritos.repository.js: o card da faculdade salva é o mesmo da pesquisa.
  RESUMO_CAMPUS_PRINCIPAL,
  RESUMO_PROGRAMAS,
  list,
  count,
  destaques,
  findDetalhePublicado,
  existeAprovada,
  campusComCursos,
  cursosDaUniversidade,
  avaliacoes,
  countAvaliacoes,
};
