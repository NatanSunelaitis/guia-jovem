const jwt = require('jsonwebtoken');
const request = require('supertest');

jest.mock('../../config/database', () => require('../../../tests/helpers/mockPrisma'));

const prisma = require('../../config/database');
const app = require('../../app');

function tokenPara({ id, tipoUsuario, universidadeId = null }) {
  return jwt.sign({ sub: id, tipoUsuario, universidadeId }, process.env.JWT_ACCESS_SECRET, { expiresIn: '15m' });
}

const TOKEN_ADMIN = tokenPara({ id: 99, tipoUsuario: 'D' });
const TOKEN_ALUNO = tokenPara({ id: 1, tipoUsuario: 'A' });
const TOKEN_UNIVERSIDADE = tokenPara({ id: 5, tipoUsuario: 'U', universidadeId: 7 });

function programaFake(sobrescreve = {}) {
  return {
    id: 3,
    nome: 'Fundo de Financiamento Estudantil',
    sigla: 'FIES',
    tipo: 'FINANCIAMENTO',
    descricao: 'Financia a graduação.',
    requisitos: 'Ter feito o ENEM.',
    comoFunciona: 'Paga depois de formado.',
    linkOficial: 'https://fies.mec.gov.br',
    imagemUrl: null,
    usuarioId: 99,
    universidadeId: null,
    ativo: true,
    criadoEm: new Date('2026-01-01T00:00:00Z'),
    eventos: [],
    _count: { universidades: 0 },
    ...sobrescreve,
  };
}

function eventoFake(sobrescreve = {}) {
  return {
    id: 40,
    programaId: 3,
    titulo: 'Inscrições',
    descricao: null,
    dataInicio: new Date('2026-02-01T00:00:00Z'),
    dataFim: new Date('2026-02-10T00:00:00Z'),
    programa: { ativo: true, universidadeId: null },
    ...sobrescreve,
  };
}

const NOVO = {
  nome: 'Fundo de Financiamento Estudantil',
  sigla: 'FIES',
  tipo: 'FINANCIAMENTO',
  descricao: 'Financia a graduação.',
  requisitos: 'Ter feito o ENEM.',
  comoFunciona: 'Paga depois de formado.',
  linkOficial: 'https://fies.mec.gov.br',
  imagemUrl: '',
};

const comAdmin = (req) => req.set('Authorization', `Bearer ${TOKEN_ADMIN}`);

beforeEach(() => {
  prisma.resetMockPrisma();
});

describe('GET /api/v1/programas/administracao', () => {
  it('lista só os programas globais ativos, com filtro por tipo e busca (200)', async () => {
    prisma.programa.findMany.mockResolvedValue([programaFake({ _count: { universidades: 4 } })]);
    prisma.programa.count.mockResolvedValue(1);

    const resposta = await comAdmin(request(app).get('/api/v1/programas/administracao?tipo=BOLSA&busca=FI'));

    expect(resposta.status).toBe(200);
    expect(resposta.body.data[0]).toMatchObject({ id: 3, sigla: 'FIES', totalUniversidades: 4, eventos: [] });
    expect(prisma.programa.findMany.mock.calls[0][0].where).toEqual({
      ativo: true,
      universidadeId: null,
      tipo: 'BOLSA',
      OR: [{ nome: { contains: 'FI' } }, { sigla: { contains: 'FI' } }],
    });
  });

  it('detalhe do administrador traz as datas importantes em AAAA-MM-DD', async () => {
    prisma.programa.findFirst.mockResolvedValue(programaFake({ eventos: [eventoFake()] }));

    const resposta = await comAdmin(request(app).get('/api/v1/programas/administracao/3'));

    expect(resposta.status).toBe(200);
    expect(resposta.body.data.eventos).toEqual([
      { id: 40, titulo: 'Inscrições', descricao: null, dataInicio: '2026-02-01', dataFim: '2026-02-10' },
    ]);
  });

  it('responde 401 sem login e 403 para aluno e universidade', async () => {
    const semLogin = await request(app).get('/api/v1/programas/administracao');
    const aluno = await request(app).get('/api/v1/programas/administracao').set('Authorization', `Bearer ${TOKEN_ALUNO}`);
    const universidade = await request(app)
      .get('/api/v1/programas/administracao')
      .set('Authorization', `Bearer ${TOKEN_UNIVERSIDADE}`);

    expect(semLogin.status).toBe(401);
    expect(aluno.status).toBe(403);
    expect(universidade.status).toBe(403);
  });
});

