const jwt = require('jsonwebtoken');
const request = require('supertest');

jest.mock('../../config/database', () => require('../../../tests/helpers/mockPrisma'));

const prisma = require('../../config/database');
const app = require('../../app');

function tokenPara({ id, tipoUsuario, universidadeId = null }) {
  return jwt.sign({ sub: id, tipoUsuario, universidadeId }, process.env.JWT_ACCESS_SECRET, {
    expiresIn: '15m',
  });
}

const TOKEN_ALUNO = tokenPara({ id: 1, tipoUsuario: 'A' });
const TOKEN_OUTRO_ALUNO = tokenPara({ id: 2, tipoUsuario: 'A' });
const TOKEN_UNIVERSIDADE = tokenPara({ id: 3, tipoUsuario: 'U', universidadeId: 7 });
const TOKEN_ADMIN = tokenPara({ id: 99, tipoUsuario: 'D' });

function pesquisaFake(sobrescreve = {}) {
  return {
    id: 20,
    usuarioId: 1,
    nome: 'Públicas em Sorocaba',
    tipo: 'UNIVERSIDADE',
    parametros: { cidade: 'Sorocaba', natureza: 'P', notaMinima: 4 },
    criadoEm: new Date('2026-11-15T09:00:00.000Z'),
    ...sobrescreve,
  };
}

beforeEach(() => {
  prisma.resetMockPrisma();
});

describe('POST /api/v1/pesquisas-salvas', () => {
  it('salva nome e filtros já validados, com data do servidor (201)', async () => {
    prisma.pesquisaSalva.findFirst.mockResolvedValue(null);
    prisma.pesquisaSalva.create.mockImplementation(({ data }) =>
      Promise.resolve({ id: 20, criadoEm: new Date(), ...data }),
    );

    const resposta = await request(app)
      .post('/api/v1/pesquisas-salvas')
      .set('Authorization', `Bearer ${TOKEN_ALUNO}`)
      .send({
        nome: '  Públicas em Sorocaba ',
        parametros: { cidade: 'Sorocaba', natureza: 'P', notaMinima: '4', programaId: '3', sort: 'media' },
      });

    expect(resposta.status).toBe(201);
    expect(resposta.body.data).toMatchObject({ id: 20, nome: 'Públicas em Sorocaba', tipo: 'UNIVERSIDADE' });
    // Os filtros passam pelo mesmo schema de GET /universidades (com coerção).
    expect(prisma.pesquisaSalva.create).toHaveBeenCalledWith({
      data: {
        usuarioId: 1,
        nome: 'Públicas em Sorocaba',
        tipo: 'UNIVERSIDADE',
        parametros: { cidade: 'Sorocaba', natureza: 'P', notaMinima: 4, programaId: 3, sort: 'media' },
      },
    });
    expect(prisma.pesquisaSalva.create.mock.calls[0][0].data.criadoEm).toBeUndefined();
    expect(prisma.logAuditoria.create).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({ acao: 'CREATE', entidade: 'pesquisa_salva', entidadeId: 20 }),
      }),
    );
  });

  it('aceita pesquisa sem filtros', async () => {
    prisma.pesquisaSalva.findFirst.mockResolvedValue(null);
    prisma.pesquisaSalva.create.mockImplementation(({ data }) => Promise.resolve({ id: 21, criadoEm: new Date(), ...data }));

    const resposta = await request(app)
      .post('/api/v1/pesquisas-salvas')
      .set('Authorization', `Bearer ${TOKEN_ALUNO}`)
      .send({ nome: 'Todas' });

    expect(resposta.status).toBe(201);
    expect(resposta.body.data.parametros).toEqual({});
  });

  it('responde 409 PESQUISA_DUPLICADA com nome repetido do mesmo usuário', async () => {
    prisma.pesquisaSalva.findFirst.mockResolvedValue(pesquisaFake());

    const resposta = await request(app)
      .post('/api/v1/pesquisas-salvas')
      .set('Authorization', `Bearer ${TOKEN_ALUNO}`)
      .send({ nome: 'Públicas em Sorocaba', parametros: {} });

    expect(resposta.status).toBe(409);
    expect(resposta.body.error.code).toBe('PESQUISA_DUPLICADA');
    expect(resposta.body.error.message).toMatch(/Escolha outro nome/);
    expect(prisma.pesquisaSalva.findFirst).toHaveBeenCalledWith({
      where: { usuarioId: 1, nome: 'Públicas em Sorocaba' },
    });
    expect(prisma.pesquisaSalva.create).not.toHaveBeenCalled();
  });

  it('responde 409 quando o índice único barra uma gravação simultânea (P2002)', async () => {
    prisma.pesquisaSalva.findFirst.mockResolvedValue(null);
    prisma.pesquisaSalva.create.mockRejectedValue(Object.assign(new Error('Unique'), { code: 'P2002' }));

    const resposta = await request(app)
      .post('/api/v1/pesquisas-salvas')
      .set('Authorization', `Bearer ${TOKEN_ALUNO}`)
      .send({ nome: 'Repetida' });

    expect(resposta.status).toBe(409);
    expect(resposta.body.error.code).toBe('PESQUISA_DUPLICADA');
  });

  it('responde 400 e não grava filtros inválidos ou desconhecidos', async () => {
    const invalidos = [
      { estado: 'SPX' },
      { natureza: 'X' },
      { notaMinima: 9 },
      { sort: 'preco' },
      { filtroQueNaoExiste: 'x' },
    ];

    for (const parametros of invalidos) {
      const resposta = await request(app)
        .post('/api/v1/pesquisas-salvas')
        .set('Authorization', `Bearer ${TOKEN_ALUNO}`)
        .send({ nome: 'Inválida', parametros });

      expect(resposta.status).toBe(400);
      expect(resposta.body.error.code).toBe('VALIDATION_ERROR');
    }
    expect(prisma.pesquisaSalva.create).not.toHaveBeenCalled();
  });

  it('responde 400 sem nome', async () => {
    const resposta = await request(app)
      .post('/api/v1/pesquisas-salvas')
      .set('Authorization', `Bearer ${TOKEN_ALUNO}`)
      .send({ nome: '   ', parametros: {} });

    expect(resposta.status).toBe(400);
  });

  it('responde 401 sem login e 403 para outro perfil', async () => {
    expect((await request(app).post('/api/v1/pesquisas-salvas').send({ nome: 'X' })).status).toBe(401);

    for (const token of [TOKEN_UNIVERSIDADE, TOKEN_ADMIN]) {
      const resposta = await request(app)
        .post('/api/v1/pesquisas-salvas')
        .set('Authorization', `Bearer ${token}`)
        .send({ nome: 'X' });
      expect(resposta.status).toBe(403);
    }
  });
});

