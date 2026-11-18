/**
 * Painel da universidade (Pendência 3): rotas de escrita e leitura da conta
 * de universidade, com o ownership e as regras de acesso pela situação do
 * cadastro (pendente, aprovada, reprovada, inativa), as regras de campus
 * principal, ofertas, programas aceitos, bolsas institucionais, reenvio e a
 * estatística simples. Usa um banco em memória sobre o Prisma simulado.
 */
const jwt = require('jsonwebtoken');
const request = require('supertest');

jest.mock('../../config/database', () => require('../../../tests/helpers/mockPrisma'));
jest.mock('../../config/mailer', () => ({ enviarEmail: jest.fn().mockResolvedValue(undefined) }));

const prisma = require('../../config/database');
const app = require('../../app');

function tokenPara({ id, tipoUsuario, universidadeId = null }) {
  return jwt.sign({ sub: id, tipoUsuario, universidadeId }, process.env.JWT_ACCESS_SECRET, { expiresIn: '15m' });
}

const TOKEN_DONA = tokenPara({ id: 5, tipoUsuario: 'U', universidadeId: 7 });
const TOKEN_OUTRA = tokenPara({ id: 6, tipoUsuario: 'U', universidadeId: 8 });
const TOKEN_ADMIN = tokenPara({ id: 99, tipoUsuario: 'D' });
const TOKEN_ALUNO = tokenPara({ id: 1, tipoUsuario: 'A' });

// ---------------------------------------------------------------------------
// Banco em memória
// ---------------------------------------------------------------------------

function combina(registro, where = {}) {
  return Object.entries(where).every(([campo, esperado]) => {
    const valor = registro[campo];
    if (esperado && typeof esperado === 'object' && !(esperado instanceof Date)) {
      if ('in' in esperado) return esperado.in.includes(valor);
      if ('not' in esperado) return valor !== esperado.not;
      if ('gte' in esperado || 'lt' in esperado) {
        return (!esperado.gte || valor >= esperado.gte) && (!esperado.lt || valor < esperado.lt);
      }
      return true;
    }
    return valor === esperado;
  });
}

let banco;

function novoBanco(status = 'A') {
  banco = {
    universidades: [
      {
        id: 7,
        usuarioId: 5,
        nomeFantasia: 'Fatec Itu',
        razaoSocial: 'Faculdade de Tecnologia de Itu',
        cnpj: '12345678000199',
        natureza: 'P',
        descricao: null,
        telefonePrincipal: null,
        linkPagina: null,
        linkSimulados: null,
        logoUrl: null,
        status,
        motivoReprovacao: status === 'R' ? 'CNPJ não confere' : null,
        aprovadoEm: status === 'A' ? new Date('2026-11-01T12:00:00Z') : null,
        aprovadoPor: null,
        mediaAvaliacao: '4.50',
        totalAvaliacoes: 2,
        criadoEm: new Date('2026-10-01T12:00:00Z'),
      },
      { id: 8, usuarioId: 6, nomeFantasia: 'Outra', cnpj: '99999999000199', status: 'A' },
    ],
    enderecos: [{ id: 1, logradouro: 'Av. Tiradentes', numero: '1211', complemento: null, bairro: 'Centro', cidade: 'Itu', estado: 'SP', cep: '13309640' }],
    campus: [
      { id: 20, universidadeId: 7, enderecoId: 1, nome: 'Campus Itu', cnpj: null, telefoneCelular: null, telefoneFixo: null, emailCampus: null, principal: true, ativo: true },
      { id: 30, universidadeId: 8, enderecoId: 1, nome: 'Campus da outra', principal: true, ativo: true },
    ],
    cursos: [
      { id: 40, universidadeId: 7, nome: 'ADS', areaCurso: 'Tecnologia', notaMec: null, modalidade: 'Presencial', grau: 'Tecnólogo', duracaoSemestres: 6, descricao: null, ativo: true },
      { id: 41, universidadeId: 8, nome: 'Direito', ativo: true },
    ],
    ofertas: [],
    programas: [
      { id: 1, nome: 'ENEM', sigla: 'ENEM', tipo: 'ENTRADA', universidadeId: null, ativo: true },
      { id: 2, nome: 'FIES', sigla: 'FIES', tipo: 'FINANCIAMENTO', universidadeId: null, ativo: true },
      { id: 3, nome: 'ProUni', sigla: 'ProUni', tipo: 'BOLSA', universidadeId: null, ativo: true },
      { id: 50, nome: 'Bolsa da outra', tipo: 'BOLSA', universidadeId: 8, ativo: true, descricao: 'x' },
    ],
    aceitos: [{ universidadeId: 7, programaId: 1, observacao: null }],
    visitas: 12,
  };
  ligarBanco();
}

