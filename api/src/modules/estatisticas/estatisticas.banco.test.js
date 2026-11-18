/**
 * Confere os números do dashboard (RF16) contra um MySQL real, com dados
 * conhecidos gravados numa transação que é desfeita no fim: o banco fica
 * como estava. Roda na CI (que aplica as migrations antes dos testes) e
 * localmente com TESTE_BANCO_REAL=1 e o DATABASE_URL do banco de
 * desenvolvimento. Os totais do resumo são conferidos pela diferença
 * antes/depois, e as visitas e os logins num período de 2001 que nenhum
 * dado real alcança.
 */
const { PrismaClient } = require('@prisma/client');

const service = require('./estatisticas.service');

const bancoReal = process.env.TESTE_BANCO_REAL === '1';
const descrever = bancoReal ? describe : describe.skip;

const DESFAZER = new Error('desfazer a transação do teste');

let prisma;

beforeAll(() => {
  if (bancoReal) prisma = new PrismaClient({ datasources: { db: { url: process.env.DATABASE_URL } } });
});

afterAll(async () => {
  if (prisma) await prisma.$disconnect();
});

/** Roda `fn` numa transação e desfaz tudo no fim, mesmo quando passa. */
async function emTransacaoDesfeita(fn) {
  try {
    await prisma.$transaction(
      async (tx) => {
        await fn(tx);
        throw DESFAZER;
      },
      { timeout: 30000 },
    );
  } catch (erro) {
    if (erro !== DESFAZER) throw erro;
  }
}

let sequencia = 0;
function unico() {
  sequencia += 1;
  return `${Date.now()}${sequencia}`.slice(-10);
}

async function criarUsuario(tx, tipoUsuario) {
  return tx.usuario.create({ data: { nome: 'Teste', email: `teste-${unico()}@exemplo.com`, tipoUsuario } });
}

async function criarUniversidade(tx, status, nomeFantasia = 'Universidade Teste') {
  return tx.universidade.create({
    data: { nomeFantasia, razaoSocial: 'Teste S.A.', cnpj: `9${unico()}`.padEnd(14, '0').slice(0, 14), status },
  });
}

const em = (dataHoraUtc) => new Date(dataHoraUtc);

