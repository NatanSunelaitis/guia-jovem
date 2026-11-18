const { Prisma } = require('@prisma/client');

// Formatos fixos (nada vem do usuário): o agrupamento vira texto no SQL.
const FORMATOS = { dia: Prisma.raw("'%Y-%m-%d'"), mes: Prisma.raw("'%Y-%m'") };

// Brasília sem horário de verão (desde 2019): UTC-3 fixo, sem depender das
// tabelas de fuso do MySQL.
function visitasPorPeriodo(prisma, { inicio, fim, agrupar }) {
  return prisma.$queryRaw`
    SELECT DATE_FORMAT(DATE_SUB(criado_em, INTERVAL 3 HOUR), ${FORMATOS[agrupar]}) AS periodo, COUNT(*) AS total
    FROM visita_pagina
    WHERE criado_em >= ${inicio} AND criado_em < ${fim}
    GROUP BY periodo
    ORDER BY periodo`;
}

function loginsUnicosPorPeriodo(prisma, { inicio, fim, agrupar }) {
  return prisma.$queryRaw`
    SELECT DATE_FORMAT(DATE_SUB(criado_em, INTERVAL 3 HOUR), ${FORMATOS[agrupar]}) AS periodo,
           COUNT(DISTINCT entidade_id) AS total
    FROM log_auditoria
    WHERE acao = 'LOGIN' AND entidade = 'usuario' AND criado_em >= ${inicio} AND criado_em < ${fim}
    GROUP BY periodo
    ORDER BY periodo`;
}

/** Contas distintas no período inteiro (não é a soma dos dias). */
function loginsUnicosNoPeriodo(prisma, { inicio, fim }) {
  return prisma.$queryRaw`
    SELECT COUNT(DISTINCT entidade_id) AS total
    FROM log_auditoria
    WHERE acao = 'LOGIN' AND entidade = 'usuario' AND criado_em >= ${inicio} AND criado_em < ${fim}`;
}

function visitasPorPerfil(prisma, { inicio, fim }) {
  return prisma.visitaPagina.groupBy({
    by: ['tipoUsuario'],
    where: { criadoEm: { gte: inicio, lt: fim } },
    _count: { _all: true },
  });
}

function maisVisitados(prisma, entidade, { inicio, fim, limite }) {
  return prisma.visitaPagina.groupBy({
    by: ['entidadeId'],
    where: { entidade, entidadeId: { not: null }, criadoEm: { gte: inicio, lt: fim } },
    _count: { entidadeId: true },
    orderBy: [{ _count: { entidadeId: 'desc' } }, { entidadeId: 'asc' }],
    take: limite,
  });
}

const NOMES = {
  universidade: (prisma, ids) =>
    prisma.universidade.findMany({ where: { id: { in: ids } }, select: { id: true, nomeFantasia: true } }),
  programa: (prisma, ids) =>
    prisma.programa.findMany({ where: { id: { in: ids } }, select: { id: true, nome: true, sigla: true } }),
  curso: (prisma, ids) =>
    prisma.curso.findMany({
      where: { id: { in: ids } },
      select: { id: true, nome: true, universidade: { select: { nomeFantasia: true } } },
    }),
};

function nomes(prisma, entidade, ids) {
  return ids.length === 0 ? Promise.resolve([]) : NOMES[entidade](prisma, ids);
}

function usuariosPorPerfil(prisma) {
  return prisma.usuario.groupBy({ by: ['tipoUsuario'], _count: { _all: true } });
}

function universidadesPorStatus(prisma) {
  return prisma.universidade.groupBy({ by: ['status'], _count: { _all: true } });
}

function totalCursos(prisma) {
  return prisma.curso.count({ where: { ativo: true } });
}

function programasPorTipo(prisma) {
  return prisma.programa.groupBy({ by: ['tipo'], where: { ativo: true }, _count: { _all: true } });
}

module.exports = {
  visitasPorPeriodo,
  loginsUnicosPorPeriodo,
  loginsUnicosNoPeriodo,
  visitasPorPerfil,
  maisVisitados,
  nomes,
  usuariosPorPerfil,
  universidadesPorStatus,
  totalCursos,
  programasPorTipo,
};
