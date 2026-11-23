const AppError = require('../../shared/errors/AppError');
const { buildMeta, parsePagination } = require('../../shared/utils/pagination');
const { agruparPorNome, normalizarNome } = require('../../shared/utils/nomesCurso');
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

/**
 * Cursos agrupados pelo nome (sem diferenciar maiúsculas, acentos e espaços
 * repetidos), com a grafia mais usada, a área mais frequente e os graus do
 * grupo, dos mais oferecidos para os menos.
 */
async function listarDestaques(prisma, { limite = DESTAQUES_PADRAO, q, areaCurso } = {}) {
  const where = buildWhere({ q, areaCurso });
  const cursos = await repo.nomesAtivos(prisma, where);

  return agruparPorNome(cursos)
    .sort((a, b) => b.totalOfertas - a.totalOfertas || a.nome.localeCompare(b.nome, 'pt-BR'))
    .slice(0, limite)
    .map(({ nome, areaCurso: area, graus, totalOfertas, totalUniversidades }) => ({
      nome,
      areaCurso: area,
      graus,
      totalOfertas,
      totalUniversidades,
    }));
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

/**
 * Página do curso por nome (T06): os cursos de mesmo nome normalizado em
 * universidades aprovadas. O título é a grafia mais usada e a área (que o
 * app usa para a foto) é a mais frequente do grupo.
 */
async function obterPorNome(prisma, nome, req) {
  const chave = normalizarNome(nome);
  const candidatos = await repo.nomesAtivos(prisma, buildWhere({}));
  const [grupo] = agruparPorNome(candidatos.filter((c) => normalizarNome(c.nome) === chave));
  if (!grupo) {
    throw AppError.notFound('Nenhum curso encontrado com esse nome');
  }

  const cursos = await repo.findOfertas(prisma, grupo.cursos.map((c) => c.id));

  // Várias universidades, sem um id só.
  req.registrarVisita({ entidade: 'curso' });

  return {
    nome: grupo.nome,
    areaCurso: grupo.areaCurso,
    universidades: cursos.map(paraOferta),
  };
}

function listarAreas(prisma) {
  return repo.areas(prisma);
}

module.exports = { listar, listarDestaques, listarAreas, obterDetalhe, obterPorNome };
