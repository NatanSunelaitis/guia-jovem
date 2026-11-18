const request = require('supertest');

jest.mock('../../config/database', () => require('../../../tests/helpers/mockPrisma'));

const prisma = require('../../config/database');
const app = require('../../app');

function universidadeFake(sobrescreve = {}) {
  return {
    id: 1,
    nomeFantasia: 'Fatec Sorocaba',
    logoUrl: null,
    natureza: 'P',
    status: 'A',
    mediaAvaliacao: '4.60',
    totalAvaliacoes: 12,
    razaoSocial: 'Faculdade de Tecnologia de Sorocaba',
    descricao: 'Descrição',
    linkPagina: 'https://fatecsorocaba.edu.br',
    linkSimulados: null,
    campus: [
      {
        id: 10,
        nome: 'Fatec Sorocaba',
        principal: true,
        endereco: { cidade: 'Sorocaba', estado: 'SP' },
      },
    ],
    universidadeProgramas: [
      { programa: { id: 1, nome: 'ENEM', sigla: 'ENEM', tipo: 'ENTRADA' }, observacao: null },
    ],
    ...sobrescreve,
  };
}

beforeEach(() => {
  prisma.resetMockPrisma();
});

describe('GET /api/v1/universidades', () => {
  it('lista universidades paginadas (200)', async () => {
    prisma.universidade.findMany.mockResolvedValue([universidadeFake()]);
    prisma.universidade.count.mockResolvedValue(1);

    const resposta = await request(app).get('/api/v1/universidades');

    expect(resposta.status).toBe(200);
    expect(resposta.body.data).toHaveLength(1);
    expect(resposta.body.data[0]).toMatchObject({ id: 1, cidade: 'Sorocaba', estado: 'SP' });
    expect(resposta.body.meta).toMatchObject({ page: 1, pageSize: 20, total: 1 });
  });

  it('aplica status=A no filtro e repassa os filtros de busca', async () => {
    prisma.universidade.findMany.mockResolvedValue([]);
    prisma.universidade.count.mockResolvedValue(0);

    await request(app).get('/api/v1/universidades?cidade=Sorocaba&natureza=P&sort=media');

    const chamada = prisma.universidade.findMany.mock.calls[0][0];
    expect(chamada.where.status).toBe('A');
    expect(chamada.where.natureza).toBe('P');
    expect(chamada.where.campus.some.endereco.cidade).toEqual({ contains: 'Sorocaba' });
    expect(chamada.orderBy).toEqual([{ mediaAvaliacao: 'desc' }, { totalAvaliacoes: 'desc' }]);
  });

  it('aplica o filtro de nota mínima (RF06)', async () => {
    prisma.universidade.findMany.mockResolvedValue([]);
    prisma.universidade.count.mockResolvedValue(0);

    await request(app).get('/api/v1/universidades?notaMinima=3.5');

    const chamada = prisma.universidade.findMany.mock.calls[0][0];
    expect(chamada.where.mediaAvaliacao).toEqual({ gte: 3.5 });
  });

  it('responde 400 com estado inválido', async () => {
    const resposta = await request(app).get('/api/v1/universidades?estado=SPX');

    expect(resposta.status).toBe(400);
    expect(resposta.body.error.code).toBe('VALIDATION_ERROR');
  });
});

describe('GET /api/v1/universidades/destaques', () => {
  it('retorna a lista de destaques (200)', async () => {
    prisma.universidade.findMany.mockResolvedValue([universidadeFake()]);

    const resposta = await request(app).get('/api/v1/universidades/destaques?limite=4');

    expect(resposta.status).toBe(200);
    expect(resposta.body.data).toHaveLength(1);
    expect(prisma.universidade.findMany).toHaveBeenCalledWith(
      expect.objectContaining({ where: { status: 'A' }, take: 4 }),
    );
  });
});

