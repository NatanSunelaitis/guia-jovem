const jwt = require('jsonwebtoken');
const request = require('supertest');

jest.mock('../../config/database', () => require('../../../tests/helpers/mockPrisma'));
jest.mock('../../config/mailer', () => ({ enviarEmail: jest.fn().mockResolvedValue(undefined) }));

const prisma = require('../../config/database');
const { enviarEmail } = require('../../config/mailer');
const app = require('../../app');

function tokenPara({ id, tipoUsuario, universidadeId = null }) {
  return jwt.sign({ sub: id, tipoUsuario, universidadeId }, process.env.JWT_ACCESS_SECRET, { expiresIn: '15m' });
}

const TOKEN_ADMIN = tokenPara({ id: 99, tipoUsuario: 'D' });
const TOKEN_ALUNO = tokenPara({ id: 1, tipoUsuario: 'A' });
const TOKEN_DONA = tokenPara({ id: 5, tipoUsuario: 'U', universidadeId: 7 });
const TOKEN_OUTRA_UNIVERSIDADE = tokenPara({ id: 6, tipoUsuario: 'U', universidadeId: 8 });

function universidadeFake(sobrescreve = {}) {
  return {
    id: 7,
    usuarioId: 5,
    nomeFantasia: 'Fatec Itu',
    razaoSocial: 'Faculdade de Tecnologia de Itu',
    cnpj: '12345678000199',
    natureza: 'P',
    descricao: null,
    telefonePrincipal: '1140000000',
    linkPagina: 'https://fatecitu.edu.br',
    linkSimulados: null,
    logoUrl: null,
    status: 'P',
    motivoReprovacao: null,
    aprovadoEm: null,
    aprovadoPor: null,
    mediaAvaliacao: null,
    totalAvaliacoes: 0,
    criadoEm: new Date('2026-11-10T12:00:00.000Z'),
    usuario: { id: 5, nome: 'Secretaria Fatec Itu', email: 'secretaria@fatecitu.edu.br', ativo: true },
    campus: [
      {
        id: 20,
        nome: 'Campus Itu',
        principal: true,
        telefoneCelular: null,
        telefoneFixo: '1140000000',
        emailCampus: 'campus@fatecitu.edu.br',
        endereco: {
          logradouro: 'Av. Tiradentes',
          numero: '1211',
          complemento: null,
          bairro: 'Centro',
          cidade: 'Itu',
          estado: 'SP',
          cep: '13309640',
        },
      },
    ],
    universidadeProgramas: [{ programa: { id: 1, nome: 'ENEM', sigla: 'ENEM', tipo: 'ENTRADA' } }],
    programas: [],
    ...sobrescreve,
  };
}

/**
 * Banco de uma universidade só: `updateMany` muda o status apenas se o
 * `where.status.in` bater, como no MySQL, e as leituras enxergam a mudança.
 */
function bancoComUniversidade(inicial) {
  const estado = { ...inicial };
  prisma.universidade.findUnique.mockImplementation(async ({ where }) => (where.id === estado.id ? { ...estado } : null));
  prisma.universidade.findFirst.mockImplementation(async ({ where }) =>
    where.id === estado.id && (where.status === undefined || where.status === estado.status) ? { ...estado } : null,
  );
  prisma.universidade.findMany.mockImplementation(async ({ where }) =>
    where.status === undefined || where.status === estado.status ? [{ ...estado }] : [],
  );
  prisma.universidade.count.mockImplementation(async ({ where }) =>
    where.status === undefined || where.status === estado.status ? 1 : 0,
  );
  prisma.universidade.updateMany.mockImplementation(async ({ where, data }) => {
    if (where.id !== estado.id || !where.status.in.includes(estado.status)) return { count: 0 };
    Object.assign(estado, data);
    return { count: 1 };
  });
  return estado;
}

const acoes = (id, acao, token, body) =>
  request(app).post(`/api/v1/universidades/${id}/${acao}`).set('Authorization', `Bearer ${token}`).send(body);

beforeEach(() => {
  prisma.resetMockPrisma();
  enviarEmail.mockReset();
  enviarEmail.mockResolvedValue(undefined);
});

