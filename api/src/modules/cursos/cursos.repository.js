const INCLUDE_UNIVERSIDADE = {
  universidade: { select: { id: true, nomeFantasia: true, logoUrl: true } },
};

// Página do curso (T06): cada oferta mostra a universidade com a natureza, a
// cidade do campus principal e os programas aceitos (com as bolsas
// institucionais dela), e os campi ativos onde o curso é dado.
const INCLUDE_OFERTA = {
  universidade: {
    select: {
      id: true,
      nomeFantasia: true,
      logoUrl: true,
      natureza: true,
      campus: {
        where: { ativo: true },
        orderBy: [{ principal: 'desc' }, { id: 'asc' }],
        take: 1,
        include: { endereco: true },
      },
      universidadeProgramas: { where: { programa: { ativo: true } }, include: { programa: true } },
      programas: { where: { ativo: true }, orderBy: { criadoEm: 'asc' } },
    },
  },
  campusCursos: {
    where: { campus: { ativo: true } },
    include: { campus: { include: { endereco: true } } },
    orderBy: { campusId: 'asc' },
  },
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

/** Campos para agrupar pelo nome, na ordem de cadastro (desempata a grafia e a área). */
function nomesAtivos(prisma, where) {
  return prisma.curso.findMany({
    where,
    select: { id: true, nome: true, areaCurso: true, grau: true, universidadeId: true },
    orderBy: { id: 'asc' },
  });
}

function findDetalhePublicado(prisma, id) {
  return prisma.curso.findFirst({
    where: { id, ativo: true, universidade: { status: 'A' } },
    include: INCLUDE_OFERTA,
  });
}

/** Ofertas da página do curso: os cursos do grupo, pelos ids. */
function findOfertas(prisma, ids) {
  return prisma.curso.findMany({
    where: { id: { in: ids } },
    include: INCLUDE_OFERTA,
    orderBy: [{ universidade: { nomeFantasia: 'asc' } }, { id: 'asc' }],
  });
}

/** Áreas distintas dos cursos ativos de universidades aprovadas. */
async function areas(prisma) {
  const linhas = await prisma.curso.findMany({
    where: { ativo: true, universidade: { status: 'A' }, areaCurso: { not: null } },
    select: { areaCurso: true },
    distinct: ['areaCurso'],
  });
  return linhas.map((l) => l.areaCurso).filter(Boolean).sort((a, b) => a.localeCompare(b, 'pt-BR'));
}

module.exports = { list, count, nomesAtivos, findDetalhePublicado, findOfertas, areas };