const proximoId = (lista) => Math.max(0, ...lista.map((r) => r.id)) + 1;
const enderecoDe = (campus) => banco.enderecos.find((e) => e.id === campus.enderecoId);
const comEndereco = (campus) => ({
  ...campus,
  endereco: enderecoDe(campus),
  _count: { campusCursos: banco.ofertas.filter((o) => o.campusId === campus.id).length },
});
const comCampus = (oferta) => ({ ...oferta, campus: banco.campus.find((c) => c.id === oferta.campusId) });
const chaveOferta = (where) => where.campusId_cursoId;

function universidadeCompleta(u) {
  return {
    ...u,
    usuario: { id: u.usuarioId, nome: 'Secretaria', email: 'secretaria@fatecitu.edu.br', ativo: true },
    campus: banco.campus.filter((c) => c.universidadeId === u.id && c.ativo).map(comEndereco),
    universidadeProgramas: banco.aceitos
      .filter((a) => a.universidadeId === u.id)
      .map((a) => ({ ...a, programa: banco.programas.find((p) => p.id === a.programaId) })),
  };
}

function ligarBanco() {
  const p = prisma;
  p.universidade.findUnique.mockImplementation(async ({ where }) => {
    const u = banco.universidades.find((x) => (where.id ? x.id === where.id : x.cnpj === where.cnpj));
    return u ? universidadeCompleta(u) : null;
  });
  p.universidade.update.mockImplementation(async ({ where, data }) => {
    const u = banco.universidades.find((x) => x.id === where.id);
    Object.assign(u, data);
    return { ...u };
  });
  p.universidade.updateMany.mockImplementation(async ({ where, data }) => {
    const lista = banco.universidades.filter((u) => combina(u, where));
    lista.forEach((u) => Object.assign(u, data));
    return { count: lista.length };
  });

  p.campus.findFirst.mockImplementation(async ({ where }) => {
    const c = banco.campus.find((x) => combina(x, where));
    return c ? comEndereco(c) : null;
  });
  p.campus.findMany.mockImplementation(async ({ where }) => banco.campus.filter((c) => combina(c, where)).map(comEndereco));
  p.campus.count.mockImplementation(async ({ where }) => banco.campus.filter((c) => combina(c, where)).length);
  p.campus.updateMany.mockImplementation(async ({ where, data }) => {
    const lista = banco.campus.filter((c) => combina(c, where));
    lista.forEach((c) => Object.assign(c, data));
    return { count: lista.length };
  });
  p.campus.create.mockImplementation(async ({ data }) => {
    const campus = { id: proximoId(banco.campus), ativo: true, ...data };
    banco.campus.push(campus);
    return comEndereco(campus);
  });
  p.campus.update.mockImplementation(async ({ where, data }) => {
    const campus = banco.campus.find((c) => c.id === where.id);
    Object.assign(campus, data);
    return comEndereco(campus);
  });
  p.endereco.create.mockImplementation(async ({ data }) => {
    const endereco = { id: proximoId(banco.enderecos), ...data };
    banco.enderecos.push(endereco);
    return endereco;
  });
  p.endereco.update.mockImplementation(async ({ where, data }) => {
    const endereco = banco.enderecos.find((e) => e.id === where.id);
    Object.assign(endereco, data);
    return endereco;
  });

  p.curso.findFirst.mockImplementation(async ({ where }) => {
    const curso = banco.cursos.find((c) => combina(c, where));
    return curso
      ? {
          ...curso,
          universidade: { id: curso.universidadeId, nomeFantasia: 'Fatec Itu' },
          _count: { campusCursos: banco.ofertas.filter((o) => o.cursoId === curso.id).length },
        }
      : null;
  });
  p.curso.findMany.mockImplementation(async ({ where }) =>
    banco.cursos
      .filter((c) => combina(c, where))
      .map((curso) => ({
        ...curso,
        campusCursos: banco.ofertas
          .filter((o) => o.cursoId === curso.id && banco.campus.find((c) => c.id === o.campusId)?.ativo)
          .map(comCampus),
      })),
  );
  p.curso.create.mockImplementation(async ({ data }) => {
    const curso = { id: proximoId(banco.cursos), ativo: true, ...data };
    banco.cursos.push(curso);
    return { ...curso, universidade: { id: curso.universidadeId, nomeFantasia: 'Fatec Itu' }, _count: { campusCursos: 0 } };
  });
  p.curso.update.mockImplementation(async ({ where, data }) => {
    const curso = banco.cursos.find((c) => c.id === where.id);
    Object.assign(curso, data);
    return { ...curso, universidade: { id: curso.universidadeId, nomeFantasia: 'Fatec Itu' }, _count: { campusCursos: 0 } };
  });

  p.campusCurso.count.mockImplementation(async ({ where }) => banco.ofertas.filter((o) => combina(o, where)).length);
  p.campusCurso.findUnique.mockImplementation(async ({ where }) => {
    const { campusId, cursoId } = chaveOferta(where);
    const oferta = banco.ofertas.find((o) => o.campusId === campusId && o.cursoId === cursoId);
    return oferta ? comCampus(oferta) : null;
  });
  p.campusCurso.create.mockImplementation(async ({ data }) => {
    banco.ofertas.push({ ...data });
    return comCampus(data);
  });
  p.campusCurso.update.mockImplementation(async ({ where, data }) => {
    const { campusId, cursoId } = chaveOferta(where);
    const oferta = banco.ofertas.find((o) => o.campusId === campusId && o.cursoId === cursoId);
    Object.assign(oferta, data);
    return comCampus(oferta);
  });
  p.campusCurso.delete.mockImplementation(async ({ where }) => {
    const { campusId, cursoId } = chaveOferta(where);
    banco.ofertas = banco.ofertas.filter((o) => !(o.campusId === campusId && o.cursoId === cursoId));
  });

  p.programa.findMany.mockImplementation(async ({ where }) => banco.programas.filter((x) => combina(x, where)));
  p.programa.findFirst.mockImplementation(async ({ where }) => banco.programas.find((x) => combina(x, where)) ?? null);
  p.programa.count.mockImplementation(async ({ where }) => banco.programas.filter((x) => combina(x, where)).length);
  p.programa.create.mockImplementation(async ({ data }) => {
    const programa = { id: proximoId(banco.programas), ativo: true, criadoEm: new Date(), ...data };
    banco.programas.push(programa);
    return programa;
  });
  p.programa.update.mockImplementation(async ({ where, data }) => {
    const programa = banco.programas.find((x) => x.id === where.id);
    Object.assign(programa, data);
    return { ...programa };
  });

  p.universidadePrograma.findMany.mockImplementation(async ({ where }) => banco.aceitos.filter((a) => combina(a, where)));
  p.universidadePrograma.deleteMany.mockImplementation(async ({ where }) => {
    banco.aceitos = banco.aceitos.filter((a) => !combina(a, where));
  });
  p.universidadePrograma.createMany.mockImplementation(async ({ data }) => {
    banco.aceitos.push(...data);
  });

  p.visitaPagina.count.mockImplementation(async () => banco.visitas);
  p.usuario.findMany.mockResolvedValue([{ id: 99 }, { id: 98 }]);
}