describe('GET /api/v1/pesquisas-salvas', () => {
  it('lista só as pesquisas do aluno logado (200)', async () => {
    prisma.pesquisaSalva.findMany.mockResolvedValue([pesquisaFake()]);
    prisma.pesquisaSalva.count.mockResolvedValue(1);

    const resposta = await request(app)
      .get('/api/v1/pesquisas-salvas')
      .set('Authorization', `Bearer ${TOKEN_ALUNO}`);

    expect(resposta.status).toBe(200);
    expect(resposta.body.data[0]).toMatchObject({ id: 20, nome: 'Públicas em Sorocaba' });
    expect(resposta.body.data[0].usuarioId).toBeUndefined();
    expect(prisma.pesquisaSalva.findMany).toHaveBeenCalledWith(expect.objectContaining({ where: { usuarioId: 1 } }));
  });

  it('responde 401 sem login', async () => {
    expect((await request(app).get('/api/v1/pesquisas-salvas')).status).toBe(401);
  });
});

describe('GET /api/v1/pesquisas-salvas/:id', () => {
  it('devolve os filtros para reexecutar a pesquisa (200)', async () => {
    prisma.pesquisaSalva.findUnique.mockResolvedValue(pesquisaFake());

    const resposta = await request(app)
      .get('/api/v1/pesquisas-salvas/20')
      .set('Authorization', `Bearer ${TOKEN_ALUNO}`);

    expect(resposta.status).toBe(200);
    expect(resposta.body.data.parametros).toEqual({ cidade: 'Sorocaba', natureza: 'P', notaMinima: 4 });
  });

  it('responde 403 para pesquisa de outro aluno', async () => {
    prisma.pesquisaSalva.findUnique.mockResolvedValue(pesquisaFake({ usuarioId: 1 }));

    const resposta = await request(app)
      .get('/api/v1/pesquisas-salvas/20')
      .set('Authorization', `Bearer ${TOKEN_OUTRO_ALUNO}`);

    expect(resposta.status).toBe(403);
  });

  it('responde 404 quando não existe', async () => {
    prisma.pesquisaSalva.findUnique.mockResolvedValue(null);

    const resposta = await request(app)
      .get('/api/v1/pesquisas-salvas/999')
      .set('Authorization', `Bearer ${TOKEN_ALUNO}`);

    expect(resposta.status).toBe(404);
  });
});

describe('DELETE /api/v1/pesquisas-salvas/:id', () => {
  it('exclui a própria pesquisa e grava a auditoria (200)', async () => {
    prisma.pesquisaSalva.findUnique.mockResolvedValue(pesquisaFake());
    prisma.pesquisaSalva.delete.mockResolvedValue(pesquisaFake());

    const resposta = await request(app)
      .delete('/api/v1/pesquisas-salvas/20')
      .set('Authorization', `Bearer ${TOKEN_ALUNO}`);

    expect(resposta.status).toBe(200);
    expect(prisma.pesquisaSalva.delete).toHaveBeenCalledWith({ where: { id: 20 } });
    expect(prisma.logAuditoria.create).toHaveBeenCalledWith(
      expect.objectContaining({ data: expect.objectContaining({ acao: 'DELETE', entidade: 'pesquisa_salva' }) }),
    );
  });

  it('responde 403 ao excluir pesquisa de outro aluno', async () => {
    prisma.pesquisaSalva.findUnique.mockResolvedValue(pesquisaFake({ usuarioId: 1 }));

    const resposta = await request(app)
      .delete('/api/v1/pesquisas-salvas/20')
      .set('Authorization', `Bearer ${TOKEN_OUTRO_ALUNO}`);

    expect(resposta.status).toBe(403);
    expect(prisma.pesquisaSalva.delete).not.toHaveBeenCalled();
  });

  it('responde 401 sem login e 403 para administrador', async () => {
    expect((await request(app).delete('/api/v1/pesquisas-salvas/20')).status).toBe(401);

    const resposta = await request(app)
      .delete('/api/v1/pesquisas-salvas/20')
      .set('Authorization', `Bearer ${TOKEN_ADMIN}`);
    expect(resposta.status).toBe(403);
  });
});
