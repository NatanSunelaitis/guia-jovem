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
    campusCursos: [
      { curso: { id: 5, nome: 'Administração', areaCurso: 'Negócios', grau: 'Bacharelado' }, turno: 'Integral', vagas: 40 },
    ],
  };
}

beforeEach(() => {
  prisma.resetMockPrisma();
});

describe('GET /api/v1/campus/:id', () => {
  it('retorna o detalhe do campus com os cursos (200)', async () => {
    prisma.campus.findFirst.mockResolvedValue(campusFake());

    const resposta = await request(app).get('/api/v1/campus/10');

    expect(resposta.status).toBe(200);
    expect(resposta.body.data.nome).toBe('Fatec Sorocaba');
    expect(resposta.body.data.cursos[0]).toMatchObject({ id: 5, nome: 'Administração', turno: 'Integral' });
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