describe('POST /api/v1/programas', () => {
  it('cria programa global com todos os campos da página do programa (201)', async () => {
    prisma.programa.create.mockResolvedValue(programaFake());

    const resposta = await comAdmin(request(app).post('/api/v1/programas')).send(NOVO);

    expect(resposta.status).toBe(201);
    expect(prisma.programa.create).toHaveBeenCalledWith(
      expect.objectContaining({
        data: { ...NOVO, imagemUrl: null, usuarioId: 99, universidadeId: null },
      }),
    );
    expect(prisma.logAuditoria.create).toHaveBeenCalledWith({
      data: expect.objectContaining({ usuarioId: 99, acao: 'CREATE', entidade: 'programa', entidadeId: 3 }),
    });
  });

  it.each([
    ['sem nome', { ...NOVO, nome: '' }, 'nome'],
    ['sem descrição', { ...NOVO, descricao: undefined }, 'descricao'],
    ['tipo inválido', { ...NOVO, tipo: 'OUTRO' }, 'tipo'],
    ['link sem http', { ...NOVO, linkOficial: 'fies.mec.gov.br' }, 'linkOficial'],
  ])('responde 400 %s', async (_, body, campo) => {
    const resposta = await comAdmin(request(app).post('/api/v1/programas')).send(body);

    expect(resposta.status).toBe(400);
    expect(resposta.body.error.details.map((d) => d.campo)).toContain(campo);
    expect(prisma.programa.create).not.toHaveBeenCalled();
  });

  it('responde 403 para universidade (bolsa institucional fica para o painel dela)', async () => {
    const resposta = await request(app)
      .post('/api/v1/programas')
      .set('Authorization', `Bearer ${TOKEN_UNIVERSIDADE}`)
      .send(NOVO);

    expect(resposta.status).toBe(403);
  });
});

describe('PATCH e DELETE /api/v1/programas/:id', () => {
  it('atualiza o programa global e grava antes e depois (200)', async () => {
    prisma.programa.findFirst.mockResolvedValue(programaFake());
    prisma.programa.update.mockResolvedValue(programaFake({ requisitos: null }));

    const resposta = await comAdmin(request(app).patch('/api/v1/programas/3')).send({ requisitos: '' });

    expect(resposta.status).toBe(200);
    expect(prisma.programa.update).toHaveBeenCalledWith(expect.objectContaining({ data: { requisitos: null } }));
    expect(prisma.logAuditoria.create).toHaveBeenCalledWith({
      data: expect.objectContaining({
        dadosAntes: expect.objectContaining({ requisitos: 'Ter feito o ENEM.' }),
        dadosDepois: expect.objectContaining({ requisitos: null }),
      }),
    });
  });

  it('bolsa institucional ou programa excluído não é deste cadastro (404)', async () => {
    prisma.programa.findFirst.mockResolvedValue(null);

    const resposta = await comAdmin(request(app).patch('/api/v1/programas/3')).send({ nome: 'X' });

    expect(resposta.status).toBe(404);
    expect(prisma.programa.findFirst).toHaveBeenCalledWith(
      expect.objectContaining({ where: { id: 3, ativo: true, universidadeId: null } }),
    );
  });

  it('exclui (ativo=false) programa que nenhuma universidade aceita (200)', async () => {
    prisma.programa.findFirst.mockResolvedValue(programaFake());
    prisma.universidadePrograma.count.mockResolvedValue(0);

    const resposta = await comAdmin(request(app).delete('/api/v1/programas/3'));

    expect(resposta.status).toBe(200);
    expect(prisma.programa.update).toHaveBeenCalledWith({ where: { id: 3 }, data: { ativo: false } });
    expect(prisma.logAuditoria.create).toHaveBeenCalledWith({
      data: expect.objectContaining({ acao: 'DELETE', entidade: 'programa' }),
    });
  });

  it('programa aceito por universidades não é excluído (409)', async () => {
    prisma.programa.findFirst.mockResolvedValue(programaFake());
    prisma.universidadePrograma.count.mockResolvedValue(5);

    const resposta = await comAdmin(request(app).delete('/api/v1/programas/3'));

    expect(resposta.status).toBe(409);
    expect(resposta.body.error.code).toBe('PROGRAMA_ACEITO');
    expect(resposta.body.error.message).toContain('aceito por 5 universidades');
    expect(prisma.programa.update).not.toHaveBeenCalled();
  });
});

