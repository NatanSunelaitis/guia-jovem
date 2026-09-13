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
