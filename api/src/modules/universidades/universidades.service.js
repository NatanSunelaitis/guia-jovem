const AppError = require('../../shared/errors/AppError');
const { buildMeta, parsePagination } = require('../../shared/utils/pagination');
const repo = require('./universidades.repository');

function campusPrincipalResumo(universidade) {
  const principal = universidade.campus?.[0];
  return principal
    ? { cidade: principal.endereco.cidade, estado: principal.endereco.estado }
    : { cidade: null, estado: null };
}

function paraLista(universidade) {
  return {
    id: universidade.id,
    nomeFantasia: universidade.nomeFantasia,
    logoUrl: universidade.logoUrl,
    natureza: universidade.natureza,
    mediaAvaliacao: universidade.mediaAvaliacao,
    totalAvaliacoes: universidade.totalAvaliacoes,
    ...campusPrincipalResumo(universidade),
    programas: universidade.universidadeProgramas.map((up) => ({
      id: up.programa.id,
      nome: up.programa.nome,
      sigla: up.programa.sigla,
      tipo: up.programa.tipo,
    })),
  };
}

function buildWhere(query) {
  const where = { status: 'A' };

  if (query.q) where.nomeFantasia = { contains: query.q };
  if (query.natureza) where.natureza = query.natureza;

  if (query.cidade || query.estado) {
    where.campus = {
      some: {
        endereco: {
          ...(query.cidade ? { cidade: { contains: query.cidade } } : {}),
          ...(query.estado ? { estado: query.estado.toUpperCase() } : {}),
        },
      },
    };
  }

  if (query.programaId) {
    where.universidadeProgramas = { some: { programaId: query.programaId } };
  }

  const condicoesCurso = {};
  if (query.cursoId) condicoesCurso.id = query.cursoId;
  if (query.areaCurso) condicoesCurso.areaCurso = { contains: query.areaCurso };
  if (Object.keys(condicoesCurso).length > 0) {
    where.cursos = { some: condicoesCurso };
  }

  return where;
}

function buildOrderBy(sort) {
  switch (sort) {
    case 'media':
      return [{ mediaAvaliacao: 'desc' }, { totalAvaliacoes: 'desc' }];
    case 'avaliacoes':
      return [{ totalAvaliacoes: 'desc' }, { mediaAvaliacao: 'desc' }];
    case 'nome':
    default:
      return [{ nomeFantasia: 'asc' }];
  }
}

async function listar(prisma, query) {
  const { page, pageSize, skip, take } = parsePagination(query);
  const where = buildWhere(query);
  const orderBy = buildOrderBy(query.sort);

  const [universidades, total] = await Promise.all([
    repo.list(prisma, { where, orderBy, skip, take }),
    repo.count(prisma, where),
  ]);

  return { data: universidades.map(paraLista), meta: buildMeta({ page, pageSize, total }) };
}

async function listarDestaques(prisma, limite = 8) {
  const universidades = await repo.destaques(prisma, limite);
  return universidades.map(paraLista);
}

function agruparProgramasPorTipo(universidadeProgramas) {
  const grupos = { ENTRADA: [], FINANCIAMENTO: [], BOLSA: [] };

  for (const relacao of universidadeProgramas) {
    grupos[relacao.programa.tipo].push({
      id: relacao.programa.id,
      nome: relacao.programa.nome,
      sigla: relacao.programa.sigla,
      observacao: relacao.observacao,
    });
  }

  return grupos;
}

