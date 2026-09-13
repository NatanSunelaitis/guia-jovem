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
});

describe('GET /api/v1/cursos/:id', () => {
  it('retorna o detalhe com os campus onde é ofertado (200)', async () => {
    prisma.curso.findFirst.mockResolvedValue(cursoFake());

    const resposta = await request(app).get('/api/v1/cursos/5');

    expect(resposta.status).toBe(200);
    expect(resposta.body.data.campus[0]).toMatchObject({ id: 10, cidade: 'Sorocaba', turno: 'Integral' });
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
  });

  it('responde 404 quando nenhum curso tem esse nome', async () => {
    prisma.curso.findMany.mockResolvedValue([]);

    const resposta = await request(app).get('/api/v1/cursos/nome/Inexistente');

    expect(resposta.status).toBe(404);
  });
});
