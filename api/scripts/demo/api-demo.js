/**
 * Sobe a API contra o banco de demonstração. Os e-mails vão para a caixa de
 * testes local (MailDev) na porta SMTP dada; sem ela, vão para o log. Usado
 * pelo iniciar-demo.cmd; as variáveis definidas aqui vencem as do api/.env,
 * que continua fornecendo os segredos do JWT.
 *
 *   node scripts/demo/api-demo.js <porta> [url do app] [porta SMTP da caixa de testes] [limite de login]
 *
 * O limite de tentativas de login sem sucesso (LIMITE_TENTATIVAS_LOGIN) sobe
 * para 500 por padrão: ensaios e capturas fazem muitos logins seguidos. Só
 * vale para a demonstração; em produção o padrão é 10 em 15 minutos.
 *   node scripts/demo/api-demo.js --conferir   (só confere o banco)
 *
 * Banco: DEMO_DATABASE_URL, ou o DATABASE_URL do api/.env com o nome trocado
 * para guiajovem_demo.
 */
const path = require('path');

const RAIZ_API = path.join(__dirname, '..', '..');
require('dotenv').config({ path: path.join(RAIZ_API, '.env') });

function urlDoBancoDemo(env = process.env) {
  if (env.DEMO_DATABASE_URL) return env.DEMO_DATABASE_URL;
  if (!env.DATABASE_URL) throw new Error('Defina DEMO_DATABASE_URL ou DATABASE_URL no api/.env.');
  const url = new URL(env.DATABASE_URL);
  url.pathname = '/guiajovem_demo';
  return url.toString();
}

/** Confere se o banco responde, tem as migrations e os dados (código 1 se não). */
async function conferirBanco() {
  const { PrismaClient } = require('@prisma/client');
  const url = urlDoBancoDemo();
  const nome = new URL(url).pathname.replace(/^\//, '');
  const prisma = new PrismaClient({ datasources: { db: { url } } });
  try {
    const [usuarios, universidades] = await Promise.all([prisma.usuario.count(), prisma.universidade.count()]);
    if (usuarios === 0 || universidades === 0) {
      console.error(`O banco "${nome}" está vazio. Rode na pasta api: npm run db:demo`);
      return 1;
    }
    console.log(`Banco "${nome}": ${usuarios} contas e ${universidades} universidades.`);
    return 0;
  } catch (erro) {
    console.error(`Não foi possível usar o banco "${nome}": ${erro.message.split('\n').filter(Boolean).pop()}`);
    console.error('Confira se o MySQL está no ar e, se o banco não existir, rode na pasta api: npm run db:demo');
    return 1;
  } finally {
    await prisma.$disconnect();
  }
}

if (require.main === module && process.argv[2] === '--conferir') {
  conferirBanco().then((codigo) => {
    process.exitCode = codigo;
  });
} else if (require.main === module) {
  const [porta = '3000', appUrl = 'http://localhost:8080', portaSmtp = '', limiteLogin = '500'] = process.argv.slice(2);
  process.env.DATABASE_URL = urlDoBancoDemo();
  process.env.PORT = porta;
  process.env.NODE_ENV = 'development';
  // Caixa de testes local (sem usuário e senha) ou, sem ela, o log.
  process.env.SMTP_HOST = portaSmtp ? '127.0.0.1' : '';
  process.env.SMTP_PORT = portaSmtp || '587';
  process.env.SMTP_USER = '';
  process.env.SMTP_PASSWORD = '';
  process.env.APP_URL = appUrl;
  process.env.LIMITE_TENTATIVAS_LOGIN = limiteLogin;
  // O CORS aceita só a origem do app servido pelo iniciar-demo (com localhost e 127.0.0.1).
  process.env.CORS_ORIGENS = [appUrl, appUrl.replace('localhost', '127.0.0.1')].join(',');
  process.chdir(RAIZ_API);
  require(path.join(RAIZ_API, 'src', 'server.js'));
}

module.exports = { urlDoBancoDemo };