async function obterDetalhe(prisma, id, req) {
  const universidade = await repo.findDetalhePublicado(prisma, id);
  if (!universidade) {
    throw AppError.notFound('Universidade não encontrada');
  }

  req.registrarVisita({ entidade: 'universidade', entidadeId: id });

  const principal = universidade.campus.find((c) => c.principal) ?? universidade.campus[0] ?? null;

  return {
    id: universidade.id,
    nomeFantasia: universidade.nomeFantasia,
    razaoSocial: universidade.razaoSocial,
    descricao: universidade.descricao,
    logoUrl: universidade.logoUrl,
    natureza: universidade.natureza,
    linkPagina: universidade.linkPagina,
    linkSimulados: universidade.linkSimulados,
    mediaAvaliacao: universidade.mediaAvaliacao,
    totalAvaliacoes: universidade.totalAvaliacoes,
    enderecoPrincipal: principal
      ? {
          logradouro: principal.endereco.logradouro,
          numero: principal.endereco.numero,
          bairro: principal.endereco.bairro,
          cidade: principal.endereco.cidade,
          estado: principal.endereco.estado,
          cep: principal.endereco.cep,
        }
      : null,
    campus: universidade.campus.map((c) => ({
      id: c.id,
      nome: c.nome,
      cidade: c.endereco.cidade,
      estado: c.endereco.estado,
      principal: c.principal,
    })),
    programas: agruparProgramasPorTipo(universidade.universidadeProgramas),
  };
}

async function listarCampus(prisma, universidadeId) {
  const universidadeExiste = await repo.existeAprovada(prisma, universidadeId);
  if (!universidadeExiste) {
    throw AppError.notFound('Universidade não encontrada');
  }

  const campus = await repo.campusComCursos(prisma, universidadeId);

  return campus.map((c) => ({
    id: c.id,
    nome: c.nome,
    telefoneCelular: c.telefoneCelular,
    telefoneFixo: c.telefoneFixo,
    emailCampus: c.emailCampus,
    principal: c.principal,
    endereco: {
      logradouro: c.endereco.logradouro,
      numero: c.endereco.numero,
      bairro: c.endereco.bairro,
      cidade: c.endereco.cidade,
      estado: c.endereco.estado,
      cep: c.endereco.cep,
    },
    cursos: c.campusCursos.map((cc) => ({
      id: cc.curso.id,
      nome: cc.curso.nome,
      turno: cc.turno,
      vagas: cc.vagas,
    })),
  }));
}

async function listarCursos(prisma, universidadeId) {
  const universidadeExiste = await repo.existeAprovada(prisma, universidadeId);
  if (!universidadeExiste) {
    throw AppError.notFound('Universidade não encontrada');
  }

  const cursos = await repo.cursosDaUniversidade(prisma, universidadeId);

  return cursos.map((curso) => ({
    id: curso.id,
    nome: curso.nome,
    areaCurso: curso.areaCurso,
    grau: curso.grau,
    modalidade: curso.modalidade,
    duracaoSemestres: curso.duracaoSemestres,
  }));
}

function primeiroNome(nomeCompleto) {
  return nomeCompleto.split(' ')[0];
}

async function listarAvaliacoes(prisma, universidadeId, query) {
  const universidadeExiste = await repo.existeAprovada(prisma, universidadeId);
  if (!universidadeExiste) {
    throw AppError.notFound('Universidade não encontrada');
  }

  const { page, pageSize, skip, take } = parsePagination(query);

  const [avaliacoes, total] = await Promise.all([
    repo.avaliacoes(prisma, universidadeId, { skip, take }),
    repo.countAvaliacoes(prisma, universidadeId),
  ]);

  return {
    data: avaliacoes.map((avaliacao) => ({
      id: avaliacao.id,
      nota: avaliacao.nota,
      comentario: avaliacao.comentario,
      criadoEm: avaliacao.criadoEm,
      // RNF17/RNF24: e-mail nunca aparece; só o primeiro nome, e some no anônimo.
      autor: avaliacao.usuario ? primeiroNome(avaliacao.usuario.nome) : null,
    })),
    meta: buildMeta({ page, pageSize, total }),
  };
}

module.exports = {
  listar,
  listarDestaques,
  obterDetalhe,
  listarCampus,
  listarCursos,
  listarAvaliacoes,
};
