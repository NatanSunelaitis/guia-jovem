const request = require('supertest');

jest.mock('../src/config/database', () => require('./helpers/mockPrisma'));

const app = require('../src/app');
const { origensPermitidas } = require('../src/config/cors');

describe('cabeçalhos de segurança e CORS (RNF07)', () => {
  it('não expõe o x-powered-by e envia os cabeçalhos do helmet', async () => {
    const resposta = await request(app).get('/api/v1/health');

    expect(resposta.headers['x-powered-by']).toBeUndefined();
    expect(resposta.headers['x-content-type-options']).toBe('nosniff');
  });

  it('libera a origem local do app fora de produção', async () => {
    const resposta = await request(app).get('/api/v1/health').set('Origin', 'http://localhost:8080');

    expect(resposta.headers['access-control-allow-origin']).toBe('http://localhost:8080');
  });

  it('o relatório chega ao app em outra origem, com o nome do arquivo exposto (RF02)', async () => {
    require('../src/config/database').universidade.findMany.mockResolvedValue([]);
    const resposta = await request(app).get('/api/v1/relatorios/pesquisa?formato=csv').set('Origin', 'http://localhost:8080');

    expect(resposta.headers['access-control-allow-origin']).toBe('http://localhost:8080');
    expect(resposta.headers['access-control-expose-headers']).toBe('Content-Disposition');
    expect(resposta.headers['content-disposition']).toContain('relatorio-pesquisa.csv');
    expect(resposta.headers['cross-origin-resource-policy']).toBe('cross-origin');
  });

  it('não libera uma origem fora da lista', async () => {
    const resposta = await request(app).get('/api/v1/health').set('Origin', 'https://site-qualquer.example');

    expect(resposta.status).toBe(200);
    expect(resposta.headers['access-control-allow-origin']).toBeUndefined();
  });
});

describe('origensPermitidas', () => {
  it('usa a lista de CORS_ORIGENS quando definida', () => {
    expect(origensPermitidas({ CORS_ORIGENS: 'https://guiajovem.com.br/, https://app.netlify.app', NODE_ENV: 'production' })).toEqual([
      'https://guiajovem.com.br',
      'https://app.netlify.app',
    ]);
  });

  it('sem a variável, usa o APP_URL e as origens locais fora de produção', () => {
    expect(origensPermitidas({ APP_URL: 'http://localhost:8081/', NODE_ENV: 'development' })).toEqual([
      'http://localhost:8081',
      'http://localhost:8080',
      'http://127.0.0.1:8080',
    ]);
  });

  it('em produção, sem a variável, só o APP_URL', () => {
    expect(origensPermitidas({ APP_URL: 'https://guiajovem.com.br', NODE_ENV: 'production' })).toEqual(['https://guiajovem.com.br']);
  });
});
