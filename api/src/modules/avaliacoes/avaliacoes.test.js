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

function avaliacaoFake(sobrescreve = {}) {
  return {
    id: 50,
    usuarioId: 1,
    universidadeId: 7,
    nota: 4,
    comentario: 'Boa estrutura',
    criadoEm: new Date('2026-11-01T12:00:00.000Z'),
    ...sobrescreve,
  };
}

/**
 * avaliacao.findUnique atende duas buscas: por id (PUT/DELETE) e pela chave
 * composta aluno + universidade (POST e detalhe). Responde conforme o where.
 */
function mockFindUniqueAvaliacao({ porId = null, doUsuario = null } = {}) {
  prisma.avaliacao.findUnique.mockImplementation(({ where }) =>
    Promise.resolve(where.usuarioId_universidadeId ? doUsuario : porId),
  );
}

function mockRecalculo({ media = 4, total = 1 } = {}) {
  prisma.avaliacao.aggregate.mockResolvedValue({ _avg: { nota: media }, _count: { _all: total } });
  prisma.universidade.update.mockImplementation(({ where, data }) =>
    Promise.resolve({ id: where.id, mediaAvaliacao: data.mediaAvaliacao, totalAvaliacoes: data.totalAvaliacoes }),
  );
}

beforeEach(() => {
  prisma.resetMockPrisma();
});

describe('POST /api/v1/universidades/:id/avaliacoes', () => {
  it('aluno avalia, a média é recalculada na transação e a auditoria é gravada (201)', async () => {
    prisma.universidade.findFirst.mockResolvedValue({ id: 7 });
    mockFindUniqueAvaliacao({ doUsuario: null });
    prisma.avaliacao.create.mockResolvedValue(avaliacaoFake({ nota: 5 }));
    mockRecalculo({ media: 4.333333, total: 3 });

    const resposta = await request(app)
      .post('/api/v1/universidades/7/avaliacoes')
      .set('Authorization', `Bearer ${TOKEN_ALUNO}`)
      .send({ nota: 5, comentario: '  Ótimos professores  ' });

    expect(resposta.status).toBe(201);
    expect(resposta.body.data).toMatchObject({ id: 50, nota: 5, universidadeId: 7 });
    expect(resposta.body.data.universidade).toEqual({ id: 7, mediaAvaliacao: 4.33, totalAvaliacoes: 3 });

    expect(prisma.$transaction).toHaveBeenCalledTimes(1);
    expect(prisma.$queryRaw).toHaveBeenCalledTimes(1);
    expect(prisma.avaliacao.create).toHaveBeenCalledWith({
      data: { usuarioId: 1, universidadeId: 7, nota: 5, comentario: 'Ótimos professores' },
    });
    expect(prisma.universidade.update).toHaveBeenCalledWith(
      expect.objectContaining({ where: { id: 7 }, data: { mediaAvaliacao: 4.33, totalAvaliacoes: 3 } }),
    );
    expect(prisma.logAuditoria.create).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({ usuarioId: 1, acao: 'CREATE', entidade: 'avaliacao', entidadeId: 50 }),
      }),
    );
  });

  it('comentário vazio é gravado como null', async () => {
    prisma.universidade.findFirst.mockResolvedValue({ id: 7 });
    mockFindUniqueAvaliacao({ doUsuario: null });
    prisma.avaliacao.create.mockResolvedValue(avaliacaoFake({ comentario: null }));
    mockRecalculo();

    await request(app)
      .post('/api/v1/universidades/7/avaliacoes')
      .set('Authorization', `Bearer ${TOKEN_ALUNO}`)
      .send({ nota: 4, comentario: '   ' });

    expect(prisma.avaliacao.create.mock.calls[0][0].data.comentario).toBeNull();
  });

  it('responde 409 AVALIACAO_DUPLICADA quando o aluno já avaliou', async () => {
    prisma.universidade.findFirst.mockResolvedValue({ id: 7 });
    mockFindUniqueAvaliacao({ doUsuario: avaliacaoFake() });

    const resposta = await request(app)
      .post('/api/v1/universidades/7/avaliacoes')
      .set('Authorization', `Bearer ${TOKEN_ALUNO}`)
      .send({ nota: 3 });

    expect(resposta.status).toBe(409);
    expect(resposta.body.error.code).toBe('AVALIACAO_DUPLICADA');
    expect(prisma.avaliacao.create).not.toHaveBeenCalled();
  });

  it('responde 409 quando o índice único barra uma requisição simultânea (P2002)', async () => {
    prisma.universidade.findFirst.mockResolvedValue({ id: 7 });
    mockFindUniqueAvaliacao({ doUsuario: null });
    prisma.avaliacao.create.mockRejectedValue(Object.assign(new Error('Unique'), { code: 'P2002' }));

    const resposta = await request(app)
      .post('/api/v1/universidades/7/avaliacoes')
      .set('Authorization', `Bearer ${TOKEN_ALUNO}`)
      .send({ nota: 3 });

    expect(resposta.status).toBe(409);
    expect(resposta.body.error.code).toBe('AVALIACAO_DUPLICADA');
  });

  it('responde 404 quando a universidade não está aprovada', async () => {
    prisma.universidade.findFirst.mockResolvedValue(null);

    const resposta = await request(app)
      .post('/api/v1/universidades/7/avaliacoes')
      .set('Authorization', `Bearer ${TOKEN_ALUNO}`)
      .send({ nota: 3 });

    expect(resposta.status).toBe(404);
    expect(prisma.universidade.findFirst).toHaveBeenCalledWith(
      expect.objectContaining({ where: { id: 7, status: 'A' } }),
    );
  });

  it('responde 400 com nota fora da escala de 1 a 5', async () => {
    for (const nota of [0, 6, 3.5, '4']) {
      const resposta = await request(app)
        .post('/api/v1/universidades/7/avaliacoes')
        .set('Authorization', `Bearer ${TOKEN_ALUNO}`)
        .send({ nota });

      expect(resposta.status).toBe(400);
      expect(resposta.body.error.code).toBe('VALIDATION_ERROR');
    }
  });

  it('responde 401 sem login', async () => {
    const resposta = await request(app).post('/api/v1/universidades/7/avaliacoes').send({ nota: 5 });

    expect(resposta.status).toBe(401);
  });

  it('responde 403 para perfil Universidade e Administrador', async () => {
    for (const token of [TOKEN_UNIVERSIDADE, TOKEN_ADMIN]) {
      const resposta = await request(app)
        .post('/api/v1/universidades/7/avaliacoes')
        .set('Authorization', `Bearer ${token}`)
        .send({ nota: 5 });

      expect(resposta.status).toBe(403);
    }
  });
});

