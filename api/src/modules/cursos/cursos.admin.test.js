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

function cursoFake(sobrescreve = {}) {
  return {
    id: 30,
    universidadeId: 7,
    nome: 'Análise e Desenvolvimento de Sistemas',
    areaCurso: 'Tecnologia',
    notaMec: '4',
    modalidade: 'Presencial',
    grau: 'Tecnólogo',
    duracaoSemestres: 6,
    descricao: null,
    ativo: true,
    universidade: { id: 7, nomeFantasia: 'Fatec Itu' },
    _count: { campusCursos: 0 },
    ...sobrescreve,
  };
}

const comAdmin = (req) => req.set('Authorization', `Bearer ${TOKEN_ADMIN}`);

beforeEach(() => {
  prisma.resetMockPrisma();
});

describe('GET /api/v1/cursos/administracao', () => {
  it('lista os cursos ativos de qualquer universidade com os filtros (200)', async () => {
    prisma.curso.findMany.mockResolvedValue([cursoFake({ _count: { campusCursos: 2 } })]);
    prisma.curso.count.mockResolvedValue(1);

    const resposta = await comAdmin(request(app).get('/api/v1/cursos/administracao?busca=An&universidadeId=7&areaCurso=Tec'));

    expect(resposta.status).toBe(200);
    expect(resposta.body.data[0]).toMatchObject({ id: 30, totalCampus: 2, universidade: { nomeFantasia: 'Fatec Itu' } });
    expect(prisma.curso.findMany.mock.calls[0][0].where).toEqual({
      ativo: true,
      nome: { contains: 'An' },
      areaCurso: { contains: 'Tec' },
      universidadeId: 7,
    });
  });

  it('responde 401 sem login e 403 para aluno e universidade', async () => {
    const semLogin = await request(app).get('/api/v1/cursos/administracao');
    const aluno = await request(app).get('/api/v1/cursos/administracao').set('Authorization', `Bearer ${TOKEN_ALUNO}`);
    const universidade = await request(app)
      .get('/api/v1/cursos/administracao')
      .set('Authorization', `Bearer ${TOKEN_UNIVERSIDADE}`);

    expect(semLogin.status).toBe(401);
    expect(aluno.status).toBe(403);
    expect(universidade.status).toBe(403);
  });
});

describe('POST /api/v1/universidades/:id/cursos', () => {
  it('cria o curso na universidade e grava auditoria (201)', async () => {
    prisma.universidade.findUnique.mockResolvedValue({ id: 7 });
    prisma.curso.create.mockResolvedValue(cursoFake());

    const resposta = await comAdmin(request(app).post('/api/v1/universidades/7/cursos')).send({
      nome: ' Análise e Desenvolvimento de Sistemas ',
      areaCurso: 'Tecnologia',
      grau: 'Tecnólogo',
      modalidade: 'Presencial',
      duracaoSemestres: 6,
      descricao: '',
    });

    expect(resposta.status).toBe(201);
    expect(prisma.curso.create).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({ universidadeId: 7, nome: 'Análise e Desenvolvimento de Sistemas', descricao: null }),
      }),
    );
    expect(prisma.logAuditoria.create).toHaveBeenCalledWith({
      data: expect.objectContaining({ usuarioId: 99, acao: 'CREATE', entidade: 'curso', entidadeId: 30 }),
    });
  });

  it('responde 400 sem nome e com duração fora do intervalo', async () => {
    const semNome = await comAdmin(request(app).post('/api/v1/universidades/7/cursos')).send({ areaCurso: 'x' });
    const duracao = await comAdmin(request(app).post('/api/v1/universidades/7/cursos')).send({ nome: 'X', duracaoSemestres: 0 });

    expect(semNome.status).toBe(400);
    expect(semNome.body.error.details[0].campo).toBe('nome');
    expect(duracao.status).toBe(400);
    expect(prisma.curso.create).not.toHaveBeenCalled();
  });

  it('responde 404 quando a universidade não existe e 403 para universidade', async () => {
    prisma.universidade.findUnique.mockResolvedValue(null);

    const inexistente = await comAdmin(request(app).post('/api/v1/universidades/70/cursos')).send({ nome: 'X' });
    const universidade = await request(app)
      .post('/api/v1/universidades/7/cursos')
      .set('Authorization', `Bearer ${TOKEN_UNIVERSIDADE}`)
      .send({ nome: 'X' });

    expect(inexistente.status).toBe(404);
    expect(universidade.status).toBe(403);
  });
});

