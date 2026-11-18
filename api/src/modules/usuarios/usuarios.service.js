const bcrypt = require('bcryptjs');

const AppError = require('../../shared/errors/AppError');
const { buildMeta, parsePagination } = require('../../shared/utils/pagination');
const repo = require('./usuarios.repository');

const BCRYPT_CUSTO = 12;

function paraPublico(usuario) {
  return {
    id: usuario.id,
    nome: usuario.nome,
    email: usuario.email,
    tipoUsuario: usuario.tipoUsuario,
    fotoUrl: usuario.fotoUrl,
    ativo: usuario.ativo,
    criadoEm: usuario.criadoEm,
  };
}

function garantirDonoOuAdmin(actor, usuarioId) {
  if (actor.tipoUsuario !== 'D' && actor.id !== usuarioId) {
    throw AppError.forbidden();
  }
}

/**
 * Quadro 14: a única conta de administrador ativa não pode ser inativada,
 * excluída nem perder o perfil de administrador. Chamar dentro da transação
 * que faz a alteração.
 */
async function garantirOutroAdministradorAtivo(tx, usuarioId) {
  await repo.travarAdministradoresAtivos(tx);
  const outros = await repo.contarOutrosAdministradoresAtivos(tx, usuarioId);
  if (outros === 0) {
    throw AppError.conflict(
      'ULTIMO_ADMINISTRADOR',
      'Esta é a única conta de administrador ativa. Ative ou cadastre outro administrador antes de inativar, excluir ou mudar o perfil desta conta.',
    );
  }
}

function deixaDeSerAdministradorAtivo(usuario, dados) {
  if (usuario.tipoUsuario !== 'D' || !usuario.ativo) return false;
  return dados.ativo === false || (dados.tipoUsuario !== undefined && dados.tipoUsuario !== 'D');
}

async function listar(prisma, query) {
  const { page, pageSize, skip, take } = parsePagination(query);

  const where = {
    ...(query.tipoUsuario ? { tipoUsuario: query.tipoUsuario } : {}),
    ...(query.ativo !== undefined ? { ativo: query.ativo } : {}),
    ...(query.busca
      ? {
          OR: [
            { nome: { contains: query.busca } },
            { email: { contains: query.busca } },
          ],
        }
      : {}),
  };

  const [usuarios, total] = await Promise.all([
    repo.list(prisma, { where, skip, take }),
    repo.count(prisma, where),
  ]);

  return {
    data: usuarios.map(paraPublico),
    meta: buildMeta({ page, pageSize, total }),
  };
}

async function obter(prisma, id, actor) {
  garantirDonoOuAdmin(actor, id);

  const usuario = await repo.findById(prisma, id);
  if (!usuario) {
    throw AppError.notFound('Usuário não encontrado');
  }

  return paraPublico(usuario);
}

async function criar(prisma, dados, req) {
  const existente = await repo.findByEmail(prisma, dados.email);
  if (existente) {
    throw AppError.conflict('EMAIL_EM_USO', 'Este e-mail já está em uso');
  }

  const senhaHash = await bcrypt.hash(dados.senha, BCRYPT_CUSTO);

  const usuario = await repo.create(prisma, {
    nome: dados.nome,
    email: dados.email,
    senhaHash,
    tipoUsuario: dados.tipoUsuario,
    cpf: dados.tipoUsuario === 'D' ? dados.cpf ?? null : null,
  });

  await req.registrarAuditoria({
    acao: 'CREATE',
    entidade: 'usuario',
    entidadeId: usuario.id,
    dadosDepois: { nome: usuario.nome, email: usuario.email, tipoUsuario: usuario.tipoUsuario },
  });

  return paraPublico(usuario);
}

