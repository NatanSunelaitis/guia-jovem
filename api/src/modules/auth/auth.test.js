const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const request = require('supertest');

jest.mock('../../config/database', () => require('../../../tests/helpers/mockPrisma'));
jest.mock('../../config/mailer', () => ({ enviarEmail: jest.fn().mockResolvedValue(undefined) }));
jest.mock('./google.util', () => ({ verifyGoogleIdToken: jest.fn() }));

const prisma = require('../../config/database');
const { enviarEmail } = require('../../config/mailer');
const { verifyGoogleIdToken } = require('./google.util');
const app = require('../../app');

const SENHA_HASH_123 = bcrypt.hashSync('senha1234', 12);

function usuarioFake(sobrescreve = {}) {
  return {
    id: 1,
    nome: 'Aluno Teste',
    email: 'aluno@example.com',
    senhaHash: SENHA_HASH_123,
    tipoUsuario: 'A',
    googleId: null,
    fotoUrl: null,
    ativo: true,
    universidade: null,
    ...sobrescreve,
  };
}

function accessTokenPara(usuario) {
  return jwt.sign(
    { sub: usuario.id, tipoUsuario: usuario.tipoUsuario, universidadeId: null },
    process.env.JWT_ACCESS_SECRET,
    { expiresIn: '15m' },
  );
}

beforeEach(() => {
  prisma.resetMockPrisma();
  enviarEmail.mockClear();
  verifyGoogleIdToken.mockReset();
});

describe('POST /api/v1/auth/register/aluno', () => {
  it('cria o usuário e retorna tokens (201)', async () => {
    prisma.usuario.findUnique.mockResolvedValue(null);
    prisma.usuario.create.mockResolvedValue(usuarioFake({ id: 10 }));

    const resposta = await request(app)
      .post('/api/v1/auth/register/aluno')
      .send({ nome: 'Aluno Teste', email: 'aluno@example.com', senha: 'senha1234' });

    expect(resposta.status).toBe(201);
    expect(resposta.body.data.usuario).toMatchObject({ id: 10, tipoUsuario: 'A' });
    expect(resposta.body.data.accessToken).toEqual(expect.any(String));
    expect(resposta.body.data.refreshToken).toEqual(expect.any(String));
    expect(prisma.logAuditoria.create).toHaveBeenCalled();
    // O cadastro já entra logado: conta nos logins únicos (RF16).
    expect(prisma.logAuditoria.create).toHaveBeenCalledWith({
      data: expect.objectContaining({ acao: 'LOGIN', entidade: 'usuario', entidadeId: 10 }),
    });
  });

  it('responde 409 EMAIL_EM_USO quando o e-mail já existe', async () => {
    prisma.usuario.findUnique.mockResolvedValue(usuarioFake());

    const resposta = await request(app)
      .post('/api/v1/auth/register/aluno')
      .send({ nome: 'Aluno Teste', email: 'aluno@example.com', senha: 'senha1234' });

    expect(resposta.status).toBe(409);
    expect(resposta.body.error.code).toBe('EMAIL_EM_USO');
  });

  it('responde 400 VALIDATION_ERROR com senha curta', async () => {
    const resposta = await request(app)
      .post('/api/v1/auth/register/aluno')
      .send({ nome: 'Aluno Teste', email: 'aluno@example.com', senha: '123' });

    expect(resposta.status).toBe(400);
    expect(resposta.body.error.code).toBe('VALIDATION_ERROR');
  });
});

