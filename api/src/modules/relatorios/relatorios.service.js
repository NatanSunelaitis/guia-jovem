const universidadesService = require('../universidades/universidades.service');
const repo = require('./relatorios.repository');

// Mesmo teto de linhas usado como pageSize máximo do restante da API
// (src/shared/utils/pagination.js): o relatório cobre o resultado da
// pesquisa, não a base inteira.
const MAX_LINHAS = 100;

async function buscarUniversidades(prisma, query) {
  const where = universidadesService.buildWhere(query);
  const orderBy = universidadesService.buildOrderBy(query.sort);
  return repo.buscarParaRelatorio(prisma, { where, orderBy, take: MAX_LINHAS });
}

const CABECALHO_CSV = [
  'Universidade',
  'Natureza',
  'Cidade',
  'Estado',
  'Media de avaliacao',
  'Total de avaliacoes',
  'Campus',
  'Cursos',
  'Programas',
];

function campusPrincipal(universidade) {
  return universidade.campus.find((c) => c.principal) ?? universidade.campus[0] ?? null;
}

function escapeCsv(valor) {
  const texto = valor == null ? '' : String(valor);
  if (/[",\n]/.test(texto)) {
    return `"${texto.replace(/"/g, '""')}"`;
  }
  return texto;
}

function linhaRelatorio(universidade) {
  const principal = campusPrincipal(universidade);
  return {
    nome: universidade.nomeFantasia,
    natureza: universidade.natureza === 'P' ? 'Pública' : 'Privada',
    cidade: principal?.endereco.cidade ?? '',
    estado: principal?.endereco.estado ?? '',
    mediaAvaliacao: universidade.mediaAvaliacao ?? '',
    totalAvaliacoes: universidade.totalAvaliacoes,
    campus: universidade.campus.map((c) => c.nome).join(', '),
    cursos: universidade.cursos.map((c) => c.nome).join(', '),
    programas: universidade.universidadeProgramas.map((up) => up.programa.sigla ?? up.programa.nome).join(', '),
  };
}

function gerarCsv(universidades) {
  const linhas = [CABECALHO_CSV.map(escapeCsv).join(',')];

  for (const universidade of universidades) {
    const linha = linhaRelatorio(universidade);
    linhas.push(
      [
        linha.nome,
        linha.natureza,
        linha.cidade,
        linha.estado,
        linha.mediaAvaliacao,
        linha.totalAvaliacoes,
        linha.campus,
        linha.cursos,
        linha.programas,
      ]
        .map(escapeCsv)
        .join(','),
    );
  }

  // BOM UTF-8 no início: sem ele, o Excel no Windows abre acentos como Latin-1.
  return '﻿' + linhas.join('\r\n');
}

function gerarPdf(universidades, doc) {
  doc.fontSize(18).fillColor('#1A1C1C').text('Relatório de pesquisa · Guia Jovem');
  doc.moveDown(0.5);
  doc
    .fontSize(10)
    .fillColor('#404752')
    .text(`${universidades.length} universidade(s) encontrada(s) para os filtros aplicados.`);
  doc.moveDown();

  for (const universidade of universidades) {
    const linha = linhaRelatorio(universidade);

    doc.fontSize(13).fillColor('#0061A4').text(linha.nome);
    doc.fontSize(9).fillColor('#404752');
    doc.text(`${linha.natureza} · ${linha.cidade ? `${linha.cidade}/${linha.estado}` : 'cidade não informada'}`);
    doc.text(`Média: ${linha.mediaAvaliacao === '' ? 'sem avaliações' : linha.mediaAvaliacao} (${linha.totalAvaliacoes} avaliações)`);
    if (linha.campus) doc.text(`Campus: ${linha.campus}`);
    if (linha.cursos) doc.text(`Cursos: ${linha.cursos}`);
    if (linha.programas) doc.text(`Programas: ${linha.programas}`);
    doc.moveDown();
  }
}

module.exports = { buscarUniversidades, gerarCsv, gerarPdf };