descrever('Estatísticas contra o MySQL real', () => {
  it('resumo: soma exatamente o que foi cadastrado', async () => {
    await emTransacaoDesfeita(async (tx) => {
      const antes = await service.resumo(tx);

      const admin = await criarUsuario(tx, 'D');
      await criarUsuario(tx, 'A');
      await criarUsuario(tx, 'A');
      const aprovada = await criarUniversidade(tx, 'A');
      await criarUniversidade(tx, 'P');
      await criarUniversidade(tx, 'R');
      await tx.curso.create({ data: { universidadeId: aprovada.id, nome: 'ADS' } });
      await tx.curso.create({ data: { universidadeId: aprovada.id, nome: 'Inativo', ativo: false } });
      await tx.programa.create({ data: { nome: 'P1', descricao: 'x', tipo: 'ENTRADA', usuarioId: admin.id } });
      await tx.programa.create({ data: { nome: 'P2', descricao: 'x', tipo: 'BOLSA', usuarioId: admin.id } });
      await tx.programa.create({ data: { nome: 'P3', descricao: 'x', tipo: 'BOLSA', usuarioId: admin.id, ativo: false } });

      const depois = await service.resumo(tx);

      expect(depois.usuariosPorPerfil.A - antes.usuariosPorPerfil.A).toBe(2);
      expect(depois.usuariosPorPerfil.D - antes.usuariosPorPerfil.D).toBe(1);
      expect(depois.usuariosPorPerfil.total - antes.usuariosPorPerfil.total).toBe(3);
      expect(depois.universidadesPorStatus.A - antes.universidadesPorStatus.A).toBe(1);
      expect(depois.universidadesPorStatus.P - antes.universidadesPorStatus.P).toBe(1);
      expect(depois.universidadesPorStatus.R - antes.universidadesPorStatus.R).toBe(1);
      expect(depois.universidadesPorStatus.I - antes.universidadesPorStatus.I).toBe(0);
      // Curso e programa excluídos (ativo=false) não contam.
      expect(depois.cursos - antes.cursos).toBe(1);
      expect(depois.programasPorTipo.ENTRADA - antes.programasPorTipo.ENTRADA).toBe(1);
      expect(depois.programasPorTipo.BOLSA - antes.programasPorTipo.BOLSA).toBe(1);
    });
  });

  it('visitas e logins únicos por dia, no fuso de Brasília', async () => {
    await emTransacaoDesfeita(async (tx) => {
      await tx.visitaPagina.createMany({
        data: [
          // 10/03/2001 em Brasília: 03:00 UTC até 02:59 UTC do dia 11.
          { rota: '/', entidade: 'home', criadoEm: em('2001-03-10T03:00:00Z') },
          { rota: '/', entidade: 'home', criadoEm: em('2001-03-11T02:59:00Z'), tipoUsuario: 'A' },
          // 02:00 UTC do dia 10 ainda é 09/03 em Brasília: fora do período.
          { rota: '/', entidade: 'home', criadoEm: em('2001-03-10T02:00:00Z') },
          { rota: '/x', entidade: 'home', criadoEm: em('2001-03-12T15:00:00Z') },
        ],
      });
      await tx.logAuditoria.createMany({
        data: [
          // Conta 1 entra duas vezes no dia 10 e uma no 12; conta 2 só no dia 12.
          { acao: 'LOGIN', entidade: 'usuario', entidadeId: 900001, criadoEm: em('2001-03-10T12:00:00Z') },
          { acao: 'LOGIN', entidade: 'usuario', entidadeId: 900001, criadoEm: em('2001-03-10T18:00:00Z') },
          { acao: 'LOGIN', entidade: 'usuario', entidadeId: 900001, criadoEm: em('2001-03-12T12:00:00Z') },
          { acao: 'LOGIN', entidade: 'usuario', entidadeId: 900002, criadoEm: em('2001-03-12T13:00:00Z') },
          // Não é login: não conta.
          { acao: 'LOGOUT', entidade: 'usuario', entidadeId: 900003, criadoEm: em('2001-03-12T14:00:00Z') },
        ],
      });

      const resultado = await service.visitas(tx, { de: '2001-03-10', ate: '2001-03-12' });

      expect(resultado.serie).toEqual([
        { periodo: '2001-03-10', visitas: 2, loginsUnicos: 1 },
        { periodo: '2001-03-11', visitas: 0, loginsUnicos: 0 },
        { periodo: '2001-03-12', visitas: 1, loginsUnicos: 2 },
      ]);
      expect(resultado.totalVisitas).toBe(3);
      // Contas distintas no período, não a soma dos dias (1 + 0 + 2).
      expect(resultado.loginsUnicos).toBe(2);
      expect(resultado.visitasPorPerfil).toEqual({ visitante: 2, A: 1, U: 0, D: 0 });

      const porMes = await service.visitas(tx, { de: '2001-03-01', ate: '2001-03-31', agrupar: 'mes' });
      expect(porMes.serie).toEqual([{ periodo: '2001-03', visitas: 4, loginsUnicos: 2 }]);
    });
  });

  it('ranking: mais acessados do período, em ordem, com o nome', async () => {
    await emTransacaoDesfeita(async (tx) => {
      const admin = await criarUsuario(tx, 'D');
      const primeira = await criarUniversidade(tx, 'A', 'Primeira Teste');
      const segunda = await criarUniversidade(tx, 'A', 'Segunda Teste');
      const programa = await tx.programa.create({
        data: { nome: 'Programa Teste', sigla: 'PT', descricao: 'x', tipo: 'ENTRADA', usuarioId: admin.id },
      });
      const visita = (entidade, entidadeId, dia) => ({
        rota: '/x',
        entidade,
        entidadeId,
        criadoEm: em(`2001-04-${dia}T12:00:00Z`),
      });
      await tx.visitaPagina.createMany({
        data: [
          visita('universidade', segunda.id, '10'),
          visita('universidade', segunda.id, '11'),
          visita('universidade', segunda.id, '12'),
          visita('universidade', primeira.id, '10'),
          // Fora do período: não muda a ordem.
          visita('universidade', primeira.id, '20'),
          visita('universidade', primeira.id, '21'),
          visita('universidade', primeira.id, '22'),
          visita('programa', programa.id, '11'),
        ],
      });

      const resultado = await service.ranking(tx, { de: '2001-04-10', ate: '2001-04-12' });

      expect(resultado.universidades).toEqual([
        { id: segunda.id, nome: 'Segunda Teste', visitas: 3 },
        { id: primeira.id, nome: 'Primeira Teste', visitas: 1 },
      ]);
      expect(resultado.programas).toEqual([{ id: programa.id, nome: 'PT', visitas: 1 }]);
      expect(resultado.cursos).toEqual([]);
    });
  });
});
