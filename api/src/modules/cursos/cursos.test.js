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
    universidade: { id: 1, nomeFantasia: 'Fatec Sorocaba', logoUrl: null },
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
      { nome: 'Administração', areaCurso: 'Negócios' },
      { nome: 'Administração', areaCurso: 'Negócios' },
      { nome: 'Farmácia', areaCurso: 'Saúde' },
    ]);

    const resposta = await request(app).get('/api/v1/cursos/destaques');

    expect(resposta.status).toBe(200);
    expect(resposta.body.data[0]).toEqual({ nome: 'Administração', areaCurso: 'Negócios', totalOfertas: 2 });
    expect(resposta.body.data[1]).toEqual({ nome: 'Farmácia', areaCurso: 'Saúde', totalOfertas: 1 });
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
    expect(resposta.body.data.campus[0]).toMatchObject({ id: 10, cidade: 'Sorocaba', turno: 'Integral' });
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
  it('retorna as universidades que oferecem o curso (200)', async () => {
    prisma.curso.findMany.mockResolvedValue([cursoFake()]);

    const resposta = await request(app).get('/api/v1/cursos/nome/Administração');

    expect(resposta.status).toBe(200);
    expect(resposta.body.data.universidades[0].universidade.nomeFantasia).toBe('Fatec Sorocaba');
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