describe('PATCH /api/v1/cursos/:id', () => {
  it('atualiza e grava os dados antes e depois (200)', async () => {
    prisma.curso.findFirst.mockResolvedValue(cursoFake());
    prisma.curso.update.mockResolvedValue(cursoFake({ nome: 'ADS', notaMec: null }));

    const resposta = await comAdmin(request(app).patch('/api/v1/cursos/30')).send({ nome: 'ADS', notaMec: null });

    expect(resposta.status).toBe(200);
    expect(resposta.body.data.nome).toBe('ADS');
    expect(prisma.logAuditoria.create).toHaveBeenCalledWith({
      data: expect.objectContaining({
        acao: 'UPDATE',
        dadosAntes: expect.objectContaining({ nome: 'Análise e Desenvolvimento de Sistemas', notaMec: '4' }),
        dadosDepois: expect.objectContaining({ nome: 'ADS', notaMec: null }),
      }),
    });
  });

  it('não troca a universidade do curso (400) e responde 404 para curso excluído', async () => {
    const trocar = await comAdmin(request(app).patch('/api/v1/cursos/30')).send({ universidadeId: 8 });
    prisma.curso.findFirst.mockResolvedValue(null);
    const excluido = await comAdmin(request(app).patch('/api/v1/cursos/30')).send({ nome: 'X' });

    expect(trocar.status).toBe(400);
    expect(excluido.status).toBe(404);
  });
});

describe('DELETE /api/v1/cursos/:id', () => {
  it('exclui (ativo=false) o curso sem ofertas e grava auditoria (200)', async () => {
    prisma.curso.findFirst.mockResolvedValue(cursoFake());
    prisma.campusCurso.count.mockResolvedValue(0);

    const resposta = await comAdmin(request(app).delete('/api/v1/cursos/30'));

    expect(resposta.status).toBe(200);
    expect(prisma.curso.update).toHaveBeenCalledWith({ where: { id: 30 }, data: { ativo: false } });
    expect(prisma.logAuditoria.create).toHaveBeenCalledWith({
      data: expect.objectContaining({ acao: 'DELETE', entidade: 'curso', entidadeId: 30 }),
    });
  });

  it.each([
    [1, 'ofertado em 1 campus.'],
    [3, 'ofertado em 3 campi.'],
  ])('curso ofertado em %i campus não é excluído (409)', async (ofertas, trecho) => {
    prisma.curso.findFirst.mockResolvedValue(cursoFake());
    prisma.campusCurso.count.mockResolvedValue(ofertas);

    const resposta = await comAdmin(request(app).delete('/api/v1/cursos/30'));

    expect(resposta.status).toBe(409);
    expect(resposta.body.error.code).toBe('CURSO_OFERTADO');
    expect(resposta.body.error.message).toContain(trecho);
    expect(resposta.body.error.message).toContain('Remova as ofertas antes de excluir');
    expect(prisma.curso.update).not.toHaveBeenCalled();
    expect(prisma.logAuditoria.create).not.toHaveBeenCalled();
  });

  it('responde 403 para quem não é administrador', async () => {
    const resposta = await request(app).delete('/api/v1/cursos/30').set('Authorization', `Bearer ${TOKEN_ALUNO}`);

    expect(resposta.status).toBe(403);
  });
});
