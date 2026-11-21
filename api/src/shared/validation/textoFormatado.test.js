const jwt = require('jsonwebtoken');
const request = require('supertest');

jest.mock('../../config/database', () => require('../../../tests/helpers/mockPrisma'));

const prisma = require('../../config/database');
const app = require('../../app');
const { LIMITE_TEXTO_FORMATADO, textoFormatadoOpcional, textoFormatadoObrigatorio } = require('./textoFormatado');
const programasSchemas = require('../../modules/programas/programas.schema');
const cursosSchemas = require('../../modules/cursos/cursos.schema');
const universidadesSchemas = require('../../modules/universidades/universidades.schema');

function tokenPara({ id, tipoUsuario, universidadeId = null }) {
  return jwt.sign({ sub: id, tipoUsuario, universidadeId }, process.env.JWT_ACCESS_SECRET, { expiresIn: '15m' });
}

const TOKEN_ADMIN = tokenPara({ id: 99, tipoUsuario: 'D' });
const TOKEN_UNIVERSIDADE = tokenPara({ id: 5, tipoUsuario: 'U', universidadeId: 7 });

const NO_LIMITE = 'a'.repeat(LIMITE_TEXTO_FORMATADO);
const ACIMA_DO_LIMITE = 'a'.repeat(LIMITE_TEXTO_FORMATADO + 1);

// Texto de várias seções, como os da demonstração.
const MARKDOWN = [
  '## O que é',
  '',
  'Programa **federal** de _bolsas_. Veja o [site oficial](https://www.example.com).',
  '',
  '## Passo a passo',
  '',
  '1. Faça o Enem.',
  '2. Inscreva-se.',
  '',
  '<script>alert(1)</script> ![foto](https://www.example.com/foto.png)',
].join('\n');

beforeEach(() => {
  prisma.resetMockPrisma();
});

describe('Limite das descrições formatadas', () => {
  it('é de 10.000 caracteres', () => {
    expect(LIMITE_TEXTO_FORMATADO).toBe(10000);
  });

  it('aceita exatamente o limite e recusa um caractere a mais, com a mensagem em pt-BR', () => {
    expect(textoFormatadoOpcional().safeParse(NO_LIMITE).success).toBe(true);
    expect(textoFormatadoObrigatorio('Informe a descrição').safeParse(NO_LIMITE).success).toBe(true);

    const recusado = textoFormatadoOpcional().safeParse(ACIMA_DO_LIMITE);
    expect(recusado.success).toBe(false);
    expect(recusado.error.issues[0].message).toBe('Use no máximo 10.000 caracteres');
  });

  it('guarda o Markdown como veio (HTML e imagem incluídos): quem interpreta é o app', () => {
    expect(textoFormatadoOpcional().parse(MARKDOWN)).toBe(MARKDOWN);
    expect(textoFormatadoOpcional().parse('   ')).toBeNull();
  });

  it.each([
    ['programa', programasSchemas.criarProgramaSchema.body, { nome: 'P', tipo: 'BOLSA' }, ['descricao', 'requisitos', 'comoFunciona']],
    ['bolsa institucional', programasSchemas.criarBolsaSchema.body, { nome: 'B' }, ['descricao', 'requisitos', 'comoFunciona']],
    ['curso', cursosSchemas.criarCursoSchema.body, { nome: 'C' }, ['descricao']],
  ])('%s aceita descrição longa de várias seções', (_, schema, base, campos) => {
    for (const campo of campos) {
      const dados = { descricao: 'Texto.', ...base, [campo]: NO_LIMITE };
      expect(schema.safeParse(dados).success).toBe(true);
      expect(schema.safeParse({ ...dados, [campo]: MARKDOWN }).success).toBe(true);
    }
  });

  it('universidade aceita "Sobre" no limite', () => {
    expect(universidadesSchemas.atualizarUniversidadeSchema.body.safeParse({ descricao: NO_LIMITE }).success).toBe(true);
  });
});

describe('Rotas de escrita recusam descrição acima do limite (400)', () => {
  const comAdmin = (req) => req.set('Authorization', `Bearer ${TOKEN_ADMIN}`);
  const comUniversidade = (req) => req.set('Authorization', `Bearer ${TOKEN_UNIVERSIDADE}`);

  it.each([
    ['descricao'],
    ['requisitos'],
    ['comoFunciona'],
  ])('POST /programas com %s longo demais', async (campo) => {
    const corpo = { nome: 'ProUni', tipo: 'BOLSA', descricao: 'Bolsas.', [campo]: ACIMA_DO_LIMITE };

    const resposta = await comAdmin(request(app).post('/api/v1/programas')).send(corpo);

    expect(resposta.status).toBe(400);
    expect(resposta.body.error.details).toContainEqual({ campo, mensagem: 'Use no máximo 10.000 caracteres' });
    expect(prisma.programa.create).not.toHaveBeenCalled();
  });

  it('PATCH /programas/:id com descrição longa demais', async () => {
    const resposta = await comAdmin(request(app).patch('/api/v1/programas/3')).send({ descricao: ACIMA_DO_LIMITE });

    expect(resposta.status).toBe(400);
    expect(prisma.programa.update).not.toHaveBeenCalled();
  });

  it('POST /universidades/:id/bolsas com descrição longa demais', async () => {
    const resposta = await comUniversidade(request(app).post('/api/v1/universidades/7/bolsas')).send({
      nome: 'Bolsa Mérito',
      descricao: ACIMA_DO_LIMITE,
    });

    expect(resposta.status).toBe(400);
    expect(resposta.body.error.details.map((d) => d.campo)).toContain('descricao');
    expect(prisma.programa.create).not.toHaveBeenCalled();
  });

  it('POST /universidades/:id/cursos com descrição longa demais', async () => {
    const resposta = await comUniversidade(request(app).post('/api/v1/universidades/7/cursos')).send({
      nome: 'Enfermagem',
      descricao: ACIMA_DO_LIMITE,
    });

    expect(resposta.status).toBe(400);
    expect(resposta.body.error.details.map((d) => d.campo)).toContain('descricao');
    expect(prisma.curso.create).not.toHaveBeenCalled();
  });

  it('PATCH /cursos/:id com descrição longa demais', async () => {
    const resposta = await comUniversidade(request(app).patch('/api/v1/cursos/4')).send({ descricao: ACIMA_DO_LIMITE });

    expect(resposta.status).toBe(400);
    expect(prisma.curso.update).not.toHaveBeenCalled();
  });

  it('PATCH /universidades/:id com "Sobre" longo demais', async () => {
    const resposta = await comAdmin(request(app).patch('/api/v1/universidades/7')).send({ descricao: ACIMA_DO_LIMITE });

    expect(resposta.status).toBe(400);
    expect(resposta.body.error.details).toContainEqual({ campo: 'descricao', mensagem: 'Use no máximo 10.000 caracteres' });
    expect(prisma.universidade.update).not.toHaveBeenCalled();
  });
});
