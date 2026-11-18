const AppError = require('../../shared/errors/AppError');
const { resolverPeriodo } = require('../estatisticas/estatisticas.service');
const notificacoesService = require('../notificacoes/notificacoes.service');
const adminService = require('./universidades.admin.service');

/**
 * Painel da universidade (Pendência 3): programas aceitos (RF12, RF13,
 * RF17), reenvio do cadastro reprovado e a estatística simples da página.
 * A edição dos dados da instituição usa o mesmo serviço do administrador
 * (universidades.admin.service.atualizar).
 */

async function garantirUniversidade(prisma, id, select = { id: true }) {
  const universidade = await prisma.universidade.findUnique({ where: { id }, select });
  if (!universidade) throw AppError.notFound('Universidade não encontrada');
  return universidade;
}

/**
 * Programas globais ativos (entrada, financiamento e bolsa), cada um com
 * `aceito` e a `observacao` que a universidade escreveu (aparece na página
 * pública ao lado do programa).
 */
async function listarProgramas(prisma, universidadeId) {
  await garantirUniversidade(prisma, universidadeId);
  const [programas, aceitos] = await Promise.all([
    prisma.programa.findMany({
      where: { ativo: true, universidadeId: null },
      orderBy: [{ tipo: 'asc' }, { nome: 'asc' }, { id: 'asc' }],
      select: { id: true, nome: true, sigla: true, tipo: true },
    }),
    prisma.universidadePrograma.findMany({ where: { universidadeId } }),
  ]);
  const porPrograma = new Map(aceitos.map((up) => [up.programaId, up]));
  return programas.map((programa) => ({
    ...programa,
    aceito: porPrograma.has(programa.id),
    observacao: porPrograma.get(programa.id)?.observacao ?? null,
  }));
}

/**
 * Substitui o conjunto de programas aceitos (seção 5.3, PUT). Só programas
 * globais ativos; bolsa institucional é da própria universidade e não passa
 * por aqui.
 */
async function definirProgramas(prisma, universidadeId, { programas }, req) {
  await garantirUniversidade(prisma, universidadeId);

  const ids = [...new Set(programas.map((p) => p.programaId))];
  if (ids.length !== programas.length) {
    throw AppError.validation([{ campo: 'programas', mensagem: 'Cada programa pode aparecer uma vez só' }]);
  }
  if (ids.length > 0) {
    const validos = await prisma.programa.count({ where: { id: { in: ids }, ativo: true, universidadeId: null } });
    if (validos !== ids.length) {
      throw new AppError('PROGRAMA_INVALIDO', 'Escolha apenas programas de entrada, financiamento ou bolsa cadastrados', 400);
    }
  }

  await prisma.$transaction(async (tx) => {
    const antes = await tx.universidadePrograma.findMany({ where: { universidadeId } });
    await tx.universidadePrograma.deleteMany({ where: { universidadeId } });
    if (programas.length > 0) {
      await tx.universidadePrograma.createMany({
        data: programas.map((p) => ({ universidadeId, programaId: p.programaId, observacao: p.observacao ?? null })),
      });
    }
    await req.registrarAuditoria(
      {
        acao: 'UPDATE',
        entidade: 'universidade_programa',
        entidadeId: universidadeId,
        dadosAntes: antes.map((up) => ({ programaId: up.programaId, observacao: up.observacao })),
        dadosDepois: programas.map((p) => ({ programaId: p.programaId, observacao: p.observacao ?? null })),
      },
      tx,
    );
  });

  return listarProgramas(prisma, universidadeId);
}

/**
 * Universidade reprovada reenvia o cadastro corrigido: o status volta para
 * pendente, o motivo sai da universidade e fica no log_auditoria (dados
 * antes), e os administradores ativos são notificados. Gravação condicional
 * ao status R, para dois reenvios ao mesmo tempo valerem como um.
 */
async function reenviar(prisma, id, req) {
  const universidade = await garantirUniversidade(prisma, id, {
    id: true,
    nomeFantasia: true,
    status: true,
    motivoReprovacao: true,
  });
  const erro = () => AppError.conflict('STATUS_INVALIDO', 'Só é possível reenviar um cadastro reprovado');
  if (universidade.status !== 'R') throw erro();

  await prisma.$transaction(async (tx) => {
    const { count } = await tx.universidade.updateMany({
      where: { id, status: 'R' },
      data: { status: 'P', motivoReprovacao: null },
    });
    if (count === 0) throw erro();

    await req.registrarAuditoria(
      {
        acao: 'UPDATE',
        entidade: 'universidade',
        entidadeId: id,
        dadosAntes: { status: 'R', motivoReprovacao: universidade.motivoReprovacao },
        dadosDepois: { acao: 'reenviar', status: 'P', motivoReprovacao: null },
      },
      tx,
    );

    await notificacoesService.notificar(tx, await notificacoesService.idsAdministradoresAtivos(tx), {
      tipo: 'UNIVERSIDADE_PENDENTE',
      titulo: 'Cadastro reenviado para análise',
      mensagem: `${universidade.nomeFantasia} corrigiu o cadastro reprovado e o reenviou para análise.`,
      referenciaTipo: 'universidade',
      referenciaId: id,
    });
  });

  return adminService.obterCadastro(prisma, id);
}

/**
 * Estatística simples da página (card "Desempenho da página" do T23.1):
 * visitas à página da universidade no período (mesma regra de datas do
 * dashboard, últimos 30 dias por padrão) e a média das avaliações.
 */
async function estatisticas(prisma, id, query = {}, agora = new Date()) {
  const universidade = await garantirUniversidade(prisma, id, {
    id: true,
    mediaAvaliacao: true,
    totalAvaliacoes: true,
  });
  const periodo = resolverPeriodo(query, agora);
  const visitas = await prisma.visitaPagina.count({
    where: { entidade: 'universidade', entidadeId: id, criadoEm: { gte: periodo.inicio, lt: periodo.fim } },
  });
  return {
    de: periodo.de,
    ate: periodo.ate,
    visitas,
    mediaAvaliacao: universidade.mediaAvaliacao == null ? null : Number(universidade.mediaAvaliacao),
    totalAvaliacoes: universidade.totalAvaliacoes,
  };
}

module.exports = { listarProgramas, definirProgramas, reenviar, estatisticas };
