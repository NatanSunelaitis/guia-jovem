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
const TOKEN_OUTRA_UNIVERSIDADE = tokenPara({ id: 4, tipoUsuario: 'U', universidadeId: 8 });
const TOKEN_ADMIN = tokenPara({ id: 99, tipoUsuario: 'D' });

const UNIVERSIDADE = { id: 7, nomeFantasia: 'Fatec Itu', usuarioId: 3 };

function sugestaoFake(sobrescreve = {}) {
  return {
    id: 12,
    usuarioId: 1,
    universidadeId: null,
    titulo: 'Filtro por cidade',
    texto: 'Seria ótimo filtrar universidades pela cidade.',
    status: 'EM_ANALISE',
    resposta: null,
    avaliadoPor: null,
    avaliadoEm: null,
    criadoEm: new Date('2026-11-10T12:00:00.000Z'),
    universidade: null,
    usuario: { id: 1, nome: 'Ana Souza' },
    ...sobrescreve,
  };
}

function paraUniversidade(sobrescreve = {}) {
  return sugestaoFake({ universidadeId: 7, universidade: UNIVERSIDADE, ...sobrescreve });
}

function notificacoesGravadas() {
  return prisma.notificacao.createMany.mock.calls.flatMap(([{ data }]) => data);
}

beforeEach(() => {
  prisma.resetMockPrisma();
});

describe('POST /api/v1/sugestoes', () => {
  it('aluno envia para a administração: nasce Em análise e notifica todos os administradores ativos (201)', async () => {
    prisma.sugestao.create.mockResolvedValue(sugestaoFake());
    prisma.usuario.findMany.mockResolvedValue([{ id: 99 }, { id: 98 }]);

    const resposta = await request(app)
      .post('/api/v1/sugestoes')
      .set('Authorization', `Bearer ${TOKEN_ALUNO}`)
      .send({ titulo: '  Filtro por cidade ', texto: 'Seria ótimo filtrar universidades pela cidade.' });

    expect(resposta.status).toBe(201);
    expect(resposta.body.data).toMatchObject({ id: 12, status: 'EM_ANALISE', universidade: null });

    // Sem status nem data no corpo gravado: vêm dos defaults do banco.
    expect(prisma.sugestao.create.mock.calls[0][0].data).toEqual({
      usuarioId: 1,
      universidadeId: null,
      titulo: 'Filtro por cidade',
      texto: 'Seria ótimo filtrar universidades pela cidade.',
    });
    expect(prisma.usuario.findMany).toHaveBeenCalledWith(
      expect.objectContaining({ where: { tipoUsuario: 'D', ativo: true } }),
    );
    expect(notificacoesGravadas()).toEqual([
      expect.objectContaining({ usuarioId: 99, tipo: 'NOVA_SUGESTAO', referenciaTipo: 'sugestao', referenciaId: 12 }),
      expect.objectContaining({ usuarioId: 98, tipo: 'NOVA_SUGESTAO', referenciaTipo: 'sugestao', referenciaId: 12 }),
    ]);
    expect(prisma.$transaction).toHaveBeenCalledTimes(1);
    expect(prisma.logAuditoria.create).toHaveBeenCalledWith(
      expect.objectContaining({ data: expect.objectContaining({ acao: 'CREATE', entidade: 'sugestao', entidadeId: 12 }) }),
    );
  });

  it('com universidade aprovada, notifica só a conta que a administra', async () => {
    prisma.universidade.findFirst.mockResolvedValue(UNIVERSIDADE);
    prisma.sugestao.create.mockResolvedValue(paraUniversidade());

    const resposta = await request(app)
      .post('/api/v1/sugestoes')
      .set('Authorization', `Bearer ${TOKEN_ALUNO}`)
      .send({ titulo: 'Mais vagas noturnas', texto: 'Abrir mais vagas no período noturno.', universidadeId: 7 });

    expect(resposta.status).toBe(201);
    expect(resposta.body.data.universidade).toEqual({ id: 7, nomeFantasia: 'Fatec Itu' });
    expect(prisma.universidade.findFirst).toHaveBeenCalledWith(
      expect.objectContaining({ where: { id: 7, status: 'A' } }),
    );
    expect(prisma.usuario.findMany).not.toHaveBeenCalled();
    expect(notificacoesGravadas()).toEqual([expect.objectContaining({ usuarioId: 3, tipo: 'NOVA_SUGESTAO' })]);
  });

  it('universidade que não está aprovada responde 400 e não grava nada', async () => {
    prisma.universidade.findFirst.mockResolvedValue(null);

    const resposta = await request(app)
      .post('/api/v1/sugestoes')
      .set('Authorization', `Bearer ${TOKEN_ALUNO}`)
      .send({ titulo: 'Mais vagas', texto: 'Abrir mais vagas no período noturno.', universidadeId: 70 });

    expect(resposta.status).toBe(400);
    expect(resposta.body.error.code).toBe('UNIVERSIDADE_INVALIDA');
    expect(prisma.sugestao.create).not.toHaveBeenCalled();
    expect(prisma.notificacao.createMany).not.toHaveBeenCalled();
  });

  it('valida título e texto (400)', async () => {
    const resposta = await request(app)
      .post('/api/v1/sugestoes')
      .set('Authorization', `Bearer ${TOKEN_ALUNO}`)
      .send({ titulo: '', texto: 'curto' });

    expect(resposta.status).toBe(400);
    expect(resposta.body.error.details.map((d) => d.campo).sort()).toEqual(['texto', 'titulo']);
  });

  it('sem login responde 401', async () => {
    const resposta = await request(app).post('/api/v1/sugestoes').send({ titulo: 'Oi', texto: 'Texto' });
    expect(resposta.status).toBe(401);
  });

  it.each([
    ['universidade', TOKEN_UNIVERSIDADE],
    ['administrador', TOKEN_ADMIN],
  ])('perfil %s não envia sugestão (403)', async (_perfil, token) => {
    const resposta = await request(app)
      .post('/api/v1/sugestoes')
      .set('Authorization', `Bearer ${token}`)
      .send({ titulo: 'Filtro por cidade', texto: 'Seria ótimo filtrar universidades pela cidade.' });

    expect(resposta.status).toBe(403);
    expect(prisma.sugestao.create).not.toHaveBeenCalled();
  });
});