describe('PUT /api/v1/avaliacoes/:id', () => {
  it('aluno edita a própria avaliação e a média é recalculada (200)', async () => {
    mockFindUniqueAvaliacao({ porId: avaliacaoFake() });
    prisma.universidade.findFirst.mockResolvedValue({ id: 7 });
    prisma.avaliacao.update.mockResolvedValue(avaliacaoFake({ nota: 2, comentario: 'Mudei de ideia' }));
    mockRecalculo({ media: 3, total: 2 });

    const resposta = await request(app)
      .put('/api/v1/avaliacoes/50')
      .set('Authorization', `Bearer ${TOKEN_ALUNO}`)
      .send({ nota: 2, comentario: 'Mudei de ideia' });

    expect(resposta.status).toBe(200);
    expect(resposta.body.data).toMatchObject({ nota: 2, comentario: 'Mudei de ideia' });
    expect(resposta.body.data.universidade).toEqual({ id: 7, mediaAvaliacao: 3, totalAvaliacoes: 2 });
    expect(prisma.$queryRaw).toHaveBeenCalledTimes(1);
    expect(prisma.logAuditoria.create).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({
          acao: 'UPDATE',
          entidade: 'avaliacao',
          dadosAntes: expect.objectContaining({ nota: 4 }),
          dadosDepois: expect.objectContaining({ nota: 2 }),
        }),
      }),
    );
  });

  it('responde 403 ao editar avaliação de outro aluno', async () => {
    mockFindUniqueAvaliacao({ porId: avaliacaoFake({ usuarioId: 1 }) });

    const resposta = await request(app)
      .put('/api/v1/avaliacoes/50')
      .set('Authorization', `Bearer ${TOKEN_OUTRO_ALUNO}`)
      .send({ nota: 1 });

    expect(resposta.status).toBe(403);
    expect(prisma.avaliacao.update).not.toHaveBeenCalled();
  });

  it('responde 403 para o administrador (edição é só do autor)', async () => {
    const resposta = await request(app)
      .put('/api/v1/avaliacoes/50')
      .set('Authorization', `Bearer ${TOKEN_ADMIN}`)
      .send({ nota: 1 });

    expect(resposta.status).toBe(403);
  });

  it('responde 404 quando a avaliação não existe', async () => {
    mockFindUniqueAvaliacao({ porId: null });

    const resposta = await request(app)
      .put('/api/v1/avaliacoes/999')
      .set('Authorization', `Bearer ${TOKEN_ALUNO}`)
      .send({ nota: 1 });

    expect(resposta.status).toBe(404);
  });

  it('responde 401 sem login', async () => {
    const resposta = await request(app).put('/api/v1/avaliacoes/50').send({ nota: 1 });

    expect(resposta.status).toBe(401);
  });
});