const comToken = (req, token) => (token ? req.set('Authorization', `Bearer ${token}`) : req);
const api = {
  get: (url, token = TOKEN_DONA) => comToken(request(app).get(`/api/v1${url}`), token),
  post: (url, body, token = TOKEN_DONA) => comToken(request(app).post(`/api/v1${url}`), token).send(body),
  put: (url, body, token = TOKEN_DONA) => comToken(request(app).put(`/api/v1${url}`), token).send(body),
  patch: (url, body, token = TOKEN_DONA) => comToken(request(app).patch(`/api/v1${url}`), token).send(body),
  delete: (url, token = TOKEN_DONA) => comToken(request(app).delete(`/api/v1${url}`), token),
};

const ENDERECO = { logradouro: 'Rua Nova', numero: '10', bairro: 'Centro', cidade: 'Salto', estado: 'sp', cep: '13320-000' };
const auditorias = () => prisma.logAuditoria.create.mock.calls.map(([{ data }]) => data);

beforeEach(() => {
  prisma.resetMockPrisma();
  novoBanco('A');
});

// ---------------------------------------------------------------------------
// Caminho feliz
// ---------------------------------------------------------------------------

describe('dados da instituição', () => {
  it('a dona edita os próprios dados, inclusive os links (200, com auditoria)', async () => {
    const resposta = await api.patch('/universidades/7', {
      descricao: 'Nova descrição',
      linkPagina: 'https://fatecitu.edu.br',
      linkSimulados: 'https://fatecitu.edu.br/simulados',
    });

    expect(resposta.status).toBe(200);
    expect(resposta.body.data).toMatchObject({ linkPagina: 'https://fatecitu.edu.br', linkSimulados: 'https://fatecitu.edu.br/simulados' });
    expect(banco.universidades[0].status).toBe('A');
    expect(auditorias()[0]).toMatchObject({ acao: 'UPDATE', entidade: 'universidade', entidadeId: 7, usuarioId: 5 });
  });

  it('não aceita status pela edição (400)', async () => {
    const resposta = await api.patch('/universidades/7', { status: 'A' });
    expect(resposta.status).toBe(400);
  });
});

