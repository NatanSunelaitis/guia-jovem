const env = require('../../config/env');

/** Escapa texto vindo do cadastro antes de pôr no HTML do e-mail. */
function escaparHtml(texto) {
  return String(texto ?? '')
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}

/** Endereço do app sem a barra final, para montar os links dos botões. */
function urlDoApp(caminho = '') {
  return `${String(env.APP_URL).replace(/\/+$/, '')}${caminho}`;
}

const COR = {
  primaria: '#0061A4',
  texto: '#1A1C1C',
  secundario: '#404752',
  fundo: '#F3F3F3',
  cartao: '#FFFFFF',
  borda: '#E2E2E2',
  destaque: '#FFF4E5',
};

/**
 * E-mail do Guia Jovem em HTML de tabelas com estilos em linha (o que Gmail,
 * Outlook, Apple Mail e os webmails aceitam), com o logo em PNG hospedado no
 * próprio app, título, parágrafos, um quadro de destaque opcional (ex.: o
 * motivo da reprovação), botão de ação com o link também em texto e rodapé.
 * Devolve também a versão em texto puro, para clientes que não mostram HTML.
 *
 * [paragrafos] e [destaque] são texto puro: o modelo escapa tudo. Use
 * {forte: 'texto'} dentro de um parágrafo (array) para negrito.
 */
function montarEmail({ titulo, saudacao, paragrafos = [], destaque, botao, observacao }) {
  const trecho = (parte) => (typeof parte === 'string' ? escaparHtml(parte) : `<strong>${escaparHtml(parte.forte)}</strong>`);
  const paragrafoHtml = (p) => (Array.isArray(p) ? p.map(trecho).join('') : trecho(p));
  const paragrafoTexto = (p) => (Array.isArray(p) ? p.map((x) => (typeof x === 'string' ? x : x.forte)).join('') : p);
  const estiloP = `margin:0 0 16px;font-family:Arial,Helvetica,sans-serif;font-size:16px;line-height:24px;color:${COR.texto};`;

  const html = `<!DOCTYPE html>
<html lang="pt-BR">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="color-scheme" content="light">
<title>${escaparHtml(titulo)}</title>
</head>
<body style="margin:0;padding:0;background:${COR.fundo};">
<table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="background:${COR.fundo};">
<tr><td align="center" style="padding:24px 12px;">
<table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="max-width:560px;background:${COR.cartao};border:1px solid ${COR.borda};border-radius:12px;">
<tr><td style="padding:28px 32px 8px;">
<a href="${urlDoApp('/')}" style="text-decoration:none;"><img src="${urlDoApp('/email/logo-guia-jovem.png')}" width="200" height="31" alt="Guia Jovem" style="display:block;border:0;outline:none;width:200px;height:31px;font-family:Arial,Helvetica,sans-serif;font-size:22px;font-weight:bold;color:${COR.primaria};"></a>
</td></tr>
<tr><td style="padding:16px 32px 8px;">
<h1 style="margin:0 0 20px;font-family:Arial,Helvetica,sans-serif;font-size:22px;line-height:30px;color:${COR.texto};">${escaparHtml(titulo)}</h1>
${saudacao ? `<p style="${estiloP}">${escaparHtml(saudacao)}</p>` : ''}
${paragrafos.map((p) => `<p style="${estiloP}">${paragrafoHtml(p)}</p>`).join('\n')}
${destaque ? `<table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="margin:0 0 20px;"><tr><td style="background:${COR.destaque};border-left:4px solid #B26A00;border-radius:6px;padding:14px 16px;font-family:Arial,Helvetica,sans-serif;font-size:15px;line-height:22px;color:${COR.texto};"><strong>${escaparHtml(destaque.titulo)}</strong><br>${escaparHtml(destaque.texto)}</td></tr></table>` : ''}
${botao ? `<table role="presentation" cellpadding="0" cellspacing="0" border="0" style="margin:8px 0 16px;"><tr><td align="center" bgcolor="${COR.primaria}" style="border-radius:999px;"><a href="${escaparHtml(botao.url)}" style="display:inline-block;padding:14px 28px;font-family:Arial,Helvetica,sans-serif;font-size:16px;font-weight:bold;color:#FFFFFF;text-decoration:none;border-radius:999px;">${escaparHtml(botao.texto)}</a></td></tr></table>
<p style="margin:0 0 16px;font-family:Arial,Helvetica,sans-serif;font-size:13px;line-height:20px;color:${COR.secundario};">Se o botão não funcionar, copie e cole este endereço no navegador:<br><a href="${escaparHtml(botao.url)}" style="color:${COR.primaria};word-break:break-all;">${escaparHtml(botao.url)}</a></p>` : ''}
${observacao ? `<p style="margin:0 0 16px;font-family:Arial,Helvetica,sans-serif;font-size:14px;line-height:22px;color:${COR.secundario};">${escaparHtml(observacao)}</p>` : ''}
</td></tr>
<tr><td style="padding:20px 32px 28px;border-top:1px solid ${COR.borda};font-family:Arial,Helvetica,sans-serif;font-size:12px;line-height:18px;color:${COR.secundario};">
Guia Jovem: universidades, cursos e programas de acesso ao ensino superior.<br>
Este é um e-mail automático, enviado porque há uma conta com este endereço no Guia Jovem. Não é preciso responder; para falar com a equipe, use a área de sugestões em <a href="${urlDoApp('/')}" style="color:${COR.primaria};">${escaparHtml(urlDoApp('/').replace(/^https?:\/\//, '').replace(/\/$/, ''))}</a>.
</td></tr>
</table>
</td></tr>
</table>
</body>
</html>`;

  const texto = [
    titulo,
    '',
    saudacao,
    ...paragrafos.map(paragrafoTexto),
    destaque ? `${destaque.titulo}: ${destaque.texto}` : null,
    botao ? `${botao.texto}: ${botao.url}` : null,
    observacao,
    '',
    '--',
    'Guia Jovem. E-mail automático: não é preciso responder. Para falar com a equipe, use a área de sugestões do site.',
  ]
    .filter((linha) => linha !== null && linha !== undefined)
    .join('\n');

  return { html, texto };
}

module.exports = { montarEmail, escaparHtml, urlDoApp };
