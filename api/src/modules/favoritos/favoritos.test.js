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
const TOKEN_UNIVERSIDADE = tokenPara({ id: 3, tipoUsuario: 'U', universidadeId: 7 });
const TOKEN_ADMIN = tokenPara({ id: 99, tipoUsuario: 'D' });

function universidadeFake(sobrescreve = {}) {
  return {
    id: 7,
    nomeFantasia: 'Fatec Sorocaba',
    logoUrl: null,
    natureza: 'P',
    status: 'A',
    mediaAvaliacao: '4.60',
    totalAvaliacoes: 12,
    razaoSocial: 'Faculdade de Tecnologia de Sorocaba',
    descricao: null,
    linkPagina: null,
    linkSimulados: null,
    campus: [{ id: 10, nome: 'Fatec Sorocaba', principal: true, endereco: { cidade: 'Sorocaba', estado: 'SP' } }],
    universidadeProgramas: [],
    ...sobrescreve,
  };
}

beforeEach(() => {
  prisma.resetMockPrisma();
});

describe('GET /api/v1/favoritos/universidades', () => {
  it('lista as salvas do aluno com os dados do card (200)', async () => {
    prisma.universidadeSalva.findMany.mockResolvedValue([
      { usuarioId: 1, universidadeId: 7, criadoEm: new Date('2026-11-10T10:00:00.000Z'), universidade: universidadeFake() },
    ]);
    prisma.universidadeSalva.count.mockResolvedValue(1);

    const resposta = await request(app)
      .get('/api/v1/favoritos/universidades')
      .set('Authorization', `Bearer ${TOKEN_ALUNO}`);

    expect(resposta.status).toBe(200);
    expect(resposta.body.data[0]).toMatchObject({
      id: 7,
      nomeFantasia: 'Fatec Sorocaba',
      cidade: 'Sorocaba',
      estado: 'SP',
      mediaAvaliacao: '4.60',
      salva: true,
    });
    expect(resposta.body.meta).toMatchObject({ total: 1 });
    expect(prisma.universidadeSalva.findMany).toHaveBeenCalledWith(
      expect.objectContaining({ where: { usuarioId: 1, universidade: { status: 'A' } } }),
    );
  });

  it('responde 401 sem login', async () => {
    const resposta = await request(app).get('/api/v1/favoritos/universidades');

    expect(resposta.status).toBe(401);
  });

  it('responde 403 para perfil Universidade e Administrador', async () => {
    for (const token of [TOKEN_UNIVERSIDADE, TOKEN_ADMIN]) {
      const resposta = await request(app)
        .get('/api/v1/favoritos/universidades')
        .set('Authorization', `Bearer ${token}`);

      expect(resposta.status).toBe(403);
    }
  });
});

describe('POST /api/v1/favoritos/universidades', () => {
  it('salva a universidade e grava a auditoria (201)', async () => {
    prisma.universidade.findFirst.mockResolvedValue({ id: 7 });
    prisma.universidadeSalva.findUnique.mockResolvedValue(null);
    prisma.universidadeSalva.create.mockResolvedValue({ usuarioId: 1, universidadeId: 7, criadoEm: new Date() });

    const resposta = await request(app)
      .post('/api/v1/favoritos/universidades')
      .set('Authorization', `Bearer ${TOKEN_ALUNO}`)
      .send({ universidadeId: 7 });

    expect(resposta.status).toBe(201);
    expect(resposta.body.data).toMatchObject({ universidadeId: 7, salva: true });
    expect(prisma.universidadeSalva.create).toHaveBeenCalledWith({ data: { usuarioId: 1, universidadeId: 7 } });
    expect(prisma.logAuditoria.create).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({ acao: 'CREATE', entidade: 'universidade_salva', entidadeId: 7 }),
      }),
    );
  });

  it('é idempotente: salvar de novo responde 200 sem gravar nada', async () => {
    prisma.universidade.findFirst.mockResolvedValue({ id: 7 });
    prisma.universidadeSalva.findUnique.mockResolvedValue({ usuarioId: 1, universidadeId: 7, criadoEm: new Date() });

    const resposta = await request(app)
      .post('/api/v1/favoritos/universidades')
      .set('Authorization', `Bearer ${TOKEN_ALUNO}`)
      .send({ universidadeId: 7 });

    expect(resposta.status).toBe(200);
    expect(resposta.body.data.salva).toBe(true);
    expect(prisma.universidadeSalva.create).not.toHaveBeenCalled();
    expect(prisma.logAuditoria.create).not.toHaveBeenCalled();
  });

  it('trata o clique duplo simultâneo (P2002) como já salva (200)', async () => {
    prisma.universidade.findFirst.mockResolvedValue({ id: 7 });
    prisma.universidadeSalva.findUnique.mockResolvedValueOnce(null).mockResolvedValueOnce({ criadoEm: new Date() });
    prisma.universidadeSalva.create.mockRejectedValue(Object.assign(new Error('Unique'), { code: 'P2002' }));

    const resposta = await request(app)
      .post('/api/v1/favoritos/universidades')
      .set('Authorization', `Bearer ${TOKEN_ALUNO}`)
      .send({ universidadeId: 7 });

    expect(resposta.status).toBe(200);
  });

  it('responde 404 para universidade inexistente ou não aprovada', async () => {
    prisma.universidade.findFirst.mockResolvedValue(null);

    const resposta = await request(app)
      .post('/api/v1/favoritos/universidades')
      .set('Authorization', `Bearer ${TOKEN_ALUNO}`)
      .send({ universidadeId: 7 });

    expect(resposta.status).toBe(404);
  });

  it('responde 400 sem universidadeId', async () => {
    const resposta = await request(app)
      .post('/api/v1/favoritos/universidades')
      .set('Authorization', `Bearer ${TOKEN_ALUNO}`)
      .send({});

    expect(resposta.status).toBe(400);
  });

  it('responde 401 sem login e 403 para outro perfil', async () => {
    expect((await request(app).post('/api/v1/favoritos/universidades').send({ universidadeId: 7 })).status).toBe(401);

    const resposta = await request(app)
      .post('/api/v1/favoritos/universidades')
      .set('Authorization', `Bearer ${TOKEN_UNIVERSIDADE}`)
      .send({ universidadeId: 7 });
    expect(resposta.status).toBe(403);
  });
});