describe('campi', () => {
  it('lista os campi com endereço e total de ofertas', async () => {
    banco.ofertas.push({ campusId: 20, cursoId: 40, turno: 'Noturno', vagas: 40 });
    const resposta = await api.get('/universidades/7/gestao/campus');

    expect(resposta.status).toBe(200);
    expect(resposta.body.data).toEqual([
      expect.objectContaining({ id: 20, principal: true, totalOfertas: 1, endereco: expect.objectContaining({ cidade: 'Itu' }) }),
    ]);
  });

  it('cria campus com CNPJ alfanumérico e CEP, sem mexer no principal (201)', async () => {
    const resposta = await api.post('/universidades/7/campus', {
      nome: 'Campus Salto',
      cnpj: '12.ABC.345/01DE-35',
      telefoneFixo: '1140001111',
      emailCampus: 'salto@fatec.sp.gov.br',
      endereco: ENDERECO,
    });

    expect(resposta.status).toBe(201);
    expect(resposta.body.data).toMatchObject({ nome: 'Campus Salto', cnpj: '12ABC34501DE35', principal: false });
    expect(resposta.body.data.endereco).toMatchObject({ estado: 'SP', cep: '13320000' });
    expect(banco.campus.find((c) => c.id === 20).principal).toBe(true);
    expect(auditorias()[0]).toMatchObject({ acao: 'CREATE', entidade: 'campus' });
  });

  it('recusa CNPJ do campus com tamanho errado e CEP faltando (400)', async () => {
    const semCep = { ...ENDERECO };
    delete semCep.cep;
    const resposta = await api.post('/universidades/7/campus', { nome: 'X', cnpj: '123', endereco: semCep });

    expect(resposta.status).toBe(400);
    const campos = resposta.body.error.details.map((d) => d.campo);
    expect(campos).toEqual(expect.arrayContaining(['cnpj', 'endereco.cep']));
  });

  it('edita campus e endereço', async () => {
    const resposta = await api.patch('/campus/20', { telefoneCelular: '11999990000', endereco: { numero: '99' } });

    expect(resposta.status).toBe(200);
    expect(resposta.body.data).toMatchObject({ telefoneCelular: '11999990000', endereco: expect.objectContaining({ numero: '99' }) });
  });
});

