/**
 * Conferência de ponta a ponta: sobe a API contra um banco MySQL de teste
 * real, executa os fluxos dos três perfis e do visitante pela HTTP, confere
 * no banco o que a API não devolve (auditoria, visitas, hash da senha) e
 * termina com código 1 se algum ponto falhar.
 *
 * Uso: CONFERENCIA_DATABASE_URL=mysql://root:senha@127.0.0.1:3306/guiajovem_teste npm run conferencia
 *
 * O banco é APAGADO e recriado a cada execução (prisma migrate reset), por
 * isso o nome dele precisa terminar em _teste, _test ou _e2e.
 */
const path = require('path');
const { spawn, execFileSync } = require('child_process');

const { PrismaClient } = require('@prisma/client');

const { criarRoteiro } = require('./roteiro');

const RAIZ_API = path.join(__dirname, '..', '..');
const PRISMA_CLI = require.resolve('prisma/build/index.js');
const PORTA = Number(process.env.CONFERENCIA_PORTA || 3999);
const BASE = `http://127.0.0.1:${PORTA}/api/v1`;

const ADMIN = { nome: 'Administrador da Conferência', email: 'admin.conferencia@guiajovem.com.br', senha: 'senha-da-conferencia-1' };

function lerBanco() {
  const url = process.env.CONFERENCIA_DATABASE_URL;
  if (!url) {
    console.error('Defina CONFERENCIA_DATABASE_URL com um banco de teste (ex.: .../guiajovem_teste).');
    process.exit(2);
  }
  const nome = new URL(url).pathname.replace(/^\//, '');
  if (!/_(teste|test|e2e)$/.test(nome)) {
    console.error(`O banco "${nome}" não parece de teste. Use um nome terminado em _teste, _test ou _e2e: ele é apagado a cada execução.`);
    process.exit(2);
  }
  return { url, nome };
}

function ambienteDaApi(urlBanco) {
  return {
    ...process.env,
    NODE_ENV: 'development',
    PORT: String(PORTA),
    DATABASE_URL: urlBanco,
    JWT_ACCESS_SECRET: 'conferencia-access',
    JWT_REFRESH_SECRET: 'conferencia-refresh',
    JWT_ACCESS_EXPIRES_IN: '15m',
    JWT_REFRESH_EXPIRES_IN: '7d',
    SMTP_HOST: '',
    GOOGLE_CLIENT_ID: '',
    APP_URL: 'http://localhost:8080',
    LIMITE_TENTATIVAS_LOGIN: '1000',
    ADMIN_NOME: ADMIN.nome,
    ADMIN_EMAIL: ADMIN.email,
    ADMIN_SENHA: ADMIN.senha,
  };
}

function prepararBanco({ url, nome }) {
  const servidor = new URL(url);
  servidor.pathname = '/';
  console.log(`Recriando o banco "${nome}" em ${servidor.host}...`);
  execFileSync(process.execPath, [PRISMA_CLI, 'db', 'execute', '--url', servidor.toString(), '--stdin'], {
    input: `CREATE DATABASE IF NOT EXISTS \`${nome}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;`,
    stdio: ['pipe', 'inherit', 'inherit'],
    cwd: RAIZ_API,
  });
  const env = ambienteDaApi(url);
  execFileSync(process.execPath, [PRISMA_CLI, 'migrate', 'reset', '--force', '--skip-seed', '--skip-generate'], {
    env,
    stdio: 'inherit',
    cwd: RAIZ_API,
  });
  execFileSync(process.execPath, ['prisma/seed.js'], { env, stdio: 'inherit', cwd: RAIZ_API });
}

/** Sobe `node src/server.js` e guarda a saída (o e-mail sem SMTP sai no log). */
function subirApi(urlBanco) {
  const log = [];
  const processo = spawn(process.execPath, ['src/server.js'], { env: ambienteDaApi(urlBanco), cwd: RAIZ_API });
  processo.stdout.on('data', (trecho) => log.push(trecho.toString()));
  processo.stderr.on('data', (trecho) => log.push(trecho.toString()));
  return { processo, log };
}

async function esperarApi(processo) {
  const limite = Date.now() + 30000;
  while (Date.now() < limite) {
    if (processo.exitCode !== null) throw new Error(`a API encerrou com código ${processo.exitCode}`);
    try {
      const resposta = await fetch(`${BASE}/health`);
      if (resposta.ok) return;
    } catch {
      // ainda subindo
    }
    await new Promise((resolve) => setTimeout(resolve, 300));
  }
  throw new Error('a API não respondeu em 30 segundos');
}

/** Cliente HTTP mínimo: devolve status, corpo JSON (ou texto) e cabeçalhos. */
function criarCliente() {
  return async function chamar(metodo, caminho, { token, corpo, cru = false } = {}) {
    const resposta = await fetch(`${BASE}${caminho}`, {
      method: metodo,
      headers: {
        ...(corpo !== undefined ? { 'Content-Type': 'application/json' } : {}),
        ...(token ? { Authorization: `Bearer ${token}` } : {}),
      },
      body: corpo !== undefined ? JSON.stringify(corpo) : undefined,
    });
    const tipo = resposta.headers.get('content-type') || '';
    let dados;
    if (cru) dados = Buffer.from(await resposta.arrayBuffer());
    else if (tipo.includes('application/json')) dados = await resposta.json();
    else dados = await resposta.text();
    return { status: resposta.status, corpo: dados, tipo, cabecalhos: resposta.headers };
  };
}

async function main() {
  const banco = lerBanco();
  prepararBanco(banco);

  const { processo, log } = subirApi(banco.url);
  const prisma = new PrismaClient({ datasources: { db: { url: banco.url } } });
  const resultados = [];

  try {
    await esperarApi(processo);
    const roteiro = criarRoteiro({ chamar: criarCliente(), prisma, log, admin: ADMIN, base: BASE });

    for (const [indice, { nome, executar }] of roteiro.entries()) {
      const numero = String(indice + 1).padStart(2, '0');
      try {
        await executar();
        resultados.push({ numero, nome, ok: true });
        console.log(`  ok   ${numero}. ${nome}`);
      } catch (erro) {
        resultados.push({ numero, nome, ok: false, erro: erro.message });
        console.log(`  FALHA ${numero}. ${nome}\n         ${erro.message}`);
      }
    }
  } finally {
    processo.kill();
    await prisma.$disconnect();
  }

  const falhas = resultados.filter((resultado) => !resultado.ok);
  console.log(`\n${resultados.length - falhas.length} de ${resultados.length} pontos conferidos.`);
  if (falhas.length > 0) {
    console.log(`Falharam: ${falhas.map((falha) => falha.numero).join(', ')}`);
    const ultimas = log.join('').split('\n').slice(-30).join('\n');
    console.log(`\nÚltimas linhas do log da API:\n${ultimas}`);
    process.exitCode = 1;
  }
}

main().catch((erro) => {
  console.error(erro);
  process.exitCode = 1;
});
