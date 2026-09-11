const nodemailer = require('nodemailer');

const env = require('./env');

const transporter = nodemailer.createTransport({
  host: env.SMTP_HOST,
  port: env.SMTP_PORT,
  secure: env.SMTP_PORT === 465,
  auth: env.SMTP_USER ? { user: env.SMTP_USER, pass: env.SMTP_PASSWORD } : undefined,
});

async function enviarEmail({ para, assunto, html }) {
  return transporter.sendMail({
    from: env.SMTP_FROM,
    to: para,
    subject: assunto,
    html,
  });
}

module.exports = { transporter, enviarEmail };