describe('regras de campus principal', () => {
  beforeEach(() => {
    banco.campus.push({ id: 21, universidadeId: 7, enderecoId: 1, nome: 'Campus Salto', principal: false, ativo: true });
  });

  const principais = () => banco.campus.filter((c) => c.universidadeId === 7 && c.ativo && c.principal).map((c) => c.id);

  it('criar um campus principal desmarca o anterior: sempre um só', async () => {
    const resposta = await api.post('/universidades/7/campus', { nome: 'Novo', principal: true, endereco: ENDERECO });

    expect(resposta.status).toBe(201);
    expect(principais()).toEqual([resposta.body.data.id]);
  });

  it('marcar outro campus como principal desmarca o anterior', async () => {
    const resposta = await api.patch('/campus/21', { principal: true });

    expect(resposta.status).toBe(200);
    expect(principais()).toEqual([21]);
  });

  it('não desmarca o principal sem marcar outro (409 CAMPUS_PRINCIPAL_OBRIGATORIO)', async () => {
    const resposta = await api.patch('/campus/20', { principal: false });

    expect(resposta.status).toBe(409);
    expect(resposta.body.error.code).toBe('CAMPUS_PRINCIPAL_OBRIGATORIO');
    expect(principais()).toEqual([20]);
  });

  it('não exclui o campus principal (409 CAMPUS_PRINCIPAL)', async () => {
    const resposta = await api.delete('/campus/20');

    expect(resposta.status).toBe(409);
    expect(resposta.body.error.code).toBe('CAMPUS_PRINCIPAL');
  });

  it('não exclui o único campus (409 UNICO_CAMPUS)', async () => {
    banco.campus = banco.campus.filter((c) => c.id !== 21);
    const resposta = await api.delete('/campus/20');

    expect(resposta.status).toBe(409);
    expect(resposta.body.error.code).toBe('UNICO_CAMPUS');
  });

  it('não exclui campus com cursos ofertados (409 CAMPUS_COM_OFERTAS)', async () => {
    banco.ofertas.push({ campusId: 21, cursoId: 40, turno: 'Noturno', vagas: 40 });
    const resposta = await api.delete('/campus/21');

    expect(resposta.status).toBe(409);
    expect(resposta.body.error.code).toBe('CAMPUS_COM_OFERTAS');
    expect(banco.campus.find((c) => c.id === 21).ativo).toBe(true);
  });

  it('exclui (logicamente) um campus que não é o principal nem tem ofertas', async () => {
    const resposta = await api.delete('/campus/21');

    expect(resposta.status).toBe(200);
    expect(banco.campus.find((c) => c.id === 21).ativo).toBe(false);
    expect(auditorias()[0]).toMatchObject({ acao: 'DELETE', entidade: 'campus', entidadeId: 21 });
  });

  it('trava a linha da universidade em cada alteração de campus', async () => {
    await api.patch('/campus/21', { principal: true });
    expect(prisma.$queryRaw).toHaveBeenCalled();
  });
});

describe('cursos e ofertas', () => {
  it('a dona cria, edita e exclui um curso próprio', async () => {
    const criado = await api.post('/universidades/7/cursos', { nome: 'Gestão Empresarial', grau: 'Tecnólogo' });
    expect(criado.status).toBe(201);

    const editado = await api.patch(`/cursos/${criado.body.data.id}`, { areaCurso: 'Gestão' });
    expect(editado.status).toBe(200);
    expect(editado.body.data.areaCurso).toBe('Gestão');

    const excluido = await api.delete(`/cursos/${criado.body.data.id}`);
    expect(excluido.status).toBe(200);
    expect(banco.cursos.find((c) => c.id === criado.body.data.id).ativo).toBe(false);
  });

  it('não exclui curso ofertado (409 CURSO_OFERTADO, regra do administrador)', async () => {
    banco.ofertas.push({ campusId: 20, cursoId: 40, turno: 'Noturno', vagas: 40 });
    const resposta = await api.delete('/cursos/40');
    expect(resposta.status).toBe(409);
    expect(resposta.body.error.code).toBe('CURSO_OFERTADO');
  });

  it('cria, lista, edita e remove a oferta do curso em campus', async () => {
    const criada = await api.post('/cursos/40/ofertas', { campusId: 20, turno: 'Noturno', vagas: 40 });
    expect(criada.status).toBe(201);
    expect(criada.body.data).toMatchObject({ cursoId: 40, campusId: 20, campusNome: 'Campus Itu', turno: 'Noturno', vagas: 40 });

    const lista = await api.get('/universidades/7/gestao/cursos');
    expect(lista.body.data[0].ofertas).toEqual([expect.objectContaining({ campusId: 20, turno: 'Noturno' })]);

    const editada = await api.patch('/cursos/40/ofertas/20', { vagas: 35 });
    expect(editada.status).toBe(200);
    expect(editada.body.data.vagas).toBe(35);

    const removida = await api.delete('/cursos/40/ofertas/20');
    expect(removida.status).toBe(200);
    expect(banco.ofertas).toHaveLength(0);
    expect(auditorias().map((a) => a.acao)).toEqual(['CREATE', 'UPDATE', 'DELETE']);
  });

  it('recusa oferta em campus de outra universidade (400 CAMPUS_INVALIDO)', async () => {
    const resposta = await api.post('/cursos/40/ofertas', { campusId: 30, turno: 'Noturno' });
    expect(resposta.status).toBe(400);
    expect(resposta.body.error.code).toBe('CAMPUS_INVALIDO');
  });

  it('recusa oferta repetida no mesmo campus (409 OFERTA_DUPLICADA) e turno desconhecido (400)', async () => {
    banco.ofertas.push({ campusId: 20, cursoId: 40, turno: 'Noturno', vagas: 40 });
    const repetida = await api.post('/cursos/40/ofertas', { campusId: 20, turno: 'Matutino' });
    const turno = await api.post('/cursos/40/ofertas', { campusId: 20, turno: 'Madrugada' });

    expect(repetida.status).toBe(409);
    expect(repetida.body.error.code).toBe('OFERTA_DUPLICADA');
    expect(turno.status).toBe(400);
  });
});