describe('DELETE /api/v1/avaliacoes/:id', () => {
  it('aluno remove a própria avaliação e a média volta a null sem avaliações (200)', async () => {
    mockFindUniqueAvaliacao({ porId: avaliacaoFake() });
    prisma.avaliacao.delete.mockResolvedValue(avaliacaoFake());
    mockRecalculo({ media: null, total: 0 });

    const resposta = await request(app)
      .delete('/api/v1/avaliacoes/50')
      .set('Authorization', `Bearer ${TOKEN_ALUNO}`);

    expect(resposta.status).toBe(200);
    expect(resposta.body.data).toEqual({
      sucesso: true,
      universidade: { id: 7, mediaAvaliacao: null, totalAvaliacoes: 0 },
    });
    expect(prisma.avaliacao.delete).toHaveBeenCalledWith({ where: { id: 50 } });
    expect(prisma.logAuditoria.create).toHaveBeenCalledWith(
      expect.objectContaining({ data: expect.objectContaining({ acao: 'DELETE', entidade: 'avaliacao' }) }),
    );
  });

  it('administrador remove avaliação de qualquer aluno (200)', async () => {
    mockFindUniqueAvaliacao({ porId: avaliacaoFake({ usuarioId: 1 }) });
    prisma.avaliacao.delete.mockResolvedValue(avaliacaoFake());
    mockRecalculo();

    const resposta = await request(app)
      .delete('/api/v1/avaliacoes/50')
      .set('Authorization', `Bearer ${TOKEN_ADMIN}`);

    expect(resposta.status).toBe(200);
  });

  it('responde 403 ao remover avaliação de outro aluno', async () => {
    mockFindUniqueAvaliacao({ porId: avaliacaoFake({ usuarioId: 1 }) });

    const resposta = await request(app)
      .delete('/api/v1/avaliacoes/50')
      .set('Authorization', `Bearer ${TOKEN_OUTRO_ALUNO}`);

    expect(resposta.status).toBe(403);
    expect(prisma.avaliacao.delete).not.toHaveBeenCalled();
  });

  it('responde 403 para perfil Universidade', async () => {
    const resposta = await request(app)
      .delete('/api/v1/avaliacoes/50')
      .set('Authorization', `Bearer ${TOKEN_UNIVERSIDADE}`);

    expect(resposta.status).toBe(403);
  });

  it('responde 401 sem login', async () => {
    const resposta = await request(app).delete('/api/v1/avaliacoes/50');

    expect(resposta.status).toBe(401);
  });
});

describe('GET /api/v1/avaliacoes/minhas', () => {
  it('lista só as avaliações do aluno logado (200)', async () => {
    prisma.avaliacao.findMany.mockResolvedValue([
      { ...avaliacaoFake(), universidade: { id: 7, nomeFantasia: 'Fatec Sorocaba', logoUrl: null } },
    ]);
    prisma.avaliacao.count.mockResolvedValue(1);

    const resposta = await request(app)
      .get('/api/v1/avaliacoes/minhas')
      .set('Authorization', `Bearer ${TOKEN_ALUNO}`);

    expect(resposta.status).toBe(200);
    expect(resposta.body.data[0].universidade.nomeFantasia).toBe('Fatec Sorocaba');
    expect(prisma.avaliacao.findMany).toHaveBeenCalledWith(expect.objectContaining({ where: { usuarioId: 1 } }));
  });

  it('responde 401 sem login e 403 para outro perfil', async () => {
    expect((await request(app).get('/api/v1/avaliacoes/minhas')).status).toBe(401);
    const resposta = await request(app)
      .get('/api/v1/avaliacoes/minhas')
      .set('Authorization', `Bearer ${TOKEN_ADMIN}`);
    expect(resposta.status).toBe(403);
  });
});

describe('GET /api/v1/universidades/:id com sessão (minhaAvaliacao)', () => {
  function universidadeDetalheFake() {
    return {
      id: 7,
      nomeFantasia: 'Fatec Sorocaba',
      razaoSocial: 'Faculdade de Tecnologia de Sorocaba',
      descricao: null,
      logoUrl: null,
      natureza: 'P',
      linkPagina: null,
      linkSimulados: null,
      mediaAvaliacao: '4.00',
      totalAvaliacoes: 1,
      campus: [],
      universidadeProgramas: [],
    };
  }

  it('devolve a avaliação do aluno logado', async () => {
    prisma.universidade.findFirst.mockResolvedValue(universidadeDetalheFake());
    mockFindUniqueAvaliacao({ doUsuario: avaliacaoFake() });

    const resposta = await request(app)
      .get('/api/v1/universidades/7')
      .set('Authorization', `Bearer ${TOKEN_ALUNO}`);

    expect(resposta.status).toBe(200);
    expect(resposta.body.data.minhaAvaliacao).toMatchObject({ id: 50, nota: 4, comentario: 'Boa estrutura' });
  });

  it('devolve null para visitante sem consultar avaliações', async () => {
    prisma.universidade.findFirst.mockResolvedValue(universidadeDetalheFake());

    const resposta = await request(app).get('/api/v1/universidades/7');

    expect(resposta.status).toBe(200);
    expect(resposta.body.data.minhaAvaliacao).toBeNull();
    expect(prisma.avaliacao.findUnique).not.toHaveBeenCalled();
  });

  it('responde 401 com token inválido (o app renova a sessão)', async () => {
    const resposta = await request(app)
      .get('/api/v1/universidades/7')
      .set('Authorization', 'Bearer token-invalido');

    expect(resposta.status).toBe(401);
  });
});
