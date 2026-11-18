const repo = require('./estatisticas.repository');

const DIA_MS = 24 * 60 * 60 * 1000;
const DIAS_PADRAO = 30;
const LIMITE_RANKING = 5;
// Brasília é UTC-3: o dia "2026-11-17" começa às 03:00 UTC.
const INICIO_DO_DIA_BRASILIA = 'T03:00:00.000Z';

function hojeEmBrasilia(agora) {
  return new Date(agora.getTime() - 3 * 60 * 60 * 1000).toISOString().slice(0, 10);
}

function somarDias(dataIso, dias) {
  return new Date(Date.parse(`${dataIso}T00:00:00Z`) + dias * DIA_MS).toISOString().slice(0, 10);
}

/**
 * Período em datas de Brasília, `de` e `ate` inclusivos. Sem `ate`, vai até
 * hoje; sem `de`, começa 30 dias antes do fim. Devolve também o intervalo
 * em UTC ([inicio, fim)) para a consulta.
 */
function resolverPeriodo({ de, ate } = {}, agora = new Date()) {
  const fimData = ate ?? hojeEmBrasilia(agora);
  const inicioData = de ?? somarDias(fimData, -(DIAS_PADRAO - 1));
  return {
    de: inicioData,
    ate: fimData,
    inicio: new Date(`${inicioData}${INICIO_DO_DIA_BRASILIA}`),
    fim: new Date(Date.parse(`${fimData}${INICIO_DO_DIA_BRASILIA}`) + DIA_MS),
  };
}

/** Todos os dias (AAAA-MM-DD) ou meses (AAAA-MM) do período, para os vazios virem com zero. */
function chavesDoPeriodo(de, ate, agrupar) {
  const chaves = [];
  if (agrupar === 'mes') {
    let [ano, mes] = de.slice(0, 7).split('-').map(Number);
    const ultimo = ate.slice(0, 7);
    for (;;) {
      const chave = `${ano}-${String(mes).padStart(2, '0')}`;
      chaves.push(chave);
      if (chave >= ultimo) break;
      mes += 1;
      if (mes > 12) {
        mes = 1;
        ano += 1;
      }
    }
    return chaves;
  }
  for (let dia = de; dia <= ate; dia = somarDias(dia, 1)) chaves.push(dia);
  return chaves;
}

function contagem(linhas, campo) {
  const resultado = {};
  for (const linha of linhas) resultado[linha[campo]] = linha._count._all;
  return resultado;
}

function comTotal(valores, chaves) {
  const resultado = {};
  let total = 0;
  for (const chave of chaves) {
    resultado[chave] = valores[chave] ?? 0;
    total += resultado[chave];
  }
  return { ...resultado, total };
}

/** Cartões do dashboard (RF16): retrato do momento, sem período. */
async function resumo(prisma) {
  const [usuarios, universidades, cursos, programas] = await Promise.all([
    repo.usuariosPorPerfil(prisma),
    repo.universidadesPorStatus(prisma),
    repo.totalCursos(prisma),
    repo.programasPorTipo(prisma),
  ]);

  return {
    usuariosPorPerfil: comTotal(contagem(usuarios, 'tipoUsuario'), ['A', 'U', 'D']),
    universidadesPorStatus: comTotal(contagem(universidades, 'status'), ['P', 'A', 'R', 'I']),
    cursos,
    programasPorTipo: comTotal(contagem(programas, 'tipo'), ['ENTRADA', 'FINANCIAMENTO', 'BOLSA']),
  };
}

/** Visitas e logins únicos por dia ou mês no período (RF16). */
async function visitas(prisma, query = {}, agora = new Date()) {
  const agrupar = query.agrupar ?? 'dia';
  const periodo = resolverPeriodo(query, agora);

  const [visitasLinhas, loginsLinhas, loginsTotalLinhas, perfis] = await Promise.all([
    repo.visitasPorPeriodo(prisma, { ...periodo, agrupar }),
    repo.loginsUnicosPorPeriodo(prisma, { ...periodo, agrupar }),
    repo.loginsUnicosNoPeriodo(prisma, periodo),
    repo.visitasPorPerfil(prisma, periodo),
  ]);

  // COUNT do MySQL chega como BigInt.
  const porChave = (linhas) => new Map(linhas.map((linha) => [linha.periodo, Number(linha.total)]));
  const visitasMap = porChave(visitasLinhas);
  const loginsMap = porChave(loginsLinhas);

  const serie = chavesDoPeriodo(periodo.de, periodo.ate, agrupar).map((chave) => ({
    periodo: chave,
    visitas: visitasMap.get(chave) ?? 0,
    loginsUnicos: loginsMap.get(chave) ?? 0,
  }));

  const contagemPerfis = {};
  for (const linha of perfis) contagemPerfis[linha.tipoUsuario ?? 'visitante'] = linha._count._all;

  return {
    de: periodo.de,
    ate: periodo.ate,
    agrupar,
    totalVisitas: serie.reduce((soma, ponto) => soma + ponto.visitas, 0),
    loginsUnicos: Number(loginsTotalLinhas[0]?.total ?? 0),
    visitasPorPerfil: {
      visitante: contagemPerfis.visitante ?? 0,
      A: contagemPerfis.A ?? 0,
      U: contagemPerfis.U ?? 0,
      D: contagemPerfis.D ?? 0,
    },
    serie,
  };
}

async function rankingDe(prisma, entidade, periodo, limite, nomear) {
  const linhas = await repo.maisVisitados(prisma, entidade, { ...periodo, limite });
  const ids = linhas.map((linha) => linha.entidadeId);
  const registros = new Map((await repo.nomes(prisma, entidade, ids)).map((r) => [r.id, r]));
  return linhas.map((linha) => ({
    id: linha.entidadeId,
    // Registro apagado do banco continua no histórico de visitas.
    nome: registros.has(linha.entidadeId) ? nomear(registros.get(linha.entidadeId)) : 'Registro removido',
    visitas: linha._count.entidadeId,
  }));
}

/** Universidades, programas e cursos mais acessados no período (RF16). */
async function ranking(prisma, query = {}, agora = new Date()) {
  const periodo = resolverPeriodo(query, agora);
  const limite = query.limite ?? LIMITE_RANKING;

  const [universidades, programas, cursos] = await Promise.all([
    rankingDe(prisma, 'universidade', periodo, limite, (u) => u.nomeFantasia),
    rankingDe(prisma, 'programa', periodo, limite, (p) => p.sigla ?? p.nome),
    rankingDe(prisma, 'curso', periodo, limite, (c) => `${c.nome} (${c.universidade.nomeFantasia})`),
  ]);

  return { de: periodo.de, ate: periodo.ate, universidades, programas, cursos };
}

module.exports = { resolverPeriodo, chavesDoPeriodo, resumo, visitas, ranking };
