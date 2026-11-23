const request = require('supertest');

jest.mock('../../config/database', () => require('../../../tests/helpers/mockPrisma'));

const prisma = require('../../config/database');
const app = require('../../app');

function cursoFake(sobrescreve = {}) {
  return {
    id: 5,
    nome: 'Administração',
    areaCurso: 'Negócios',
    notaMec: '4',
    modalidade: 'Presencial',
    grau: 'Bacharelado',
    duracaoSemestres: 8,
    descricao: 'Descrição do curso',
    universidade: {
      id: 1,
      nomeFantasia: 'Fatec Sorocaba',
      logoUrl: null,
      natureza: 'P',
      campus: [{ id: 10, principal: true, endereco: { cidade: 'Sorocaba', estado: 'SP' } }],
      universidadeProgramas: [
        { observacao: 'Todas as vagas', programa: { id: 2, nome: 'Sistema de Seleção Unificada', sigla: 'SiSU', tipo: 'ENTRADA', universidadeId: null } },
        { observacao: null, programa: { id: 3, nome: 'Fundo de Financiamento Estudantil', sigla: 'FIES', tipo: 'FINANCIAMENTO', universidadeId: null } },
      ],
      programas: [{ id: 9, nome: 'Bolsa Mérito', sigla: null, tipo: 'BOLSA', universidadeId: 1 }],
    },
    campusCursos: [
      { turno: 'Integral', vagas: 40, campus: { id: 10, nome: 'Fatec Sorocaba', endereco: { cidade: 'Sorocaba', estado: 'SP' } } },
    ],
    ...sobrescreve,
  };
}

beforeEach(() => {
  prisma.resetMockPrisma();
});

describe('GET /api/v1/cursos', () => {
  it('lista cursos paginados (200)', async () => {
    prisma.curso.findMany.mockResolvedValue([cursoFake()]);
    prisma.curso.count.mockResolvedValue(1);

    const resposta = await request(app).get('/api/v1/cursos?areaCurso=Negócios');

    expect(resposta.status).toBe(200);
    expect(resposta.body.data[0].nome).toBe('Administração');
    expect(resposta.body.meta.total).toBe(1);
  });
});

describe('GET /api/v1/cursos/destaques', () => {
  it('agrupa por nome e ordena pela contagem (200)', async () => {
    prisma.curso.findMany.mockResolvedValue([
      { id: 1, nome: 'Administração', areaCurso: 'Negócios', grau: 'Bacharelado', universidadeId: 1 },
      { id: 2, nome: 'Administração', areaCurso: 'Negócios', grau: 'Bacharelado', universidadeId: 2 },
      { id: 3, nome: 'Farmácia', areaCurso: 'Saúde', grau: 'Bacharelado', universidadeId: 1 },
    ]);

    const resposta = await request(app).get('/api/v1/cursos/destaques');

    expect(resposta.status).toBe(200);
    expect(resposta.body.data[0]).toEqual({
      nome: 'Administração',
      areaCurso: 'Negócios',
      graus: ['Bacharelado'],
      totalOfertas: 2,
      totalUniversidades: 2,
    });
    expect(resposta.body.data[1]).toMatchObject({ nome: 'Farmácia', areaCurso: 'Saúde', totalOfertas: 1 });
    expect(prisma.curso.findMany.mock.calls[0][0].orderBy).toEqual({ id: 'asc' });
  });

  it('junta grafias que só diferem em maiúsculas, acentos e espaços, com a grafia e a área mais usadas', async () => {
    prisma.curso.findMany.mockResolvedValue([
      { id: 1, nome: 'Análise e Desenvolvimento de Sistemas', areaCurso: 'Tecnologia', grau: 'Tecnólogo', universidadeId: 1 },
      { id: 2, nome: 'analise e desenvolvimento  de sistemas ', areaCurso: 'Computação', grau: 'Tecnólogo', universidadeId: 2 },
      { id: 3, nome: 'Análise e Desenvolvimento de Sistemas', areaCurso: 'Tecnologia', grau: 'Bacharelado', universidadeId: 3 },
      { id: 4, nome: 'Educação Física', areaCurso: 'Saúde', grau: 'Licenciatura', universidadeId: 1 },
    ]);

    const resposta = await request(app).get('/api/v1/cursos/destaques');

    expect(resposta.body.data).toHaveLength(2);
    expect(resposta.body.data[0]).toEqual({
      nome: 'Análise e Desenvolvimento de Sistemas',
      areaCurso: 'Tecnologia',
      graus: ['Tecnólogo', 'Bacharelado'],
      totalOfertas: 3,
      totalUniversidades: 3,
    });
  });

  it('aplica os filtros q e areaCurso (usado por T07)', async () => {
    prisma.curso.findMany.mockResolvedValue([]);

    await request(app).get('/api/v1/cursos/destaques?q=Farm&areaCurso=Sa%C3%BAde&limite=100');

    const chamada = prisma.curso.findMany.mock.calls[0][0];
    expect(chamada.where.nome).toEqual({ contains: 'Farm' });
    expect(chamada.where.areaCurso).toEqual({ contains: 'Saúde' });
  });
});