describe('GET /api/v1/universidades/:id', () => {
  it('retorna o detalhe e registra a visita (200)', async () => {
    prisma.universidade.findFirst.mockResolvedValue(universidadeFake());

    const resposta = await request(app).get('/api/v1/universidades/1');

    expect(resposta.status).toBe(200);
    expect(resposta.body.data.nomeFantasia).toBe('Fatec Sorocaba');
    expect(resposta.body.data.programas.ENTRADA).toHaveLength(1);
    expect(resposta.body.data.programas.BOLSA).toHaveLength(0);
    expect(prisma.visitaPagina.create).toHaveBeenCalledWith(
      expect.objectContaining({ data: expect.objectContaining({ entidade: 'universidade', entidadeId: 1 }) }),
    );
  });

  it('exibe as bolsas institucionais da universidade junto das bolsas aceitas (RF11)', async () => {
    prisma.universidade.findFirst.mockResolvedValue(
      universidadeFake({
        universidadeProgramas: [
          { programa: { id: 3, nome: 'ProUni', sigla: 'PROUNI', tipo: 'BOLSA', universidadeId: null }, observacao: null },
        ],
        programas: [{ id: 30, nome: 'Bolsa Mérito Fatec', sigla: null, tipo: 'BOLSA', universidadeId: 1 }],
      }),
    );

    const resposta = await request(app).get('/api/v1/universidades/1');

    expect(resposta.status).toBe(200);
    expect(resposta.body.data.programas.BOLSA).toEqual([
      { id: 3, nome: 'ProUni', sigla: 'PROUNI', observacao: null, institucional: false },
      { id: 30, nome: 'Bolsa Mérito Fatec', sigla: null, observacao: null, institucional: true },
    ]);
    expect(prisma.universidade.findFirst.mock.calls[0][0].include.programas).toEqual({
      where: { ativo: true },
      orderBy: { criadoEm: 'asc' },
    });
  });

  it('responde 404 quando a universidade não existe ou não está aprovada', async () => {
    prisma.universidade.findFirst.mockResolvedValue(null);

    const resposta = await request(app).get('/api/v1/universidades/999');

    expect(resposta.status).toBe(404);
  });
});

describe('GET /api/v1/universidades/:id/campus', () => {
  it('lista os campus com os cursos (200)', async () => {
    prisma.universidade.findFirst.mockResolvedValue({ id: 1 });
    prisma.campus.findMany.mockResolvedValue([
      {
        id: 10,
        nome: 'Fatec Sorocaba',
        telefoneCelular: null,
        telefoneFixo: null,
        emailCampus: null,
        principal: true,
        endereco: { logradouro: 'Rua X', numero: '1', bairro: 'Centro', cidade: 'Sorocaba', estado: 'SP', cep: '18000000' },
        campusCursos: [{ curso: { id: 5, nome: 'Administração' }, turno: 'Integral', vagas: 40 }],
      },
    ]);

    const resposta = await request(app).get('/api/v1/universidades/1/campus');

    expect(resposta.status).toBe(200);
    expect(resposta.body.data[0].cursos[0]).toMatchObject({ id: 5, nome: 'Administração' });
  });

  it('responde 404 quando a universidade não existe', async () => {
    prisma.universidade.findFirst.mockResolvedValue(null);

    const resposta = await request(app).get('/api/v1/universidades/1/campus');

    expect(resposta.status).toBe(404);
  });
});

describe('GET /api/v1/universidades/:id/cursos', () => {
  it('lista os cursos da universidade (200)', async () => {
    prisma.universidade.findFirst.mockResolvedValue({ id: 1 });
    prisma.curso.findMany.mockResolvedValue([{ id: 5, nome: 'Administração', areaCurso: 'Negócios', grau: 'Bacharelado', modalidade: 'Presencial', duracaoSemestres: 8 }]);

    const resposta = await request(app).get('/api/v1/universidades/1/cursos');

    expect(resposta.status).toBe(200);
    expect(resposta.body.data).toHaveLength(1);
  });
});

describe('GET /api/v1/universidades/:id/avaliacoes', () => {
  it('lista avaliações paginadas mostrando só o primeiro nome (200)', async () => {
    prisma.universidade.findFirst.mockResolvedValue({ id: 1 });
    prisma.avaliacao.findMany.mockResolvedValue([
      { id: 1, nota: 5, comentario: 'Ótima', criadoEm: new Date(), usuario: { nome: 'Maria Silva' } },
      { id: 2, nota: 4, comentario: 'Boa', criadoEm: new Date(), usuario: null },
    ]);
    prisma.avaliacao.count.mockResolvedValue(2);

    const resposta = await request(app).get('/api/v1/universidades/1/avaliacoes');

    expect(resposta.status).toBe(200);
    expect(resposta.body.data[0].autor).toBe('Maria');
    expect(resposta.body.data[1].autor).toBeNull();
  });

  it('responde 404 quando a universidade não existe', async () => {
    prisma.universidade.findFirst.mockResolvedValue(null);

    const resposta = await request(app).get('/api/v1/universidades/1/avaliacoes');

    expect(resposta.status).toBe(404);
  });
});

describe('GET /api/v1/universidades/destaques (visita à home)', () => {
  it('cada carregamento da home grava uma visita com rota "/"', async () => {
    prisma.universidade.findMany.mockResolvedValue([]);

    const resposta = await request(app).get('/api/v1/universidades/destaques');

    expect(resposta.status).toBe(200);
    expect(prisma.visitaPagina.create).toHaveBeenCalledWith({
      data: { rota: '/', entidade: 'home', entidadeId: null, tipoUsuario: null },
    });
  });
});
