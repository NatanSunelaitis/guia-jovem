const crypto = require('crypto');

const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

const env = require('../../config/env');
const { enviarEmail } = require('../../config/mailer');
const AppError = require('../../shared/errors/AppError');
const { verifyGoogleIdToken } = require('./google.util');
const { issueTokenPair, hashToken } = require('./token.util');

const BCRYPT_CUSTO = 12;
const RECUPERACAO_VALIDADE_MS = 60 * 60 * 1000; // 1h

function paraResumo(usuario) {
  return {
    id: usuario.id,
    nome: usuario.nome,
    email: usuario.email,
    tipoUsuario: usuario.tipoUsuario,
    fotoUrl: usuario.fotoUrl,
    ...(usuario.universidade
      ? { universidade: { id: usuario.universidade.id, status: usuario.universidade.status } }
      : {}),
  };
}

const INCLUDE_UNIVERSIDADE = {
  universidade: { select: { id: true, status: true } },
};

async function registrarAluno(prisma, { nome, email, senha }, req) {
  const existente = await prisma.usuario.findUnique({ where: { email } });
  if (existente) {
    throw AppError.conflict('EMAIL_EM_USO', 'Este e-mail já está em uso');
  }

  const senhaHash = await bcrypt.hash(senha, BCRYPT_CUSTO);

  const usuario = await prisma.usuario.create({
    data: { nome, email, senhaHash, tipoUsuario: 'A' },
  });

  await req.registrarAuditoria({
    acao: 'CREATE',
    entidade: 'usuario',
    entidadeId: usuario.id,
    dadosDepois: { nome: usuario.nome, email: usuario.email, tipoUsuario: usuario.tipoUsuario },
  });

  const tokens = await issueTokenPair(prisma, usuario);
  return { ...tokens, usuario: paraResumo(usuario) };
}

async function registrarUniversidade(prisma, dados, req) {
  const { usuario: dadosUsuario, universidade: dadosUniversidade, programasIds, campus: dadosCampus } = dados;

  const emailEmUso = await prisma.usuario.findUnique({ where: { email: dadosUsuario.email } });
  if (emailEmUso) {
    throw AppError.conflict('EMAIL_EM_USO', 'Este e-mail já está em uso');
  }

  const cnpjEmUso = await prisma.universidade.findUnique({ where: { cnpj: dadosUniversidade.cnpj } });
  if (cnpjEmUso) {
    throw AppError.conflict('CNPJ_EM_USO', 'Este CNPJ já está cadastrado');
  }

  const senhaHash = await bcrypt.hash(dadosUsuario.senha, BCRYPT_CUSTO);

  const { usuario, universidade } = await prisma.$transaction(async (tx) => {
    const usuarioCriado = await tx.usuario.create({
      data: { nome: dadosUsuario.nome, email: dadosUsuario.email, senhaHash, tipoUsuario: 'U' },
    });

    const universidadeCriada = await tx.universidade.create({
      data: {
        usuarioId: usuarioCriado.id,
        razaoSocial: dadosUniversidade.razaoSocial,
        nomeFantasia: dadosUniversidade.nomeFantasia,
        cnpj: dadosUniversidade.cnpj,
        telefonePrincipal: dadosUniversidade.telefonePrincipal ?? null,
        linkPagina: dadosUniversidade.linkPagina ?? null,
        linkSimulados: dadosUniversidade.linkSimulados ?? null,
        natureza: dadosUniversidade.natureza,
        status: 'P',
      },
    });

    if (programasIds.length > 0) {
      await tx.universidadePrograma.createMany({
        data: programasIds.map((programaId) => ({ universidadeId: universidadeCriada.id, programaId })),
      });
    }

    const endereco = await tx.endereco.create({ data: dadosCampus.endereco });
    await tx.campus.create({
      data: {
        universidadeId: universidadeCriada.id,
        enderecoId: endereco.id,
        nome: dadosCampus.nome,
        telefoneCelular: dadosCampus.telefoneCelular ?? null,
        telefoneFixo: dadosCampus.telefoneFixo ?? null,
        emailCampus: dadosCampus.emailCampus ?? null,
        principal: true,
      },
    });

    await req.registrarAuditoria(
      {
        acao: 'CREATE',
        entidade: 'universidade',
        entidadeId: universidadeCriada.id,
        dadosDepois: { nomeFantasia: universidadeCriada.nomeFantasia, status: universidadeCriada.status },
      },
      tx,
    );

    return { usuario: usuarioCriado, universidade: universidadeCriada };
  });

  // RF25: avisa os administradores para a análise do cadastro (seção 5.1).
  const admins = await prisma.usuario.findMany({ where: { tipoUsuario: 'D', ativo: true }, select: { id: true } });
  if (admins.length > 0) {
    await prisma.notificacao.createMany({
      data: admins.map((admin) => ({
        usuarioId: admin.id,
        tipo: 'UNIVERSIDADE_PENDENTE',
        titulo: 'Nova universidade aguardando aprovação',
        mensagem: `${universidade.nomeFantasia} enviou um cadastro para análise.`,
        referenciaTipo: 'universidade',
        referenciaId: universidade.id,
      })),
    });
  }

  const tokens = await issueTokenPair(prisma, usuario);
  return {
    ...tokens,
    usuario: paraResumo({ ...usuario, universidade: { id: universidade.id, status: universidade.status } }),
  };
}

