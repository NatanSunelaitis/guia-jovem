const request = require('supertest');

jest.mock('../../config/database', () => require('../../../tests/helpers/mockPrisma'));

const prisma = require('../../config/database');
const app = require('../../app');

function programaFake(sobrescreve = {}) {
  return {
    id: 1,
    nome: 'Exame Nacional do Ensino Médio',
    sigla: 'ENEM',
    tipo: 'ENTRADA',
    descricao: 'Descrição',
    requisitos: 'Requisitos',
    comoFunciona: 'Como funciona',
    linkOficial: 'https://enem.inep.gov.br',
    imagemUrl: null,
    universidadeId: null,
    eventos: [{ id: 1, titulo: 'Inscrições', descricao: null, dataInicio: new Date(), dataFim: null }],
    universidades: [
      { observacao: null, universidade: { id: 1, nomeFantasia: 'Fatec Sorocaba', logoUrl: null } },
    ],
    ...sobrescreve,
  };
}

beforeEach(() => {
  prisma.resetMockPrisma();
});

describe('GET /api/v1/programas', () => {
  it('lista programas paginados (200)', async () => {
    prisma.programa.findMany.mockResolvedValue([programaFake()]);
    prisma.programa.count.mockResolvedValue(1);

    const resposta = await request(app).get('/api/v1/programas?tipo=ENTRADA');

    expect(resposta.status).toBe(200);
    expect(resposta.body.data[0].sigla).toBe('ENEM');
  });

  it('responde 400 com tipo inválido', async () => {
    const resposta = await request(app).get('/api/v1/programas?tipo=INVALIDO');

    expect(resposta.status).toBe(400);
  });

  it('pesquisa geral não traz bolsas institucionais: só programas globais (RF11)', async () => {
    prisma.programa.findMany.mockResolvedValue([]);
    prisma.programa.count.mockResolvedValue(0);

    await request(app).get('/api/v1/programas?tipo=BOLSA');

    const { where } = prisma.programa.findMany.mock.calls[0][0];
    expect(where.universidadeId).toBeNull();
    expect(prisma.programa.count).toHaveBeenCalledWith({ where });
  });

  it('com universidadeId, traz as bolsas institucionais daquela universidade', async () => {
    prisma.programa.findMany.mockResolvedValue([programaFake({ id: 30, tipo: 'BOLSA', universidadeId: 7 })]);
    prisma.programa.count.mockResolvedValue(1);

    const resposta = await request(app).get('/api/v1/programas?universidadeId=7');

    expect(resposta.status).toBe(200);
    expect(resposta.body.data[0]).toMatchObject({ id: 30, universidadeId: 7 });
    const { where } = prisma.programa.findMany.mock.calls[0][0];
    expect(where.universidadeId).toBe(7);
    // A universidade dona continua precisando estar aprovada.
    expect(where.AND[0]).toEqual({ OR: [{ universidadeId: null }, { universidade: { status: 'A' } }] });
  });

  it('filtra apenas globais quando apenasGlobais=true', async () => {
    prisma.programa.findMany.mockResolvedValue([]);
    prisma.programa.count.mockResolvedValue(0);

    await request(app).get('/api/v1/programas?apenasGlobais=true');

    const chamada = prisma.programa.findMany.mock.calls[0][0];
    expect(chamada.where.universidadeId).toBeNull();
  });
});

describe('GET /api/v1/programas/destaques', () => {
  it('retorna os destaques (200)', async () => {
    prisma.programa.findMany.mockResolvedValue([programaFake()]);

    const resposta = await request(app).get('/api/v1/programas/destaques');

    expect(resposta.status).toBe(200);
    expect(resposta.body.data).toHaveLength(1);
    // Sem bolsas institucionais nos destaques (RF11).
    expect(prisma.programa.findMany.mock.calls[0][0].where).toEqual({ ativo: true, universidadeId: null });
  });

  it('filtra os destaques por tipo (home: programas de entrada)', async () => {
    prisma.programa.findMany.mockResolvedValue([programaFake()]);

    const resposta = await request(app).get('/api/v1/programas/destaques?tipo=ENTRADA&limite=4');

    expect(resposta.status).toBe(200);
    expect(prisma.programa.findMany).toHaveBeenCalledWith(
      expect.objectContaining({ where: { ativo: true, universidadeId: null, tipo: 'ENTRADA' }, take: 4 }),
    );
  });

  it('responde 400 com tipo inválido', async () => {
    const resposta = await request(app).get('/api/v1/programas/destaques?tipo=OUTRO');

    expect(resposta.status).toBe(400);
  });
});

describe('GET /api/v1/programas/:id', () => {
  it('retorna o detalhe com eventos e universidades, e registra a visita (200)', async () => {
    prisma.programa.findFirst.mockResolvedValue(programaFake());

    const resposta = await request(app).get('/api/v1/programas/1');

    expect(resposta.status).toBe(200);
    expect(resposta.body.data.eventos).toHaveLength(1);
    expect(resposta.body.data.universidades[0].nomeFantasia).toBe('Fatec Sorocaba');
    expect(prisma.visitaPagina.create).toHaveBeenCalledWith(
      expect.objectContaining({ data: expect.objectContaining({ entidade: 'programa', entidadeId: 1 }) }),
    );
  });

  it('traz a universidade dona quando é bolsa institucional (200)', async () => {
    prisma.programa.findFirst.mockResolvedValue({
      ...programaFake(),
      universidadeId: 7,
      universidade: { id: 7, nomeFantasia: 'UniVale Sorocaba', logoUrl: null },
      universidades: [],
    });

    const resposta = await request(app).get('/api/v1/programas/1');

    expect(resposta.status).toBe(200);
    expect(resposta.body.data.universidade).toEqual({ id: 7, nomeFantasia: 'UniVale Sorocaba', logoUrl: null });
  });

  it('responde 404 quando o programa não existe', async () => {
    prisma.programa.findFirst.mockResolvedValue(null);

    const resposta = await request(app).get('/api/v1/programas/999');

    expect(resposta.status).toBe(404);
  });
});

describe('GET /api/v1/programas/:id/universidades', () => {
  it('retorna as universidades relacionadas (200)', async () => {
    prisma.programa.findFirst.mockResolvedValue(programaFake());

    const resposta = await request(app).get('/api/v1/programas/1/universidades');

    expect(resposta.status).toBe(200);
    expect(resposta.body.data[0].nomeFantasia).toBe('Fatec Sorocaba');
  });
});
