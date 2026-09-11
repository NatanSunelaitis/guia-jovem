const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const request = require('supertest');

jest.mock('../../config/database', () => require('../../../tests/helpers/mockPrisma'));

const prisma = require('../../config/database');
const app = require('../../app');

const SENHA_HASH = bcrypt.hashSync('senha1234', 12);

function usuarioFake(sobrescreve = {}) {
  return {
    id: 1,
    nome: 'Aluno Teste',
    email: 'aluno@example.com',
    senhaHash: SENHA_HASH,
    tipoUsuario: 'A',
    googleId: null,
    fotoUrl: null,
    ativo: true,
    cpf: null,
    criadoEm: new Date('2026-01-01T00:00:00.000Z'),
    atualizadoEm: new Date('2026-01-01T00:00:00.000Z'),
    ...sobrescreve,
  };
}

function tokenPara({ id, tipoUsuario }) {
  return jwt.sign({ sub: id, tipoUsuario, universidadeId: null }, process.env.JWT_ACCESS_SECRET, {
    expiresIn: '15m',
  });
}

const TOKEN_ADMIN = tokenPara({ id: 99, tipoUsuario: 'D' });
const TOKEN_ALUNO = tokenPara({ id: 1, tipoUsuario: 'A' });
const TOKEN_OUTRO_ALUNO = tokenPara({ id: 2, tipoUsuario: 'A' });

beforeEach(() => {
  prisma.resetMockPrisma();
});

describe('GET /api/v1/usuarios', () => {
  it('lista usuários paginados para o administrador (200)', async () => {
    prisma.usuario.findMany.mockResolvedValue([usuarioFake()]);
    prisma.usuario.count.mockResolvedValue(1);

    const resposta = await request(app)
      .get('/api/v1/usuarios')
      .set('Authorization', `Bearer ${TOKEN_ADMIN}`);

    expect(resposta.status).toBe(200);
    expect(resposta.body.data).toHaveLength(1);
    expect(resposta.body.meta).toMatchObject({ page: 1, pageSize: 20, total: 1 });
  });

  it('responde 403 para quem não é administrador', async () => {
    const resposta = await request(app)
      .get('/api/v1/usuarios')
      .set('Authorization', `Bearer ${TOKEN_ALUNO}`);

    expect(resposta.status).toBe(403);
  });
});

describe('POST /api/v1/usuarios', () => {
  it('admin cria um usuário (201)', async () => {
    prisma.usuario.findUnique.mockResolvedValue(null);
    prisma.usuario.create.mockResolvedValue(usuarioFake({ id: 30, tipoUsuario: 'D' }));

    const resposta = await request(app)
      .post('/api/v1/usuarios')
      .set('Authorization', `Bearer ${TOKEN_ADMIN}`)
      .send({ nome: 'Novo Admin', email: 'novo-admin@example.com', senha: 'senha1234', tipoUsuario: 'D' });

    expect(resposta.status).toBe(201);
    expect(resposta.body.data.tipoUsuario).toBe('D');
  });

  it('responde 400 ao tentar criar tipoUsuario U (requer universidade vinculada)', async () => {
    const resposta = await request(app)
      .post('/api/v1/usuarios')
      .set('Authorization', `Bearer ${TOKEN_ADMIN}`)
      .send({ nome: 'X', email: 'x@example.com', senha: 'senha1234', tipoUsuario: 'U' });

    expect(resposta.status).toBe(400);
    expect(resposta.body.error.code).toBe('VALIDATION_ERROR');
  });

  it('responde 409 quando o e-mail já existe', async () => {
    prisma.usuario.findUnique.mockResolvedValue(usuarioFake());

    const resposta = await request(app)
      .post('/api/v1/usuarios')
      .set('Authorization', `Bearer ${TOKEN_ADMIN}`)
      .send({ nome: 'X', email: 'aluno@example.com', senha: 'senha1234', tipoUsuario: 'A' });

    expect(resposta.status).toBe(409);
  });

  it('responde 403 para quem não é administrador', async () => {
    const resposta = await request(app)
      .post('/api/v1/usuarios')
      .set('Authorization', `Bearer ${TOKEN_ALUNO}`)
      .send({ nome: 'X', email: 'x@example.com', senha: 'senha1234', tipoUsuario: 'A' });

    expect(resposta.status).toBe(403);
  });
});

