const nodemailer = require('nodemailer');

const env = require('./env');

// Sem SMTP_HOST fora de produção (desenvolvimento, demonstração e a
// conferência de ponta a ponta), o e-mail não sai: vai para o log do
// servidor, com o link de recuperação de senha. Em produção, a falta do SMTP
// continua sendo erro.
const semSmtp = !env.SMTP_HOST && env.NODE_ENV !== 'production';

const transporter = semSmtp
  ? nodemailer.createTransport({ jsonTransport: true })
  : nodemailer.createTransport({
      host: env.SMTP_HOST,
      port: env.SMTP_PORT,
      secure: env.SMTP_PORT === 465,
      auth: env.SMTP_USER ? { user: env.SMTP_USER, pass: env.SMTP_PASSWORD } : undefined,
    });

/** Envia HTML e, quando houver, a versão em texto puro (clientes sem HTML). */
async function enviarEmail({ para, assunto, html, texto }) {
  const resultado = await transporter.sendMail({
    from: env.SMTP_FROM,
    to: para,
    subject: assunto,
    html,
    ...(texto ? { text: texto } : {}),
  });
  if (semSmtp && env.NODE_ENV !== 'test') {
    console.log(`[e-mail sem SMTP] para: ${para} | assunto: ${assunto}\n${texto ?? html}`);
  }
  return resultado;
}

module.exports = { transporter, enviarEmail };
