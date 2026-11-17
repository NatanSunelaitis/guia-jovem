const AppError = require('../../shared/errors/AppError');
const { buildMeta, parsePagination } = require('../../shared/utils/pagination');
const notificacoesService = require('../notificacoes/notificacoes.service');
const repo = require('./sugestoes.repository');

const ROTULO_STATUS = { APROVADA: 'aprovada', REPROVADA: 'reprovada' };

/** Notificacao.mensagem é VARCHAR(255). */
function limitar(texto, maximo = 255) {
  return texto.length <= maximo ? texto : `${texto.slice(0, maximo - 1)}…`;
}

function nomeDoDestino(sugestao) {
  return sugestao.universidade?.nomeFantasia ?? 'Equipe Guia Jovem';
}

/**
 * Destinatário da sugestão (RF08): sem universidade, a administração (todo
 * D); com universidade, a conta U que a administra.
 */
function ehDestinatario(sugestao, usuario) {
  if (sugestao.universidadeId == null) {
    return usuario.tipoUsuario === 'D';
  }
  return usuario.tipoUsuario === 'U' && Number(usuario.universidadeId) === sugestao.universidadeId;
}

function ehAutor(sugestao, usuario) {
  return sugestao.usuarioId != null && sugestao.usuarioId === usuario.id;
}

function paraPublico(sugestao) {
  return {
    id: sugestao.id,
    titulo: sugestao.titulo,
    texto: sugestao.texto,
    status: sugestao.status,
    resposta: sugestao.resposta,
    criadoEm: sugestao.criadoEm,
    avaliadoEm: sugestao.avaliadoEm,
    universidade: sugestao.universidade
      ? { id: sugestao.universidade.id, nomeFantasia: sugestao.universidade.nomeFantasia }
      : null,
  };
}

/** Para o destinatário: inclui o nome do autor (null se a conta foi excluída). */
function paraDestinatario(sugestao) {
  return { ...paraPublico(sugestao), autor: sugestao.usuario ? { nome: sugestao.usuario.nome } : null };
}

async function criar(prisma, dados, req) {
  let universidade = null;
  if (dados.universidadeId) {
    universidade = await repo.universidadeAprovada(prisma, dados.universidadeId);
    if (!universidade) {
      throw new AppError('UNIVERSIDADE_INVALIDA', 'Escolha uma universidade aprovada ou envie para a equipe Guia Jovem', 400, [
        { campo: 'universidadeId', mensagem: 'Universidade não encontrada' },
      ]);
    }
  }

  return prisma.$transaction(async (tx) => {
    // status EM_ANALISE e criado_em vêm do default do banco (data do servidor).
    const sugestao = await repo.create(tx, {
      usuarioId: req.user.id,
      universidadeId: universidade?.id ?? null,
      titulo: dados.titulo,
      texto: dados.texto,
    });

    await req.registrarAuditoria(
      {
        acao: 'CREATE',
        entidade: 'sugestao',
        entidadeId: sugestao.id,
        dadosDepois: { titulo: sugestao.titulo, universidadeId: sugestao.universidadeId, status: sugestao.status },
      },
      tx,
    );

    // RF14: notifica o destinatário junto com a criação.
    const destinatarios = universidade
      ? [universidade.usuarioId]
      : await notificacoesService.idsAdministradoresAtivos(tx);
    await notificacoesService.notificar(tx, destinatarios, {
      tipo: 'NOVA_SUGESTAO',
      titulo: 'Nova sugestão recebida',
      mensagem: limitar(`"${sugestao.titulo}" está aguardando avaliação.`),
      referenciaTipo: 'sugestao',
      referenciaId: sugestao.id,
    });

    return paraPublico(sugestao);
  });
}

async function listarMinhas(prisma, usuarioId, query) {
  const { page, pageSize, skip, take } = parsePagination(query);
  const where = { usuarioId };

  const [sugestoes, total] = await Promise.all([
    repo.list(prisma, { where, skip, take }),
    repo.count(prisma, where),
  ]);

  return { data: sugestoes.map(paraPublico), meta: buildMeta({ page, pageSize, total }) };
}

/** Sugestões recebidas: D vê as da administração; U, as da própria universidade. */
async function listarRecebidas(prisma, usuario, query) {
  if (usuario.tipoUsuario === 'U' && usuario.universidadeId == null) {
    throw AppError.forbidden();
  }

  const { page, pageSize, skip, take } = parsePagination(query);
  const where = {
    universidadeId: usuario.tipoUsuario === 'D' ? null : Number(usuario.universidadeId),
    ...(query.status ? { status: query.status } : {}),
  };

  const [sugestoes, total] = await Promise.all([
    repo.list(prisma, { where, skip, take }),
    repo.count(prisma, where),
  ]);

  return { data: sugestoes.map(paraDestinatario), meta: buildMeta({ page, pageSize, total }) };
}

async function buscarVisivel(prisma, id, usuario) {
  const sugestao = await repo.findById(prisma, id);
  if (!sugestao) {
    throw AppError.notFound('Sugestão não encontrada');
  }

  const destinatario = ehDestinatario(sugestao, usuario);
  if (!destinatario && !ehAutor(sugestao, usuario)) {
    throw AppError.forbidden();
  }
  return { sugestao, destinatario };
}

async function obterDetalhe(prisma, id, usuario) {
  const { sugestao, destinatario } = await buscarVisivel(prisma, id, usuario);
  return {
    ...paraDestinatario(sugestao),
    // O app mostra o formulário de avaliação só para o destinatário (RF15).
    podeAvaliar: destinatario && sugestao.status === 'EM_ANALISE',
  };
}

async function avaliar(prisma, id, dados, req) {
  const { sugestao, destinatario } = await buscarVisivel(prisma, id, req.user);
  if (!destinatario) {
    throw AppError.forbidden('Só o destinatário avalia a sugestão');
  }

  const erroJaAvaliada = AppError.conflict('SUGESTAO_JA_AVALIADA', 'Esta sugestão já foi avaliada');
  if (sugestao.status !== 'EM_ANALISE') {
    throw erroJaAvaliada;
  }

  return prisma.$transaction(async (tx) => {
    const { count } = await repo.avaliarSeEmAnalise(tx, id, {
      status: dados.status,
      resposta: dados.resposta,
      avaliadoPor: req.user.id,
      avaliadoEm: new Date(),
    });
    if (count === 0) {
      throw erroJaAvaliada;
    }

    const avaliada = await repo.findById(tx, id);

    await req.registrarAuditoria(
      {
        acao: 'UPDATE',
        entidade: 'sugestao',
        entidadeId: id,
        dadosAntes: { status: sugestao.status, resposta: sugestao.resposta },
        dadosDepois: { status: avaliada.status, resposta: avaliada.resposta },
      },
      tx,
    );

    // RF15: avisa o autor do resultado (sem autor quando a conta foi excluída).
    await notificacoesService.notificar(tx, [avaliada.usuarioId], {
      tipo: 'SUGESTAO_AVALIADA',
      titulo: `Sua sugestão foi ${ROTULO_STATUS[avaliada.status]}`,
      mensagem: limitar(`${nomeDoDestino(avaliada)} respondeu "${avaliada.titulo}".`),
      referenciaTipo: 'sugestao',
      referenciaId: id,
    });

    return { ...paraDestinatario(avaliada), podeAvaliar: false };
  });
}

module.exports = { criar, listarMinhas, listarRecebidas, obterDetalhe, avaliar };