describe('GET /api/v1/usuarios/:id', () => {
  it('permite que o próprio usuário veja seus dados (200)', async () => {
    prisma.usuario.findUnique.mockResolvedValue(usuarioFake());

    const resposta = await request(app)
      .get('/api/v1/usuarios/1')
      .set('Authorization', `Bearer ${TOKEN_ALUNO}`);

    expect(resposta.status).toBe(200);
    expect(resposta.body.data.id).toBe(1);
  });

  it('responde 403 quando outro usuário tenta ver dados alheios', async () => {
    const resposta = await request(app)
      .get('/api/v1/usuarios/1')
      .set('Authorization', `Bearer ${TOKEN_OUTRO_ALUNO}`);

    expect(resposta.status).toBe(403);
  });

  it('responde 404 quando o usuário não existe', async () => {
    prisma.usuario.findUnique.mockResolvedValue(null);

    const resposta = await request(app)
      .get('/api/v1/usuarios/1')
      .set('Authorization', `Bearer ${TOKEN_ALUNO}`);

    expect(resposta.status).toBe(404);
  });
});

describe('PATCH /api/v1/usuarios/:id', () => {
  it('permite que o próprio usuário altere o nome (200)', async () => {
    prisma.usuario.findUnique.mockResolvedValue(usuarioFake());
    prisma.usuario.update.mockResolvedValue(usuarioFake({ nome: 'Novo Nome' }));

    const resposta = await request(app)
      .patch('/api/v1/usuarios/1')
      .set('Authorization', `Bearer ${TOKEN_ALUNO}`)
      .send({ nome: 'Novo Nome' });

    expect(resposta.status).toBe(200);
    expect(resposta.body.data.nome).toBe('Novo Nome');
  });

  it('responde 403 quando um usuário comum tenta alterar o campo ativo', async () => {
    prisma.usuario.findUnique.mockResolvedValue(usuarioFake());

    const resposta = await request(app)
      .patch('/api/v1/usuarios/1')
      .set('Authorization', `Bearer ${TOKEN_ALUNO}`)
      .send({ ativo: false });

    expect(resposta.status).toBe(403);
  });

  it('admin pode alterar tipoUsuario e ativo (200)', async () => {
    prisma.usuario.findUnique.mockResolvedValue(usuarioFake());
    prisma.usuario.update.mockResolvedValue(usuarioFake({ ativo: false }));

    const resposta = await request(app)
      .patch('/api/v1/usuarios/1')
      .set('Authorization', `Bearer ${TOKEN_ADMIN}`)
      .send({ ativo: false });

    expect(resposta.status).toBe(200);
  });

  it('responde 403 ao tentar mudar o tipo de um usuário Universidade', async () => {
    prisma.usuario.findUnique.mockResolvedValue(usuarioFake({ tipoUsuario: 'U' }));

    const resposta = await request(app)
      .patch('/api/v1/usuarios/1')
      .set('Authorization', `Bearer ${TOKEN_ADMIN}`)
      .send({ tipoUsuario: 'A' });

    expect(resposta.status).toBe(403);
  });
});

