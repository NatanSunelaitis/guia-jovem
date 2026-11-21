const AppError = require('../../shared/errors/AppError');
const { buildMeta, parsePagination } = require('../../shared/utils/pagination');
const repo = require('./campus.repository');

async function obterDetalhe(prisma, id, req) {
  const campus = await repo.findDetalhePublicado(prisma, id);
  if (!campus) {
    throw AppError.notFound('Campus não encontrado');
  }
  const areas = await repo.areasDosCursos(prisma, id);

  req.registrarVisita({ entidade: 'campus', entidadeId: id });

  return {
    id: campus.id,
    nome: campus.nome,
    telefoneCelular: campus.telefoneCelular,
    telefoneFixo: campus.telefoneFixo,
    emailCampus: campus.emailCampus,
    principal: campus.principal,
    universidade: campus.universidade,
    endereco: {
      logradouro: campus.endereco.logradouro,
      numero: campus.endereco.numero,
      complemento: campus.endereco.complemento,
      bairro: campus.endereco.bairro,
      cidade: campus.endereco.cidade,
      estado: campus.endereco.estado,
      cep: campus.endereco.cep,
    },
    // Os cursos vêm paginados de GET /campus/:id/cursos.
    totalCursos: campus._count?.campusCursos ?? 0,
    areasCursos: areas,
  };
}

/** Cursos oferecidos no campus (T04), paginados, com busca e filtro por área. */
async function listarCursos(prisma, id, query = {}) {
  if (!(await repo.existePublicado(prisma, id))) {
    throw AppError.notFound('Campus não encontrado');
  }
  const { page, pageSize, skip, take } = parsePagination(query);
  const filtros = { q: query.q, areaCurso: query.areaCurso };
  const [ofertas, total] = await Promise.all([
    repo.cursosDoCampus(prisma, id, filtros, { skip, take }),
    repo.contarCursosDoCampus(prisma, id, filtros),
  ]);
  return {
    data: ofertas.map((cc) => ({
      id: cc.curso.id,
      nome: cc.curso.nome,
      areaCurso: cc.curso.areaCurso,
      grau: cc.curso.grau,
      modalidade: cc.curso.modalidade,
      turno: cc.turno,
      vagas: cc.vagas,
    })),
    meta: buildMeta({ page, pageSize, total }),
  };
}

module.exports = { obterDetalhe, listarCursos };
