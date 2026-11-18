const AppError = require('../../shared/errors/AppError');
const { buildMeta, parsePagination } = require('../../shared/utils/pagination');
const repo = require('./cursos.repository');

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

function paraDetalhe(curso) {
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
    campus: curso.campusCursos.map((cc) => ({
      id: cc.campus.id,
      nome: cc.campus.nome,
      cidade: cc.campus.endereco.cidade,
      estado: cc.campus.endereco.estado,
      turno: cc.turno,
      vagas: cc.vagas,
    })),
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
    universidades: cursos.map((curso) => ({
      cursoId: curso.id,
      universidade: curso.universidade,
      campus: curso.campusCursos.map((cc) => ({
        id: cc.campus.id,
        nome: cc.campus.nome,
        cidade: cc.campus.endereco.cidade,
        estado: cc.campus.endereco.estado,
      })),
    })),
  };
}

module.exports = { listar, listarDestaques, obterDetalhe, obterPorNome };