describe('PATCH /api/v1/usuarios/:id/senha', () => {
  it('altera a própria senha com a senha atual correta (200)', async () => {
    prisma.usuario.findUnique.mockResolvedValue(usuarioFake());

    const resposta = await request(app)
      .patch('/api/v1/usuarios/1/senha')
      .set('Authorization', `Bearer ${TOKEN_ALUNO}`)
      .send({ senhaAtual: 'senha1234', novaSenha: 'senha-nova-99', confirmacao: 'senha-nova-99' });

    expect(resposta.status).toBe(200);
    expect(prisma.usuario.update).toHaveBeenCalled();
    expect(prisma.refreshToken.updateMany).toHaveBeenCalled();
  });

  it('responde 400 quando a senha atual está incorreta', async () => {
    prisma.usuario.findUnique.mockResolvedValue(usuarioFake());

    const resposta = await request(app)
      .patch('/api/v1/usuarios/1/senha')
      .set('Authorization', `Bearer ${TOKEN_ALUNO}`)
      .send({ senhaAtual: 'senha-errada', novaSenha: 'senha-nova-99', confirmacao: 'senha-nova-99' });

    expect(resposta.status).toBe(400);
    expect(resposta.body.error.code).toBe('SENHA_ATUAL_INVALIDA');
  });

  it('responde 400 quando a confirmação não bate com a nova senha', async () => {
    const resposta = await request(app)
      .patch('/api/v1/usuarios/1/senha')
      .set('Authorization', `Bearer ${TOKEN_ALUNO}`)
      .send({ senhaAtual: 'senha1234', novaSenha: 'senha-nova-99', confirmacao: 'outra-coisa' });

    expect(resposta.status).toBe(400);
    expect(resposta.body.error.code).toBe('VALIDATION_ERROR');
  });

  it('responde 403 quando o admin tenta alterar a senha de outra pessoa', async () => {
    const resposta = await request(app)
      .patch('/api/v1/usuarios/1/senha')
      .set('Authorization', `Bearer ${TOKEN_ADMIN}`)
      .send({ senhaAtual: 'senha1234', novaSenha: 'senha-nova-99', confirmacao: 'senha-nova-99' });

    expect(resposta.status).toBe(403);
  });
});

describe('DELETE /api/v1/usuarios/:id', () => {
  it('exclui a própria conta com confirmacao=EXCLUIR (200)', async () => {
    prisma.usuario.findUnique.mockResolvedValue(usuarioFake());

    const resposta = await request(app)
      .delete('/api/v1/usuarios/1')
      .set('Authorization', `Bearer ${TOKEN_ALUNO}`)
      .send({ confirmacao: 'EXCLUIR' });

    expect(resposta.status).toBe(200);
    expect(prisma.usuario.delete).toHaveBeenCalledWith({ where: { id: 1 } });
  });

  it('exclui com a senha atual em vez de EXCLUIR (200)', async () => {
    prisma.usuario.findUnique.mockResolvedValue(usuarioFake());

    const resposta = await request(app)
      .delete('/api/v1/usuarios/1')
      .set('Authorization', `Bearer ${TOKEN_ALUNO}`)
      .send({ senhaAtual: 'senha1234' });

    expect(resposta.status).toBe(200);
  });

  it('responde 400 sem confirmação válida', async () => {
    prisma.usuario.findUnique.mockResolvedValue(usuarioFake());

    const resposta = await request(app)
      .delete('/api/v1/usuarios/1')
      .set('Authorization', `Bearer ${TOKEN_ALUNO}`)
      .send({});

    expect(resposta.status).toBe(400);
  });

  it('inativa a universidade ao excluir um usuário tipo U', async () => {
    prisma.usuario.findUnique.mockResolvedValue(usuarioFake({ tipoUsuario: 'U' }));

    const resposta = await request(app)
      .delete('/api/v1/usuarios/1')
      .set('Authorization', `Bearer ${TOKEN_ALUNO}`)
      .send({ confirmacao: 'EXCLUIR' });

    expect(resposta.status).toBe(200);
    expect(prisma.universidade.updateMany).toHaveBeenCalledWith({
      where: { usuarioId: 1 },
      data: { status: 'I' },
    });
  });

  it('responde 403 quando outro usuário tenta excluir uma conta alheia', async () => {
    const resposta = await request(app)
      .delete('/api/v1/usuarios/1')
      .set('Authorization', `Bearer ${TOKEN_OUTRO_ALUNO}`)
      .send({ confirmacao: 'EXCLUIR' });

    expect(resposta.status).toBe(403);
  });
});