describe('POST /api/v1/auth/register/universidade', () => {
  function corpoValido(sobrescreve = {}) {
    return {
      aceitouTermos: true,
      usuario: { nome: 'Responsável Fatec', email: 'contato@fatec-teste.edu.br', senha: 'senha1234' },
      universidade: {
        razaoSocial: 'Faculdade de Tecnologia Teste',
        nomeFantasia: 'Fatec Teste',
        cnpj: '11.222.333/0001-81',
        telefonePrincipal: '(15) 3223-1450',
        linkPagina: 'https://fatecteste.edu.br',
        natureza: 'P',
      },
      programasIds: [1, 2],
      campus: {
        nome: 'Fatec Teste',
        telefoneFixo: '(15) 3223-1450',
        endereco: {
          logradouro: 'Avenida Teste',
          numero: '100',
          bairro: 'Centro',
          cidade: 'Sorocaba',
          estado: 'sp',
          cep: '18000-000',
        },
      },
      ...sobrescreve,
    };
  }

  it('cria usuário U, universidade P, programas, campus e notifica admins (201)', async () => {
    prisma.usuario.findUnique.mockResolvedValue(null);
    prisma.universidade.findUnique.mockResolvedValue(null);
    prisma.usuario.create.mockResolvedValue(usuarioFake({ id: 20, tipoUsuario: 'U', senhaHash: null }));
    prisma.universidade.create.mockResolvedValue({ id: 5, nomeFantasia: 'Fatec Teste', status: 'P' });
    prisma.endereco.create.mockResolvedValue({ id: 30 });
    prisma.usuario.findMany.mockResolvedValue([{ id: 1 }, { id: 2 }]);

    const resposta = await request(app).post('/api/v1/auth/register/universidade').send(corpoValido());

    expect(resposta.status).toBe(201);
    expect(resposta.body.data.usuario).toMatchObject({ id: 20, tipoUsuario: 'U', universidade: { id: 5, status: 'P' } });
    expect(resposta.body.data.accessToken).toEqual(expect.any(String));
    // Sem o universidadeId no token, o painel da própria universidade daria 403.
    expect(jwt.decode(resposta.body.data.accessToken)).toMatchObject({ sub: 20, tipoUsuario: 'U', universidadeId: 5 });

    expect(prisma.universidade.create).toHaveBeenCalledWith(
      expect.objectContaining({ data: expect.objectContaining({ cnpj: '11222333000181', status: 'P' }) }),
    );
    expect(prisma.universidadePrograma.createMany).toHaveBeenCalledWith(
      expect.objectContaining({ data: [{ universidadeId: 5, programaId: 1 }, { universidadeId: 5, programaId: 2 }] }),
    );
    expect(prisma.campus.create).toHaveBeenCalledWith(
      expect.objectContaining({ data: expect.objectContaining({ principal: true, enderecoId: 30 }) }),
    );
    expect(prisma.notificacao.createMany).toHaveBeenCalledWith(
      expect.objectContaining({
        data: [
          expect.objectContaining({ usuarioId: 1, tipo: 'UNIVERSIDADE_PENDENTE' }),
          expect.objectContaining({ usuarioId: 2, tipo: 'UNIVERSIDADE_PENDENTE' }),
        ],
      }),
    );
  });

  it('responde 409 EMAIL_EM_USO quando o e-mail já existe', async () => {
    prisma.usuario.findUnique.mockResolvedValue(usuarioFake());

    const resposta = await request(app).post('/api/v1/auth/register/universidade').send(corpoValido());

    expect(resposta.status).toBe(409);
    expect(resposta.body.error.code).toBe('EMAIL_EM_USO');
  });

  it('responde 409 CNPJ_EM_USO quando o CNPJ já existe', async () => {
    prisma.usuario.findUnique.mockResolvedValue(null);
    prisma.universidade.findUnique.mockResolvedValue({ id: 9 });

    const resposta = await request(app).post('/api/v1/auth/register/universidade').send(corpoValido());

    expect(resposta.status).toBe(409);
    expect(resposta.body.error.code).toBe('CNPJ_EM_USO');
  });

  it('responde 400 quando aceitouTermos não é true', async () => {
    const resposta = await request(app)
      .post('/api/v1/auth/register/universidade')
      .send(corpoValido({ aceitouTermos: false }));

    expect(resposta.status).toBe(400);
    expect(resposta.body.error.code).toBe('VALIDATION_ERROR');
  });

  it('responde 400 com CNPJ inválido', async () => {
    const resposta = await request(app)
      .post('/api/v1/auth/register/universidade')
      .send(corpoValido({ universidade: { ...corpoValido().universidade, cnpj: '123' } }));

    expect(resposta.status).toBe(400);
    expect(resposta.body.error.code).toBe('VALIDATION_ERROR');
  });
});

