const AppError = require('../../shared/errors/AppError');
const { buildMeta, parsePagination } = require('../../shared/utils/pagination');
const repo = require('./programas.repository');

const DESTAQUES_PADRAO = 8;

function paraLista(programa) {
  return {
    id: programa.id,
    nome: programa.nome,
    sigla: programa.sigla,
    tipo: programa.tipo,
    descricao: programa.descricao,
    imagemUrl: programa.imagemUrl,
    universidadeId: programa.universidadeId,
  };
}

function buildWhere(query) {
  // Programas globais (id_universidade nulo) sempre aparecem; bolsas/programas
  // institucionais só quando a universidade dona está aprovada (RF25).
  const visibilidadePublica = { OR: [{ universidadeId: null }, { universidade: { status: 'A' } }] };
  const where = { ativo: true, AND: [visibilidadePublica] };

  if (query.tipo) where.tipo = query.tipo;
  if (query.q) {
    where.AND.push({ OR: [{ nome: { contains: query.q } }, { sigla: { contains: query.q } }] });
  }
  // RF11: a bolsa institucional é visível só no perfil da universidade. Sem
  // o filtro por universidade, a pesquisa traz apenas os programas globais;
  // `apenasGlobais` continua aceito, e já é o comportamento padrão.
  where.universidadeId = query.universidadeId && !query.apenasGlobais ? query.universidadeId : null;

  return where;
}

async function listar(prisma, query) {
  const { page, pageSize, skip, take } = parsePagination(query);
  const where = buildWhere(query);

  const [programas, total] = await Promise.all([
    repo.list(prisma, { where, skip, take }),
    repo.count(prisma, where),
  ]);

  return { data: programas.map(paraLista), meta: buildMeta({ page, pageSize, total }) };
}

async function listarDestaques(prisma, limite = DESTAQUES_PADRAO, tipo = undefined) {
  const programas = await repo.destaques(prisma, limite, tipo);
  return programas.map(paraLista);
}

async function obterDetalhe(prisma, id, req) {
  const programa = await repo.findDetalhePublicado(prisma, id);
  if (!programa) {
    throw AppError.notFound('Programa não encontrado');
  }

  req.registrarVisita({ entidade: 'programa', entidadeId: id });

  return {
    id: programa.id,
    nome: programa.nome,
    sigla: programa.sigla,
    tipo: programa.tipo,
    descricao: programa.descricao,
    requisitos: programa.requisitos,
    comoFunciona: programa.comoFunciona,
    linkOficial: programa.linkOficial,
    imagemUrl: programa.imagemUrl,
    universidadeId: programa.universidadeId,
    eventos: programa.eventos.map((evento) => ({
      id: evento.id,
      titulo: evento.titulo,
      descricao: evento.descricao,
      dataInicio: evento.dataInicio,
      dataFim: evento.dataFim,
    })),
    universidades: programa.universidades.map((up) => ({
      id: up.universidade.id,
      nomeFantasia: up.universidade.nomeFantasia,
      logoUrl: up.universidade.logoUrl,
      observacao: up.observacao,
    })),
  };
}

async function listarUniversidades(prisma, id) {
  const programa = await repo.findDetalhePublicado(prisma, id);
  if (!programa) {
    throw AppError.notFound('Programa não encontrado');
  }

  return programa.universidades.map((up) => ({
    id: up.universidade.id,
    nomeFantasia: up.universidade.nomeFantasia,
    logoUrl: up.universidade.logoUrl,
    observacao: up.observacao,
  }));
}

module.exports = { listar, listarDestaques, obterDetalhe, listarUniversidades };
