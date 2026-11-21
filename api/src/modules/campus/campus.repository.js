const CURSO_ATIVO = { curso: { ativo: true } };

function findDetalhePublicado(prisma, id) {
  return prisma.campus.findFirst({
    where: { id, ativo: true, universidade: { status: 'A' } },
    include: {
      endereco: true,
      universidade: { select: { id: true, nomeFantasia: true } },
      // A lista de cursos é paginada em /campus/:id/cursos; aqui só o total.
      _count: { select: { campusCursos: { where: CURSO_ATIVO } } },
    },
  });
}

function existePublicado(prisma, id) {
  return prisma.campus.findFirst({
    where: { id, ativo: true, universidade: { status: 'A' } },
    select: { id: true },
  });
}

/** Áreas dos cursos ativos do campus, para o filtro da página. */
async function areasDosCursos(prisma, campusId) {
  const ofertas = await prisma.campusCurso.findMany({
    where: { campusId, ...CURSO_ATIVO },
    select: { curso: { select: { areaCurso: true } } },
  });
  return [...new Set(ofertas.map((o) => o.curso.areaCurso).filter(Boolean))].sort((a, b) => a.localeCompare(b, 'pt-BR'));
}

// Busca por nome sem diferenciar maiúsculas nem acentos (collation do MySQL).
function whereCursos(campusId, { q, areaCurso }) {
  return {
    campusId,
    curso: {
      ativo: true,
      ...(q ? { nome: { contains: q } } : {}),
      ...(areaCurso ? { areaCurso } : {}),
    },
  };
}

function cursosDoCampus(prisma, campusId, filtros, { skip, take }) {
  return prisma.campusCurso.findMany({
    where: whereCursos(campusId, filtros),
    include: { curso: true },
    orderBy: { curso: { nome: 'asc' } },
    skip,
    take,
  });
}

function contarCursosDoCampus(prisma, campusId, filtros) {
  return prisma.campusCurso.count({ where: whereCursos(campusId, filtros) });
}

module.exports = { findDetalhePublicado, existePublicado, areasDosCursos, cursosDoCampus, contarCursosDoCampus };