describe('GET /api/v1/universidades/administracao', () => {
  it('lista com o status e a busca pedidos e conta as pendentes (200)', async () => {
    prisma.universidade.findMany.mockResolvedValue([universidadeFake()]);
    prisma.universidade.count.mockResolvedValueOnce(1).mockResolvedValueOnce(3);

    const resposta = await request(app)
      .get('/api/v1/universidades/administracao?status=P&busca=Itu')
      .set('Authorization', `Bearer ${TOKEN_ADMIN}`);

    expect(resposta.status).toBe(200);
    expect(resposta.body.data[0]).toMatchObject({ id: 7, status: 'P', cidade: 'Itu', estado: 'SP', cnpj: '12345678000199' });
    expect(resposta.body.meta).toMatchObject({ total: 1, pendentes: 3 });
    const { where } = prisma.universidade.findMany.mock.calls[0][0];
    expect(where.status).toBe('P');
    expect(where.OR).toEqual([{ nomeFantasia: { contains: 'Itu' } }, { razaoSocial: { contains: 'Itu' } }]);
  });

  it('sem filtro, traz todos os status', async () => {
    prisma.universidade.findMany.mockResolvedValue([]);
    prisma.universidade.count.mockResolvedValue(0);

    await request(app).get('/api/v1/universidades/administracao').set('Authorization', `Bearer ${TOKEN_ADMIN}`);

    expect(prisma.universidade.findMany.mock.calls[0][0].where).toEqual({});
  });

  it('responde 400 para status desconhecido', async () => {
    const resposta = await request(app)
      .get('/api/v1/universidades/administracao?status=X')
      .set('Authorization', `Bearer ${TOKEN_ADMIN}`);

    expect(resposta.status).toBe(400);
  });

  it('responde 401 sem login e 403 para outro perfil', async () => {
    const semLogin = await request(app).get('/api/v1/universidades/administracao');
    const aluno = await request(app)
      .get('/api/v1/universidades/administracao')
      .set('Authorization', `Bearer ${TOKEN_ALUNO}`);
    const universidade = await request(app)
      .get('/api/v1/universidades/administracao')
      .set('Authorization', `Bearer ${TOKEN_DONA}`);

    expect(semLogin.status).toBe(401);
    expect(aluno.status).toBe(403);
    expect(universidade.status).toBe(403);
  });
});

describe('GET /api/v1/universidades/:id/cadastro', () => {
  it('traz os dados da análise para o administrador (200)', async () => {
    prisma.universidade.findUnique.mockResolvedValue(universidadeFake());

    const resposta = await request(app)
      .get('/api/v1/universidades/7/cadastro')
      .set('Authorization', `Bearer ${TOKEN_ADMIN}`);

    expect(resposta.status).toBe(200);
    expect(resposta.body.data).toMatchObject({
      id: 7,
      razaoSocial: 'Faculdade de Tecnologia de Itu',
      status: 'P',
      totalCampus: 1,
      campusPrincipal: { nome: 'Campus Itu', endereco: { cidade: 'Itu', cep: '13309640' } },
      programas: [{ id: 1, sigla: 'ENEM' }],
      responsavel: { nome: 'Secretaria Fatec Itu', email: 'secretaria@fatecitu.edu.br' },
    });
  });

  it('abrir o cadastro marca como lidos os avisos dele (RF14)', async () => {
    prisma.universidade.findUnique.mockResolvedValue(universidadeFake());
    prisma.notificacao.updateMany.mockResolvedValue({ count: 1 });

    const resposta = await request(app)
      .get('/api/v1/universidades/7/cadastro')
      .set('Authorization', `Bearer ${TOKEN_ADMIN}`);

    expect(resposta.status).toBe(200);
    expect(prisma.notificacao.updateMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: expect.objectContaining({ lida: false, referenciaTipo: 'universidade', referenciaId: { in: [7] } }),
      }),
    );
  });

  it('a própria universidade vê a situação e o motivo da reprovação (200)', async () => {
    prisma.universidade.findUnique.mockResolvedValue(
      universidadeFake({ status: 'R', motivoReprovacao: 'CNPJ não confere' }),
    );

    const resposta = await request(app)
      .get('/api/v1/universidades/7/cadastro')
      .set('Authorization', `Bearer ${TOKEN_DONA}`);

    expect(resposta.status).toBe(200);
    expect(resposta.body.data).toMatchObject({ status: 'R', motivoReprovacao: 'CNPJ não confere' });
  });

  it('responde 403 para outra universidade e para aluno', async () => {
    const outra = await request(app)
      .get('/api/v1/universidades/7/cadastro')
      .set('Authorization', `Bearer ${TOKEN_OUTRA_UNIVERSIDADE}`);
    const aluno = await request(app)
      .get('/api/v1/universidades/7/cadastro')
      .set('Authorization', `Bearer ${TOKEN_ALUNO}`);

    expect(outra.status).toBe(403);
    expect(aluno.status).toBe(403);
  });

  it('responde 404 quando não existe', async () => {
    prisma.universidade.findUnique.mockResolvedValue(null);

    const resposta = await request(app)
      .get('/api/v1/universidades/70/cadastro')
      .set('Authorization', `Bearer ${TOKEN_ADMIN}`);

    expect(resposta.status).toBe(404);
  });
});

