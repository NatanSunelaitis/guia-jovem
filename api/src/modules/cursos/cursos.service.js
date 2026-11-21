const AppError = require('../../shared/errors/AppError');
const { buildMeta, parsePagination } = require('../../shared/utils/pagination');
const repo = require('./cursos.repository');
const { agruparProgramasPorTipo } = require('../universidades/universidades.service');

const DESTAQUES_PADRAO = 8;

function paraLista(curso) {
  return {
    id: curso.id,
    nome: curso.nome,
    areaCurso: curso.areaCurso,
    modalidade: curso.modalidade,
    grau: curso.grau,
    universidade: curso.universidade,
  };
}

function buildWhere(query) {
  const where = { ativo: true, universidade: { status: 'A' } };

  if (query.q) where.nome = { contains: query.q };
  if (query.areaCurso) where.areaCurso = { contains: query.areaCurso };
  if (query.modalidade) where.modalidade = query.modalidade;
  if (query.grau) where.grau = query.grau;
  if (query.universidadeId) where.universidadeId = query.universidadeId;

  if (query.cidade || query.estado) {
    where.campusCursos = {
      some: {
        campus: {
          endereco: {
            ...(query.cidade ? { cidade: { contains: query.cidade } } : {}),
            ...(query.estado ? { estado: query.estado.toUpperCase() } : {}),
          },
        },
      },
    };
  }

  return where;
}

async function listar(prisma, query) {
  const { page, pageSize, skip, take } = parsePagination(query);
  const where = buildWhere(query);

  const [cursos, total] = await Promise.all([
    repo.list(prisma, { where, skip, take }),
    repo.count(prisma, where),
  ]);

  return { data: cursos.map(paraLista), meta: buildMeta({ page, pageSize, total }) };
}

async function listarDestaques(prisma, { limite = DESTAQUES_PADRAO, q, areaCurso } = {}) {
  const where = buildWhere({ q, areaCurso });
  const cursos = await repo.nomesAtivos(prisma, where);

  const contagemPorNome = new Map();
  const areaPorNome = new Map();
  for (const { nome, areaCurso } of cursos) {
    contagemPorNome.set(nome, (contagemPorNome.get(nome) ?? 0) + 1);
    if (!areaPorNome.has(nome)) areaPorNome.set(nome, areaCurso);
  }

  return [...contagemPorNome.entries()]
    .sort((a, b) => b[1] - a[1])
    .slice(0, limite)
    .map(([nome, totalOfertas]) => ({ nome, areaCurso: areaPorNome.get(nome), totalOfertas }));
}

function paraCampus(campusCurso) {
  return {
    id: campusCurso.campus.id,
    nome: campusCurso.campus.nome,
    cidade: campusCurso.campus.endereco.cidade,
    estado: campusCurso.campus.endereco.estado,
    turno: campusCurso.turno,
    vagas: campusCurso.vagas,
  };
}

/** Universidade da oferta, com a cidade do campus principal (card do T06). */
function paraUniversidade(universidade) {
  const principal = universidade.campus?.[0] ?? null;
  return {
    id: universidade.id,
    nomeFantasia: universidade.nomeFantasia,
    logoUrl: universidade.logoUrl,
    natureza: universidade.natureza ?? null,
    cidade: principal?.endereco.cidade ?? null,
    estado: principal?.endereco.estado ?? null,
  };
}

/**
 * Uma oferta do curso (cada curso pertence a uma universidade): dados do
 * curso, campi ativos com turno e vagas e os programas que a universidade
 * aceita, agrupados por tipo, com as bolsas institucionais dela.
 */
function paraOferta(curso) {
  return {
    cursoId: curso.id,
    areaCurso: curso.areaCurso,
    grau: curso.grau,
    modalidade: curso.modalidade,
    duracaoSemestres: curso.duracaoSemestres,
    notaMec: curso.notaMec,
    descricao: curso.descricao,
    universidade: paraUniversidade(curso.universidade),
    campus: curso.campusCursos.map(paraCampus),
    programas: agruparProgramasPorTipo(curso.universidade.universidadeProgramas ?? [], curso.universidade.programas ?? []),
  };
}

function paraDetalhe(curso) {
  const oferta = paraOferta(curso);
  return {
    id: curso.id,
    nome: curso.nome,
    areaCurso: curso.areaCurso,
    notaMec: curso.notaMec,
    modalidade: curso.modalidade,
    grau: curso.grau,
    duracaoSemestres: curso.duracaoSemestres,
    descricao: curso.descricao,
    universidade: oferta.universidade,
    campus: oferta.campus,
    programas: oferta.programas,
  };
}

async function obterDetalhe(prisma, id, req) {
  const curso = await repo.findDetalhePublicado(prisma, id);
  if (!curso) {
    throw AppError.notFound('Curso não encontrado');
  }

  req.registrarVisita({ entidade: 'curso', entidadeId: id });

  return paraDetalhe(curso);
}

async function obterPorNome(prisma, nome, req) {
  const cursos = await repo.findPorNome(prisma, nome);
  if (cursos.length === 0) {
    throw AppError.notFound('Nenhum curso encontrado com esse nome');
  }

  // Página do curso por nome (T06): várias universidades, sem um id só.
  req.registrarVisita({ entidade: 'curso' });

  return {
    nome,
    // Área do primeiro cadastro: o app usa para escolher a foto do curso.
    areaCurso: cursos[0].areaCurso ?? null,
    universidades: cursos.map(paraOferta),
  };
}

module.exports = { listar, listarDestaques, obterDetalhe, obterPorNome };