describe('programas aceitos', () => {
  it('lista os programas globais com o que a universidade aceita', async () => {
    const resposta = await api.get('/universidades/7/gestao/programas');

    expect(resposta.status).toBe(200);
    expect(resposta.body.data.map((p) => [p.id, p.aceito])).toEqual([
      [1, true],
      [2, false],
      [3, false],
    ]);
  });

  it('marca e desmarca programas, com observação (PUT substitui o conjunto)', async () => {
    const resposta = await api.put('/universidades/7/programas', {
      programas: [
        { programaId: 2, observacao: 'Aceito em todos os cursos' },
        { programaId: 3 },
      ],
    });

    expect(resposta.status).toBe(200);
    expect(banco.aceitos.map((a) => a.programaId)).toEqual([2, 3]);
    expect(resposta.body.data.find((p) => p.id === 2)).toMatchObject({ aceito: true, observacao: 'Aceito em todos os cursos' });
    expect(auditorias()[0]).toMatchObject({
      acao: 'UPDATE',
      entidade: 'universidade_programa',
      dadosAntes: [{ programaId: 1, observacao: null }],
    });
  });

  it('não aceita bolsa institucional de outra universidade nem programa inexistente (400)', async () => {
    const resposta = await api.put('/universidades/7/programas', { programas: [{ programaId: 50 }] });
    expect(resposta.status).toBe(400);
    expect(resposta.body.error.code).toBe('PROGRAMA_INVALIDO');
    expect(banco.aceitos.map((a) => a.programaId)).toEqual([1]);
  });
});

describe('bolsas institucionais', () => {
  it('cria, lista, edita e exclui uma bolsa própria do tipo BOLSA', async () => {
    const criada = await api.post('/universidades/7/bolsas', { nome: 'Bolsa Mérito', descricao: '50% para os melhores' });
    expect(criada.status).toBe(201);
    expect(criada.body.data).toMatchObject({ tipo: 'BOLSA', nome: 'Bolsa Mérito' });
    const bolsa = banco.programas.find((p) => p.id === criada.body.data.id);
    expect(bolsa).toMatchObject({ universidadeId: 7, usuarioId: 5 });

    const lista = await api.get('/universidades/7/gestao/bolsas');
    expect(lista.body.data.map((b) => b.nome)).toEqual(['Bolsa Mérito']);

    const editada = await api.patch(`/universidades/7/bolsas/${bolsa.id}`, { requisitos: 'Nota acima de 700' });
    expect(editada.status).toBe(200);

    const excluida = await api.delete(`/universidades/7/bolsas/${bolsa.id}`);
    expect(excluida.status).toBe(200);
    expect(bolsa.ativo).toBe(false);
  });

  it('não altera bolsa de outra universidade pela própria rota (404) e não aceita trocar o tipo (400)', async () => {
    const outra = await api.patch('/universidades/7/bolsas/50', { nome: 'Minha' });
    const tipo = await api.post('/universidades/7/bolsas', { nome: 'X', descricao: 'Y', tipo: 'ENTRADA' });

    expect(outra.status).toBe(404);
    expect(tipo.status).toBe(400);
  });
});