describe('POST /api/v1/universidades/:id/aprovar', () => {
  it('aprova a pendente: status, data, auditoria, notificação e e-mail (200)', async () => {
    const estado = bancoComUniversidade(universidadeFake());

    const resposta = await acoes(7, 'aprovar', TOKEN_ADMIN);

    expect(resposta.status).toBe(200);
    expect(resposta.body.data.status).toBe('A');
    expect(estado.status).toBe('A');
    expect(estado.aprovadoEm).toBeInstanceOf(Date);
    expect(estado.aprovadoPor).toBe(99);
    expect(prisma.logAuditoria.create).toHaveBeenCalledWith({
      data: expect.objectContaining({
        usuarioId: 99,
        acao: 'UPDATE',
        entidade: 'universidade',
        entidadeId: 7,
        dadosAntes: { status: 'P', motivoReprovacao: null },
        dadosDepois: { acao: 'aprovar', status: 'A', motivoReprovacao: null },
      }),
    });
    expect(prisma.notificacao.createMany).toHaveBeenCalledWith({
      data: [
        expect.objectContaining({
          usuarioId: 5,
          tipo: 'UNIVERSIDADE_APROVADA',
          referenciaTipo: 'universidade',
          referenciaId: 7,
        }),
      ],
    });
    expect(enviarEmail).toHaveBeenCalledWith(
      expect.objectContaining({ para: 'secretaria@fatecitu.edu.br', assunto: 'Seu cadastro foi aprovado - Guia Jovem' }),
    );
  });

  it('depois de aprovada, aparece na pesquisa e no detalhe públicos', async () => {
    bancoComUniversidade(universidadeFake());

    const antes = await request(app).get('/api/v1/universidades/7');
    await acoes(7, 'aprovar', TOKEN_ADMIN);
    const depois = await request(app).get('/api/v1/universidades/7');
    const pesquisa = await request(app).get('/api/v1/universidades');

    expect(antes.status).toBe(404);
    expect(depois.status).toBe(200);
    expect(pesquisa.body.data.map((u) => u.id)).toEqual([7]);
  });

  it('aprova uma reprovada e limpa o motivo', async () => {
    const estado = bancoComUniversidade(universidadeFake({ status: 'R', motivoReprovacao: 'Dados incompletos' }));

    const resposta = await acoes(7, 'aprovar', TOKEN_ADMIN);

    expect(resposta.status).toBe(200);
    expect(estado).toMatchObject({ status: 'A', motivoReprovacao: null });
  });

  it.each([['A'], ['I']])('responde 409 ao aprovar universidade com status %s', async (status) => {
    bancoComUniversidade(universidadeFake({ status, aprovadoEm: new Date() }));

    const resposta = await acoes(7, 'aprovar', TOKEN_ADMIN);

    expect(resposta.status).toBe(409);
    expect(resposta.body.error.code).toBe('STATUS_INVALIDO');
    expect(prisma.notificacao.createMany).not.toHaveBeenCalled();
    expect(enviarEmail).not.toHaveBeenCalled();
  });

  it('responde 409 quando outro administrador decidiu antes (gravação sem efeito)', async () => {
    prisma.universidade.findUnique.mockResolvedValue(universidadeFake());
    prisma.universidade.updateMany.mockResolvedValue({ count: 0 });

    const resposta = await acoes(7, 'aprovar', TOKEN_ADMIN);

    expect(resposta.status).toBe(409);
    expect(prisma.notificacao.createMany).not.toHaveBeenCalled();
  });

  it('falha no e-mail não desfaz a aprovação (200)', async () => {
    const estado = bancoComUniversidade(universidadeFake());
    enviarEmail.mockRejectedValue(new Error('SMTP fora do ar'));
    const erroConsole = jest.spyOn(console, 'error').mockImplementation(() => {});

    const resposta = await acoes(7, 'aprovar', TOKEN_ADMIN);

    expect(resposta.status).toBe(200);
    expect(estado.status).toBe('A');
    expect(prisma.notificacao.createMany).toHaveBeenCalled();
    expect(erroConsole).toHaveBeenCalledWith(expect.stringContaining('aprovar'), 'SMTP fora do ar');
    erroConsole.mockRestore();
  });

  it('universidade sem conta (excluída): aprova sem notificação nem e-mail', async () => {
    bancoComUniversidade(universidadeFake({ usuarioId: null, usuario: null }));

    const resposta = await acoes(7, 'aprovar', TOKEN_ADMIN);

    expect(resposta.status).toBe(200);
    expect(prisma.notificacao.createMany).not.toHaveBeenCalled();
    expect(enviarEmail).not.toHaveBeenCalled();
  });

  it('responde 401 sem login, 403 para universidade e aluno e 404 se não existe', async () => {
    const semLogin = await request(app).post('/api/v1/universidades/7/aprovar');
    const dona = await acoes(7, 'aprovar', TOKEN_DONA);
    const aluno = await acoes(7, 'aprovar', TOKEN_ALUNO);
    prisma.universidade.findUnique.mockResolvedValue(null);
    const inexistente = await acoes(70, 'aprovar', TOKEN_ADMIN);

    expect(semLogin.status).toBe(401);
    expect(dona.status).toBe(403);
    expect(aluno.status).toBe(403);
    expect(inexistente.status).toBe(404);
    expect(prisma.universidade.updateMany).not.toHaveBeenCalled();
  });
});