async function atualizar(prisma, id, dados, actor, req) {
  garantirDonoOuAdmin(actor, id);

  const usuarioAtual = await repo.findById(prisma, id);
  if (!usuarioAtual) {
    throw AppError.notFound('Usuário não encontrado');
  }

  const alterandoCamposDeAdmin = 'tipoUsuario' in dados || 'ativo' in dados;
  if (alterandoCamposDeAdmin && actor.tipoUsuario !== 'D') {
    throw AppError.forbidden('Apenas o administrador pode alterar tipoUsuario ou ativo');
  }

  // Usuário tipo U só existe vinculado a uma universidade (criada via
  // /auth/register/universidade, Fase 3); mudar o tipo aqui deixaria esse
  // vínculo inconsistente, então essa transição fica bloqueada por ora.
  if ('tipoUsuario' in dados && usuarioAtual.tipoUsuario === 'U') {
    throw AppError.forbidden(
      'Não é possível alterar o tipo de um usuário Universidade por este endpoint',
    );
  }

  const dadosAntes = paraPublico(usuarioAtual);

  const usuario = await prisma.$transaction(async (tx) => {
    if (deixaDeSerAdministradorAtivo(usuarioAtual, dados)) {
      await garantirOutroAdministradorAtivo(tx, id);
    }

    const atualizado = await repo.update(tx, id, dados);

    await req.registrarAuditoria(
      {
        acao: 'UPDATE',
        entidade: 'usuario',
        entidadeId: id,
        dadosAntes,
        dadosDepois: paraPublico(atualizado),
      },
      tx,
    );

    return atualizado;
  });

  return paraPublico(usuario);
}

async function alterarSenha(prisma, id, { senhaAtual, novaSenha }, actor, req) {
  if (actor.id !== id) {
    throw AppError.forbidden('Só é possível alterar a própria senha');
  }

  const usuario = await repo.findById(prisma, id);
  if (!usuario) {
    throw AppError.notFound('Usuário não encontrado');
  }

  if (!usuario.senhaHash) {
    throw new AppError(
      'SEM_SENHA_DEFINIDA',
      'Esta conta usa login com Google e ainda não tem senha definida',
      400,
    );
  }

  const senhaConfere = await bcrypt.compare(senhaAtual, usuario.senhaHash);
  if (!senhaConfere) {
    throw new AppError('SENHA_ATUAL_INVALIDA', 'Senha atual incorreta', 400);
  }

  const senhaHash = await bcrypt.hash(novaSenha, BCRYPT_CUSTO);
  await repo.update(prisma, id, { senhaHash });
  await prisma.refreshToken.updateMany({
    where: { usuarioId: id, revogadoEm: null },
    data: { revogadoEm: new Date() },
  });

  await req.registrarAuditoria({
    acao: 'UPDATE',
    entidade: 'usuario',
    entidadeId: id,
    dadosDepois: { senhaAlterada: true },
  });
}

async function confirmacaoDeExclusaoValida(usuario, { confirmacao, senhaAtual }) {
  if (confirmacao === 'EXCLUIR') return true;
  if (senhaAtual && usuario.senhaHash) {
    return bcrypt.compare(senhaAtual, usuario.senhaHash);
  }
  return false;
}

async function excluir(prisma, id, body, actor, req) {
  garantirDonoOuAdmin(actor, id);

  const usuario = await repo.findById(prisma, id);
  if (!usuario) {
    throw AppError.notFound('Usuário não encontrado');
  }

  const confirmado = await confirmacaoDeExclusaoValida(usuario, body);
  if (!confirmado) {
    throw AppError.validation([
      { campo: 'confirmacao', mensagem: 'Informe "EXCLUIR" ou a senha atual para confirmar' },
    ]);
  }

  const dadosAntes = { nome: usuario.nome, email: usuario.email, tipoUsuario: usuario.tipoUsuario };

  await prisma.$transaction(async (tx) => {
    // Vale também para o administrador excluindo a própria conta.
    if (usuario.tipoUsuario === 'D' && usuario.ativo) {
      await garantirOutroAdministradorAtivo(tx, id);
    }

    if (usuario.tipoUsuario === 'U') {
      await repo.inativarUniversidadeDoDono(tx, id);
    }

    await req.registrarAuditoria(
      { acao: 'DELETE', entidade: 'usuario', entidadeId: id, dadosAntes },
      tx,
    );

    await tx.usuario.delete({ where: { id } });
  });
}

module.exports = {
  paraPublico,
  listar,
  obter,
  criar,
  atualizar,
  alterarSenha,
  excluir,
};
