/**
 * Backup do banco (seção 5.3 do TG): mysqldump comprimido em gzip, com o
 * nome datado, e remoção dos backups mais antigos que a retenção. O envio
 * para um armazenamento compatível com S3 (como o Cloudflare R2) é opcional
 * e só acontece quando as quatro variáveis BACKUP_S3_* estão definidas; sem
 * elas, o backup fica só no arquivo local.
 *
 *   npm run backup
 *
 * Variáveis (além do DATABASE_URL do api/.env):
 *   BACKUP_DATABASE_URL       banco a copiar (padrão: DATABASE_URL)
 *   BACKUP_DIR                pasta dos arquivos (padrão: api/backups)
 *   BACKUP_RETENCAO_DIAS      dias que um backup local é mantido (padrão: 7)
 *   MYSQLDUMP_PATH            caminho do mysqldump (padrão: o do PATH)
 *   BACKUP_S3_ENDPOINT        ex.: https://<conta>.r2.cloudflarestorage.com
 *   BACKUP_S3_BUCKET, BACKUP_S3_ACCESS_KEY_ID, BACKUP_S3_SECRET_ACCESS_KEY
 *   BACKUP_S3_REGIAO          padrão: auto (o valor do R2)
 *   BACKUP_S3_PREFIXO         pasta dentro do bucket (padrão: guiajovem/)
 */
const crypto = require('crypto');
const fs = require('fs');
const os = require('os');
const path = require('path');
const zlib = require('zlib');
const { spawn } = require('child_process');
const { pipeline } = require('stream/promises');

const PREFIXO_ARQUIVO = 'guiajovem-';
const EXTENSAO = '.sql.gz';
const DIA_MS = 24 * 60 * 60 * 1000;

/** guiajovem-<banco>-AAAA-MM-DD_HHMMSS.sql.gz, na hora local do servidor. */
function nomeDoArquivo(banco, quando = new Date()) {
  const dois = (n) => String(n).padStart(2, '0');
  const data = `${quando.getFullYear()}-${dois(quando.getMonth() + 1)}-${dois(quando.getDate())}`;
  const hora = `${dois(quando.getHours())}${dois(quando.getMinutes())}${dois(quando.getSeconds())}`;
  return `${PREFIXO_ARQUIVO}${banco}-${data}_${hora}${EXTENSAO}`;
}

/** Arquivos de backup da pasta modificados há mais de `dias` dias. */
function arquivosVencidos(arquivos, dias, agora = Date.now()) {
  const limite = agora - dias * DIA_MS;
  return arquivos.filter(
    (arquivo) => arquivo.nome.startsWith(PREFIXO_ARQUIVO) && arquivo.nome.endsWith(EXTENSAO) && arquivo.modificadoEm < limite,
  );
}

