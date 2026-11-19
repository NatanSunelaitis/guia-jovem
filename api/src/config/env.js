const { z } = require('zod');

require('dotenv').config();

const schema = z.object({
  PORT: z.coerce.number().default(3000),
  NODE_ENV: z.enum(['development', 'test', 'production']).default('development'),
  DATABASE_URL: z.string().min(1, 'DATABASE_URL é obrigatória'),
  JWT_ACCESS_SECRET: z.string().min(1, 'JWT_ACCESS_SECRET é obrigatória'),
  JWT_REFRESH_SECRET: z.string().min(1, 'JWT_REFRESH_SECRET é obrigatória'),
  JWT_ACCESS_EXPIRES_IN: z.string().default('15m'),
  JWT_REFRESH_EXPIRES_IN: z.string().default('7d'),
  GOOGLE_CLIENT_ID: z.string().optional().default(''),
  SMTP_HOST: z.string().optional().default(''),
  SMTP_PORT: z.coerce.number().optional().default(587),
  SMTP_USER: z.string().optional().default(''),
  SMTP_PASSWORD: z.string().optional().default(''),
  SMTP_FROM: z.string().optional().default('Guia Jovem <nao-responda@guiajovem.com.br>'),
  // 5.11: tentativas de login e de recuperação de senha por IP a cada 15 minutos.
  LIMITE_TENTATIVAS_LOGIN: z.coerce.number().int().positive().default(10),
  APP_URL: z.string().optional().default('http://localhost:8080'),
  ADMIN_NOME: z.string().optional().default('Administrador Guia Jovem'),
  ADMIN_EMAIL: z.string().optional().default('admin@guiajovem.com.br'),
  ADMIN_SENHA: z.string().optional().default('troque-esta-senha'),
});

const parsed = schema.safeParse(process.env);

if (!parsed.success) {
  console.error('Variáveis de ambiente inválidas:', parsed.error.flatten().fieldErrors);
  throw new Error('Configuração de ambiente inválida. Verifique o arquivo .env.');
}

module.exports = parsed.data;