describe('GET /api/v1/cursos/:id', () => {
  it('retorna o detalhe com os campus onde é ofertado (200)', async () => {
    prisma.curso.findFirst.mockResolvedValue(cursoFake());

    const resposta = await request(app).get('/api/v1/cursos/5');

    expect(resposta.status).toBe(200);
    expect(resposta.body.data.campus[0]).toMatchObject({ id: 10, cidade: 'Sorocaba', turno: 'Integral', vagas: 40 });
    expect(resposta.body.data.universidade).toMatchObject({ natureza: 'P', cidade: 'Sorocaba' });
    expect(resposta.body.data.programas.ENTRADA[0].sigla).toBe('SiSU');
    expect(prisma.visitaPagina.create).toHaveBeenCalledWith({
      data: expect.objectContaining({ entidade: 'curso', entidadeId: 5 }),
    });
  });

  it('responde 404 quando o curso não existe', async () => {
    prisma.curso.findFirst.mockResolvedValue(null);

    const resposta = await request(app).get('/api/v1/cursos/999');

    expect(resposta.status).toBe(404);
  });
});

describe('GET /api/v1/cursos/nome/:nome', () => {
  /** Primeira consulta: os nomes para agrupar; segunda: as ofertas do grupo. */
  function mockNomes(nomes) {
    prisma.curso.findMany.mockResolvedValueOnce(
      nomes.map(([id, nome, areaCurso = 'Negócios', universidadeId = id]) => ({ id, nome, areaCurso, grau: 'Bacharelado', universidadeId })),
    );
  }

  it('cada oferta traz os dados do curso, a universidade, os campi com turno e vagas e os programas aceitos', async () => {
    mockNomes([[5, 'Administração'], [6, 'Administração']]);
    prisma.curso.findMany.mockResolvedValueOnce([
      cursoFake(),
      cursoFake({
        id: 6,
        modalidade: 'EAD',
        duracaoSemestres: 6,
        descricao: '## O que você estuda\n\nOutra descrição.',
        universidade: { id: 2, nomeFantasia: 'UniVale', logoUrl: null, natureza: 'V', campus: [], universidadeProgramas: [], programas: [] },
        campusCursos: [],
      }),
    ]);

    const resposta = await request(app).get('/api/v1/cursos/nome/Administração');

    expect(resposta.status).toBe(200);
    const [primeira, segunda] = resposta.body.data.universidades;
    expect(primeira).toEqual({
      cursoId: 5,
      areaCurso: 'Negócios',
      grau: 'Bacharelado',
      modalidade: 'Presencial',
      duracaoSemestres: 8,
      notaMec: '4',
      descricao: 'Descrição do curso',
      universidade: { id: 1, nomeFantasia: 'Fatec Sorocaba', logoUrl: null, natureza: 'P', cidade: 'Sorocaba', estado: 'SP' },
      campus: [{ id: 10, nome: 'Fatec Sorocaba', cidade: 'Sorocaba', estado: 'SP', turno: 'Integral', vagas: 40 }],
      programas: {
        ENTRADA: [{ id: 2, nome: 'Sistema de Seleção Unificada', sigla: 'SiSU', observacao: 'Todas as vagas', institucional: false }],
        FINANCIAMENTO: [{ id: 3, nome: 'Fundo de Financiamento Estudantil', sigla: 'FIES', observacao: null, institucional: false }],
        BOLSA: [{ id: 9, nome: 'Bolsa Mérito', sigla: null, observacao: null, institucional: true }],
      },
    });
    expect(segunda).toMatchObject({
      modalidade: 'EAD',
      universidade: { natureza: 'V', cidade: null, estado: null },
      campus: [],
      programas: { ENTRADA: [], FINANCIAMENTO: [], BOLSA: [] },
    });
  });

  it('busca só cursos ativos de universidades aprovadas, campi e programas ativos, e ordena pelas universidades', async () => {
    mockNomes([[5, 'Administração']]);
    prisma.curso.findMany.mockResolvedValueOnce([cursoFake()]);

    await request(app).get('/api/v1/cursos/nome/Administração');

    const [nomes, ofertas] = prisma.curso.findMany.mock.calls.map((c) => c[0]);
    expect(nomes.where).toEqual({ ativo: true, universidade: { status: 'A' } });
    expect(ofertas.where).toEqual({ id: { in: [5] } });
    expect(ofertas.include.campusCursos.where).toEqual({ campus: { ativo: true } });
    expect(ofertas.include.universidade.select.campus.where).toEqual({ ativo: true });
    expect(ofertas.include.universidade.select.programas.where).toEqual({ ativo: true });
    expect(ofertas.orderBy).toEqual([{ universidade: { nomeFantasia: 'asc' } }, { id: 'asc' }]);
  });

  it('junta os cursos de nome igual sem diferenciar maiúsculas, acentos e espaços repetidos', async () => {
    mockNomes([
      [5, 'Análise e Desenvolvimento de Sistemas', 'Tecnologia'],
      [6, 'ANALISE E DESENVOLVIMENTO  DE SISTEMAS', 'Computação'],
      [7, 'Análise e Desenvolvimento de Sistemas', 'Tecnologia'],
      [8, 'Análise de Sistemas', 'Tecnologia'],
    ]);
    prisma.curso.findMany.mockResolvedValueOnce([cursoFake()]);

    const resposta = await request(app).get('/api/v1/cursos/nome/analise%20e%20desenvolvimento%20de%20sistemas');

    expect(prisma.curso.findMany.mock.calls[1][0].where).toEqual({ id: { in: [5, 6, 7] } });
    expect(resposta.body.data.nome).toBe('Análise e Desenvolvimento de Sistemas');
    expect(resposta.body.data.areaCurso).toBe('Tecnologia');
  });

  it('retorna as universidades que oferecem o curso (200)', async () => {
    mockNomes([[5, 'Administração']]);
    prisma.curso.findMany.mockResolvedValueOnce([cursoFake()]);

    const resposta = await request(app).get('/api/v1/cursos/nome/Administração');

    expect(resposta.status).toBe(200);
    expect(resposta.body.data.universidades[0].universidade.nomeFantasia).toBe('Fatec Sorocaba');
    expect(resposta.body.data.areaCurso).toBe('Negócios');
    expect(prisma.visitaPagina.create).toHaveBeenCalledWith({
      data: expect.objectContaining({ entidade: 'curso', entidadeId: null, rota: '/api/v1/cursos/nome/:nome' }),
    });
  });

  it('curso inexistente não conta visita', async () => {
    prisma.curso.findFirst.mockResolvedValue(null);

    await request(app).get('/api/v1/cursos/999');

    expect(prisma.visitaPagina.create).not.toHaveBeenCalled();
  });

  it('responde 404 quando nenhum curso tem esse nome', async () => {
    prisma.curso.findMany.mockResolvedValue([]);

    const resposta = await request(app).get('/api/v1/cursos/nome/Inexistente');

    expect(resposta.status).toBe(404);
  });
});

describe('GET /api/v1/cursos/areas', () => {
  it('lista as áreas distintas, em ordem alfabética (200)', async () => {
    prisma.curso.findMany.mockResolvedValue([{ areaCurso: 'Saúde' }, { areaCurso: 'Engenharia' }, { areaCurso: 'Negócios' }]);

    const resposta = await request(app).get('/api/v1/cursos/areas');

    expect(resposta.status).toBe(200);
    expect(resposta.body.data).toEqual(['Engenharia', 'Negócios', 'Saúde']);
    expect(prisma.curso.findMany.mock.calls[0][0]).toMatchObject({ distinct: ['areaCurso'], where: { ativo: true, universidade: { status: 'A' } } });
  });
});
