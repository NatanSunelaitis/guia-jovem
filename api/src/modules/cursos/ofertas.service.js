const AppError = require('../../shared/errors/AppError');

/**
 * Oferta de curso em campus (RF20, classe OfertaCurso, tabela campus_curso):
 * turno e vagas. Curso e campus precisam ser da mesma universidade, e o par
 * curso e campus é único (chave primária da tabela), então cada curso tem no
 * máximo uma oferta por campus.
 */

function paraOferta(oferta) {
  return {
    cursoId: oferta.cursoId,
    campusId: oferta.campusId,
    campusNome: oferta.campus?.nome ?? null,
    turno: oferta.turno,
    vagas: oferta.vagas,
  };
}

function soCampos(oferta) {
  return { cursoId: oferta.cursoId, campusId: oferta.campusId, turno: oferta.turno, vagas: oferta.vagas };
}

const INCLUDE_OFERTA = { campus: { select: { id: true, nome: true } } };

async function buscarCurso(prisma, id) {
  const curso = await prisma.curso.findFirst({ where: { id, ativo: true }, select: { id: true, universidadeId: true } });
  if (!curso) throw AppError.notFound('Curso não encontrado');
  return curso;
}

async function buscarOferta(prisma, cursoId, campusId) {
  const oferta = await prisma.campusCurso.findUnique({
    where: { campusId_cursoId: { campusId, cursoId } },
    include: INCLUDE_OFERTA,
  });
  if (!oferta) throw AppError.notFound('Oferta não encontrada');
  return oferta;
}

/** Cursos ativos da universidade com as ofertas em campi ativos (painel da universidade). */
async function listarCursosComOfertas(prisma, universidadeId) {
  const universidade = await prisma.universidade.findUnique({ where: { id: universidadeId }, select: { id: true } });
  if (!universidade) throw AppError.notFound('Universidade não encontrada');

  const cursos = await prisma.curso.findMany({
    where: { universidadeId, ativo: true },
    include: {
      campusCursos: {
        where: { campus: { ativo: true } },
        include: INCLUDE_OFERTA,
        orderBy: { campusId: 'asc' },
      },
    },
    orderBy: [{ nome: 'asc' }, { id: 'asc' }],
  });

  return cursos.map((curso) => ({
    id: curso.id,
    nome: curso.nome,
    areaCurso: curso.areaCurso,
    notaMec: curso.notaMec,
    modalidade: curso.modalidade,
    grau: curso.grau,
    duracaoSemestres: curso.duracaoSemestres,
    descricao: curso.descricao,
    ofertas: curso.campusCursos.map(paraOferta),
  }));
}

async function criar(prisma, cursoId, { campusId, turno, vagas }, req) {
  const curso = await buscarCurso(prisma, cursoId);
  const campus = await prisma.campus.findFirst({ where: { id: campusId, ativo: true }, select: { universidadeId: true } });
  if (!campus || campus.universidadeId !== curso.universidadeId) {
    throw new AppError('CAMPUS_INVALIDO', 'Escolha um campus da mesma universidade do curso', 400);
  }

  try {
    return await prisma.$transaction(async (tx) => {
      const existente = await tx.campusCurso.findUnique({ where: { campusId_cursoId: { campusId, cursoId } } });
      if (existente) {
        throw AppError.conflict('OFERTA_DUPLICADA', 'Este curso já é ofertado neste campus. Edite a oferta existente.');
      }
      const oferta = await tx.campusCurso.create({
        data: { campusId, cursoId, turno, vagas: vagas ?? null },
        include: INCLUDE_OFERTA,
      });
      await req.registrarAuditoria(
        { acao: 'CREATE', entidade: 'campus_curso', entidadeId: cursoId, dadosDepois: soCampos(oferta) },
        tx,
      );
      return paraOferta(oferta);
    });
  } catch (erro) {
    // Duas ofertas iguais gravadas ao mesmo tempo: a chave primária decide.
    if (erro.code === 'P2002') {
      throw AppError.conflict('OFERTA_DUPLICADA', 'Este curso já é ofertado neste campus. Edite a oferta existente.');
    }
    throw erro;
  }
}

async function atualizar(prisma, cursoId, campusId, dados, req) {
  await buscarCurso(prisma, cursoId);
  const antes = await buscarOferta(prisma, cursoId, campusId);

  return prisma.$transaction(async (tx) => {
    const oferta = await tx.campusCurso.update({
      where: { campusId_cursoId: { campusId, cursoId } },
      data: dados,
      include: INCLUDE_OFERTA,
    });
    await req.registrarAuditoria(
      { acao: 'UPDATE', entidade: 'campus_curso', entidadeId: cursoId, dadosAntes: soCampos(antes), dadosDepois: soCampos(oferta) },
      tx,
    );
    return paraOferta(oferta);
  });
}

async function excluir(prisma, cursoId, campusId, req) {
  await buscarCurso(prisma, cursoId);
  const oferta = await buscarOferta(prisma, cursoId, campusId);

  await prisma.$transaction(async (tx) => {
    await tx.campusCurso.delete({ where: { campusId_cursoId: { campusId, cursoId } } });
    await req.registrarAuditoria(
      { acao: 'DELETE', entidade: 'campus_curso', entidadeId: cursoId, dadosAntes: soCampos(oferta) },
      tx,
    );
  });
}

/** Dono do curso para o ownership.middleware; 404 quando não existe. */
async function universidadeDoCurso(prisma, id) {
  return (await buscarCurso(prisma, id)).universidadeId;
}

module.exports = { listarCursosComOfertas, criar, atualizar, excluir, universidadeDoCurso };
