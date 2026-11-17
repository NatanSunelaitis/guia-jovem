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

function notificacaoFake(sobrescreve = {}) {
  return {
    id: 40,
    usuarioId: 1,
    tipo: 'SUGESTAO_AVALIADA',
    titulo: 'Sua sugestão foi aprovada',
    mensagem: 'Fatec Itu respondeu "Mais vagas".',
    referenciaTipo: 'sugestao',
    referenciaId: 12,
    lida: false,
    criadoEm: new Date('2026-11-12T09:00:00.000Z'),
    ...sobrescreve,
  };
}

beforeEach(() => {
  prisma.resetMockPrisma();
});

describe('GET /api/v1/notificacoes', () => {
  it('lista as notificações do usuário logado, mais recentes primeiro, com o total de não lidas', async () => {
    prisma.notificacao.findMany.mockResolvedValue([notificacaoFake()]);
    prisma.notificacao.count.mockResolvedValueOnce(5).mockResolvedValueOnce(2);

    const resposta = await request(app)
      .get('/api/v1/notificacoes?page=2&pageSize=1')
      .set('Authorization', `Bearer ${TOKEN_ALUNO}`);

    expect(resposta.status).toBe(200);
    expect(resposta.body.data[0]).toEqual({
      id: 40,
      tipo: 'SUGESTAO_AVALIADA',
      titulo: 'Sua sugestão foi aprovada',
      mensagem: 'Fatec Itu respondeu "Mais vagas".',
      referenciaTipo: 'sugestao',
      referenciaId: 12,
      lida: false,
      criadoEm: '2026-11-12T09:00:00.000Z',
    });
    expect(resposta.body.meta).toEqual({ page: 2, pageSize: 1, total: 5, totalPages: 5, naoLidas: 2 });
    expect(prisma.notificacao.findMany).toHaveBeenCalledWith({
      where: { usuarioId: 1 },
      orderBy: [{ criadoEm: 'desc' }, { id: 'desc' }],
      skip: 1,
      take: 1,
    });
  });

  it('filtra por lida=false', async () => {
    prisma.notificacao.findMany.mockResolvedValue([]);
    prisma.notificacao.count.mockResolvedValue(0);

    await request(app).get('/api/v1/notificacoes?lida=false').set('Authorization', `Bearer ${TOKEN_UNIVERSIDADE}`);

    expect(prisma.notificacao.findMany).toHaveBeenCalledWith(
      expect.objectContaining({ where: { usuarioId: 3, lida: false } }),
    );
  });

  it('sem login responde 401', async () => {
    const resposta = await request(app).get('/api/v1/notificacoes');
    expect(resposta.status).toBe(401);
  });
});

describe('GET /api/v1/notificacoes/nao-lidas', () => {
  it('conta as não lidas do usuário logado', async () => {
    prisma.notificacao.count.mockResolvedValue(3);

    const resposta = await request(app)
      .get('/api/v1/notificacoes/nao-lidas')
      .set('Authorization', `Bearer ${TOKEN_ALUNO}`);

    expect(resposta.status).toBe(200);
    expect(resposta.body.data).toEqual({ naoLidas: 3 });
    expect(prisma.notificacao.count).toHaveBeenCalledWith({ where: { usuarioId: 1, lida: false } });
  });
});

describe('PATCH /api/v1/notificacoes/:id/lida', () => {
  it('marca a própria notificação como lida e grava a auditoria', async () => {
    prisma.notificacao.findUnique.mockResolvedValue(notificacaoFake());
    prisma.notificacao.update.mockResolvedValue(notificacaoFake({ lida: true }));

    const resposta = await request(app)
      .patch('/api/v1/notificacoes/40/lida')
      .set('Authorization', `Bearer ${TOKEN_ALUNO}`);

    expect(resposta.status).toBe(200);
    expect(resposta.body.data).toMatchObject({ id: 40, lida: true, referenciaTipo: 'sugestao', referenciaId: 12 });
    expect(prisma.notificacao.update).toHaveBeenCalledWith({ where: { id: 40 }, data: { lida: true } });
    expect(prisma.logAuditoria.create).toHaveBeenCalledWith(
      expect.objectContaining({ data: expect.objectContaining({ acao: 'UPDATE', entidade: 'notificacao', entidadeId: 40 }) }),
    );
  });

  it('já lida: responde 200 sem gravar de novo', async () => {
    prisma.notificacao.findUnique.mockResolvedValue(notificacaoFake({ lida: true }));

    const resposta = await request(app)
      .patch('/api/v1/notificacoes/40/lida')
      .set('Authorization', `Bearer ${TOKEN_ALUNO}`);

    expect(resposta.status).toBe(200);
    expect(prisma.notificacao.update).not.toHaveBeenCalled();
    expect(prisma.logAuditoria.create).not.toHaveBeenCalled();
  });

  it('notificação de outro usuário responde 403', async () => {
    prisma.notificacao.findUnique.mockResolvedValue(notificacaoFake({ usuarioId: 1 }));

    const resposta = await request(app)
      .patch('/api/v1/notificacoes/40/lida')
      .set('Authorization', `Bearer ${TOKEN_UNIVERSIDADE}`);

    expect(resposta.status).toBe(403);
    expect(prisma.notificacao.update).not.toHaveBeenCalled();
  });

  it('inexistente responde 404', async () => {
    prisma.notificacao.findUnique.mockResolvedValue(null);

    const resposta = await request(app)
      .patch('/api/v1/notificacoes/41/lida')
      .set('Authorization', `Bearer ${TOKEN_ALUNO}`);

    expect(resposta.status).toBe(404);
  });
});

describe('PATCH /api/v1/notificacoes/lidas', () => {
  it('marca todas as não lidas do usuário logado', async () => {
    prisma.notificacao.updateMany.mockResolvedValue({ count: 4 });

    const resposta = await request(app)
      .patch('/api/v1/notificacoes/lidas')
      .set('Authorization', `Bearer ${TOKEN_ALUNO}`);

    expect(resposta.status).toBe(200);
    expect(resposta.body.data).toEqual({ atualizadas: 4 });
    expect(prisma.notificacao.updateMany).toHaveBeenCalledWith({
      where: { usuarioId: 1, lida: false },
      data: { lida: true },
    });
    expect(prisma.logAuditoria.create).toHaveBeenCalledTimes(1);
  });

  it('sem login responde 401', async () => {
    const resposta = await request(app).patch('/api/v1/notificacoes/lidas');
    expect(resposta.status).toBe(401);
  });
});
