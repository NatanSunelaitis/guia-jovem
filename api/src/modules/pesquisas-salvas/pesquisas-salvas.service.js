const AppError = require('../../shared/errors/AppError');
const { buildMeta, parsePagination } = require('../../shared/utils/pagination');
const repo = require('./pesquisas-salvas.repository');

function paraPublico(pesquisa) {
  return {
    id: pesquisa.id,
    nome: pesquisa.nome,
    tipo: pesquisa.tipo,
    parametros: pesquisa.parametros,
    criadoEm: pesquisa.criadoEm,
  };
}

function erroNomeDuplicado() {
  return AppError.conflict(
    'PESQUISA_DUPLICADA',
    'Você já tem uma pesquisa salva com esse nome. Escolha outro nome.',
  );
}

async function criar(prisma, usuarioId, dados, req) {
  const existente = await repo.findPorNome(prisma, usuarioId, dados.nome);
  if (existente) {
    throw erroNomeDuplicado();
  }

  let pesquisa;
  try {
    pesquisa = await repo.create(prisma, {
      usuarioId,
      nome: dados.nome,
      tipo: dados.tipo,
      parametros: dados.parametros,
    });
  } catch (erro) {
    // Duas gravações simultâneas com o mesmo nome: a segunda esbarra no
    // índice único uk_pesquisa_salva_usuario_nome.
    if (erro?.code === 'P2002') {
      throw erroNomeDuplicado();
    }
    throw erro;
  }

  await req.registrarAuditoria({
    acao: 'CREATE',
    entidade: 'pesquisa_salva',
    entidadeId: pesquisa.id,
    dadosDepois: paraPublico(pesquisa),
  });

  return paraPublico(pesquisa);
}

async function listar(prisma, usuarioId, query) {
  const { page, pageSize, skip, take } = parsePagination(query);

  const [pesquisas, total] = await Promise.all([
    repo.list(prisma, usuarioId, { skip, take }),
    repo.count(prisma, usuarioId),
  ]);

  return { data: pesquisas.map(paraPublico), meta: buildMeta({ page, pageSize, total }) };
}

async function obter(prisma, id) {
  const pesquisa = await repo.findById(prisma, id);
  if (!pesquisa) {
    throw AppError.notFound('Pesquisa salva não encontrada');
  }
  return paraPublico(pesquisa);
}

async function excluir(prisma, id, req) {
  const pesquisa = await repo.findById(prisma, id);
  if (!pesquisa) {
    throw AppError.notFound('Pesquisa salva não encontrada');
  }

  await repo.remove(prisma, id);

  await req.registrarAuditoria({
    acao: 'DELETE',
    entidade: 'pesquisa_salva',
    entidadeId: id,
    dadosAntes: paraPublico(pesquisa),
  });
}

/** Resolvedor do dono para o ownership.middleware (porUsuario). */
async function donoDaPesquisa(prisma, id) {
  const pesquisa = await repo.findById(prisma, id);
  if (!pesquisa) {
    throw AppError.notFound('Pesquisa salva não encontrada');
  }
  return pesquisa.usuarioId;
}

module.exports = { paraPublico, criar, listar, obter, excluir, donoDaPesquisa };