describe('Datas importantes (eventos do programa)', () => {
  it('cria o evento no programa e grava auditoria (201)', async () => {
    prisma.programa.findFirst.mockResolvedValue(programaFake());
    prisma.programaEvento.create.mockResolvedValue(eventoFake());

    const resposta = await comAdmin(request(app).post('/api/v1/programas/3/eventos')).send({
      titulo: 'Inscrições',
      dataInicio: '2026-02-01',
      dataFim: '2026-02-10',
    });

    expect(resposta.status).toBe(201);
    expect(resposta.body.data).toMatchObject({ id: 40, dataInicio: '2026-02-01', dataFim: '2026-02-10' });
    expect(prisma.programaEvento.create).toHaveBeenCalledWith({
      data: {
        programaId: 3,
        titulo: 'Inscrições',
        descricao: null,
        dataInicio: new Date('2026-02-01T00:00:00.000Z'),
        dataFim: new Date('2026-02-10T00:00:00.000Z'),
      },
    });
    expect(prisma.logAuditoria.create).toHaveBeenCalledWith({
      data: expect.objectContaining({ acao: 'CREATE', entidade: 'programa_evento', entidadeId: 40 }),
    });
  });

  it.each([
    ['fim antes do início', { titulo: 'X', dataInicio: '2026-02-10', dataFim: '2026-02-01' }, 'dataFim'],
    ['sem data de início', { titulo: 'X' }, 'dataInicio'],
    ['data inválida', { titulo: 'X', dataInicio: '2026-02-30x' }, 'dataInicio'],
    ['sem título', { dataInicio: '2026-02-01' }, 'titulo'],
  ])('responde 400 com %s', async (_, body, campo) => {
    prisma.programa.findFirst.mockResolvedValue(programaFake());

    const resposta = await comAdmin(request(app).post('/api/v1/programas/3/eventos')).send(body);

    expect(resposta.status).toBe(400);
    expect(resposta.body.error.details.map((d) => d.campo)).toContain(campo);
    expect(prisma.programaEvento.create).not.toHaveBeenCalled();
  });

  it('edita o evento conferindo o fim contra o início já gravado (400 e 200)', async () => {
    prisma.programaEvento.findUnique.mockResolvedValue(eventoFake());
    prisma.programaEvento.update.mockResolvedValue(eventoFake({ titulo: 'Resultado' }));

    const invalido = await comAdmin(request(app).patch('/api/v1/programas/eventos/40')).send({ dataFim: '2026-01-15' });
    const valido = await comAdmin(request(app).patch('/api/v1/programas/eventos/40')).send({ titulo: 'Resultado' });

    expect(invalido.status).toBe(400);
    expect(valido.status).toBe(200);
    expect(valido.body.data.titulo).toBe('Resultado');
    expect(prisma.programaEvento.update).toHaveBeenCalledTimes(1);
  });

  it('exclui o evento e grava auditoria (200); evento de bolsa institucional responde 404', async () => {
    prisma.programaEvento.findUnique.mockResolvedValueOnce(eventoFake());
    const excluir = await comAdmin(request(app).delete('/api/v1/programas/eventos/40'));

    prisma.programaEvento.findUnique.mockResolvedValueOnce(eventoFake({ programa: { ativo: true, universidadeId: 7 } }));
    const institucional = await comAdmin(request(app).delete('/api/v1/programas/eventos/41'));

    expect(excluir.status).toBe(200);
    expect(prisma.programaEvento.delete).toHaveBeenCalledWith({ where: { id: 40 } });
    expect(prisma.logAuditoria.create).toHaveBeenCalledWith({
      data: expect.objectContaining({ acao: 'DELETE', entidade: 'programa_evento', entidadeId: 40 }),
    });
    expect(institucional.status).toBe(404);
  });

  it('responde 403 para aluno', async () => {
    const resposta = await request(app)
      .post('/api/v1/programas/3/eventos')
      .set('Authorization', `Bearer ${TOKEN_ALUNO}`)
      .send({ titulo: 'X', dataInicio: '2026-02-01' });

    expect(resposta.status).toBe(403);
  });
});
