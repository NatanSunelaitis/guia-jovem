/**
 * Garante que o banco de dados do DATABASE_URL exista, criando-o se
 * necessário. Usado por `npm run db:local` para validar a Fase 0/1 sem
 * Docker, contra um MySQL 8 já instalado localmente (ex.: serviço
 * "MySQL80" do Windows).
 */
require('dotenv').config();

const path = require('path');
const { execFileSync } = require('child_process');

const PRISMA_CLI = require.resolve('prisma/build/index.js');

function main() {
  const databaseUrl = process.env.DATABASE_URL;
  if (!databaseUrl) {
    console.error('DATABASE_URL não definida. Copie api/.env.example para api/.env e preencha a senha.');
    process.exit(1);
  }

  const urlBanco = new URL(databaseUrl);
  const nomeBanco = urlBanco.pathname.replace(/^\//, '');

  if (!nomeBanco) {
    console.error('DATABASE_URL precisa apontar para um banco, ex.: mysql://.../guiajovem');
    process.exit(1);
  }

  // Sem path: conecta só no servidor, sem selecionar nenhum banco. O Prisma
  // recusa rodar `db execute` contra o banco de sistema "mysql" (erro P3004),
  // e CREATE DATABASE não precisa de um banco selecionado.
  const urlServidor = new URL(databaseUrl);
  urlServidor.pathname = '/';

  const sql = `CREATE DATABASE IF NOT EXISTS \`${nomeBanco}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;`;

  console.log(`Garantindo que o banco "${nomeBanco}" existe em ${urlBanco.host}...`);

  execFileSync(process.execPath, [PRISMA_CLI, 'db', 'execute', '--url', urlServidor.toString(), '--stdin'], {
    input: sql,
    stdio: ['pipe', 'inherit', 'inherit'],
    cwd: path.join(__dirname, '..'),
  });

  console.log(`Banco "${nomeBanco}" pronto.`);
}

main();