describe('avaliações recebidas e estatística', () => {
  it('lista as avaliações em qualquer situação do cadastro', async () => {
    novoBanco('P');
    prisma.avaliacao.findMany.mockResolvedValue([
      { id: 1, nota: 5, comentario: 'Ótima', criadoEm: new Date(), usuario: { nome: 'Ana Souza' } },
    ]);
    prisma.avaliacao.count.mockResolvedValue(1);

    const resposta = await api.get('/universidades/7/gestao/avaliacoes');

    expect(resposta.status).toBe(200);
    expect(resposta.body.data[0]).toMatchObject({ nota: 5, autor: 'Ana' });
  });

  it('traz as visitas da página no período e a média das avaliações', async () => {
    const resposta = await api.get('/universidades/7/estatisticas?de=2026-11-01&ate=2026-11-10');

    expect(resposta.status).toBe(200);
    expect(resposta.body.data).toEqual({ de: '2026-11-01', ate: '2026-11-10', visitas: 12, mediaAvaliacao: 4.5, totalAvaliacoes: 2 });
    const { where } = prisma.visitaPagina.count.mock.calls[0][0];
    expect(where).toMatchObject({ entidade: 'universidade', entidadeId: 7 });
    expect(where.criadoEm.gte.toISOString()).toBe('2026-11-01T03:00:00.000Z');
    expect(where.criadoEm.lt.toISOString()).toBe('2026-11-11T03:00:00.000Z');
  });
});

// ---------------------------------------------------------------------------
// Reenvio do cadastro reprovado
// ---------------------------------------------------------------------------

describe('POST /universidades/:id/reenviar', () => {
  beforeEach(() => novoBanco('R'));

  it('volta para pendente, guarda o motivo na auditoria e notifica os administradores', async () => {
    const resposta = await api.post('/universidades/7/reenviar');

    expect(resposta.status).toBe(200);
    expect(resposta.body.data).toMatchObject({ status: 'P', motivoReprovacao: null });
    expect(auditorias()[0]).toMatchObject({
      acao: 'UPDATE',
      entidade: 'universidade',
      dadosAntes: { status: 'R', motivoReprovacao: 'CNPJ não confere' },
      dadosDepois: { acao: 'reenviar', status: 'P' },
    });
    const [{ data: notificacoes }] = prisma.notificacao.createMany.mock.calls[0];
    expect(notificacoes.map((n) => n.usuarioId)).toEqual([99, 98]);
    expect(notificacoes[0]).toMatchObject({ tipo: 'UNIVERSIDADE_PENDENTE', referenciaTipo: 'universidade', referenciaId: 7 });
  });

  it.each(['P', 'A', 'I'])('responde 409 STATUS_INVALIDO quando o status é %s', async (status) => {
    novoBanco(status);
    const resposta = await api.post('/universidades/7/reenviar');
    expect(resposta.status).toBe(409);
    expect(resposta.body.error.code).toBe('STATUS_INVALIDO');
  });

  it('só a própria universidade reenvia: administrador, aluno e outra universidade recebem 403', async () => {
    for (const token of [TOKEN_ADMIN, TOKEN_ALUNO, TOKEN_OUTRA]) {
      const resposta = await api.post('/universidades/7/reenviar', {}, token);
      expect(resposta.status).toBe(403);
    }
    expect(banco.universidades[0].status).toBe('R');
  });
});

// ---------------------------------------------------------------------------
// Sem login, perfil errado e universidade de outra conta
// ---------------------------------------------------------------------------

const ROTAS = [
  ['get', '/universidades/7/gestao/campus'],
  ['get', '/universidades/7/gestao/cursos'],
  ['get', '/universidades/7/gestao/programas'],
  ['get', '/universidades/7/gestao/bolsas'],
  ['get', '/universidades/7/gestao/avaliacoes'],
  ['get', '/universidades/7/estatisticas'],
  ['patch', '/universidades/7', { descricao: 'x' }],
  ['post', '/universidades/7/campus', { nome: 'Novo', endereco: ENDERECO }],
  ['patch', '/campus/20', { nome: 'Renomeado' }],
  ['delete', '/campus/20'],
  ['post', '/universidades/7/cursos', { nome: 'Novo curso' }],
  ['patch', '/cursos/40', { nome: 'Renomeado' }],
  ['delete', '/cursos/40'],
  ['post', '/cursos/40/ofertas', { campusId: 20, turno: 'Noturno' }],
  ['put', '/universidades/7/programas', { programas: [] }],
  ['post', '/universidades/7/bolsas', { nome: 'Bolsa', descricao: 'x' }],
];

