const AppError = require('../../shared/errors/AppError');
const { buildMeta, parsePagination } = require('../../shared/utils/pagination');
const repo = require('./favoritos.repository');

async function listar(prisma, usuarioId, query, paraLista) {
  const { page, pageSize, skip, take } = parsePagination(query);

  const [salvas, total] = await Promise.all([
    repo.list(prisma, usuarioId, { skip, take }),
    repo.count(prisma, usuarioId),
  ]);

  return {
    data: salvas.map((salva) => ({ ...paraLista(salva.universidade), salva: true, salvaEm: salva.criadoEm })),
    meta: buildMeta({ page, pageSize, total }),
  };
}

/**
 * Idempotente: salvar de novo uma universidade já salva não é erro.
 * Retorna `criada` para o controller escolher entre 201 e 200.
 */
async function salvar(prisma, usuarioId, universidadeId, req) {
  const universidade = await repo.universidadeAprovada(prisma, universidadeId);
  if (!universidade) {
    throw AppError.notFound('Universidade não encontrada');
  }

  const existente = await repo.find(prisma, usuarioId, universidadeId);
  if (existente) {
    return { criada: false, dados: { universidadeId, salva: true, salvaEm: existente.criadoEm } };
  }

  let salva;
  try {
    salva = await repo.create(prisma, usuarioId, universidadeId);
  } catch (erro) {
    // Dois cliques simultâneos: a segunda gravação esbarra na chave primária.
    if (erro?.code === 'P2002') {
      const atual = await repo.find(prisma, usuarioId, universidadeId);
      return { criada: false, dados: { universidadeId, salva: true, salvaEm: atual?.criadoEm ?? null } };
    }
    throw erro;
  }

  await req.registrarAuditoria({
    acao: 'CREATE',
    entidade: 'universidade_salva',
    entidadeId: universidadeId,
  });

  return { criada: true, dados: { universidadeId, salva: true, salvaEm: salva.criadoEm } };
}

/** Idempotente: remover uma universidade que não está salva responde sucesso. */
async function remover(prisma, usuarioId, universidadeId, req) {
  const { count } = await repo.remove(prisma, usuarioId, universidadeId);

  if (count > 0) {
    await req.registrarAuditoria({
      acao: 'DELETE',
      entidade: 'universidade_salva',
      entidadeId: universidadeId,
    });
  }
}

async function estaSalva(prisma, usuarioId, universidadeId) {
  return Boolean(await repo.find(prisma, usuarioId, universidadeId));
}

/** Conjunto dos ids, entre os informados, que o aluno salvou. */
async function idsSalvas(prisma, usuarioId, universidadeIds) {
  if (universidadeIds.length === 0) return new Set();
  const salvas = await repo.idsSalvasEntre(prisma, usuarioId, universidadeIds);
  return new Set(salvas.map((salva) => salva.universidadeId));
}

module.exports = { listar, salvar, remover, estaSalva, idsSalvas };
