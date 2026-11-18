const { enviarEmail } = require('../../config/mailer');
const AppError = require('../../shared/errors/AppError');
const { buildMeta, parsePagination } = require('../../shared/utils/pagination');
const notificacoesService = require('../notificacoes/notificacoes.service');
const repo = require('./universidades.repository');

/**
 * Aprovação de universidades (RF23) e inativação pelo administrador (RF18,
 * "Editar e inativar"). Status: P pendente | A aprovada | R reprovada | I inativa.
 */
const TRANSICOES = {
  aprovar: {
    de: ['P', 'R'],
    para: 'A',
    erro: 'Só é possível aprovar uma universidade pendente ou reprovada',
  },
  reprovar: {
    de: ['P'],
    para: 'R',
    erro: 'Só é possível reprovar uma universidade pendente',
  },
  inativar: {
    de: ['A'],
    para: 'I',
    erro: 'Só é possível inativar uma universidade aprovada',
  },
  reativar: {
    de: ['I'],
    para: 'A',
    erro: 'Só é possível reativar uma universidade inativa',
  },
};

const LIMITE_MENSAGEM_NOTIFICACAO = 255;

function limitar(texto, limite) {
  return texto.length <= limite ? texto : `${texto.slice(0, limite - 3)}...`;
}

function escaparHtml(texto) {
  return String(texto)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}

function paraListaAdmin(universidade) {
  const principal = universidade.campus?.[0];
  return {
    id: universidade.id,
    nomeFantasia: universidade.nomeFantasia,
    razaoSocial: universidade.razaoSocial,
    cnpj: universidade.cnpj,
    natureza: universidade.natureza,
    status: universidade.status,
    cidade: principal?.endereco?.cidade ?? null,
    estado: principal?.endereco?.estado ?? null,
    criadoEm: universidade.criadoEm,
    aprovadoEm: universidade.aprovadoEm,
  };
}

function paraCadastro(universidade) {
  const principal = universidade.campus.find((c) => c.principal) ?? universidade.campus[0] ?? null;
  return {
    id: universidade.id,
    nomeFantasia: universidade.nomeFantasia,
    razaoSocial: universidade.razaoSocial,
    cnpj: universidade.cnpj,
    natureza: universidade.natureza,
    descricao: universidade.descricao,
    telefonePrincipal: universidade.telefonePrincipal,
    linkPagina: universidade.linkPagina,
    linkSimulados: universidade.linkSimulados,
    logoUrl: universidade.logoUrl,
    status: universidade.status,
    motivoReprovacao: universidade.motivoReprovacao,
    aprovadoEm: universidade.aprovadoEm,
    criadoEm: universidade.criadoEm,
    totalCampus: universidade.campus.length,
    campusPrincipal: principal
      ? {
          id: principal.id,
          nome: principal.nome,
          telefoneCelular: principal.telefoneCelular,
          telefoneFixo: principal.telefoneFixo,
          emailCampus: principal.emailCampus,
          endereco: {
            logradouro: principal.endereco.logradouro,
            numero: principal.endereco.numero,
            complemento: principal.endereco.complemento,
            bairro: principal.endereco.bairro,
            cidade: principal.endereco.cidade,
            estado: principal.endereco.estado,
            cep: principal.endereco.cep,
          },
        }
      : null,
    programas: universidade.universidadeProgramas.map((up) => ({
      id: up.programa.id,
      nome: up.programa.nome,
      sigla: up.programa.sigla,
      tipo: up.programa.tipo,
    })),
    // Conta que administra a universidade; null se ela foi excluída.
    responsavel: universidade.usuario
      ? {
          id: universidade.usuario.id,
          nome: universidade.usuario.nome,
          email: universidade.usuario.email,
          ativo: universidade.usuario.ativo,
        }
      : null,
  };
}

async function listarAdmin(prisma, query) {
  const { page, pageSize, skip, take } = parsePagination(query);
  const where = {
    ...(query.status ? { status: query.status } : {}),
    ...(query.busca
      ? { OR: [{ nomeFantasia: { contains: query.busca } }, { razaoSocial: { contains: query.busca } }] }
      : {}),
  };

  const [universidades, total, pendentes] = await Promise.all([
    repo.listAdmin(prisma, { where, skip, take }),
    repo.count(prisma, where),
    repo.count(prisma, { status: 'P' }),
  ]);

  return {
    data: universidades.map(paraListaAdmin),
    // `pendentes` alimenta o contador da aba "Pendentes de aprovação".
    meta: { ...buildMeta({ page, pageSize, total }), pendentes },
  };
}

async function obterCadastro(prisma, id) {
  const universidade = await repo.findCadastro(prisma, id);
  if (!universidade) {
    throw AppError.notFound('Universidade não encontrada');
  }
  return paraCadastro(universidade);
}

function dadosDaTransicao(acao, { motivo }, req) {
  switch (acao) {
    case 'aprovar':
      return { status: 'A', aprovadoEm: new Date(), aprovadoPor: req.user.id, motivoReprovacao: null };
    case 'reprovar':
      return { status: 'R', motivoReprovacao: motivo };
    case 'inativar':
      return { status: 'I' };
    case 'reativar':
      return { status: 'A' };
    default:
      throw new Error(`Ação desconhecida: ${acao}`);
  }
}