async function login(prisma, { email, senha }, req) {
  const usuario = await prisma.usuario.findUnique({
    where: { email },
    include: INCLUDE_UNIVERSIDADE,
  });

  if (!usuario || !usuario.ativo || !usuario.senhaHash) {
    throw new AppError('CREDENCIAIS_INVALIDAS', 'E-mail ou senha inválidos', 401);
  }

  const senhaConfere = await bcrypt.compare(senha, usuario.senhaHash);
  if (!senhaConfere) {
    throw new AppError('CREDENCIAIS_INVALIDAS', 'E-mail ou senha inválidos', 401);
  }

  await req.registrarAuditoria({ acao: 'LOGIN', entidade: 'usuario', entidadeId: usuario.id });

  const tokens = await issueTokenPair(prisma, usuario);
  return { ...tokens, usuario: paraResumo(usuario) };
}

async function loginComGoogle(prisma, { idToken }, req) {
  const perfilGoogle = await verifyGoogleIdToken(idToken);

  let usuario = await prisma.usuario.findUnique({
    where: { googleId: perfilGoogle.googleId },
    include: INCLUDE_UNIVERSIDADE,
  });

  if (!usuario) {
    const porEmail = await prisma.usuario.findUnique({
      where: { email: perfilGoogle.email },
      include: INCLUDE_UNIVERSIDADE,
    });

    if (porEmail) {
      if (porEmail.tipoUsuario !== 'A') {
        throw AppError.forbidden('Esta conta não pode ser acessada com o Google');
      }

      usuario = await prisma.usuario.update({
        where: { id: porEmail.id },
        data: { googleId: perfilGoogle.googleId, fotoUrl: porEmail.fotoUrl ?? perfilGoogle.fotoUrl },
        include: INCLUDE_UNIVERSIDADE,
      });

      await req.registrarAuditoria({ acao: 'UPDATE', entidade: 'usuario', entidadeId: usuario.id });
    } else {
      usuario = await prisma.usuario.create({
        data: {
          nome: perfilGoogle.nome,
          email: perfilGoogle.email,
          googleId: perfilGoogle.googleId,
          fotoUrl: perfilGoogle.fotoUrl,
          tipoUsuario: 'A',
        },
      });

      await req.registrarAuditoria({
        acao: 'CREATE',
        entidade: 'usuario',
        entidadeId: usuario.id,
        dadosDepois: { nome: usuario.nome, email: usuario.email, tipoUsuario: usuario.tipoUsuario },
      });
    }
  } else {
    await req.registrarAuditoria({ acao: 'LOGIN', entidade: 'usuario', entidadeId: usuario.id });
  }

  if (!usuario.ativo) {
    throw new AppError('CREDENCIAIS_INVALIDAS', 'Conta desativada', 401);
  }

  const tokens = await issueTokenPair(prisma, usuario);
  return { ...tokens, usuario: paraResumo(usuario) };
}

