/**
 * Dados da apresentação: `npm run db:demo`, separado do seed.
 *
 *   DEMO_DATABASE_URL=mysql://root:senha@127.0.0.1:3306/guiajovem_demo npm run db:demo
 *
 * Cria o banco se não existir e aplica as migrations. Se o banco já tiver
 * qualquer usuário ou universidade, para sem alterar nada, a menos que o
 * comando receba `-- --substituir`: aí o banco é APAGADO (prisma migrate
 * reset) e recriado só com os dados de dados.js.
 *
 * Sugestões, pesquisas salvas e faculdades salvas ficam vazias (são criadas
 * ao vivo). Senha de todas as contas: DEMO_SENHA (padrão abaixo).
 */
const path = require('path');
const { execFileSync } = require('child_process');

const bcrypt = require('bcryptjs');
const { PrismaClient } = require('@prisma/client');

const dados = require('./dados');

const RAIZ_API = path.join(__dirname, '..', '..');
const PRISMA_CLI = require.resolve('prisma/build/index.js');
const SENHA_PADRAO = 'Demo@2026';
const DIA_MS = 24 * 60 * 60 * 1000;

function lerAlvo() {
  const url = process.env.DEMO_DATABASE_URL;
  if (!url) {
    console.error('Defina DEMO_DATABASE_URL com o banco que vai receber os dados de demonstração.');
    process.exit(2);
  }
  const nome = new URL(url).pathname.replace(/^\//, '');
  if (!nome) {
    console.error('DEMO_DATABASE_URL precisa apontar para um banco, ex.: mysql://.../guiajovem_demo');
    process.exit(2);
  }
  return { url, nome, substituir: process.argv.includes('--substituir') };
}

function prisma(args, url) {
  execFileSync(process.execPath, [PRISMA_CLI, ...args], {
    env: { ...process.env, DATABASE_URL: url },
    stdio: 'inherit',
    cwd: RAIZ_API,
  });
}

function criarBancoSeFaltar({ url, nome }) {
  const servidor = new URL(url);
  servidor.pathname = '/';
  execFileSync(process.execPath, [PRISMA_CLI, 'db', 'execute', '--url', servidor.toString(), '--stdin'], {
    input: `CREATE DATABASE IF NOT EXISTS \`${nome}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;`,
    stdio: ['pipe', 'inherit', 'inherit'],
    cwd: RAIZ_API,
  });
}

const data = (texto) => new Date(`${texto}T00:00:00Z`);

async function criarEventos(cliente, programaId, eventos = []) {
  for (const evento of eventos) {
    await cliente.programaEvento.create({
      data: {
        programaId,
        titulo: evento.titulo,
        descricao: evento.descricao ?? null,
        dataInicio: data(evento.dataInicio),
        dataFim: evento.dataFim ? data(evento.dataFim) : null,
      },
    });
  }
}

async function criarContaUniversidade(cliente, instituicao, senhaHash, status, extras = {}) {
  const usuario = await cliente.usuario.create({
    data: { nome: instituicao.responsavel, email: instituicao.email, senhaHash, tipoUsuario: 'U' },
  });
  const universidade = await cliente.universidade.create({
    data: {
      usuarioId: usuario.id,
      nomeFantasia: instituicao.nomeFantasia,
      razaoSocial: instituicao.razaoSocial,
      cnpj: instituicao.cnpj,
      natureza: instituicao.natureza,
      descricao: instituicao.descricao,
      telefonePrincipal: instituicao.telefonePrincipal,
      linkPagina: instituicao.linkPagina,
      linkSimulados: instituicao.linkSimulados ?? null,
      status,
      ...extras,
    },
  });
  return { usuario, universidade };
}

async function criarCampus(cliente, universidadeId, campus, principal) {
  const endereco = await cliente.endereco.create({ data: { complemento: null, ...campus.endereco } });
  return cliente.campus.create({
    data: {
      universidadeId,
      enderecoId: endereco.id,
      nome: campus.nome,
      principal,
      telefoneFixo: campus.telefoneFixo ?? null,
      telefoneCelular: campus.telefoneCelular ?? null,
      emailCampus: campus.emailCampus ?? null,
    },
  });
}

/** Visitas e logins dos últimos 30 dias, para o dashboard não abrir vazio. */
async function criarHistoricoDeAcesso(cliente, { universidades, programas, cursos, contas }) {
  const hoje = Date.now();
  let semente = 7;
  const sortear = (limite) => {
    semente = (semente * 48271) % 2147483647;
    return semente % limite;
  };
  const visitas = [];
  const logins = [];
  for (let dia = 29; dia >= 0; dia -= 1) {
    const base = hoje - dia * DIA_MS;
    const quantidade = 6 + sortear(10) + (dia % 7 < 2 ? 0 : 4);
    for (let i = 0; i < quantidade; i += 1) {
      const quando = new Date(base - sortear(10 * 60) * 60 * 1000);
      const perfil = [null, null, null, 'A', 'A', 'U', 'D'][sortear(7)];
      const sorteio = sortear(10);
      if (sorteio < 2) visitas.push({ rota: '/', entidade: 'home', entidadeId: null, tipoUsuario: perfil, criadoEm: quando });
      else if (sorteio < 6) {
        const u = universidades[sortear(universidades.length)];
        visitas.push({ rota: `/universidades/${u.id}`, entidade: 'universidade', entidadeId: u.id, tipoUsuario: perfil, criadoEm: quando });
      } else if (sorteio < 8) {
        const p = programas[sortear(programas.length)];
        visitas.push({ rota: `/programas/${p.id}`, entidade: 'programa', entidadeId: p.id, tipoUsuario: perfil, criadoEm: quando });
      } else {
        const c = cursos[sortear(cursos.length)];
        visitas.push({ rota: `/cursos/${c.id}`, entidade: 'curso', entidadeId: c.id, tipoUsuario: perfil, criadoEm: quando });
      }
    }
    for (const conta of contas) {
      if (sortear(3) === 0) {
        logins.push({ usuarioId: conta.id, acao: 'LOGIN', entidade: 'usuario', entidadeId: conta.id, criadoEm: new Date(base - sortear(8 * 60) * 60 * 1000) });
      }
    }
  }
  await cliente.visitaPagina.createMany({ data: visitas });
  await cliente.logAuditoria.createMany({ data: logins });
  return { visitas: visitas.length, logins: logins.length };
}

async function popular(cliente, senha) {
  const senhaHash = await bcrypt.hash(senha, 12);
  const agora = new Date();

  const admin = await cliente.usuario.create({
    data: { ...dados.CONTAS.admin, senhaHash, tipoUsuario: 'D' },
  });
  const alunos = {};
  for (const aluno of dados.CONTAS.alunos) {
    alunos[aluno.chave] = await cliente.usuario.create({
      data: { nome: aluno.nome, email: aluno.email, senhaHash, tipoUsuario: 'A' },
    });
  }

  const programas = {};
  for (const { eventos, ...programa } of dados.PROGRAMAS) {
    const criado = await cliente.programa.create({ data: { ...programa, usuarioId: admin.id } });
    programas[programa.sigla] = criado;
    await criarEventos(cliente, criado.id, eventos);
  }

  const universidades = {};
  const contasUniversidade = [];
  const todosCursos = [];
  for (const instituicao of dados.UNIVERSIDADES) {
    const { usuario, universidade } = await criarContaUniversidade(cliente, instituicao, senhaHash, 'A', {
      aprovadoEm: new Date(agora.getTime() - 20 * DIA_MS),
      aprovadoPor: admin.id,
    });
    universidades[instituicao.chave] = universidade;
    contasUniversidade.push(usuario);

    const campi = [];
    for (const campus of instituicao.campi) campi.push(await criarCampus(cliente, universidade.id, campus, campus.principal));

    for (const { ofertas, ...curso } of instituicao.cursos) {
      const criado = await cliente.curso.create({ data: { ...curso, universidadeId: universidade.id } });
      todosCursos.push(criado);
      for (const oferta of ofertas) {
        await cliente.campusCurso.create({
          data: { campusId: campi[oferta.campus].id, cursoId: criado.id, turno: oferta.turno, vagas: oferta.vagas },
        });
      }
    }

    for (const [sigla, observacao] of Object.entries(instituicao.programas)) {
      await cliente.universidadePrograma.create({
        data: { universidadeId: universidade.id, programaId: programas[sigla].id, observacao },
      });
    }

    for (const { eventos, ...bolsa } of instituicao.bolsas) {
      const criada = await cliente.programa.create({
        data: { ...bolsa, tipo: 'BOLSA', usuarioId: usuario.id, universidadeId: universidade.id },
      });
      await criarEventos(cliente, criada.id, eventos);
    }
  }

  // Avaliações e a média de cada universidade, como o RF01 grava.
  for (const avaliacao of dados.AVALIACOES) {
    await cliente.avaliacao.create({
      data: {
        usuarioId: alunos[avaliacao.aluno].id,
        universidadeId: universidades[avaliacao.universidade].id,
        nota: avaliacao.nota,
        comentario: avaliacao.comentario,
      },
    });
  }
  for (const universidade of Object.values(universidades)) {
    const agregado = await cliente.avaliacao.aggregate({
      where: { universidadeId: universidade.id },
      _avg: { nota: true },
      _count: { _all: true },
    });
    await cliente.universidade.update({
      where: { id: universidade.id },
      data: {
        mediaAvaliacao: agregado._count._all > 0 ? agregado._avg.nota.toFixed(2) : null,
        totalAvaliacoes: agregado._count._all,
      },
    });
  }

  // Pendente e reprovada, com as notificações que o fluxo real gera.
  const pendente = dados.UNIVERSIDADE_PENDENTE;
  const criadaPendente = await criarContaUniversidade(cliente, pendente, senhaHash, 'P');
  await criarCampus(cliente, criadaPendente.universidade.id, pendente.campus, true);
  for (const sigla of pendente.programas) {
    await cliente.universidadePrograma.create({ data: { universidadeId: criadaPendente.universidade.id, programaId: programas[sigla].id } });
  }
  await cliente.notificacao.create({
    data: {
      usuarioId: admin.id,
      tipo: 'UNIVERSIDADE_PENDENTE',
      titulo: 'Nova universidade aguardando aprovação',
      mensagem: `${pendente.nomeFantasia} enviou um cadastro para análise.`,
      referenciaTipo: 'universidade',
      referenciaId: criadaPendente.universidade.id,
    },
  });

  const reprovada = dados.UNIVERSIDADE_REPROVADA;
  const criadaReprovada = await criarContaUniversidade(cliente, reprovada, senhaHash, 'R', { motivoReprovacao: reprovada.motivo });
  await criarCampus(cliente, criadaReprovada.universidade.id, reprovada.campus, true);
  for (const sigla of reprovada.programas) {
    await cliente.universidadePrograma.create({ data: { universidadeId: criadaReprovada.universidade.id, programaId: programas[sigla].id } });
  }
  await cliente.notificacao.create({
    data: {
      usuarioId: criadaReprovada.usuario.id,
      tipo: 'UNIVERSIDADE_REPROVADA',
      titulo: 'Cadastro reprovado',
      mensagem: `Motivo: ${reprovada.motivo}`.slice(0, 255),
      referenciaTipo: 'universidade',
      referenciaId: criadaReprovada.universidade.id,
    },
  });

  const historico = await criarHistoricoDeAcesso(cliente, {
    universidades: Object.values(universidades),
    programas: Object.values(programas),
    cursos: todosCursos,
    contas: [admin, ...Object.values(alunos), ...contasUniversidade],
  });

  return { admin, alunos, universidades, historico, cursos: todosCursos.length };
}

async function main() {
  const alvo = lerAlvo();
  const senha = process.env.DEMO_SENHA || SENHA_PADRAO;
  if (senha.length < 7) {
    console.error('DEMO_SENHA precisa ter 7 ou mais caracteres, como as senhas do cadastro.');
    process.exit(2);
  }

  console.log(`Banco de demonstração: "${alvo.nome}" em ${new URL(alvo.url).host}`);
  criarBancoSeFaltar(alvo);
  prisma(['migrate', 'deploy'], alvo.url);

  const cliente = new PrismaClient({ datasources: { db: { url: alvo.url } } });
  try {
    const [usuarios, universidades] = await Promise.all([cliente.usuario.count(), cliente.universidade.count()]);
    if (usuarios + universidades > 0) {
      if (!alvo.substituir) {
        console.error(
          `\nO banco "${alvo.nome}" já tem dados (${usuarios} usuários, ${universidades} universidades). Nada foi alterado.\n` +
            'Para APAGAR tudo e gravar só os dados de demonstração, rode: npm run db:demo -- --substituir',
        );
        process.exitCode = 1;
        return;
      }
      await cliente.$disconnect();
      console.log(`Apagando o banco "${alvo.nome}" (--substituir)...`);
      prisma(['migrate', 'reset', '--force', '--skip-seed', '--skip-generate'], alvo.url);
      await cliente.$connect();
    }

    const resultado = await popular(cliente, senha);
    console.log('\nDados de demonstração gravados.');
    console.log(`  ${Object.keys(resultado.universidades).length} universidades aprovadas, 1 pendente e 1 reprovada; ${resultado.cursos} cursos`);
    console.log(`  ${dados.PROGRAMAS.length} programas globais; ${dados.AVALIACOES.length} avaliações`);
    console.log(`  ${resultado.historico.visitas} visitas e ${resultado.historico.logins} logins nos últimos 30 dias (ilustrativos)`);
    console.log(`\nContas (senha: ${process.env.DEMO_SENHA ? 'a de DEMO_SENHA' : SENHA_PADRAO}):`);
    console.log(`  Administrador  ${dados.CONTAS.admin.email}`);
    for (const aluno of dados.CONTAS.alunos) console.log(`  Aluno          ${aluno.email}`);
    for (const u of dados.UNIVERSIDADES) console.log(`  Universidade   ${u.email} (${u.nomeFantasia})`);
    console.log(`  Pendente       ${dados.UNIVERSIDADE_PENDENTE.email}`);
    console.log(`  Reprovada      ${dados.UNIVERSIDADE_REPROVADA.email}`);
  } finally {
    await cliente.$disconnect();
  }
}

main().catch((erro) => {
  console.error(erro);
  process.exitCode = 1;
});
