const request = require('supertest');

jest.mock('../../config/database', () => require('../../../tests/helpers/mockPrisma'));

const prisma = require('../../config/database');
const app = require('../../app');

function campusFake() {
  return {
    id: 10,
    nome: 'Fatec Sorocaba',
    telefoneCelular: null,
    telefoneFixo: '(15) 3232-0000',
    emailCampus: 'contato@fatecsorocaba.edu.br',
    principal: true,
    universidade: { id: 1, nomeFantasia: 'Fatec Sorocaba' },
    endereco: {
      logradouro: 'Av. Eng. Carlos Reinaldo Mendes',
      numero: '2929',
      complemento: null,
      bairro: 'Alto da Boa Vista',
      cidade: 'Sorocaba',
      estado: 'SP',
      cep: '18013380',
    },
    _count: { campusCursos: 40 },
  };
}

beforeEach(() => {
  prisma.resetMockPrisma();
});

describe('GET /api/v1/campus/:id', () => {
  it('retorna o detalhe do campus com o total de cursos e as áreas (200)', async () => {
    prisma.campus.findFirst.mockResolvedValue(campusFake());
    prisma.campusCurso.findMany.mockResolvedValue([
      { curso: { areaCurso: 'Saúde' } },
      { curso: { areaCurso: 'Negócios' } },
      { curso: { areaCurso: 'Saúde' } },
      { curso: { areaCurso: null } },
    ]);

    const resposta = await request(app).get('/api/v1/campus/10');

    expect(resposta.status).toBe(200);
    expect(resposta.body.data.nome).toBe('Fatec Sorocaba');
    expect(resposta.body.data.totalCursos).toBe(40);
    expect(resposta.body.data.areasCursos).toEqual(['Negócios', 'Saúde']);
    expect(resposta.body.data.cursos).toBeUndefined();
    // RF16: o detalhe do campus conta como visita.
    expect(prisma.visitaPagina.create).toHaveBeenCalledWith({
      data: expect.objectContaining({ entidade: 'campus', entidadeId: 10, rota: '/api/v1/campus/:id' }),
    });
  });

  it('responde 404 quando o campus não existe, está inativo ou a universidade não está aprovada', async () => {
    prisma.campus.findFirst.mockResolvedValue(null);

    const resposta = await request(app).get('/api/v1/campus/999');

    expect(resposta.status).toBe(404);
  });

  it('responde 400 com id inválido', async () => {
    const resposta = await request(app).get('/api/v1/campus/abc');

    expect(resposta.status).toBe(400);
  });
});

describe('GET /api/v1/campus/:id/cursos', () => {
  it('pagina os cursos ativos por nome, com área, grau, modalidade, turno e vagas (200)', async () => {
    prisma.campus.findFirst.mockResolvedValue({ id: 10 });
    prisma.campusCurso.findMany.mockResolvedValue([
      { turno: 'Noturno', vagas: 40, curso: { id: 5, nome: 'Administração', areaCurso: 'Negócios', grau: 'Bacharelado', modalidade: 'Presencial' } },
    ]);
    prisma.campusCurso.count.mockResolvedValue(40);

    const resposta = await request(app).get('/api/v1/campus/10/cursos?page=3&pageSize=12');

    expect(resposta.status).toBe(200);
    expect(resposta.body.data[0]).toEqual({
      id: 5,
      nome: 'Administração',
      areaCurso: 'Negócios',
      grau: 'Bacharelado',
      modalidade: 'Presencial',
      turno: 'Noturno',
      vagas: 40,
    });
    expect(resposta.body.meta).toEqual({ page: 3, pageSize: 12, total: 40, totalPages: 4 });
    const chamada = prisma.campusCurso.findMany.mock.calls[0][0];
    expect(chamada).toMatchObject({ skip: 24, take: 12, orderBy: { curso: { nome: 'asc' } } });
    expect(chamada.where).toEqual({ campusId: 10, curso: { ativo: true } });
  });

  it('aplica a busca por nome e o filtro por área', async () => {
    prisma.campus.findFirst.mockResolvedValue({ id: 10 });
    prisma.campusCurso.findMany.mockResolvedValue([]);
    prisma.campusCurso.count.mockResolvedValue(0);

    await request(app).get('/api/v1/campus/10/cursos?q=enferm&areaCurso=Sa%C3%BAde');

    expect(prisma.campusCurso.findMany.mock.calls[0][0].where).toEqual({
      campusId: 10,
      curso: { ativo: true, nome: { contains: 'enferm' }, areaCurso: 'Saúde' },
    });
  });

  it('campus inexistente responde 404', async () => {
    prisma.campus.findFirst.mockResolvedValue(null);

    const resposta = await request(app).get('/api/v1/campus/99/cursos');

    expect(resposta.status).toBe(404);
  });
});