async function refresh(prisma, { refreshToken }) {
  let payload;
  try {
    payload = jwt.verify(refreshToken, env.JWT_REFRESH_SECRET);
  } catch (erro) {
    throw AppError.unauthenticated('Refresh token inválido ou expirado');
  }

  const tokenHash = hashToken(refreshToken);
  const registro = await prisma.refreshToken.findUnique({ where: { tokenHash } });

  if (!registro || registro.revogadoEm || registro.usuarioId !== payload.sub) {
    throw AppError.unauthenticated('Refresh token inválido ou expirado');
  }

  const usuario = await prisma.usuario.findUnique({
    where: { id: registro.usuarioId },
    include: INCLUDE_UNIVERSIDADE,
  });

  if (!usuario || !usuario.ativo) {
    throw AppError.unauthenticated('Refresh token inválido ou expirado');
  }

  await prisma.refreshToken.update({
    where: { id: registro.id },
    data: { revogadoEm: new Date() },
  });

  return issueTokenPair(prisma, usuario);
}

async function logout(prisma, { refreshToken }, req) {
  const tokenHash = hashToken(refreshToken);
  const registro = await prisma.refreshToken.findUnique({ where: { tokenHash } });

  if (registro && !registro.revogadoEm) {
    await prisma.refreshToken.update({
      where: { id: registro.id },
      data: { revogadoEm: new Date() },
    });
  }

  await req.registrarAuditoria({ acao: 'LOGOUT', entidade: 'usuario', entidadeId: req.user.id });
}

async function forgotPassword(prisma, { email }, req) {
  const usuario = await prisma.usuario.findUnique({ where: { email } });

  if (usuario && usuario.ativo) {
    const tokenBruto = crypto.randomBytes(32).toString('hex');

    await prisma.tokenRecuperacao.create({
      data: {
        usuarioId: usuario.id,
        tokenHash: hashToken(tokenBruto),
        expiraEm: new Date(Date.now() + RECUPERACAO_VALIDADE_MS),
      },
    });

    await req.registrarAuditoria({
      acao: 'CREATE',
      entidade: 'token_recuperacao',
      entidadeId: usuario.id,
    });

    const link = `${env.APP_URL}/#/redefinir-senha?token=${tokenBruto}`;
    await enviarEmail({
      para: usuario.email,
      assunto: 'Recuperação de senha - Guia Jovem',
      html: `<p>Olá, ${usuario.nome}.</p><p>Clique no link abaixo para redefinir sua senha. O link é válido por 1 hora.</p><p><a href="${link}">${link}</a></p>`,
    });
  }

  // Resposta neutra: nunca revela se o e-mail existe (seção 6, regra 4).
}

async function resetPassword(prisma, { token, novaSenha }, req) {
  const tokenHash = hashToken(token);
  const registro = await prisma.tokenRecuperacao.findUnique({ where: { tokenHash } });

  if (!registro || registro.usadoEm || registro.expiraEm < new Date()) {
    throw new AppError('TOKEN_INVALIDO', 'Token inválido ou expirado', 400);
  }

  const senhaHash = await bcrypt.hash(novaSenha, BCRYPT_CUSTO);

  await prisma.$transaction([
    prisma.usuario.update({ where: { id: registro.usuarioId }, data: { senhaHash } }),
    prisma.tokenRecuperacao.update({ where: { id: registro.id }, data: { usadoEm: new Date() } }),
    prisma.refreshToken.updateMany({
      where: { usuarioId: registro.usuarioId, revogadoEm: null },
      data: { revogadoEm: new Date() },
    }),
  ]);

  await req.registrarAuditoria({
    acao: 'UPDATE',
    entidade: 'usuario',
    entidadeId: registro.usuarioId,
    dadosDepois: { senhaAlterada: true },
  });
}

async function me(prisma, usuarioId) {
  const usuario = await prisma.usuario.findUnique({
    where: { id: usuarioId },
    include: INCLUDE_UNIVERSIDADE,
  });

  if (!usuario) {
    throw AppError.notFound('Usuário não encontrado');
  }

  return paraResumo(usuario);
}

module.exports = {
  paraResumo,
  registrarAluno,
  registrarUniversidade,
  login,
  loginComGoogle,
  refresh,
  logout,
  forgotPassword,
  resetPassword,
  me,
};
