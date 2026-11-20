const request = require('supertest');

jest.mock('../../config/database', () => require('../../../tests/helpers/mockPrisma'));

const prisma = require('../../config/database');
const app = require('../../app');

function universidadeFake(sobrescreve = {}) {
  return {
    id: 1,
    nomeFantasia: 'Fatec Sorocaba',
    natureza: 'P',
    mediaAvaliacao: '4.67',
    totalAvaliacoes: 3,
    campus: [
      { nome: 'Fatec Sorocaba', principal: true, endereco: { cidade: 'Sorocaba', estado: 'SP' } },
      { nome: 'Fatec Itu', principal: false, endereco: { cidade: 'Itu', estado: 'SP' } },
    ],
    cursos: [{ nome: 'Administração' }, { nome: 'Pedagogia' }],
    universidadeProgramas: [{ programa: { sigla: 'ENEM', nome: 'Exame Nacional do Ensino Médio' } }],
    ...sobrescreve,
  };
}

beforeEach(() => {
  prisma.resetMockPrisma();
});

describe('GET /api/v1/relatorios/pesquisa', () => {
  it('responde 400 sem o parâmetro formato', async () => {
    const resposta = await request(app).get('/api/v1/relatorios/pesquisa');

    expect(resposta.status).toBe(400);
    expect(resposta.body.error.code).toBe('VALIDATION_ERROR');
  });

  it('gera CSV com universidades, campus, cursos e programas do resultado (RF02)', async () => {
    prisma.universidade.findMany.mockResolvedValue([universidadeFake()]);

    const resposta = await request(app).get('/api/v1/relatorios/pesquisa?formato=csv&cidade=Sorocaba');

    expect(resposta.status).toBe(200);
    expect(resposta.headers['content-type']).toContain('text/csv');
    expect(resposta.headers['content-disposition']).toContain('relatorio-pesquisa.csv');
    expect(resposta.text).toContain('Fatec Sorocaba');
    expect(resposta.text).toContain('Administração');
    expect(resposta.text).toContain('ENEM');
    // Excel em português: BOM, ponto e vírgula e cabeçalho acentuado.
    expect(resposta.text.replace(/^\uFEFF/, '')).toMatch(
      /^Universidade;Natureza;Cidade;Estado;Média de avaliação;Total de avaliações;Campus;Cursos;Programas\r\n/,
    );

    const chamada = prisma.universidade.findMany.mock.calls[0][0];
    expect(chamada.where.campus.some.endereco.cidade).toEqual({ contains: 'Sorocaba' });
  });

  it('gera PDF quando formato=pdf', async () => {
    prisma.universidade.findMany.mockResolvedValue([universidadeFake()]);

    const resposta = await request(app).get('/api/v1/relatorios/pesquisa?formato=pdf').buffer(true).parse((res, callback) => {
      const chunks = [];
      res.on('data', (chunk) => chunks.push(chunk));
      res.on('end', () => callback(null, Buffer.concat(chunks)));
    });

    expect(resposta.status).toBe(200);
    expect(resposta.headers['content-type']).toBe('application/pdf');
    expect(resposta.body.slice(0, 4).toString()).toBe('%PDF');
  });

  it('responde 400 com formato inválido', async () => {
    const resposta = await request(app).get('/api/v1/relatorios/pesquisa?formato=xls');

    expect(resposta.status).toBe(400);
  });
});
