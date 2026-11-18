const AppError = require('../../shared/errors/AppError');
const { buildMeta, parsePagination } = require('../../shared/utils/pagination');

/**
 * Cadastro de programas globais pelo administrador (RF10, RF11, RF17): os
 * três tipos (ENTRADA, FINANCIAMENTO, BOLSA) usam a mesma estrutura. Bolsas
 * institucionais (id_universidade preenchido) são da universidade e ficam
 * fora daqui. Exclusão lógica (ativo=false), bloqueada enquanto alguma
 * universidade aceitar o programa. As datas importantes (programa_evento)
 * são gravadas dentro do programa e excluídas de verdade.
 */

const CAMPOS = ['nome', 'sigla', 'tipo', 'descricao', 'requisitos', 'comoFunciona', 'linkOficial', 'imagemUrl'];

const INCLUDE_ADMIN = {
  eventos: { orderBy: [{ dataInicio: 'asc' }, { id: 'asc' }] },
  _count: { select: { universidades: true } },
};

function dataIso(data) {
  return data ? data.toISOString().slice(0, 10) : null;
}

function paraEvento(evento) {
  return {
    id: evento.id,
    titulo: evento.titulo,
    descricao: evento.descricao,
    dataInicio: dataIso(evento.dataInicio),
    dataFim: dataIso(evento.dataFim),
  };
}

function paraAdmin(programa) {
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
    criadoEm: programa.criadoEm,
    totalUniversidades: programa._count?.universidades ?? 0,
    eventos: (programa.eventos ?? []).map(paraEvento),
  };
}

function soCampos(programa) {
  const dados = {};
  for (const campo of CAMPOS) dados[campo] = programa[campo] ?? null;
  return dados;
}

async function listarAdmin(prisma, query) {
  const { page, pageSize, skip, take } = parsePagination(query);
  const where = {
    ativo: true,
    universidadeId: null,
    ...(query.tipo ? { tipo: query.tipo } : {}),
    ...(query.busca ? { OR: [{ nome: { contains: query.busca } }, { sigla: { contains: query.busca } }] } : {}),
  };

  const [programas, total] = await Promise.all([
    prisma.programa.findMany({ where, include: INCLUDE_ADMIN, orderBy: [{ nome: 'asc' }, { id: 'asc' }], skip, take }),
    prisma.programa.count({ where }),
  ]);

  return { data: programas.map(paraAdmin), meta: buildMeta({ page, pageSize, total }) };
}

async function buscarGlobal(prisma, id) {
  const programa = await prisma.programa.findFirst({
    where: { id, ativo: true, universidadeId: null },
    include: INCLUDE_ADMIN,
  });
  if (!programa) throw AppError.notFound('Programa não encontrado');
  return programa;
}

async function obterAdmin(prisma, id) {
  return paraAdmin(await buscarGlobal(prisma, id));
}

async function criar(prisma, dados, req) {
  return prisma.$transaction(async (tx) => {
    const programa = await tx.programa.create({
      data: { ...dados, usuarioId: req.user.id, universidadeId: null },
      include: INCLUDE_ADMIN,
    });
    await req.registrarAuditoria(
      { acao: 'CREATE', entidade: 'programa', entidadeId: programa.id, dadosDepois: soCampos(programa) },
      tx,
    );
    return paraAdmin(programa);
  });
}

async function atualizar(prisma, id, dados, req) {
  const antes = await buscarGlobal(prisma, id);

  return prisma.$transaction(async (tx) => {
    const programa = await tx.programa.update({ where: { id }, data: dados, include: INCLUDE_ADMIN });
    await req.registrarAuditoria(
      { acao: 'UPDATE', entidade: 'programa', entidadeId: id, dadosAntes: soCampos(antes), dadosDepois: soCampos(programa) },
      tx,
    );
    return paraAdmin(programa);
  });
}

