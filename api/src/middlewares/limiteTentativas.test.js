const express = require('express');
const request = require('supertest');

const { limitadorDeLogin, limitadorDeRecuperacao, MULTIPLICADOR_POR_REDE } = require('./limiteTentativas.middleware');

// Login de mentira: "certa" entra (200); qualquer outra senha falha (401);
// sem senha é erro de validação (400).
function appDeLogin(limite) {
  const app = express();
  app.use(express.json());
  app.post('/login', ...limitadorDeLogin({ limite }), (req, res) => {
    if (!req.body.senha) return res.status(400).json({ error: { code: 'VALIDATION_ERROR' } });
    if (req.body.senha === 'certa') return res.json({ data: { ok: true } });
    return res.status(401).json({ error: { code: 'CREDENCIAIS_INVALIDAS' } });
  });
  return app;
}

const tentar = (app, email, senha) => request(app).post('/login').send({ email, senha });

describe('limite de tentativas de login', () => {
  it('login certo repetido não bloqueia', async () => {
    const app = appDeLogin(3);
    for (let i = 0; i < 10; i += 1) {
      expect((await tentar(app, 'ana@exemplo.com', 'certa')).status).toBe(200);
    }
  });

  it('falhas repetidas bloqueiam, inclusive a senha certa, e a mensagem traz o tempo de espera', async () => {
    const app = appDeLogin(3);
    for (let i = 0; i < 3; i += 1) {
      expect((await tentar(app, 'ana@exemplo.com', 'errada')).status).toBe(401);
    }

    const bloqueio = await tentar(app, 'ana@exemplo.com', 'certa');

    expect(bloqueio.status).toBe(429);
    expect(bloqueio.body.error.code).toBe('RATE_LIMITED');
    expect(bloqueio.body.error.message).toBe(
      'Muitas tentativas de login sem sucesso nesta conta. Tente novamente em 15 minutos.',
    );
    expect(bloqueio.headers['retry-after']).toBeDefined();
  });

  it('o tempo de espera diminui com a janela e usa o singular', async () => {
    jest.useFakeTimers({ now: new Date('2026-11-23T12:00:00Z'), doNotFake: ['nextTick', 'setImmediate'] });
    try {
      const app = appDeLogin(1);
      await tentar(app, 'ana@exemplo.com', 'errada');

      jest.setSystemTime(new Date('2026-11-23T12:03:10Z'));
      expect((await tentar(app, 'ana@exemplo.com', 'errada')).body.error.message).toMatch(/Tente novamente em 12 minutos\.$/);

      jest.setSystemTime(new Date('2026-11-23T12:14:30Z'));
      expect((await tentar(app, 'ana@exemplo.com', 'errada')).body.error.message).toMatch(/Tente novamente em 1 minuto\.$/);
    } finally {
      jest.useRealTimers();
    }
  });

  it('erros de validação e logins certos no meio não gastam tentativas', async () => {
    const app = appDeLogin(3);
    await tentar(app, 'ana@exemplo.com', 'errada');
    await tentar(app, 'ana@exemplo.com', 'errada');
    for (let i = 0; i < 5; i += 1) {
      expect((await tentar(app, 'ana@exemplo.com', '')).status).toBe(400);
      expect((await tentar(app, 'ana@exemplo.com', 'certa')).status).toBe(200);
    }
    expect((await tentar(app, 'ana@exemplo.com', 'errada')).status).toBe(401);
    expect((await tentar(app, 'ana@exemplo.com', 'certa')).status).toBe(429);
  });

  it('conta por IP e e-mail: a conta bloqueada não bloqueia outra pessoa da mesma rede', async () => {
    const app = appDeLogin(3);
    for (let i = 0; i < 3; i += 1) await tentar(app, 'Ana@Exemplo.com ', 'errada');

    expect((await tentar(app, 'ana@exemplo.com', 'certa')).status).toBe(429);
    expect((await tentar(app, 'bruno@exemplo.com', 'certa')).status).toBe(200);
    expect((await tentar(app, 'bruno@exemplo.com', 'errada')).status).toBe(401);
  });

  it('a mesma rede tem um teto de falhas somando as contas', async () => {
    const app = appDeLogin(2);
    const teto = 2 * MULTIPLICADOR_POR_REDE;
    for (let i = 0; i < teto; i += 1) {
      expect((await tentar(app, `pessoa${i}@exemplo.com`, 'errada')).status).toBe(401);
    }

    const bloqueio = await tentar(app, 'outra@exemplo.com', 'certa');

    expect(bloqueio.status).toBe(429);
    expect(bloqueio.body.error.message).toMatch(/^Muitas tentativas de login sem sucesso nesta rede\. Tente novamente em \d+ minutos\.$/);
  });
});

describe('limite de pedidos de recuperação de senha', () => {
  it('cada pedido conta e o bloqueio traz o tempo de espera', async () => {
    const app = express();
    app.use(express.json());
    app.post('/forgot', limitadorDeRecuperacao({ limite: 2 }), (req, res) => res.json({ data: { ok: true } }));

    expect((await request(app).post('/forgot').send({ email: 'a@b.com' })).status).toBe(200);
    expect((await request(app).post('/forgot').send({ email: 'a@b.com' })).status).toBe(200);
    const bloqueio = await request(app).post('/forgot').send({ email: 'a@b.com' });

    expect(bloqueio.status).toBe(429);
    expect(bloqueio.body.error.message).toBe('Muitos pedidos de recuperação de senha. Tente novamente em 15 minutos.');
  });
});