describe('DELETE /api/v1/favoritos/universidades/:id', () => {
  it('remove só da lista do aluno logado e grava a auditoria (200)', async () => {
    prisma.universidadeSalva.deleteMany.mockResolvedValue({ count: 1 });

    const resposta = await request(app)
      .delete('/api/v1/favoritos/universidades/7')
      .set('Authorization', `Bearer ${TOKEN_ALUNO}`);

    expect(resposta.status).toBe(200);
    expect(resposta.body.data).toMatchObject({ sucesso: true, salva: false });
    expect(prisma.universidadeSalva.deleteMany).toHaveBeenCalledWith({ where: { usuarioId: 1, universidadeId: 7 } });
    expect(prisma.logAuditoria.create).toHaveBeenCalledWith(
      expect.objectContaining({ data: expect.objectContaining({ acao: 'DELETE', entidade: 'universidade_salva' }) }),
    );
  });

  it('é idempotente: remover o que não está salvo responde 200 sem auditoria', async () => {
    prisma.universidadeSalva.deleteMany.mockResolvedValue({ count: 0 });

    const resposta = await request(app)
      .delete('/api/v1/favoritos/universidades/7')
      .set('Authorization', `Bearer ${TOKEN_ALUNO}`);

    expect(resposta.status).toBe(200);
    expect(prisma.logAuditoria.create).not.toHaveBeenCalled();
  });

  it('responde 401 sem login e 403 para outro perfil', async () => {
    expect((await request(app).delete('/api/v1/favoritos/universidades/7')).status).toBe(401);

    const resposta = await request(app)
      .delete('/api/v1/favoritos/universidades/7')
      .set('Authorization', `Bearer ${TOKEN_ADMIN}`);
    expect(resposta.status).toBe(403);
  });
});

describe('Indicador "salva" na pesquisa e no detalhe', () => {
  it('a pesquisa marca as universidades salvas do aluno logado', async () => {
    prisma.universidade.findMany.mockResolvedValue([universidadeFake({ id: 7 }), universidadeFake({ id: 8 })]);
    prisma.universidade.count.mockResolvedValue(2);
    prisma.universidadeSalva.findMany.mockResolvedValue([{ universidadeId: 8 }]);

    const resposta = await request(app)
      .get('/api/v1/universidades')
      .set('Authorization', `Bearer ${TOKEN_ALUNO}`);

    expect(resposta.status).toBe(200);
    expect(resposta.body.data.map((u) => u.salva)).toEqual([false, true]);
    expect(prisma.universidadeSalva.findMany).toHaveBeenCalledWith({
      where: { usuarioId: 1, universidadeId: { in: [7, 8] } },
      select: { universidadeId: true },
    });
  });

  it('para visitante, a pesquisa devolve salva=false sem consultar favoritos', async () => {
    prisma.universidade.findMany.mockResolvedValue([universidadeFake()]);
    prisma.universidade.count.mockResolvedValue(1);

    const resposta = await request(app).get('/api/v1/universidades');

    expect(resposta.body.data[0].salva).toBe(false);
    expect(prisma.universidadeSalva.findMany).not.toHaveBeenCalled();
  });

  it('o detalhe diz se a universidade está salva para o aluno logado', async () => {
    prisma.universidade.findFirst.mockResolvedValue(universidadeFake());
    prisma.universidadeSalva.findUnique.mockResolvedValue({ usuarioId: 1, universidadeId: 7 });

    const resposta = await request(app)
      .get('/api/v1/universidades/7')
      .set('Authorization', `Bearer ${TOKEN_ALUNO}`);

    expect(resposta.body.data.salva).toBe(true);
  });

  it('o detalhe devolve salva=false para visitante', async () => {
    prisma.universidade.findFirst.mockResolvedValue(universidadeFake());

    const resposta = await request(app).get('/api/v1/universidades/7');

    expect(resposta.body.data.salva).toBe(false);
  });
});
