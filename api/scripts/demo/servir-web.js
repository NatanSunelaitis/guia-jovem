/**
 * Servidor estático mínimo para o build web do app (app/build/web), usado
 * pelo iniciar-demo.cmd. Caminho desconhecido devolve o index.html.
 *
 *   node scripts/demo/servir-web.js <pasta do build> <porta>
 */
const fs = require('fs');
const http = require('http');
const path = require('path');

const TIPOS = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'text/javascript; charset=utf-8',
  '.mjs': 'text/javascript; charset=utf-8',
  '.json': 'application/json',
  '.css': 'text/css',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.webp': 'image/webp',
  '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon',
  '.otf': 'font/otf',
  '.ttf': 'font/ttf',
  '.woff2': 'font/woff2',
  '.wasm': 'application/wasm',
};

const [pasta, porta = '8080'] = process.argv.slice(2);
const raiz = path.resolve(pasta || path.join(__dirname, '..', '..', '..', 'app', 'build', 'web'));
const indice = path.join(raiz, 'index.html');
if (!fs.existsSync(indice)) {
  console.error(`Build não encontrado em ${raiz}. Rode flutter build web antes.`);
  process.exit(1);
}

http
  .createServer((req, res) => {
    let arquivo = path.join(raiz, decodeURIComponent(req.url.split('?')[0]));
    if (!arquivo.startsWith(raiz) || !fs.existsSync(arquivo) || fs.statSync(arquivo).isDirectory()) arquivo = indice;
    res.writeHead(200, {
      'Content-Type': TIPOS[path.extname(arquivo).toLowerCase()] || 'application/octet-stream',
      'Cache-Control': 'no-cache',
    });
    fs.createReadStream(arquivo).pipe(res);
  })
  .listen(Number(porta), () => console.log(`App em http://localhost:${porta}`));