describe('GET /api/v1/sugestoes/minhas', () => {
  it('lista as sugestões do aluno logado com status, resposta e data da avaliação', async () => {
    const avaliada = paraUniversidade({
      status: 'APROVADA',
      resposta: 'Vamos abrir uma turma em 2027.',
      avaliadoEm: new Date('2026-11-12T09:00:00.000Z'),
    });
    prisma.sugestao.findMany.mockResolvedValue([avaliada]);
    prisma.sugestao.count.mockResolvedValue(1);

    const resposta = await request(app)
      .get('/api/v1/sugestoes/minhas')
      .set('Authorization', `Bearer ${TOKEN_ALUNO}`);

    expect(resposta.status).toBe(200);
    expect(resposta.body.data[0]).toEqual({
      id: 12,
      titulo: 'Filtro por cidade',
      texto: 'Seria ótimo filtrar universidades pela cidade.',
      status: 'APROVADA',
      resposta: 'Vamos abrir uma turma em 2027.',
      criadoEm: '2026-11-10T12:00:00.000Z',
      avaliadoEm: '2026-11-12T09:00:00.000Z',
      universidade: { id: 7, nomeFantasia: 'Fatec Itu' },
    });
    expect(resposta.body.meta).toMatchObject({ page: 1, total: 1 });
    expect(prisma.sugestao.findMany).toHaveBeenCalledWith(
      expect.objectContaining({ where: { usuarioId: 1 }, orderBy: [{ criadoEm: 'desc' }, { id: 'desc' }] }),
    );
  });

  it('é exclusiva do aluno (403 para administrador)', async () => {
    const resposta = await request(app)
      .get('/api/v1/sugestoes/minhas')
      .set('Authorization', `Bearer ${TOKEN_ADMIN}`);
    expect(resposta.status).toBe(403);
  });
});

