/**
 * Origens que o CORS aceita (RNF07). Com CORS_ORIGENS definida, vale a lista
 * dela (separada por vírgula). Sem ela, vale o APP_URL e, fora de produção,
 * também as origens locais do `flutter run` e do iniciar-demo.
 *
 * Requisições sem Origin (curl, a própria página /docs, outro servidor) não
 * passam pelo CORS e continuam funcionando.
 */
const ORIGENS_LOCAIS = ['http://localhost:8080', 'http://127.0.0.1:8080'];

function semBarraFinal(origem) {
  return origem.trim().replace(/\/+$/, '');
}

function origensPermitidas({ CORS_ORIGENS = '', APP_URL = '', NODE_ENV = 'development' } = {}) {
  const definidas = CORS_ORIGENS.split(',').map(semBarraFinal).filter(Boolean);
  if (definidas.length > 0) return [...new Set(definidas)];

  const padrao = APP_URL ? [semBarraFinal(new URL(APP_URL).origin)] : [];
  if (NODE_ENV !== 'production') padrao.push(...ORIGENS_LOCAIS);
  return [...new Set(padrao)];
}

module.exports = { origensPermitidas };
