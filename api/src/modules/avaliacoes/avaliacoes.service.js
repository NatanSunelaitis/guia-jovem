const AppError = require('../../shared/errors/AppError');
const { buildMeta, parsePagination } = require('../../shared/utils/pagination');
const repo = require('./avaliacoes.repository');

function paraPublico(avaliacao) {
  return {
    id: avaliacao.id,
    universidadeId: avaliacao.universidadeId,
    nota: avaliacao.nota,
    comentario: avaliacao.comentario,
    criadoEm: avaliacao.criadoEm,
  };
}

function resumoMedia(universidade) {
  return {
    id: universidade.id,
    mediaAvaliacao: universidade.mediaAvaliacao,
    totalAvaliacoes: universidade.totalAvaliacoes,
  };
}

function erroDuplicada() {
  return AppError.conflict(
    'AVALIACAO_DUPLICADA',
    'Você já avaliou esta universidade. Edite a sua avaliação.',
  );
}

/** RF01: recalcula media_avaliacao e total_avaliacoes dentro da transação. */
async function recalcularMedia(tx, universidadeId) {
  const agregado = await repo.agregarNotas(tx, universidadeId);
  const totalAvaliacoes = agregado._count._all;
  const mediaAvaliacao =
    totalAvaliacoes > 0 ? Math.round(Number(agregado._avg.nota) * 100) / 100 : null;

  return repo.atualizarMedia(tx, universidadeId, { mediaAvaliacao, totalAvaliacoes });
}

async function criar(prisma, universidadeId, dados, req) {
  const universidade = await repo.universidadeAprovada(prisma, universidadeId);
  if (!universidade) {
    throw AppError.notFound('Universidade não encontrada');
  }

  const existente = await repo.findDoUsuario(prisma, req.user.id, universidadeId);
  if (existente) {
    throw erroDuplicada();
  }

  try {
    return await prisma.$transaction(async (tx) => {
      await repo.travarUniversidade(tx, universidadeId);

      const avaliacao = await repo.create(tx, {
        usuarioId: req.user.id,
        universidadeId,
        nota: dados.nota,
        comentario: dados.comentario,
      });

      const universidadeAtualizada = await recalcularMedia(tx, universidadeId);

      await req.registrarAuditoria(
        {
          acao: 'CREATE',
          entidade: 'avaliacao',
          entidadeId: avaliacao.id,
          dadosDepois: paraPublico(avaliacao),
        },
        tx,
      );

      return { ...paraPublico(avaliacao), universidade: resumoMedia(universidadeAtualizada) };
    });
  } catch (erro) {
    // Duas requisições simultâneas do mesmo aluno: a segunda esbarra no
    // índice único uk_avaliacao_usuario_univ.
    if (erro?.code === 'P2002') {
      throw erroDuplicada();
    }
    throw erro;
  }
}

async function atualizar(prisma, id, dados, req) {
  const atual = await repo.findById(prisma, id);
  if (!atual) {
    throw AppError.notFound('Avaliação não encontrada');
  }

  const universidade = await repo.universidadeAprovada(prisma, atual.universidadeId);
  if (!universidade) {
    throw AppError.notFound('Universidade não encontrada');
  }

  return prisma.$transaction(async (tx) => {
    await repo.travarUniversidade(tx, atual.universidadeId);

    const avaliacao = await repo.update(tx, id, { nota: dados.nota, comentario: dados.comentario });
    const universidadeAtualizada = await recalcularMedia(tx, atual.universidadeId);

    await req.registrarAuditoria(
      {
        acao: 'UPDATE',
        entidade: 'avaliacao',
        entidadeId: id,
        dadosAntes: paraPublico(atual),
        dadosDepois: paraPublico(avaliacao),
      },
      tx,
    );

    return { ...paraPublico(avaliacao), universidade: resumoMedia(universidadeAtualizada) };
  });
}

async function excluir(prisma, id, req) {
  const atual = await repo.findById(prisma, id);
  if (!atual) {
    throw AppError.notFound('Avaliação não encontrada');
  }

  return prisma.$transaction(async (tx) => {
    await repo.travarUniversidade(tx, atual.universidadeId);
    await repo.remove(tx, id);
    const universidadeAtualizada = await recalcularMedia(tx, atual.universidadeId);

    await req.registrarAuditoria(
      { acao: 'DELETE', entidade: 'avaliacao', entidadeId: id, dadosAntes: paraPublico(atual) },
      tx,
    );

    return { universidade: resumoMedia(universidadeAtualizada) };
  });
}

async function listarMinhas(prisma, usuarioId, query) {
  const { page, pageSize, skip, take } = parsePagination(query);

  const [avaliacoes, total] = await Promise.all([
    repo.listDoUsuario(prisma, usuarioId, { skip, take }),
    repo.countDoUsuario(prisma, usuarioId),
  ]);

  return {
    data: avaliacoes.map((avaliacao) => ({
      ...paraPublico(avaliacao),
      universidade: {
        id: avaliacao.universidade.id,
        nomeFantasia: avaliacao.universidade.nomeFantasia,
        logoUrl: avaliacao.universidade.logoUrl,
      },
    })),
    meta: buildMeta({ page, pageSize, total }),
  };
}

/** Usado pelo detalhe da universidade para o app saber se o aluno já avaliou. */
async function minhaAvaliacao(prisma, usuarioId, universidadeId) {
  const avaliacao = await repo.findDoUsuario(prisma, usuarioId, universidadeId);
  return avaliacao ? paraPublico(avaliacao) : null;
}

/** Resolvedor do dono para o ownership.middleware (porUsuario). */
async function donoDaAvaliacao(prisma, id) {
  const avaliacao = await repo.findById(prisma, id);
  if (!avaliacao) {
    throw AppError.notFound('Avaliação não encontrada');
  }
  return avaliacao.usuarioId;
}

module.exports = {
  paraPublico,
  recalcularMedia,
  criar,
  atualizar,
  excluir,
  listarMinhas,
  minhaAvaliacao,
  donoDaAvaliacao,
};