describe('GET /api/v1/sugestoes (recebidas)', () => {
  it('administrador recebe as sugestões sem universidade, com filtro por status e o nome do autor', async () => {
    prisma.sugestao.findMany.mockResolvedValue([sugestaoFake()]);
    prisma.sugestao.count.mockResolvedValue(1);

    const resposta = await request(app)
      .get('/api/v1/sugestoes?status=EM_ANALISE')
      .set('Authorization', `Bearer ${TOKEN_ADMIN}`);

    expect(resposta.status).toBe(200);
    expect(resposta.body.data[0].autor).toEqual({ nome: 'Ana Souza' });
    expect(prisma.sugestao.findMany).toHaveBeenCalledWith(
      expect.objectContaining({ where: { universidadeId: null, status: 'EM_ANALISE' } }),
    );
  });

  it('conta de universidade recebe só as destinadas à própria universidade', async () => {
    prisma.sugestao.findMany.mockResolvedValue([]);
    prisma.sugestao.count.mockResolvedValue(0);

    const resposta = await request(app)
      .get('/api/v1/sugestoes')
      .set('Authorization', `Bearer ${TOKEN_UNIVERSIDADE}`);

    expect(resposta.status).toBe(200);
    expect(prisma.sugestao.findMany).toHaveBeenCalledWith(expect.objectContaining({ where: { universidadeId: 7 } }));
  });

  it('status inválido responde 400', async () => {
    const resposta = await request(app)
      .get('/api/v1/sugestoes?status=LIDA')
      .set('Authorization', `Bearer ${TOKEN_ADMIN}`);
    expect(resposta.status).toBe(400);
  });

  it('aluno não acessa as recebidas (403) e visitante recebe 401', async () => {
    const aluno = await request(app).get('/api/v1/sugestoes').set('Authorization', `Bearer ${TOKEN_ALUNO}`);
    const visitante = await request(app).get('/api/v1/sugestoes');

    expect(aluno.status).toBe(403);
    expect(visitante.status).toBe(401);
  });
});

describe('GET /api/v1/sugestoes/:id', () => {
  it('autor vê a própria sugestão, sem poder avaliar', async () => {
    prisma.sugestao.findUnique.mockResolvedValue(sugestaoFake());

    const resposta = await request(app)
      .get('/api/v1/sugestoes/12')
      .set('Authorization', `Bearer ${TOKEN_ALUNO}`);

    expect(resposta.status).toBe(200);
    expect(resposta.body.data).toMatchObject({ id: 12, podeAvaliar: false });
  });

  it('destinatário vê e pode avaliar enquanto estiver Em análise', async () => {
    prisma.sugestao.findUnique.mockResolvedValue(paraUniversidade());

    const resposta = await request(app)
      .get('/api/v1/sugestoes/12')
      .set('Authorization', `Bearer ${TOKEN_UNIVERSIDADE}`);

    expect(resposta.status).toBe(200);
    expect(resposta.body.data).toMatchObject({ podeAvaliar: true, autor: { nome: 'Ana Souza' } });
  });

  it.each([
    ['outro aluno', TOKEN_OUTRO_ALUNO, sugestaoFake()],
    ['outra universidade', TOKEN_OUTRA_UNIVERSIDADE, paraUniversidade()],
    ['administrador em sugestão para universidade', TOKEN_ADMIN, paraUniversidade()],
    ['universidade em sugestão para a administração', TOKEN_UNIVERSIDADE, sugestaoFake()],
  ])('%s não vê a sugestão de terceiros (403)', async (_caso, token, sugestao) => {
    prisma.sugestao.findUnique.mockResolvedValue(sugestao);

    const resposta = await request(app).get('/api/v1/sugestoes/12').set('Authorization', `Bearer ${token}`);

    expect(resposta.status).toBe(403);
  });

  it('inexistente responde 404', async () => {
    prisma.sugestao.findUnique.mockResolvedValue(null);
    const resposta = await request(app).get('/api/v1/sugestoes/404').set('Authorization', `Bearer ${TOKEN_ADMIN}`);
    expect(resposta.status).toBe(404);
  });
});

