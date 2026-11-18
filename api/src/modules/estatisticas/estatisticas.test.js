const jwt = require('jsonwebtoken');
const request = require('supertest');

jest.mock('../../config/database', () => require('../../../tests/helpers/mockPrisma'));

const prisma = require('../../config/database');
const app = require('../../app');
const service = require('./estatisticas.service');

function tokenPara({ id, tipoUsuario }) {
  return jwt.sign({ sub: id, tipoUsuario, universidadeId: null }, process.env.JWT_ACCESS_SECRET, { expiresIn: '15m' });
}

const TOKEN_ADMIN = tokenPara({ id: 99, tipoUsuario: 'D' });
const TOKEN_ALUNO = tokenPara({ id: 1, tipoUsuario: 'A' });

const get = (rota, token = TOKEN_ADMIN) => request(app).get(`/api/v1/estatisticas${rota}`).set('Authorization', `Bearer ${token}`);

beforeEach(() => {
  prisma.resetMockPrisma();
  prisma.$queryRaw.mockResolvedValue([]);
  prisma.visitaPagina.groupBy.mockResolvedValue([]);
});

describe('Acesso às estatísticas', () => {
  it.each([['/resumo'], ['/visitas'], ['/ranking']])('%s: 401 sem login e 403 para quem não é administrador', async (rota) => {
    const semLogin = await request(app).get(`/api/v1/estatisticas${rota}`);
    const aluno = await get(rota, TOKEN_ALUNO);

    expect(semLogin.status).toBe(401);
    expect(aluno.status).toBe(403);
  });

  it.each([
    ['/visitas?de=2026-13-01'],
    ['/visitas?de=17/11/2026'],
    ['/visitas?de=2026-11-20&ate=2026-11-10'],
    ['/visitas?agrupar=semana'],
    ['/ranking?limite=50'],
  ])('%s responde 400', async (rota) => {
    const resposta = await get(rota);

    expect(resposta.status).toBe(400);
    expect(resposta.body.error.code).toBe('VALIDATION_ERROR');
  });
});

describe('GET /api/v1/estatisticas/resumo', () => {
  it('soma os totais por perfil, status e tipo, com zero no que não aparece', async () => {
    prisma.usuario.groupBy.mockResolvedValue([
      { tipoUsuario: 'A', _count: { _all: 10 } },
      { tipoUsuario: 'D', _count: { _all: 2 } },
    ]);
    prisma.universidade.groupBy.mockResolvedValue([
      { status: 'A', _count: { _all: 4 } },
      { status: 'P', _count: { _all: 1 } },
    ]);
    prisma.curso.count.mockResolvedValue(25);
    prisma.programa.groupBy.mockResolvedValue([{ tipo: 'ENTRADA', _count: { _all: 3 } }]);

    const resposta = await get('/resumo');

    expect(resposta.status).toBe(200);
    expect(resposta.body.data).toEqual({
      usuariosPorPerfil: { A: 10, U: 0, D: 2, total: 12 },
      universidadesPorStatus: { P: 1, A: 4, R: 0, I: 0, total: 5 },
      cursos: 25,
      programasPorTipo: { ENTRADA: 3, FINANCIAMENTO: 0, BOLSA: 0, total: 3 },
    });
    expect(prisma.curso.count).toHaveBeenCalledWith({ where: { ativo: true } });
  });
});

describe('GET /api/v1/estatisticas/visitas', () => {
  it('preenche os dias sem dados com zero e converte as contagens', async () => {
    prisma.$queryRaw
      .mockResolvedValueOnce([
        { periodo: '2026-11-01', total: 5n },
        { periodo: '2026-11-03', total: 2n },
      ])
      .mockResolvedValueOnce([{ periodo: '2026-11-03', total: 1n }])
      .mockResolvedValueOnce([{ total: 3n }]);
    prisma.visitaPagina.groupBy.mockResolvedValue([
      { tipoUsuario: null, _count: { _all: 6 } },
      { tipoUsuario: 'A', _count: { _all: 1 } },
    ]);

    const resposta = await get('/visitas?de=2026-11-01&ate=2026-11-03');

    expect(resposta.status).toBe(200);
    expect(resposta.body.data).toEqual({
      de: '2026-11-01',
      ate: '2026-11-03',
      agrupar: 'dia',
      totalVisitas: 7,
      loginsUnicos: 3,
      visitasPorPerfil: { visitante: 6, A: 1, U: 0, D: 0 },
      serie: [
        { periodo: '2026-11-01', visitas: 5, loginsUnicos: 0 },
        { periodo: '2026-11-02', visitas: 0, loginsUnicos: 0 },
        { periodo: '2026-11-03', visitas: 2, loginsUnicos: 1 },
      ],
    });
    // Datas de Brasília: o dia começa às 03:00 UTC e o fim é exclusivo.
    expect(prisma.visitaPagina.groupBy).toHaveBeenCalledWith(
      expect.objectContaining({
        where: {
          criadoEm: { gte: new Date('2026-11-01T03:00:00.000Z'), lt: new Date('2026-11-04T03:00:00.000Z') },
        },
      }),
    );
  });

  it('agrupa por mês atravessando a virada do ano', async () => {
    const resposta = await get('/visitas?de=2026-11-15&ate=2027-02-10&agrupar=mes');

    expect(resposta.body.data.serie.map((ponto) => ponto.periodo)).toEqual(['2026-11', '2026-12', '2027-01', '2027-02']);
  });
});

describe('Período padrão', () => {
  it('sem filtro: os últimos 30 dias até hoje em Brasília', () => {
    // 02:00 UTC de 18/11 ainda é 17/11 em Brasília.
    const periodo = service.resolverPeriodo({}, new Date('2026-11-18T02:00:00.000Z'));

    expect(periodo).toMatchObject({ de: '2026-10-19', ate: '2026-11-17' });
    expect(service.chavesDoPeriodo(periodo.de, periodo.ate, 'dia')).toHaveLength(30);
  });
});

describe('GET /api/v1/estatisticas/ranking', () => {
  it('traz os mais acessados com o nome, e marca registro já removido', async () => {
    prisma.visitaPagina.groupBy
      .mockResolvedValueOnce([
        { entidadeId: 7, _count: { entidadeId: 12 } },
        { entidadeId: 8, _count: { entidadeId: 3 } },
      ])
      .mockResolvedValueOnce([{ entidadeId: 1, _count: { entidadeId: 9 } }])
      .mockResolvedValueOnce([]);
    prisma.universidade.findMany.mockResolvedValue([{ id: 7, nomeFantasia: 'Fatec Itu' }]);
    prisma.programa.findMany.mockResolvedValue([{ id: 1, nome: 'Exame Nacional do Ensino Médio', sigla: 'ENEM' }]);

    const resposta = await get('/ranking?de=2026-11-01&ate=2026-11-30&limite=2');

    expect(resposta.status).toBe(200);
    expect(resposta.body.data).toEqual({
      de: '2026-11-01',
      ate: '2026-11-30',
      universidades: [
        { id: 7, nome: 'Fatec Itu', visitas: 12 },
        { id: 8, nome: 'Registro removido', visitas: 3 },
      ],
      programas: [{ id: 1, nome: 'ENEM', visitas: 9 }],
      cursos: [],
    });
    expect(prisma.visitaPagina.groupBy).toHaveBeenCalledWith(
      expect.objectContaining({ where: expect.objectContaining({ entidade: 'universidade' }), take: 2 }),
    );
  });
});