describe.each(ROTAS)('%s %s', (metodo, url, body) => {
  const chamar = (token) => (metodo === 'get' || metodo === 'delete' ? api[metodo](url, token) : api[metodo](url, body, token));

  it('responde 401 sem login', async () => {
    expect((await chamar(null)).status).toBe(401);
  });

  it('responde 403 para o aluno', async () => {
    expect((await chamar(TOKEN_ALUNO)).status).toBe(403);
  });

  it('responde 403 FORBIDDEN para a universidade de outra conta, sem gravar nada', async () => {
    const resposta = await chamar(TOKEN_OUTRA);
    expect(resposta.status).toBe(403);
    expect(resposta.body.error.code).toBe('FORBIDDEN');
    expect(prisma.logAuditoria.create).not.toHaveBeenCalled();
  });
});

describe('recursos de outra universidade pelo id', () => {
  it('a dona não altera campus, curso nem oferta de outra universidade (403)', async () => {
    expect((await api.patch('/campus/30', { nome: 'x' })).status).toBe(403);
    expect((await api.delete('/cursos/41')).status).toBe(403);
    expect((await api.post('/cursos/41/ofertas', { campusId: 30, turno: 'Noturno' })).status).toBe(403);
  });

  it('campus ou curso inexistente responde 404', async () => {
    expect((await api.patch('/campus/999', { nome: 'x' })).status).toBe(404);
    expect((await api.patch('/cursos/999', { nome: 'x' })).status).toBe(404);
  });

  it('o administrador também gerencia o painel de qualquer universidade', async () => {
    const resposta = await api.post('/universidades/7/campus', { nome: 'Pelo admin', endereco: ENDERECO }, TOKEN_ADMIN);
    expect(resposta.status).toBe(201);
  });
});

// ---------------------------------------------------------------------------
// Regras de acesso pela situação do cadastro
// ---------------------------------------------------------------------------

// Escritas: [descrição, método, url, body, grupo]. Grupo "cadastro" é o que a
// reprovada pode corrigir (instituição e campi); "dominio" é o resto.
const ESCRITAS = [
  ['editar a instituição', 'patch', '/universidades/7', { descricao: 'x' }, 'cadastro'],
  ['criar campus', 'post', '/universidades/7/campus', { nome: 'Novo', endereco: ENDERECO }, 'cadastro'],
  ['editar campus', 'patch', '/campus/20', { nome: 'Renomeado' }, 'cadastro'],
  ['criar curso', 'post', '/universidades/7/cursos', { nome: 'Novo curso' }, 'dominio'],
  ['editar curso', 'patch', '/cursos/40', { nome: 'Renomeado' }, 'dominio'],
  ['criar oferta', 'post', '/cursos/40/ofertas', { campusId: 20, turno: 'Noturno' }, 'dominio'],
  ['marcar programas', 'put', '/universidades/7/programas', { programas: [{ programaId: 1 }] }, 'dominio'],
  ['criar bolsa', 'post', '/universidades/7/bolsas', { nome: 'Bolsa', descricao: 'x' }, 'dominio'],
];

const PERMITIDO = {
  P: { cadastro: true, dominio: true },
  A: { cadastro: true, dominio: true },
  R: { cadastro: true, dominio: false },
  I: { cadastro: false, dominio: false },
};

describe.each(['P', 'A', 'R', 'I'])('universidade com status %s', (status) => {
  beforeEach(() => novoBanco(status));

  it.each(ESCRITAS)('%s', async (_descricao, metodo, url, body, grupo) => {
    const resposta = await api[metodo](url, body);

    if (PERMITIDO[status][grupo]) {
      expect([200, 201]).toContain(resposta.status);
      expect(prisma.logAuditoria.create).toHaveBeenCalled();
    } else {
      expect(resposta.status).toBe(403);
      expect(resposta.body.error.code).toBe('UNIVERSIDADE_NAO_APROVADA');
      expect(prisma.logAuditoria.create).not.toHaveBeenCalled();
    }
  });

  it('continua lendo os dados do painel', async () => {
    for (const url of ['/universidades/7/gestao/campus', '/universidades/7/gestao/cursos', '/universidades/7/cadastro']) {
      expect((await api.get(url)).status).toBe(200);
    }
  });
});

describe('alterações da aprovada valem na hora', () => {
  it('editar a instituição não muda o status nem pede nova aprovação', async () => {
    await api.patch('/universidades/7', { nomeFantasia: 'Fatec Itu Nova' });
    expect(banco.universidades[0]).toMatchObject({ status: 'A', nomeFantasia: 'Fatec Itu Nova' });
    expect(prisma.notificacao.createMany).not.toHaveBeenCalled();
  });
});