describe('PATCH /api/v1/sugestoes/:id/status', () => {
  it('universidade destinatária aprova com resposta, grava a data e notifica o autor', async () => {
    prisma.sugestao.findUnique
      .mockResolvedValueOnce(paraUniversidade())
      .mockResolvedValueOnce(
        paraUniversidade({ status: 'APROVADA', resposta: 'Ótima ideia!', avaliadoPor: 3, avaliadoEm: new Date() }),
      );
    prisma.sugestao.updateMany.mockResolvedValue({ count: 1 });

    const resposta = await request(app)
      .patch('/api/v1/sugestoes/12/status')
      .set('Authorization', `Bearer ${TOKEN_UNIVERSIDADE}`)
      .send({ status: 'APROVADA', resposta: '  Ótima ideia! ' });

    expect(resposta.status).toBe(200);
    expect(resposta.body.data).toMatchObject({ status: 'APROVADA', resposta: 'Ótima ideia!', podeAvaliar: false });

    const { where, data } = prisma.sugestao.updateMany.mock.calls[0][0];
    expect(where).toEqual({ id: 12, status: 'EM_ANALISE' });
    expect(data).toMatchObject({ status: 'APROVADA', resposta: 'Ótima ideia!', avaliadoPor: 3 });
    expect(data.avaliadoEm).toBeInstanceOf(Date);

    expect(notificacoesGravadas()).toEqual([
      expect.objectContaining({
        usuarioId: 1,
        tipo: 'SUGESTAO_AVALIADA',
        titulo: 'Sua sugestão foi aprovada',
        referenciaTipo: 'sugestao',
        referenciaId: 12,
      }),
    ]);
    expect(prisma.logAuditoria.create).toHaveBeenCalledWith(
      expect.objectContaining({ data: expect.objectContaining({ acao: 'UPDATE', entidade: 'sugestao', entidadeId: 12 }) }),
    );
  });

  it('administrador reprova sugestão da administração e o autor é avisado do resultado', async () => {
    prisma.sugestao.findUnique
      .mockResolvedValueOnce(sugestaoFake())
      .mockResolvedValueOnce(sugestaoFake({ status: 'REPROVADA', resposta: 'Fora do escopo.' }));
    prisma.sugestao.updateMany.mockResolvedValue({ count: 1 });

    const resposta = await request(app)
      .patch('/api/v1/sugestoes/12/status')
      .set('Authorization', `Bearer ${TOKEN_ADMIN}`)
      .send({ status: 'REPROVADA', resposta: 'Fora do escopo.' });

    expect(resposta.status).toBe(200);
    expect(notificacoesGravadas()).toEqual([
      expect.objectContaining({ usuarioId: 1, titulo: 'Sua sugestão foi reprovada' }),
    ]);
  });

  it('autor com a conta excluída: avalia sem notificar ninguém', async () => {
    prisma.sugestao.findUnique
      .mockResolvedValueOnce(sugestaoFake({ usuarioId: null, usuario: null }))
      .mockResolvedValueOnce(sugestaoFake({ usuarioId: null, usuario: null, status: 'APROVADA', resposta: 'Ok' }));
    prisma.sugestao.updateMany.mockResolvedValue({ count: 1 });

    const resposta = await request(app)
      .patch('/api/v1/sugestoes/12/status')
      .set('Authorization', `Bearer ${TOKEN_ADMIN}`)
      .send({ status: 'APROVADA', resposta: 'Ok' });

    expect(resposta.status).toBe(200);
    expect(resposta.body.data.autor).toBeNull();
    expect(prisma.notificacao.createMany).not.toHaveBeenCalled();
  });

  it('avaliação repetida responde 409 SUGESTAO_JA_AVALIADA', async () => {
    prisma.sugestao.findUnique.mockResolvedValue(sugestaoFake({ status: 'APROVADA', resposta: 'Já respondida' }));

    const resposta = await request(app)
      .patch('/api/v1/sugestoes/12/status')
      .set('Authorization', `Bearer ${TOKEN_ADMIN}`)
      .send({ status: 'REPROVADA', resposta: 'Mudei de ideia' });

    expect(resposta.status).toBe(409);
    expect(resposta.body.error.code).toBe('SUGESTAO_JA_AVALIADA');
    expect(prisma.sugestao.updateMany).not.toHaveBeenCalled();
    expect(prisma.notificacao.createMany).not.toHaveBeenCalled();
  });

  it('avaliação simultânea: a segunda não encontra mais a sugestão Em análise (409)', async () => {
    prisma.sugestao.findUnique.mockResolvedValue(sugestaoFake());
    prisma.sugestao.updateMany.mockResolvedValue({ count: 0 });

    const resposta = await request(app)
      .patch('/api/v1/sugestoes/12/status')
      .set('Authorization', `Bearer ${TOKEN_ADMIN}`)
      .send({ status: 'APROVADA', resposta: 'Ok' });

    expect(resposta.status).toBe(409);
    expect(prisma.notificacao.createMany).not.toHaveBeenCalled();
  });

  it('resposta é obrigatória e o status só pode ser Aprovada ou Reprovada (400)', async () => {
    const semResposta = await request(app)
      .patch('/api/v1/sugestoes/12/status')
      .set('Authorization', `Bearer ${TOKEN_ADMIN}`)
      .send({ status: 'APROVADA', resposta: '   ' });
    const emAnalise = await request(app)
      .patch('/api/v1/sugestoes/12/status')
      .set('Authorization', `Bearer ${TOKEN_ADMIN}`)
      .send({ status: 'EM_ANALISE', resposta: 'Ok' });

    expect(semResposta.status).toBe(400);
    expect(semResposta.body.error.details[0].campo).toBe('resposta');
    expect(emAnalise.status).toBe(400);
    expect(emAnalise.body.error.details[0].campo).toBe('status');
  });

  it('o autor não avalia a própria sugestão (403)', async () => {
    const resposta = await request(app)
      .patch('/api/v1/sugestoes/12/status')
      .set('Authorization', `Bearer ${TOKEN_ALUNO}`)
      .send({ status: 'APROVADA', resposta: 'Ok' });

    expect(resposta.status).toBe(403);
  });

  it.each([
    ['outra universidade', TOKEN_OUTRA_UNIVERSIDADE, paraUniversidade()],
    ['administrador em sugestão para universidade', TOKEN_ADMIN, paraUniversidade()],
  ])('%s não avalia sugestão de terceiros (403)', async (_caso, token, sugestao) => {
    prisma.sugestao.findUnique.mockResolvedValue(sugestao);

    const resposta = await request(app)
      .patch('/api/v1/sugestoes/12/status')
      .set('Authorization', `Bearer ${token}`)
      .send({ status: 'APROVADA', resposta: 'Ok' });

    expect(resposta.status).toBe(403);
    expect(prisma.sugestao.updateMany).not.toHaveBeenCalled();
  });

  it('sem login responde 401', async () => {
    const resposta = await request(app).patch('/api/v1/sugestoes/12/status').send({ status: 'APROVADA', resposta: 'Ok' });
    expect(resposta.status).toBe(401);
  });
});