describe('POST /api/v1/auth/login', () => {
  it('retorna tokens com credenciais corretas (200)', async () => {
    prisma.usuario.findUnique.mockResolvedValue(usuarioFake());

    const resposta = await request(app)
      .post('/api/v1/auth/login')
      .send({ email: 'aluno@example.com', senha: 'senha1234' });

    expect(resposta.status).toBe(200);
    expect(resposta.body.data.usuario.email).toBe('aluno@example.com');
    expect(resposta.body.data.accessToken).toEqual(expect.any(String));
  });

  it('responde 401 quando o usuário não existe', async () => {
    prisma.usuario.findUnique.mockResolvedValue(null);

    const resposta = await request(app)
      .post('/api/v1/auth/login')
      .send({ email: 'ninguem@example.com', senha: 'senha1234' });

    expect(resposta.status).toBe(401);
    expect(resposta.body.error.code).toBe('CREDENCIAIS_INVALIDAS');
  });

  it('responde 401 quando a senha está incorreta', async () => {
    prisma.usuario.findUnique.mockResolvedValue(usuarioFake());

    const resposta = await request(app)
      .post('/api/v1/auth/login')
      .send({ email: 'aluno@example.com', senha: 'senha-errada' });

    expect(resposta.status).toBe(401);
    expect(resposta.body.error.code).toBe('CREDENCIAIS_INVALIDAS');
  });
});

describe('POST /api/v1/auth/login: limite de tentativas (padrão de 10 falhas em 15 minutos)', () => {
  it('login certo repetido não bloqueia', async () => {
    prisma.usuario.findUnique.mockResolvedValue(usuarioFake());

    for (let i = 0; i < 12; i += 1) {
      const resposta = await request(app).post('/api/v1/auth/login').send({ email: 'repetido@example.com', senha: 'senha1234' });
      expect(resposta.status).toBe(200);
    }
  });

  it('a 11ª tentativa depois de 10 falhas é bloqueada com o tempo de espera, e a outra conta segue entrando', async () => {
    prisma.usuario.findUnique.mockResolvedValue(usuarioFake());
    for (let i = 0; i < 10; i += 1) {
      const falha = await request(app).post('/api/v1/auth/login').send({ email: 'bloqueado@example.com', senha: 'senha-errada' });
      expect(falha.status).toBe(401);
    }

    const bloqueio = await request(app).post('/api/v1/auth/login').send({ email: 'bloqueado@example.com', senha: 'senha1234' });
    const outra = await request(app).post('/api/v1/auth/login').send({ email: 'outra.pessoa@example.com', senha: 'senha1234' });

    expect(bloqueio.status).toBe(429);
    expect(bloqueio.body.error).toMatchObject({
      code: 'RATE_LIMITED',
      message: 'Muitas tentativas de login sem sucesso nesta conta. Tente novamente em 15 minutos.',
    });
    expect(outra.status).toBe(200);
  });
});

