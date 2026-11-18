const AppError = require('../../shared/errors/AppError');

/**
 * Bolsas institucionais (RF11, relação "Mantém"): programas do tipo BOLSA
 * com id_universidade preenchido, cadastrados pela universidade (ou pelo
 * administrador por ela) e visíveis só na página da universidade (a
 * pesquisa e os destaques de programas trazem só os globais). Exclusão
 * lógica (ativo = false).
 */

const CAMPOS = ['nome', 'sigla', 'descricao', 'requisitos', 'comoFunciona', 'linkOficial', 'imagemUrl'];

function paraBolsa(programa) {
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
  };
}

function soCampos(programa) {
  const dados = {};
  for (const campo of CAMPOS) dados[campo] = programa[campo] ?? null;
  return dados;
}

async function garantirUniversidade(prisma, universidadeId) {
  const universidade = await prisma.universidade.findUnique({ where: { id: universidadeId }, select: { id: true } });
  if (!universidade) throw AppError.notFound('Universidade não encontrada');
}

async function buscar(prisma, universidadeId, id) {
  const bolsa = await prisma.programa.findFirst({ where: { id, universidadeId, tipo: 'BOLSA', ativo: true } });
  if (!bolsa) throw AppError.notFound('Bolsa não encontrada');
  return bolsa;
}

async function listar(prisma, universidadeId) {
  await garantirUniversidade(prisma, universidadeId);
  const bolsas = await prisma.programa.findMany({
    where: { universidadeId, tipo: 'BOLSA', ativo: true },
    orderBy: [{ nome: 'asc' }, { id: 'asc' }],
  });
  return bolsas.map(paraBolsa);
}

async function criar(prisma, universidadeId, dados, req) {
  await garantirUniversidade(prisma, universidadeId);

  return prisma.$transaction(async (tx) => {
    const bolsa = await tx.programa.create({
      data: { ...dados, tipo: 'BOLSA', universidadeId, usuarioId: req.user.id },
    });
    await req.registrarAuditoria(
      { acao: 'CREATE', entidade: 'programa', entidadeId: bolsa.id, dadosDepois: { universidadeId, tipo: 'BOLSA', ...soCampos(bolsa) } },
      tx,
    );
    return paraBolsa(bolsa);
  });
}

async function atualizar(prisma, universidadeId, id, dados, req) {
  const antes = await buscar(prisma, universidadeId, id);

  return prisma.$transaction(async (tx) => {
    const bolsa = await tx.programa.update({ where: { id }, data: dados });
    await req.registrarAuditoria(
      { acao: 'UPDATE', entidade: 'programa', entidadeId: id, dadosAntes: soCampos(antes), dadosDepois: soCampos(bolsa) },
      tx,
    );
    return paraBolsa(bolsa);
  });
}

async function excluir(prisma, universidadeId, id, req) {
  const bolsa = await buscar(prisma, universidadeId, id);

  await prisma.$transaction(async (tx) => {
    await tx.programa.update({ where: { id }, data: { ativo: false } });
    await req.registrarAuditoria(
      { acao: 'DELETE', entidade: 'programa', entidadeId: id, dadosAntes: soCampos(bolsa), dadosDepois: { ativo: false } },
      tx,
    );
  });
}

module.exports = { listar, criar, atualizar, excluir };