describe('POST /api/v1/universidades/:id/reprovar', () => {
  it('reprova a pendente com motivo: grava, notifica e manda o motivo por e-mail (200)', async () => {
    const estado = bancoComUniversidade(universidadeFake());

    const resposta = await acoes(7, 'reprovar', TOKEN_ADMIN, { motivo: '  CNPJ não confere com a razão social  ' });

    expect(resposta.status).toBe(200);
    expect(resposta.body.data).toMatchObject({ status: 'R', motivoReprovacao: 'CNPJ não confere com a razão social' });
    expect(estado).toMatchObject({ status: 'R', motivoReprovacao: 'CNPJ não confere com a razão social' });
    expect(prisma.logAuditoria.create).toHaveBeenCalledWith({
      data: expect.objectContaining({
        dadosDepois: { acao: 'reprovar', status: 'R', motivoReprovacao: 'CNPJ não confere com a razão social' },
      }),
    });
    expect(prisma.notificacao.createMany).toHaveBeenCalledWith({
      data: [
        expect.objectContaining({
          usuarioId: 5,
          tipo: 'UNIVERSIDADE_REPROVADA',
          mensagem: 'Motivo: CNPJ não confere com a razão social',
        }),
      ],
    });
    const email = enviarEmail.mock.calls[0][0];
    expect(email.para).toBe('secretaria@fatecitu.edu.br');
    expect(email.html).toContain('CNPJ não confere com a razão social');
  });

  it('escapa HTML do motivo no e-mail e corta a notificação em 255 caracteres', async () => {
    bancoComUniversidade(universidadeFake());
    const motivo = `<b>x</b>${'a'.repeat(480)}`;

    await acoes(7, 'reprovar', TOKEN_ADMIN, { motivo });

    expect(enviarEmail.mock.calls[0][0].html).toContain('&lt;b&gt;x&lt;/b&gt;');
    const [notificacao] = prisma.notificacao.createMany.mock.calls[0][0].data;
    expect(notificacao.mensagem).toHaveLength(255);
    expect(notificacao.mensagem.endsWith('...')).toBe(true);
  });

  it.each([[{}], [{ motivo: '   ' }], [{ motivo: 'a'.repeat(501) }]])(
    'responde 400 sem motivo válido (%j)',
    async (body) => {
      bancoComUniversidade(universidadeFake());

      const resposta = await acoes(7, 'reprovar', TOKEN_ADMIN, body);

      expect(resposta.status).toBe(400);
      expect(resposta.body.error.details[0].campo).toBe('motivo');
      expect(prisma.universidade.updateMany).not.toHaveBeenCalled();
    },
  );

  it.each([['A'], ['R'], ['I']])('responde 409 ao reprovar universidade com status %s', async (status) => {
    bancoComUniversidade(universidadeFake({ status }));

    const resposta = await acoes(7, 'reprovar', TOKEN_ADMIN, { motivo: 'Dados incompletos' });

    expect(resposta.status).toBe(409);
    expect(resposta.body.error.message).toBe('Só é possível reprovar uma universidade pendente');
  });

  it('responde 403 para quem não é administrador', async () => {
    const resposta = await acoes(7, 'reprovar', TOKEN_DONA, { motivo: 'x' });

    expect(resposta.status).toBe(403);
  });
});

