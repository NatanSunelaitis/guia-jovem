const request = require('supertest');

const app = require('../src/app');

describe('GET /api/v1/health', () => {
  it('responde 200 com status ok no envelope padrão', async () => {
    const resposta = await request(app).get('/api/v1/health');

    expect(resposta.status).toBe(200);
    expect(resposta.body).toEqual({ data: { status: 'ok' }, meta: {} });
  });
});

describe('rota inexistente', () => {
  it('responde 404 com o envelope de erro padrão', async () => {
    const resposta = await request(app).get('/api/v1/rota-que-nao-existe');

    expect(resposta.status).toBe(404);
    expect(resposta.body.error.code).toBe('NOT_FOUND');
  });
});
