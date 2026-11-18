const AppError = require('../../shared/errors/AppError');
const { buildMeta, parsePagination } = require('../../shared/utils/pagination');

/**
 * Cadastro de cursos pelo administrador (RF19, T24.4). Cada curso pertence a
 * uma universidade (curso.id_universidade); a oferta em campus (turno e
 * vagas) é outra relação (campus_curso, RF20). Exclusão lógica (ativo=false),
 * bloqueada enquanto o curso estiver ofertado em algum campus.
 */

const INCLUDE_ADMIN = {
  universidade: { select: { id: true, nomeFantasia: true } },
  _count: { select: { campusCursos: true } },
};

const CAMPOS = ['nome', 'areaCurso', 'notaMec', 'modalidade', 'grau', 'duracaoSemestres', 'descricao'];

function paraAdmin(curso) {
  return {
    id: curso.id,
    nome: curso.nome,
    areaCurso: curso.areaCurso,
    notaMec: curso.notaMec,
    modalidade: curso.modalidade,
    grau: curso.grau,
    duracaoSemestres: curso.duracaoSemestres,
    descricao: curso.descricao,
    universidade: curso.universidade,
    totalCampus: curso._count?.campusCursos ?? 0,
  };
}

function soCampos(curso) {
  const dados = {};
  for (const campo of CAMPOS) dados[campo] = curso[campo] ?? null;
  return dados;
}

async function listarAdmin(prisma, query) {
  const { page, pageSize, skip, take } = parsePagination(query);
  const where = {
    ativo: true,
    ...(query.busca ? { nome: { contains: query.busca } } : {}),
    ...(query.areaCurso ? { areaCurso: { contains: query.areaCurso } } : {}),
    ...(query.universidadeId ? { universidadeId: query.universidadeId } : {}),
  };

  const [cursos, total] = await Promise.all([
    prisma.curso.findMany({ where, include: INCLUDE_ADMIN, orderBy: [{ nome: 'asc' }, { id: 'asc' }], skip, take }),
    prisma.curso.count({ where }),
  ]);

  return { data: cursos.map(paraAdmin), meta: buildMeta({ page, pageSize, total }) };
}

async function buscarAtivo(prisma, id) {
  const curso = await prisma.curso.findFirst({ where: { id, ativo: true }, include: INCLUDE_ADMIN });
  if (!curso) throw AppError.notFound('Curso não encontrado');
  return curso;
}

async function obterAdmin(prisma, id) {
  return paraAdmin(await buscarAtivo(prisma, id));
}

async function criar(prisma, universidadeId, dados, req) {
  const universidade = await prisma.universidade.findUnique({ where: { id: universidadeId }, select: { id: true } });
  if (!universidade) throw AppError.notFound('Universidade não encontrada');

  return prisma.$transaction(async (tx) => {
    const curso = await tx.curso.create({ data: { ...dados, universidadeId }, include: INCLUDE_ADMIN });
    await req.registrarAuditoria(
      { acao: 'CREATE', entidade: 'curso', entidadeId: curso.id, dadosDepois: { universidadeId, ...soCampos(curso) } },
      tx,
    );
    return paraAdmin(curso);
  });
}

async function atualizar(prisma, id, dados, req) {
  const antes = await buscarAtivo(prisma, id);

  return prisma.$transaction(async (tx) => {
    const curso = await tx.curso.update({ where: { id }, data: dados, include: INCLUDE_ADMIN });
    await req.registrarAuditoria(
      { acao: 'UPDATE', entidade: 'curso', entidadeId: id, dadosAntes: soCampos(antes), dadosDepois: soCampos(curso) },
      tx,
    );
    return paraAdmin(curso);
  });
}

async function excluir(prisma, id, req) {
  const curso = await buscarAtivo(prisma, id);

  return prisma.$transaction(async (tx) => {
    // Conta de novo dentro da transação: uma oferta nova não escapa da regra.
    const ofertas = await tx.campusCurso.count({ where: { cursoId: id } });
    if (ofertas > 0) {
      throw AppError.conflict(
        'CURSO_OFERTADO',
        `Este curso está ofertado em ${ofertas} ${ofertas === 1 ? 'campus' : 'campi'}. Remova as ofertas antes de excluir.`,
      );
    }

    await tx.curso.update({ where: { id }, data: { ativo: false } });
    await req.registrarAuditoria(
      { acao: 'DELETE', entidade: 'curso', entidadeId: id, dadosAntes: soCampos(curso), dadosDepois: { ativo: false } },
      tx,
    );
  });
}

module.exports = { listarAdmin, obterAdmin, criar, atualizar, excluir };