describe('POST /api/v1/auth/google', () => {
  it('recusa o token cujo e-mail o Google não verificou (401), sem criar nem vincular conta', async () => {
    verifyGoogleIdToken.mockResolvedValue({
      googleId: 'g-nv',
      email: 'nao-verificado@example.com',
      emailVerificado: false,
      nome: 'Sem Verificação',
      fotoUrl: null,
    });

    const resposta = await request(app).post('/api/v1/auth/google').send({ idToken: 'token-valido' });

    expect(resposta.status).toBe(401);
    expect(prisma.usuario.findUnique).not.toHaveBeenCalled();
    expect(prisma.usuario.create).not.toHaveBeenCalled();
    expect(prisma.usuario.update).not.toHaveBeenCalled();
  });

  it('cria uma nova conta quando não existe usuário com o e-mail ou googleId (200)', async () => {
    verifyGoogleIdToken.mockResolvedValue({ emailVerificado: true,
      googleId: 'g-123',
      email: 'novo@example.com',
      nome: 'Novo Aluno',
      fotoUrl: null,
    });
    prisma.usuario.findUnique.mockResolvedValue(null);
    prisma.usuario.create.mockResolvedValue(
      usuarioFake({ id: 20, email: 'novo@example.com', googleId: 'g-123', senhaHash: null }),
    );

    const resposta = await request(app).post('/api/v1/auth/google').send({ idToken: 'token-valido' });

    expect(resposta.status).toBe(200);
    expect(resposta.body.data.usuario.email).toBe('novo@example.com');
    expect(prisma.logAuditoria.create).toHaveBeenCalledWith({
      data: expect.objectContaining({ acao: 'LOGIN', entidade: 'usuario', entidadeId: 20 }),
    });
  });

  it('conta Google desativada não entra e não grava LOGIN (401)', async () => {
    verifyGoogleIdToken.mockResolvedValue({ emailVerificado: true, googleId: 'g-1', email: 'aluno@example.com', nome: 'Aluno', fotoUrl: null });
    prisma.usuario.findUnique.mockResolvedValue(usuarioFake({ googleId: 'g-1', ativo: false }));

    const resposta = await request(app).post('/api/v1/auth/google').send({ idToken: 'token-valido' });

    expect(resposta.status).toBe(401);
    expect(prisma.logAuditoria.create).not.toHaveBeenCalledWith({
      data: expect.objectContaining({ acao: 'LOGIN' }),
    });
  });

  it('vincula a conta existente por e-mail quando o tipo é aluno (200)', async () => {
    verifyGoogleIdToken.mockResolvedValue({ emailVerificado: true,
      googleId: 'g-999',
      email: 'aluno@example.com',
      nome: 'Aluno Teste',
      fotoUrl: null,
    });
    prisma.usuario.findUnique
      .mockResolvedValueOnce(null) // busca por googleId
      .mockResolvedValueOnce(usuarioFake()); // busca por email
    prisma.usuario.update.mockResolvedValue(usuarioFake({ googleId: 'g-999' }));

    const resposta = await request(app).post('/api/v1/auth/google').send({ idToken: 'token-valido' });

    expect(resposta.status).toBe(200);
    expect(prisma.usuario.update).toHaveBeenCalled();
  });

  it('responde 403 quando a conta com esse e-mail não é de aluno', async () => {
    verifyGoogleIdToken.mockResolvedValue({ emailVerificado: true,
      googleId: 'g-999',
      email: 'universidade@example.com',
      nome: 'Universidade',
      fotoUrl: null,
    });
    prisma.usuario.findUnique
      .mockResolvedValueOnce(null)
      .mockResolvedValueOnce(usuarioFake({ tipoUsuario: 'U', email: 'universidade@example.com' }));

    const resposta = await request(app).post('/api/v1/auth/google').send({ idToken: 'token-valido' });

    expect(resposta.status).toBe(403);
  });

  it('responde 401 quando o idToken é inválido', async () => {
    const AppError = require('../../shared/errors/AppError');
    verifyGoogleIdToken.mockRejectedValue(AppError.unauthenticated('Token do Google inválido ou expirado'));

    const resposta = await request(app).post('/api/v1/auth/google').send({ idToken: 'token-invalido' });

    expect(resposta.status).toBe(401);
  });
});

describe('POST /api/v1/auth/refresh', () => {
  it('rotaciona o refresh token válido (200)', async () => {
    const refreshToken = jwt.sign({ sub: 1, jti: 'abc' }, process.env.JWT_REFRESH_SECRET, {
      expiresIn: '7d',
    });
    prisma.refreshToken.findUnique.mockResolvedValue({
      id: 5,
      usuarioId: 1,
      revogadoEm: null,
    });
    prisma.usuario.findUnique.mockResolvedValue(usuarioFake());

    const resposta = await request(app).post('/api/v1/auth/refresh').send({ refreshToken });

    expect(resposta.status).toBe(200);
    expect(resposta.body.data.accessToken).toEqual(expect.any(String));
    expect(prisma.refreshToken.update).toHaveBeenCalledWith(
      expect.objectContaining({ where: { id: 5 } }),
    );
  });

  it('responde 401 com refresh token malformado', async () => {
    const resposta = await request(app)
      .post('/api/v1/auth/refresh')
      .send({ refreshToken: 'token-invalido' });

    expect(resposta.status).toBe(401);
  });

  it('responde 401 quando o refresh token não está cadastrado (revogado/inexistente)', async () => {
    const refreshToken = jwt.sign({ sub: 1, jti: 'abc' }, process.env.JWT_REFRESH_SECRET, {
      expiresIn: '7d',
    });
    prisma.refreshToken.findUnique.mockResolvedValue(null);

    const resposta = await request(app).post('/api/v1/auth/refresh').send({ refreshToken });

    expect(resposta.status).toBe(401);
  });
});