function lerConfiguracao(env = process.env) {
  const url = env.BACKUP_DATABASE_URL || env.DATABASE_URL;
  if (!url) throw new Error('Defina BACKUP_DATABASE_URL ou DATABASE_URL.');
  const banco = new URL(url);
  const retencao = Number(env.BACKUP_RETENCAO_DIAS ?? 7);
  if (!Number.isInteger(retencao) || retencao < 1) throw new Error('BACKUP_RETENCAO_DIAS precisa ser um inteiro a partir de 1.');
  const s3 = ['BACKUP_S3_ENDPOINT', 'BACKUP_S3_BUCKET', 'BACKUP_S3_ACCESS_KEY_ID', 'BACKUP_S3_SECRET_ACCESS_KEY'];
  const definidas = s3.filter((nome) => env[nome]);
  if (definidas.length > 0 && definidas.length < s3.length) {
    throw new Error(`Envio externo incompleto: faltam ${s3.filter((nome) => !env[nome]).join(', ')}.`);
  }
  return {
    host: banco.hostname,
    porta: banco.port || '3306',
    usuario: decodeURIComponent(banco.username),
    senha: decodeURIComponent(banco.password),
    banco: banco.pathname.replace(/^\//, ''),
    pasta: path.resolve(env.BACKUP_DIR || path.join(__dirname, '..', '..', 'backups')),
    retencao,
    mysqldump: env.MYSQLDUMP_PATH || 'mysqldump',
    s3:
      definidas.length === s3.length
        ? {
            endpoint: env.BACKUP_S3_ENDPOINT.replace(/\/$/, ''),
            bucket: env.BACKUP_S3_BUCKET,
            chave: env.BACKUP_S3_ACCESS_KEY_ID,
            segredo: env.BACKUP_S3_SECRET_ACCESS_KEY,
            regiao: env.BACKUP_S3_REGIAO || 'auto',
            prefixo: env.BACKUP_S3_PREFIXO ?? 'guiajovem/',
          }
        : null,
  };
}

/** Roda o mysqldump com a senha num arquivo de opções temporário (fora da linha de comando). */
async function gerarDump(config, destino) {
  const opcoes = path.join(os.tmpdir(), `guiajovem-backup-${process.pid}.cnf`);
  fs.writeFileSync(opcoes, `[client]\nuser="${config.usuario}"\npassword="${config.senha}"\nhost="${config.host}"\nport=${config.porta}\n`, {
    mode: 0o600,
  });
  try {
    const processo = spawn(config.mysqldump, [
      `--defaults-extra-file=${opcoes}`,
      '--single-transaction',
      '--quick',
      '--routines',
      '--triggers',
      '--no-tablespaces',
      '--default-character-set=utf8mb4',
      config.banco,
    ]);
    let erros = '';
    processo.stderr.on('data', (trecho) => {
      erros += trecho.toString();
    });
    const terminou = new Promise((resolve, reject) => {
      processo.on('error', (erro) => reject(new Error(`não foi possível executar ${config.mysqldump}: ${erro.message}`)));
      processo.on('close', (codigo) => (codigo === 0 ? resolve() : reject(new Error(`mysqldump terminou com código ${codigo}: ${erros.trim()}`))));
    });
    await Promise.all([pipeline(processo.stdout, zlib.createGzip(), fs.createWriteStream(destino)), terminou]);
  } finally {
    fs.rmSync(opcoes, { force: true });
  }
}

function hmac(chave, texto) {
  return crypto.createHmac('sha256', chave).update(texto).digest();
}

/** PUT do arquivo no bucket, com a assinatura AWS Signature V4 (aceita pelo R2). */
async function enviarParaS3(s3, arquivo) {
  const corpo = fs.readFileSync(arquivo);
  const chaveObjeto = `${s3.prefixo}${path.basename(arquivo)}`;
  const url = new URL(`${s3.endpoint}/${s3.bucket}/${chaveObjeto.split('/').map(encodeURIComponent).join('/')}`);
  const agora = new Date().toISOString().replace(/[:-]|\.\d{3}/g, '');
  const dia = agora.slice(0, 8);
  const hashCorpo = crypto.createHash('sha256').update(corpo).digest('hex');
  const cabecalhos = { host: url.host, 'x-amz-content-sha256': hashCorpo, 'x-amz-date': agora };
  const nomes = Object.keys(cabecalhos).sort();
  const requisicaoCanonica = [
    'PUT',
    url.pathname,
    '',
    ...nomes.map((nome) => `${nome}:${cabecalhos[nome]}`),
    '',
    nomes.join(';'),
    hashCorpo,
  ].join('\n');
  const escopo = `${dia}/${s3.regiao}/s3/aws4_request`;
  const textoAssinado = ['AWS4-HMAC-SHA256', agora, escopo, crypto.createHash('sha256').update(requisicaoCanonica).digest('hex')].join('\n');
  const chaveAssinatura = hmac(hmac(hmac(hmac(`AWS4${s3.segredo}`, dia), s3.regiao), 's3'), 'aws4_request');
  const assinatura = crypto.createHmac('sha256', chaveAssinatura).update(textoAssinado).digest('hex');

  const resposta = await fetch(url, {
    method: 'PUT',
    // O fetch define o host sozinho; ele entra só na assinatura.
    headers: {
      'x-amz-content-sha256': hashCorpo,
      'x-amz-date': agora,
      'Content-Type': 'application/gzip',
      Authorization: `AWS4-HMAC-SHA256 Credential=${s3.chave}/${escopo}, SignedHeaders=${nomes.join(';')}, Signature=${assinatura}`,
    },
    body: corpo,
  });
  if (!resposta.ok) throw new Error(`envio externo respondeu ${resposta.status}: ${(await resposta.text()).slice(0, 300)}`);
  return chaveObjeto;
}

function aplicarRetencao(config) {
  const arquivos = fs.readdirSync(config.pasta).map((nome) => ({
    nome,
    modificadoEm: fs.statSync(path.join(config.pasta, nome)).mtimeMs,
  }));
  const vencidos = arquivosVencidos(arquivos, config.retencao);
  for (const arquivo of vencidos) fs.rmSync(path.join(config.pasta, arquivo.nome));
  return vencidos.map((arquivo) => arquivo.nome);
}

async function main() {
  require('dotenv').config({ path: path.join(__dirname, '..', '..', '.env') });
  const config = lerConfiguracao();
  fs.mkdirSync(config.pasta, { recursive: true });
  const destino = path.join(config.pasta, nomeDoArquivo(config.banco));

  console.log(`Backup de "${config.banco}" em ${config.host}:${config.porta}...`);
  try {
    await gerarDump(config, destino);
  } catch (erro) {
    fs.rmSync(destino, { force: true });
    throw erro;
  }
  const tamanho = fs.statSync(destino).size;
  console.log(`Arquivo: ${destino} (${(tamanho / 1024).toFixed(1)} KB)`);

  if (config.s3) {
    const chave = await enviarParaS3(config.s3, destino);
    console.log(`Enviado para o bucket ${config.s3.bucket}: ${chave}`);
  } else {
    console.log('Envio externo não configurado (BACKUP_S3_*): o backup ficou só no arquivo local.');
  }

  const removidos = aplicarRetencao(config);
  console.log(`Retenção de ${config.retencao} dias: ${removidos.length} backup(s) antigo(s) removido(s).`);
}

if (require.main === module) {
  main().catch((erro) => {
    console.error(`Backup falhou: ${erro.message}`);
    process.exitCode = 1;
  });
}

module.exports = { nomeDoArquivo, arquivosVencidos, lerConfiguracao };