function avisoDaTransicao(acao, universidade, motivo) {
  const nome = universidade.nomeFantasia;
  switch (acao) {
    case 'aprovar':
      return {
        tipo: 'UNIVERSIDADE_APROVADA',
        titulo: 'Cadastro aprovado',
        mensagem: `${nome} foi aprovada e já aparece na pesquisa do Guia Jovem.`,
        assunto: 'Seu cadastro foi aprovado - Guia Jovem',
        html: `<p>Olá!</p><p>O cadastro de <strong>${escaparHtml(nome)}</strong> foi aprovado pela equipe Guia Jovem. A página da instituição já aparece na pesquisa de universidades.</p>`,
      };
    case 'reprovar':
      return {
        tipo: 'UNIVERSIDADE_REPROVADA',
        titulo: 'Cadastro reprovado',
        mensagem: `Motivo: ${motivo}`,
        assunto: 'Seu cadastro não foi aprovado - Guia Jovem',
        html: `<p>Olá!</p><p>O cadastro de <strong>${escaparHtml(nome)}</strong> não foi aprovado pela equipe Guia Jovem.</p><p>Motivo: ${escaparHtml(motivo)}</p>`,
      };
    case 'inativar':
      return {
        tipo: 'UNIVERSIDADE_INATIVADA',
        titulo: 'Universidade inativada',
        mensagem: `${nome} foi inativada pela equipe Guia Jovem e não aparece mais no site.`,
        assunto: 'Sua universidade foi inativada - Guia Jovem',
        html: `<p>Olá!</p><p><strong>${escaparHtml(nome)}</strong> foi inativada pela equipe Guia Jovem e deixou de aparecer no site. Em caso de dúvida, responda a este e-mail.</p>`,
      };
    case 'reativar':
      return {
        tipo: 'UNIVERSIDADE_REATIVADA',
        titulo: 'Universidade reativada',
        mensagem: `${nome} voltou a aparecer na pesquisa do Guia Jovem.`,
        assunto: 'Sua universidade foi reativada - Guia Jovem',
        html: `<p>Olá!</p><p><strong>${escaparHtml(nome)}</strong> foi reativada pela equipe Guia Jovem e voltou a aparecer no site.</p>`,
      };
    default:
      throw new Error(`Ação desconhecida: ${acao}`);
  }
}

/**
 * Aplica uma das ações de TRANSICOES. Status, auditoria e notificação são
 * gravados na mesma transação; o e-mail vai depois e uma falha no envio só
 * é registrada no log do servidor, sem desfazer a decisão.
 */
async function alterarStatus(prisma, id, acao, body, req) {
  const transicao = TRANSICOES[acao];
  const motivo = body?.motivo ?? null;

  const universidade = await repo.findParaTransicao(prisma, id);
  if (!universidade) {
    throw AppError.notFound('Universidade não encontrada');
  }
  if (!transicao.de.includes(universidade.status)) {
    throw AppError.conflict('STATUS_INVALIDO', transicao.erro);
  }
  // Universidade que nunca foi aprovada (ex.: pendente cuja conta foi
  // excluída) não volta para o site por "reativar".
  if (acao === 'reativar' && !universidade.aprovadoEm) {
    throw AppError.conflict(
      'STATUS_INVALIDO',
      'Esta universidade nunca foi aprovada, então não pode ser reativada',
    );
  }

  const dados = dadosDaTransicao(acao, { motivo }, req);
  const aviso = avisoDaTransicao(acao, universidade, motivo);

  await prisma.$transaction(async (tx) => {
    const { count } = await repo.atualizarStatusSe(tx, id, transicao.de, dados);
    if (count === 0) {
      // Outro administrador decidiu entre a leitura e a gravação.
      throw AppError.conflict('STATUS_INVALIDO', transicao.erro);
    }

    await req.registrarAuditoria(
      {
        acao: 'UPDATE',
        entidade: 'universidade',
        entidadeId: id,
        dadosAntes: { status: universidade.status, motivoReprovacao: universidade.motivoReprovacao },
        dadosDepois: {
          acao,
          status: dados.status,
          motivoReprovacao: 'motivoReprovacao' in dados ? dados.motivoReprovacao : universidade.motivoReprovacao,
        },
      },
      tx,
    );

    await notificacoesService.notificar(tx, [universidade.usuarioId], {
      tipo: aviso.tipo,
      titulo: aviso.titulo,
      mensagem: limitar(aviso.mensagem, LIMITE_MENSAGEM_NOTIFICACAO),
      referenciaTipo: 'universidade',
      referenciaId: id,
    });
  });

  if (universidade.usuario?.email) {
    try {
      await enviarEmail({ para: universidade.usuario.email, assunto: aviso.assunto, html: aviso.html });
    } catch (erro) {
      console.error(`Falha ao enviar o e-mail de "${acao}" da universidade ${id}:`, erro.message);
    }
  }

  return obterCadastro(prisma, id);
}

module.exports = {
  TRANSICOES,
  listarAdmin,
  obterCadastro,
  alterarStatus,
};
