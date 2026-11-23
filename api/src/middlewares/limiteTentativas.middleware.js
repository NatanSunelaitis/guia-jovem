const { rateLimit, ipKeyGenerator } = require('express-rate-limit');

const QUINZE_MINUTOS = 15 * 60 * 1000;

/**
 * Quantas tentativas uma mesma rede (IP) pode errar, somando todos os
 * e-mails, para cada falha permitida por conta: segura quem tenta muitas
 * contas da mesma máquina sem bloquear uma rede compartilhada (faculdade,
 * escola) onde várias pessoas erram a própria senha.
 */
const MULTIPLICADOR_POR_REDE = 10;

/** "1 minuto", "12 minutos": tempo até a janela do limite acabar. */
function tempoDeEspera(req) {
  const fim = req.rateLimit?.resetTime;
  const minutos = fim ? Math.max(1, Math.ceil((fim.getTime() - Date.now()) / 60000)) : 15;
  return minutos === 1 ? '1 minuto' : `${minutos} minutos`;
}

function responderBloqueio(texto) {
  return (req, res) => {
    res.status(429).json({
      error: { code: 'RATE_LIMITED', message: `${texto} Tente novamente em ${tempoDeEspera(req)}.`, details: [] },
    });
  };
}

/** E-mail como o login compara (sem espaços nas pontas e sem diferença de maiúsculas). */
function emailDaRequisicao(req) {
  const email = req.body?.email;
  return typeof email === 'string' ? email.trim().toLowerCase() : '';
}

// Só a senha ou o e-mail errados (401) contam; o login certo e os demais
// erros (validação, servidor) não gastam tentativas.
const falhouNasCredenciais = (req, res) => res.statusCode !== 401;

/**
 * 5.11: limite de tentativas de login. Conta só as falhas, por IP + e-mail
 * ([limite] falhas por conta a cada 15 minutos), e por IP no total
 * ([limite] x MULTIPLICADOR_POR_REDE falhas). O bloqueio informa em quanto
 * tempo a pessoa pode tentar de novo.
 */
function limitadorDeLogin({ limite, janelaMs = QUINZE_MINUTOS }) {
  const comum = {
    windowMs: janelaMs,
    standardHeaders: true,
    legacyHeaders: false,
    skipSuccessfulRequests: true,
    requestWasSuccessful: falhouNasCredenciais,
  };
  const porConta = rateLimit({
    ...comum,
    limit: limite,
    keyGenerator: (req) => `${ipKeyGenerator(req.ip)}|${emailDaRequisicao(req)}`,
    handler: responderBloqueio('Muitas tentativas de login sem sucesso nesta conta.'),
  });
  const porRede = rateLimit({
    ...comum,
    limit: limite * MULTIPLICADOR_POR_REDE,
    keyGenerator: (req) => ipKeyGenerator(req.ip),
    handler: responderBloqueio('Muitas tentativas de login sem sucesso nesta rede.'),
  });
  return [porRede, porConta];
}

/**
 * "Esqueci minha senha": cada pedido conta (ele envia e-mail), por IP, com
 * o mesmo limite e a mesma mensagem com o tempo de espera.
 */
function limitadorDeRecuperacao({ limite, janelaMs = QUINZE_MINUTOS }) {
  return rateLimit({
    windowMs: janelaMs,
    limit: limite,
    standardHeaders: true,
    legacyHeaders: false,
    handler: responderBloqueio('Muitos pedidos de recuperação de senha.'),
  });
}

module.exports = { limitadorDeLogin, limitadorDeRecuperacao, MULTIPLICADOR_POR_REDE };