describe('POST /api/v1/auth/logout', () => {
  it('revoga o token e responde 200 quando autenticado', async () => {
    const usuario = usuarioFake();
    const refreshToken = jwt.sign({ sub: 1, jti: 'abc' }, process.env.JWT_REFRESH_SECRET, {
      expiresIn: '7d',
    });
    prisma.refreshToken.findUnique.mockResolvedValue({ id: 7, usuarioId: 1, revogadoEm: null });

    const resposta = await request(app)
      .post('/api/v1/auth/logout')
      .set('Authorization', `Bearer ${accessTokenPara(usuario)}`)
      .send({ refreshToken });

    expect(resposta.status).toBe(200);
    expect(prisma.refreshToken.update).toHaveBeenCalled();
  });

  it('responde 401 sem token de acesso', async () => {
    const resposta = await request(app).post('/api/v1/auth/logout').send({ refreshToken: 'x' });

    expect(resposta.status).toBe(401);
  });
});

describe('POST /api/v1/auth/forgot-password', () => {
  it('responde 200 e envia e-mail quando o e-mail existe', async () => {
    prisma.usuario.findUnique.mockResolvedValue(usuarioFake());

    const resposta = await request(app)
      .post('/api/v1/auth/forgot-password')
      .send({ email: 'aluno@example.com' });

    expect(resposta.status).toBe(200);
    expect(enviarEmail).toHaveBeenCalled();
  });

  it('responde 200 com a mesma mensagem quando o e-mail não existe (resposta neutra)', async () => {
    prisma.usuario.findUnique.mockResolvedValue(null);

    const resposta = await request(app)
      .post('/api/v1/auth/forgot-password')
      .send({ email: 'ninguem@example.com' });

    expect(resposta.status).toBe(200);
    expect(enviarEmail).not.toHaveBeenCalled();
  });
});

describe('POST /api/v1/auth/reset-password', () => {
  it('redefine a senha com um token válido (200)', async () => {
    prisma.tokenRecuperacao.findUnique.mockResolvedValue({
      id: 1,
      usuarioId: 1,
      usadoEm: null,
      expiraEm: new Date(Date.now() + 60_000),
    });

    const resposta = await request(app)
      .post('/api/v1/auth/reset-password')
      .send({ token: 'token-bruto', novaSenha: 'nova-senha-123' });

    expect(resposta.status).toBe(200);
    expect(prisma.$transaction).toHaveBeenCalled();
  });

  it('responde 400 TOKEN_INVALIDO com token expirado', async () => {
    prisma.tokenRecuperacao.findUnique.mockResolvedValue({
      id: 1,
      usuarioId: 1,
      usadoEm: null,
      expiraEm: new Date(Date.now() - 60_000),
    });

    const resposta = await request(app)
      .post('/api/v1/auth/reset-password')
      .send({ token: 'token-expirado', novaSenha: 'nova-senha-123' });

    expect(resposta.status).toBe(400);
    expect(resposta.body.error.code).toBe('TOKEN_INVALIDO');
  });
});

describe('GET /api/v1/auth/me', () => {
  it('retorna os dados do usuário autenticado (200)', async () => {
    const usuario = usuarioFake();
    prisma.usuario.findUnique.mockResolvedValue(usuario);

    const resposta = await request(app)
      .get('/api/v1/auth/me')
      .set('Authorization', `Bearer ${accessTokenPara(usuario)}`);

    expect(resposta.status).toBe(200);
    expect(resposta.body.data.email).toBe('aluno@example.com');
  });

  it('responde 401 sem token de acesso', async () => {
    const resposta = await request(app).get('/api/v1/auth/me');

    expect(resposta.status).toBe(401);
  });
});