describe('POST /api/v1/universidades/:id/inativar e /reativar', () => {
  it('inativa a aprovada: some da pesquisa, do detalhe e dos destaques; notifica e envia e-mail', async () => {
    const estado = bancoComUniversidade(universidadeFake({ status: 'A', aprovadoEm: new Date('2026-11-11') }));

    const antes = await request(app).get('/api/v1/universidades');
    const resposta = await acoes(7, 'inativar', TOKEN_ADMIN);
    const pesquisa = await request(app).get('/api/v1/universidades');
    const detalhe = await request(app).get('/api/v1/universidades/7');
    const destaques = await request(app).get('/api/v1/universidades/destaques');

    expect(antes.body.data).toHaveLength(1);
    expect(resposta.status).toBe(200);
    expect(estado.status).toBe('I');
    expect(pesquisa.body.data).toHaveLength(0);
    expect(detalhe.status).toBe(404);
    expect(destaques.body.data).toHaveLength(0);
    expect(prisma.notificacao.createMany).toHaveBeenCalledWith({
      data: [expect.objectContaining({ usuarioId: 5, tipo: 'UNIVERSIDADE_INATIVADA' })],
    });
    expect(enviarEmail).toHaveBeenCalledWith(
      expect.objectContaining({ assunto: 'Sua universidade foi inativada - Guia Jovem' }),
    );
  });

  it('reativa a inativa: volta para aprovada e para a pesquisa', async () => {
    const estado = bancoComUniversidade(universidadeFake({ status: 'I', aprovadoEm: new Date('2026-11-11') }));

    const resposta = await acoes(7, 'reativar', TOKEN_ADMIN);
    const pesquisa = await request(app).get('/api/v1/universidades');

    expect(resposta.status).toBe(200);
    expect(estado.status).toBe('A');
    expect(estado.aprovadoEm).toEqual(new Date('2026-11-11'));
    expect(pesquisa.body.data).toHaveLength(1);
    expect(prisma.notificacao.createMany).toHaveBeenCalledWith({
      data: [expect.objectContaining({ tipo: 'UNIVERSIDADE_REATIVADA' })],
    });
    expect(enviarEmail).toHaveBeenCalled();
  });

  it.each([['P'], ['R'], ['I']])('responde 409 ao inativar universidade com status %s', async (status) => {
    bancoComUniversidade(universidadeFake({ status }));

    const resposta = await acoes(7, 'inativar', TOKEN_ADMIN);

    expect(resposta.status).toBe(409);
  });

  it.each([['P'], ['R'], ['A']])('responde 409 ao reativar universidade com status %s', async (status) => {
    bancoComUniversidade(universidadeFake({ status }));

    const resposta = await acoes(7, 'reativar', TOKEN_ADMIN);

    expect(resposta.status).toBe(409);
  });

  it('não reativa uma inativa que nunca foi aprovada (409)', async () => {
    bancoComUniversidade(universidadeFake({ status: 'I', aprovadoEm: null }));

    const resposta = await acoes(7, 'reativar', TOKEN_ADMIN);

    expect(resposta.status).toBe(409);
    expect(resposta.body.error.message).toContain('nunca foi aprovada');
  });

  it('responde 401 sem login e 403 para universidade', async () => {
    const semLogin = await request(app).post('/api/v1/universidades/7/inativar');
    const dona = await acoes(7, 'reativar', TOKEN_DONA);

    expect(semLogin.status).toBe(401);
    expect(dona.status).toBe(403);
  });
});