async function excluir(prisma, id, req) {
  const programa = await buscarGlobal(prisma, id);

  return prisma.$transaction(async (tx) => {
    const aceitas = await tx.universidadePrograma.count({ where: { programaId: id } });
    if (aceitas > 0) {
      throw AppError.conflict(
        'PROGRAMA_ACEITO',
        `Este programa é aceito por ${aceitas} ${aceitas === 1 ? 'universidade' : 'universidades'}. ` +
          'Ele só pode ser excluído quando nenhuma universidade o aceitar.',
      );
    }

    await tx.programa.update({ where: { id }, data: { ativo: false } });
    await req.registrarAuditoria(
      { acao: 'DELETE', entidade: 'programa', entidadeId: id, dadosAntes: soCampos(programa), dadosDepois: { ativo: false } },
      tx,
    );
  });
}

function validarDatas(dataInicio, dataFim) {
  if (dataInicio && dataFim && dataFim < dataInicio) {
    throw AppError.validation([{ campo: 'dataFim', mensagem: 'A data de fim deve ser igual ou posterior à de início' }]);
  }
}

// Datas de calendário (coluna DATE): meia-noite UTC, sem fuso.
function paraData(valor) {
  if (valor === undefined) return undefined;
  return valor === null ? null : new Date(`${valor}T00:00:00.000Z`);
}

async function criarEvento(prisma, programaId, dados, req) {
  await buscarGlobal(prisma, programaId);
  validarDatas(dados.dataInicio, dados.dataFim);

  return prisma.$transaction(async (tx) => {
    const evento = await tx.programaEvento.create({
      data: {
        programaId,
        titulo: dados.titulo,
        descricao: dados.descricao ?? null,
        dataInicio: paraData(dados.dataInicio),
        dataFim: paraData(dados.dataFim) ?? null,
      },
    });
    await req.registrarAuditoria(
      { acao: 'CREATE', entidade: 'programa_evento', entidadeId: evento.id, dadosDepois: { programaId, ...paraEvento(evento) } },
      tx,
    );
    return paraEvento(evento);
  });
}

async function buscarEvento(prisma, id) {
  const evento = await prisma.programaEvento.findUnique({
    where: { id },
    include: { programa: { select: { ativo: true, universidadeId: true } } },
  });
  // Evento de bolsa institucional ou de programa excluído não é deste cadastro.
  if (!evento || !evento.programa.ativo || evento.programa.universidadeId != null) {
    throw AppError.notFound('Data importante não encontrada');
  }
  return evento;
}

async function atualizarEvento(prisma, id, dados, req) {
  const antes = await buscarEvento(prisma, id);
  const inicio = dados.dataInicio ?? dataIso(antes.dataInicio);
  const fim = dados.dataFim === undefined ? dataIso(antes.dataFim) : dados.dataFim;
  validarDatas(inicio, fim);

  return prisma.$transaction(async (tx) => {
    const evento = await tx.programaEvento.update({
      where: { id },
      data: {
        titulo: dados.titulo,
        descricao: dados.descricao,
        dataInicio: paraData(dados.dataInicio),
        dataFim: paraData(dados.dataFim),
      },
    });
    await req.registrarAuditoria(
      {
        acao: 'UPDATE',
        entidade: 'programa_evento',
        entidadeId: id,
        dadosAntes: paraEvento(antes),
        dadosDepois: paraEvento(evento),
      },
      tx,
    );
    return paraEvento(evento);
  });
}

async function excluirEvento(prisma, id, req) {
  const evento = await buscarEvento(prisma, id);

  await prisma.$transaction(async (tx) => {
    await tx.programaEvento.delete({ where: { id } });
    await req.registrarAuditoria(
      {
        acao: 'DELETE',
        entidade: 'programa_evento',
        entidadeId: id,
        dadosAntes: { programaId: evento.programaId, ...paraEvento(evento) },
      },
      tx,
    );
  });
}

module.exports = {
  listarAdmin,
  obterAdmin,
  criar,
  atualizar,
  excluir,
  criarEvento,
  atualizarEvento,
  excluirEvento,
};