describe('PATCH /api/v1/universidades/:id (edição pelo administrador)', () => {
  const patch = (body, token = TOKEN_ADMIN) =>
    request(app).patch('/api/v1/universidades/7').set('Authorization', `Bearer ${token}`).send(body);

  it('edita os dados institucionais, normaliza o CNPJ e grava antes e depois (200)', async () => {
    const estado = bancoComUniversidade(universidadeFake({ status: 'A' }));
    prisma.universidade.update.mockImplementation(async ({ data }) => {
      Object.assign(estado, data);
      return { ...estado };
    });

    const resposta = await patch({ nomeFantasia: 'Fatec Itu Nova', cnpj: '98.765.432/0001-10', linkSimulados: '' });

    expect(resposta.status).toBe(200);
    expect(resposta.body.data).toMatchObject({ nomeFantasia: 'Fatec Itu Nova', cnpj: '98765432000110', status: 'A' });
    expect(prisma.universidade.update).toHaveBeenCalledWith({
      where: { id: 7 },
      data: { nomeFantasia: 'Fatec Itu Nova', cnpj: '98765432000110', linkSimulados: null },
    });
    expect(prisma.logAuditoria.create).toHaveBeenCalledWith({
      data: expect.objectContaining({
        usuarioId: 99,
        acao: 'UPDATE',
        entidade: 'universidade',
        entidadeId: 7,
        dadosAntes: expect.objectContaining({ nomeFantasia: 'Fatec Itu', cnpj: '12345678000199' }),
        dadosDepois: expect.objectContaining({ nomeFantasia: 'Fatec Itu Nova', cnpj: '98765432000110' }),
      }),
    });
  });

  it('CNPJ de outra universidade responde 409 CNPJ_EM_USO', async () => {
    prisma.universidade.findUnique.mockImplementation(async ({ where }) =>
      where.id === 7 ? universidadeFake() : { id: 8 },
    );

    const resposta = await patch({ cnpj: '11111111000111' });

    expect(resposta.status).toBe(409);
    expect(resposta.body.error.code).toBe('CNPJ_EM_USO');
    expect(prisma.universidade.update).not.toHaveBeenCalled();
  });

  it.each([
    ['status pela rota de edição', { status: 'A' }],
    ['CNPJ curto', { cnpj: '123' }],
    ['link sem http', { linkPagina: 'fatec.br' }],
    ['corpo vazio', {}],
  ])('responde 400 com %s', async (_, body) => {
    const resposta = await patch(body);

    expect(resposta.status).toBe(400);
  });

  it('responde 404, 401 sem login e 403 para a própria universidade (edita na rodada do painel dela)', async () => {
    prisma.universidade.findUnique.mockResolvedValue(null);
    const inexistente = await patch({ nomeFantasia: 'X' });
    const semLogin = await request(app).patch('/api/v1/universidades/7').send({ nomeFantasia: 'X' });
    const dona = await patch({ nomeFantasia: 'X' }, TOKEN_DONA);

    expect(inexistente.status).toBe(404);
    expect(semLogin.status).toBe(401);
    expect(dona.status).toBe(403);
  });
});
